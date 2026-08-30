-- Bound remaining authenticated quota races and continuously reconcile store
-- entitlements so refunds/revocations do not rely on an owner opening the app.

create or replace function public.register_trial_device(
  target_store_id uuid,
  device_claim text
)
returns boolean
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  current_account_hash bytea;
  current_device_hash bytea;
  linked_account_hash bytea;
  registered_devices integer;
  normalized_claim text := lower(trim(coalesce(device_claim, '')));
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;
  if not exists (
    select 1
    from public.store_members member
    join public.stores store on store.id = member.store_id
    where member.store_id = target_store_id
      and member.user_id = auth.uid()
      and member.role = 'owner'
      and member.status = 'active'
      and store.owner_id = auth.uid()
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  current_account_hash := extensions.digest(
    'damanak:trial-account:v1:' || auth.uid()::text,
    'sha256'
  );
  current_device_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(encode(current_account_hash, 'hex'), 0)
  );

  insert into private.trial_account_claims(account_hash)
  values (current_account_hash)
  on conflict (account_hash) do update set last_seen_at = now();

  select account_hash into linked_account_hash
  from private.trial_device_claims
  where device_hash = current_device_hash;
  if found then
    if linked_account_hash = current_account_hash then
      update private.trial_device_claims
      set last_seen_at = now()
      where device_hash = current_device_hash;
      return true;
    end if;
    return false;
  end if;

  select count(*) into registered_devices
  from private.trial_device_claims
  where account_hash = current_account_hash;
  if registered_devices >= 5 then
    return false;
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (current_device_hash, current_account_hash);
  return true;
end;
$$;

create index if not exists trial_device_claims_account_idx
  on private.trial_device_claims(account_hash);

create or replace function public.enforce_store_api_key_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':api-keys', 0)
  );
  if (
    select count(*) from public.store_api_keys
    where store_id = new.store_id and revoked_at is null
  ) >= 5 then
    raise exception 'API_KEY_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

drop trigger if exists store_api_keys_limit on public.store_api_keys;
create trigger store_api_keys_limit
before insert on public.store_api_keys
for each row execute function public.enforce_store_api_key_limit();

create or replace function public.enforce_store_webhook_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.is_active and (tg_op = 'INSERT' or not old.is_active) then
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(new.store_id::text || ':webhooks', 0)
    );
    if (
      select count(*) from public.store_webhooks
      where store_id = new.store_id and is_active
        and (tg_op = 'INSERT' or id <> new.id)
    ) >= 5 then
      raise exception 'WEBHOOK_LIMIT_REACHED';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists store_webhooks_limit on public.store_webhooks;
create trigger store_webhooks_limit
before insert or update of is_active on public.store_webhooks
for each row execute function public.enforce_store_webhook_limit();

alter table public.store_entitlements
  add column if not exists next_verification_at timestamptz not null default now(),
  add column if not exists refresh_locked_at timestamptz,
  add column if not exists refresh_failures integer not null default 0
    check (refresh_failures between 0 and 1000);

update public.store_entitlements
set next_verification_at = least(next_verification_at, now());

create index if not exists store_entitlements_refresh_due_idx
  on public.store_entitlements(next_verification_at, verified_at)
  where status in ('active', 'grace', 'past_due');

create or replace function public.claim_store_entitlement_refreshes(
  requested_limit integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements
  set refresh_locked_at = null
  where refresh_locked_at < now() - interval '15 minutes';

  with selected as (
    select entitlement.id
    from public.store_entitlements entitlement
    where entitlement.next_verification_at <= now()
      and entitlement.refresh_locked_at is null
      and entitlement.status in ('active', 'grace', 'past_due')
    order by entitlement.next_verification_at, entitlement.verified_at
    for update skip locked
    limit greatest(1, least(requested_limit, 20))
  ), claimed as (
    update public.store_entitlements entitlement
    set refresh_locked_at = now()
    from selected
    where entitlement.id = selected.id
    returning entitlement.*
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', claimed.id,
    'storeId', claimed.store_id,
    'userId', claimed.user_id,
    'platform', claimed.platform,
    'originalTransactionId', claimed.original_transaction_id,
    'purchaseToken', receipt.purchase_token
  ) order by claimed.next_verification_at), '[]'::jsonb)
  into result
  from claimed
  left join private.store_receipt_secrets receipt
    on receipt.platform = claimed.platform
   and receipt.original_transaction_id = claimed.original_transaction_id;
  return result;
end;
$$;

create or replace function public.release_store_entitlement_refresh(
  target_entitlement_id uuid,
  refresh_succeeded boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements
  set refresh_locked_at = null,
      refresh_failures = case
        when refresh_succeeded then 0
        else least(refresh_failures + 1, 1000)
      end,
      next_verification_at = case
        when not refresh_succeeded then now() + interval '15 minutes'
        when status in ('active', 'grace') then now() + interval '6 hours'
        when status = 'past_due' then now() + interval '1 hour'
        else now() + interval '24 hours'
      end
  where id = target_entitlement_id;
end;
$$;

revoke all on function public.enforce_store_api_key_limit()
  from public, anon, authenticated;
revoke all on function public.enforce_store_webhook_limit()
  from public, anon, authenticated;
revoke all on function public.claim_store_entitlement_refreshes(integer)
  from public, anon, authenticated;
revoke all on function public.release_store_entitlement_refresh(uuid, boolean)
  from public, anon, authenticated;
grant execute on function public.claim_store_entitlement_refreshes(integer)
  to service_role;
grant execute on function public.release_store_entitlement_refresh(uuid, boolean)
  to service_role;

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

do $schedule$
declare
  existing_job bigint;
begin
  select jobid into existing_job
  from cron.job
  where jobname = 'damanak-entitlement-refresh';
  if existing_job is not null then
    perform cron.unschedule(existing_job);
  end if;
  perform cron.schedule(
    'damanak-entitlement-refresh',
    '*/5 * * * *',
    $request$
      select net.http_post(
        url := 'https://exxayzlklvgeyqhvtzgi.supabase.co/functions/v1/refresh-store-entitlements',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'authorization', 'Bearer ' || coalesce((
            select decrypted_secret
            from vault.decrypted_secrets
            where name = 'entitlement_refresh_secret'
            limit 1
          ), '')
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 30000
      );
    $request$
  );
end;
$schedule$;

do $verification$
begin
  if exists (
    select 1
    from pg_catalog.pg_proc procedure
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure.pronamespace
    where namespace.nspname = 'public'
      and pg_catalog.has_function_privilege(
        'anon', procedure.oid, 'EXECUTE'
      )
  ) then
    raise exception 'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS';
  end if;
end;
$verification$;
