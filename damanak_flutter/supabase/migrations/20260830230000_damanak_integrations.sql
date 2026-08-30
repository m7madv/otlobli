-- Scale-plan integrations. API tokens are returned once and only their SHA-256
-- digest is stored. Webhook signing secrets stay service-role only.

create table if not exists public.store_api_keys (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  name text not null check (char_length(trim(name)) between 2 and 80),
  key_prefix text not null check (char_length(key_prefix) between 12 and 24),
  key_hash bytea not null unique,
  scopes text[] not null default array['warranties:read']::text[],
  created_by uuid references auth.users(id) on delete set null,
  last_used_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  check (scopes <@ array['warranties:read', 'claims:read', 'claims:write']::text[])
);

create table if not exists public.store_webhooks (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  endpoint_url text not null check (
    char_length(endpoint_url) <= 500 and endpoint_url ~ '^https://'
  ),
  events text[] not null,
  signing_secret text not null,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (events <@ array['claim.created', 'claim.updated']::text[]),
  check (cardinality(events) between 1 and 2)
);

create table if not exists public.webhook_deliveries (
  id uuid primary key default gen_random_uuid(),
  webhook_id uuid not null references public.store_webhooks(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  event_name text not null check (event_name in ('claim.created', 'claim.updated')),
  payload jsonb not null,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'delivered', 'failed')),
  attempts integer not null default 0 check (attempts between 0 and 8),
  locked_at timestamptz,
  next_attempt_at timestamptz not null default now(),
  response_status integer,
  last_error text,
  delivered_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.api_request_logs (
  id bigint generated always as identity primary key,
  key_id uuid references public.store_api_keys(id) on delete set null,
  store_id uuid not null references public.stores(id) on delete cascade,
  method text not null,
  path text not null,
  response_status integer not null,
  created_at timestamptz not null default now()
);

create index if not exists store_api_keys_store_created_idx
  on public.store_api_keys(store_id, created_at desc);
create index if not exists store_webhooks_store_created_idx
  on public.store_webhooks(store_id, created_at desc);
create index if not exists webhook_deliveries_pending_idx
  on public.webhook_deliveries(next_attempt_at, created_at)
  where status = 'pending';
create index if not exists api_request_logs_key_created_idx
  on public.api_request_logs(key_id, created_at desc);

create or replace function public.store_plan_allows(
  target_store_id uuid,
  entitlement_name text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case entitlement_name
      when 'api' then plan.api_access
      when 'webhook' then plan.webhook_access
      when 'branding' then plan.custom_branding
      else false
    end
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id
      and subscription.status in ('trialing', 'active')
    limit 1
  ), false)
$$;

create or replace function public.enforce_store_branding_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (
    new.logo_url is distinct from old.logo_url or
    new.brand_color is distinct from old.brand_color or
    new.customer_portal_title is distinct from old.customer_portal_title
  ) and not public.store_plan_allows(new.id, 'branding') then
    raise exception 'PLAN_BRANDING_REQUIRED';
  end if;
  return new;
end;
$$;

drop trigger if exists stores_branding_entitlement on public.stores;
create trigger stores_branding_entitlement
before update of logo_url, brand_color, customer_portal_title on public.stores
for each row execute function public.enforce_store_branding_entitlement();

