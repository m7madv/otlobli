-- One Starter trial per account and per protected app installation. Raw device
-- claims never leave the request transaction; only SHA-256 digests are kept.

create table if not exists private.trial_account_claims (
  account_hash bytea primary key check (octet_length(account_hash) = 32),
  first_claimed_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create table if not exists private.trial_device_claims (
  device_hash bytea primary key check (octet_length(device_hash) = 32),
  account_hash bytea not null check (octet_length(account_hash) = 32),
  first_claimed_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

revoke all on table private.trial_account_claims
  from public, anon, authenticated;
revoke all on table private.trial_device_claims
  from public, anon, authenticated;

-- Existing owners have already received a trial in the historical flow. This
-- prevents a second store trial on the same account after the migration.
insert into private.trial_account_claims(
  account_hash, first_claimed_at, last_seen_at
)
select
  extensions.digest('damanak:trial-account:v1:' || owner_id::text, 'sha256'),
  min(created_at),
  max(updated_at)
from public.stores
group by owner_id
on conflict (account_hash) do update set
  first_claimed_at = least(
    private.trial_account_claims.first_claimed_at,
    excluded.first_claimed_at
  ),
  last_seen_at = greatest(
    private.trial_account_claims.last_seen_at,
    excluded.last_seen_at
  );

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

  insert into private.trial_account_claims(account_hash)
  values (current_account_hash)
  on conflict (account_hash) do update set last_seen_at = now();

  select account_hash into linked_account_hash
  from private.trial_device_claims
  where device_hash = current_device_hash;

  if not found then
    insert into private.trial_device_claims(device_hash, account_hash)
    values (current_device_hash, current_account_hash);
    return true;
  end if;
  if linked_account_hash = current_account_hash then
    update private.trial_device_claims
    set last_seen_at = now()
    where device_hash = current_device_hash;
    return true;
  end if;
  return false;
end;
$$;

-- Old builds do not send a protected device claim. Refuse only trial creation;
-- sign-in, purchase restoration, and joining a paid store remain available.
create or replace function public.create_store_with_trial(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
  raise exception 'APP_UPDATE_REQUIRED_FOR_TRIAL';
end;
$$;

create or replace function public.create_store_with_trial(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language plpgsql
security definer
set search_path = public, private, extensions
as $$
declare
  created_store_id uuid;
  inserted_rows integer;
  account_claim_hash bytea;
  device_claim_hash bytea;
  normalized_claim text := lower(trim(coalesce(device_claim, '')));
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(trim(store_name)) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if store_country_code not in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM') then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;

  account_claim_hash := extensions.digest(
    'damanak:trial-account:v1:' || auth.uid()::text,
    'sha256'
  );
  device_claim_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  insert into private.trial_account_claims(account_hash)
  values (account_claim_hash)
  on conflict (account_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then
    raise exception 'TRIAL_ALREADY_USED_BY_ACCOUNT';
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (device_claim_hash, account_claim_hash)
  on conflict (device_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then
    raise exception 'TRIAL_ALREADY_USED_ON_DEVICE';
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    trim(store_name),
    trim(coalesce(store_phone, '')),
    trim(coalesce(store_city, '')),
    store_country_code,
    auth.uid()
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, auth.uid(), 'owner');

  insert into public.subscriptions(
    store_id, plan_id, status, trial_ends_at, source
  ) values (
    created_store_id, 'starter', 'trialing',
    now() + interval '14 days', 'trial'
  );

  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id,
    metadata
  ) values (
    created_store_id, auth.uid(), 'store_created', 'store',
    created_store_id,
    jsonb_build_object('trial_guard', 'account_and_device_v1')
  );

  return created_store_id;
end;
$$;

revoke all on function public.register_trial_device(uuid, text)
  from public, anon, authenticated;
revoke all on function public.create_store_with_trial(text, text, text, text)
  from public, anon, authenticated;
revoke all on function public.create_store_with_trial(
  text, text, text, text, text
) from public, anon, authenticated;

grant execute on function public.register_trial_device(uuid, text)
  to authenticated;
grant execute on function public.create_store_with_trial(text, text, text, text)
  to authenticated;
grant execute on function public.create_store_with_trial(
  text, text, text, text, text
) to authenticated;

comment on function public.create_store_with_trial(
  text, text, text, text, text
) is 'Creates one 14-day Starter trial per authenticated account and protected app installation.';