create or replace function public.create_store_api_key(
  target_store_id uuid,
  key_name text,
  requested_scopes text[] default array['warranties:read']::text[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  plain_key text;
  created_key public.store_api_keys;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if not public.store_plan_allows(target_store_id, 'api') then
    raise exception 'PLAN_API_REQUIRED';
  end if;
  if char_length(trim(key_name)) not between 2 and 80 or
     cardinality(requested_scopes) not between 1 and 3 or
     not (requested_scopes <@ array['warranties:read', 'claims:read', 'claims:write']::text[]) then
    raise exception 'API_KEY_INPUT_INVALID';
  end if;
  if (select count(*) from public.store_api_keys
      where store_id = target_store_id and revoked_at is null) >= 5 then
    raise exception 'API_KEY_LIMIT_REACHED';
  end if;

  plain_key := 'dmn_live_' || encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.store_api_keys(
    store_id, name, key_prefix, key_hash, scopes, created_by
  ) values (
    target_store_id, trim(key_name), left(plain_key, 17),
    extensions.digest(plain_key, 'sha256'), requested_scopes, auth.uid()
  ) returning * into created_key;

  return jsonb_build_object(
    'id', created_key.id,
    'name', created_key.name,
    'keyPrefix', created_key.key_prefix,
    'scopes', created_key.scopes,
    'createdAt', created_key.created_at,
    'secret', plain_key
  );
end;
$$;

create or replace function public.authenticate_store_api_key(presented_key text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  matched_key public.store_api_keys;
begin
  if presented_key !~ '^dmn_live_[0-9a-f]{64}$' then return null; end if;
  select * into matched_key from public.store_api_keys
  where key_hash = extensions.digest(presented_key, 'sha256')
    and revoked_at is null;
  if matched_key.id is null or not public.store_plan_allows(matched_key.store_id, 'api') then
    return null;
  end if;
  update public.store_api_keys set last_used_at = now() where id = matched_key.id;
  return jsonb_build_object(
    'keyId', matched_key.id,
    'storeId', matched_key.store_id,
    'scopes', matched_key.scopes
  );
end;
$$;

create or replace function public.list_store_api_keys(target_store_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.has_store_role(target_store_id, array['owner']) then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', key.id, 'name', key.name, 'keyPrefix', key.key_prefix,
      'scopes', key.scopes, 'createdAt', key.created_at,
      'lastUsedAt', key.last_used_at, 'revokedAt', key.revoked_at
    ) order by key.created_at desc), '[]'::jsonb)
  else '[]'::jsonb end
  from public.store_api_keys key where key.store_id = target_store_id
$$;

create or replace function public.revoke_store_api_key(target_key_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare target_store_id uuid;
begin
  select store_id into target_store_id from public.store_api_keys where id = target_key_id;
  if target_store_id is null or not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  update public.store_api_keys set revoked_at = coalesce(revoked_at, now())
  where id = target_key_id;
end;
$$;

create or replace function public.create_store_webhook(
  target_store_id uuid,
  target_url text,
  target_events text[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare secret text; created_hook public.store_webhooks;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if not public.store_plan_allows(target_store_id, 'webhook') then
    raise exception 'PLAN_WEBHOOK_REQUIRED';
  end if;
  if target_url !~ '^https://' or char_length(target_url) > 500 or
     cardinality(target_events) not between 1 and 2 or
     not (target_events <@ array['claim.created', 'claim.updated']::text[]) then
    raise exception 'WEBHOOK_INPUT_INVALID';
  end if;
  if (select count(*) from public.store_webhooks
      where store_id = target_store_id and is_active) >= 5 then
    raise exception 'WEBHOOK_LIMIT_REACHED';
  end if;
  secret := 'whsec_' || encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.store_webhooks(
    store_id, endpoint_url, events, signing_secret, created_by
  ) values (target_store_id, target_url, target_events, secret, auth.uid())
  returning * into created_hook;
  return jsonb_build_object(
    'id', created_hook.id, 'endpointUrl', created_hook.endpoint_url,
    'events', created_hook.events, 'isActive', true,
    'createdAt', created_hook.created_at, 'secret', secret
  );
end;
$$;

create or replace function public.list_store_webhooks(target_store_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when public.has_store_role(target_store_id, array['owner']) then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', hook.id, 'endpointUrl', hook.endpoint_url,
      'events', hook.events, 'isActive', hook.is_active,
      'createdAt', hook.created_at
    ) order by hook.created_at desc), '[]'::jsonb)
  else '[]'::jsonb end
  from public.store_webhooks hook where hook.store_id = target_store_id
$$;

create or replace function public.set_store_webhook_active(
  target_webhook_id uuid,
  target_active boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare target_store_id uuid;
begin
  select store_id into target_store_id from public.store_webhooks where id = target_webhook_id;
  if target_store_id is null or not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if target_active and not public.store_plan_allows(target_store_id, 'webhook') then
    raise exception 'PLAN_WEBHOOK_REQUIRED';
  end if;
  update public.store_webhooks set is_active = target_active, updated_at = now()
  where id = target_webhook_id;
end;
$$;

create or replace function public.queue_claim_webhooks()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare event_name text;
begin
  event_name := case when tg_op = 'INSERT' then 'claim.created' else 'claim.updated' end;
  insert into public.webhook_deliveries(webhook_id, store_id, event_name, payload)
  select hook.id, new.store_id, event_name, jsonb_build_object(
    'event', event_name,
    'createdAt', now(),
    'data', jsonb_build_object(
      'id', new.id, 'claimNumber', new.claim_number, 'status', new.status,
      'category', new.category, 'priority', new.priority,
      'warrantyId', new.warranty_id, 'updatedAt', new.updated_at
    )
  )
  from public.store_webhooks hook
  where hook.store_id = new.store_id and hook.is_active
    and public.store_plan_allows(new.store_id, 'webhook')
    and event_name = any(hook.events);
  return new;
end;
$$;

drop trigger if exists maintenance_requests_webhooks on public.maintenance_requests;
create trigger maintenance_requests_webhooks
after insert or update on public.maintenance_requests
for each row execute function public.queue_claim_webhooks();

create or replace function public.claim_webhook_deliveries(
  requested_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare result jsonb;
begin
  -- Recover work if a dispatcher stopped after reserving it.
  update public.webhook_deliveries
  set status = 'pending', locked_at = null
  where status = 'processing' and locked_at < now() - interval '15 minutes';

  with selected as (
    select delivery.id
    from public.webhook_deliveries delivery
    where delivery.status = 'pending' and delivery.next_attempt_at <= now()
    order by delivery.created_at
    for update skip locked
    limit greatest(1, least(requested_limit, 100))
  ), claimed as (
    update public.webhook_deliveries delivery
    set status = 'processing', locked_at = now()
    from selected
    where delivery.id = selected.id
    returning delivery.*
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', claimed.id,
    'event_name', claimed.event_name,
    'payload', claimed.payload,
    'attempts', claimed.attempts,
    'endpoint_url', hook.endpoint_url,
    'signing_secret', hook.signing_secret,
    'is_active', hook.is_active
  ) order by claimed.created_at), '[]'::jsonb)
  into result
  from claimed
  join public.store_webhooks hook on hook.id = claimed.webhook_id;

  return result;
end;
$$;

alter table public.store_api_keys enable row level security;
alter table public.store_webhooks enable row level security;
alter table public.webhook_deliveries enable row level security;
alter table public.api_request_logs enable row level security;

revoke all on table public.store_api_keys from anon, authenticated;
revoke all on table public.store_webhooks from anon, authenticated;
revoke all on table public.webhook_deliveries from anon, authenticated;
revoke all on table public.api_request_logs from anon, authenticated;

revoke all on function public.store_plan_allows(uuid, text) from public;
revoke all on function public.enforce_store_branding_entitlement() from public;
revoke all on function public.create_store_api_key(uuid, text, text[]) from public;
revoke all on function public.authenticate_store_api_key(text) from public;
revoke all on function public.list_store_api_keys(uuid) from public;
revoke all on function public.revoke_store_api_key(uuid) from public;
revoke all on function public.create_store_webhook(uuid, text, text[]) from public;
revoke all on function public.list_store_webhooks(uuid) from public;
revoke all on function public.set_store_webhook_active(uuid, boolean) from public;
revoke all on function public.queue_claim_webhooks() from public;
revoke all on function public.claim_webhook_deliveries(integer) from public;

grant execute on function public.create_store_api_key(uuid, text, text[]) to authenticated;
grant execute on function public.list_store_api_keys(uuid) to authenticated;
grant execute on function public.revoke_store_api_key(uuid) to authenticated;
grant execute on function public.create_store_webhook(uuid, text, text[]) to authenticated;
grant execute on function public.list_store_webhooks(uuid) to authenticated;
grant execute on function public.set_store_webhook_active(uuid, boolean) to authenticated;
grant execute on function public.authenticate_store_api_key(text) to service_role;
grant execute on function public.claim_webhook_deliveries(integer) to service_role;
grant select, update on table public.webhook_deliveries to service_role;
grant select on table public.store_webhooks to service_role;
grant select, insert on table public.api_request_logs to service_role;
