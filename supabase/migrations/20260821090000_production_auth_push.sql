-- Production identity + notification registry used by v86.208.
-- Extends the existing custom customer/session model; no second account system.

create table if not exists public.customer_identities (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  provider text not null,
  provider_user_id text not null,
  email text,
  email_verified boolean not null default false,
  display_name text,
  created_at timestamptz not null default now(),
  last_login_at timestamptz,
  unique (provider, provider_user_id)
);

do $$
declare
  constraint_name text;
begin
  for constraint_name in
    select conname
    from pg_constraint
    where conrelid = 'public.customer_identities'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%provider%'
  loop
    execute format('alter table public.customer_identities drop constraint %I', constraint_name);
  end loop;
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.customer_identities'::regclass
      and conname = 'customer_identities_provider_check'
  ) then
    alter table public.customer_identities
      add constraint customer_identities_provider_check check (provider in ('google', 'apple'));
  end if;
end $$;

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid references public.customers(id) on delete cascade,
  phone text not null default '',
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null unique,
  device_id text,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.device_tokens alter column customer_id drop not null;
alter table public.device_tokens add column if not exists installation_id text;
alter table public.device_tokens add column if not exists provider text;
alter table public.device_tokens add column if not exists environment text not null default 'production';
alter table public.device_tokens add column if not exists app_version text not null default '';
alter table public.device_tokens add column if not exists os_version text not null default '';
alter table public.device_tokens add column if not exists locale text not null default '';
alter table public.device_tokens add column if not exists timezone text not null default '';
alter table public.device_tokens add column if not exists notifications_enabled boolean not null default true;
alter table public.device_tokens add column if not exists last_seen_at timestamptz not null default now();
alter table public.device_tokens add column if not exists invalidated_at timestamptz;

create index if not exists idx_device_tokens_installation on public.device_tokens(installation_id);
create index if not exists idx_device_tokens_active_customer
  on public.device_tokens(customer_id) where notifications_enabled and invalidated_at is null;

-- Keep one active provider token per installation. Preserve history by
-- invalidating older duplicates before the partial unique index is created.
with ranked_installations as (
  select id, row_number() over (
    partition by installation_id order by last_seen_at desc nulls last, updated_at desc, id desc
  ) as rank
  from public.device_tokens
  where installation_id is not null and trim(installation_id) <> ''
    and enabled and notifications_enabled and invalidated_at is null
)
update public.device_tokens tokens
set enabled = false, notifications_enabled = false, invalidated_at = now(), updated_at = now()
from ranked_installations ranked
where tokens.id = ranked.id and ranked.rank > 1;

create unique index if not exists uq_device_tokens_active_installation
  on public.device_tokens(installation_id)
  where installation_id is not null and enabled and notifications_enabled and invalidated_at is null;

alter table public.customer_identities enable row level security;
alter table public.device_tokens enable row level security;
revoke all on table public.customer_identities from public, anon, authenticated;
revoke all on table public.device_tokens from public, anon, authenticated;

create table if not exists public.apple_authorizations (
  provider_user_id text primary key,
  customer_id uuid references public.customers(id) on delete cascade,
  refresh_token text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.apple_authorizations enable row level security;
revoke all on table public.apple_authorizations from public, anon, authenticated;

create or replace function public.upsert_device_token_v2(
  p_session_token text,
  p_installation_id text,
  p_platform text,
  p_provider text,
  p_token text,
  p_environment text,
  p_app_version text,
  p_os_version text,
  p_locale text,
  p_timezone text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  target_phone text;
begin
  if p_platform not in ('android', 'ios') then raise exception 'invalid platform'; end if;
  if (p_platform = 'ios' and p_provider <> 'apns') or (p_platform = 'android' and p_provider <> 'fcm') then
    raise exception 'invalid provider for platform';
  end if;
  if coalesce(trim(p_token), '') = '' or length(p_token) > 4096 then raise exception 'invalid token'; end if;
  if coalesce(trim(p_installation_id), '') = '' or length(p_installation_id) > 128 then raise exception 'invalid installation'; end if;
  if p_environment not in ('development', 'production') then raise exception 'invalid environment'; end if;

  target_customer_id := public.require_customer_session(p_session_token, null);
  select phone into target_phone from public.customers where id = target_customer_id;

  update public.device_tokens
  set notifications_enabled = false, enabled = false, invalidated_at = now(), updated_at = now()
  where installation_id = p_installation_id and token <> p_token and invalidated_at is null;

  insert into public.device_tokens (
    customer_id, phone, platform, provider, token, device_id, installation_id,
    environment, app_version, os_version, locale, timezone,
    enabled, notifications_enabled, last_seen_at, invalidated_at, updated_at
  ) values (
    target_customer_id, coalesce(target_phone, ''), p_platform, p_provider, p_token,
    p_installation_id, p_installation_id, p_environment, left(coalesce(p_app_version, ''), 32),
    left(coalesce(p_os_version, ''), 64), left(coalesce(p_locale, ''), 32),
    left(coalesce(p_timezone, ''), 64), true, true, now(), null, now()
  )
  on conflict (token) do update set
    customer_id = excluded.customer_id,
    phone = excluded.phone,
    platform = excluded.platform,
    provider = excluded.provider,
    device_id = excluded.device_id,
    installation_id = excluded.installation_id,
    environment = excluded.environment,
    app_version = excluded.app_version,
    os_version = excluded.os_version,
    locale = excluded.locale,
    timezone = excluded.timezone,
    enabled = true,
    notifications_enabled = true,
    last_seen_at = now(),
    invalidated_at = null,
    updated_at = now();
end;
$$;

create or replace function public.detach_device_token(
  p_session_token text,
  p_installation_id text
) returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  update public.device_tokens
  set customer_id = null,
      phone = '',
      enabled = false,
      notifications_enabled = false,
      invalidated_at = now(),
      updated_at = now()
  where customer_id = target_customer_id and installation_id = p_installation_id;
end;
$$;

create or replace function public.link_customer_identity(
  p_session_token text,
  p_provider text,
  p_provider_user_id text,
  p_email text,
  p_email_verified boolean,
  p_display_name text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  session_customer_id uuid;
  existing_customer_id uuid;
begin
  if p_provider not in ('google', 'apple') then raise exception 'invalid provider'; end if;
  if coalesce(trim(p_provider_user_id), '') = '' then raise exception 'invalid provider user id'; end if;
  if length(p_provider_user_id) > 512 then raise exception 'invalid provider user id'; end if;
  session_customer_id := public.require_customer_session(p_session_token, null);
  perform pg_advisory_xact_lock(hashtextextended(
    'customer_identity:' || p_provider || ':' || p_provider_user_id,
    0
  ));
  select customer_id into existing_customer_id from public.customer_identities
    where provider = p_provider and provider_user_id = p_provider_user_id limit 1;
  if existing_customer_id is not null and existing_customer_id <> session_customer_id then
    raise exception 'identity already linked to another account';
  end if;
  if coalesce(p_email_verified, false) and coalesce(trim(p_email), '') <> '' then
    perform pg_advisory_xact_lock(hashtextextended(lower(trim(p_email)), 0));
    if exists (
      select 1 from public.customer_identities
      where lower(email) = lower(trim(p_email)) and email_verified
        and customer_id <> session_customer_id
    ) then
      raise exception 'verified email already belongs to another account';
    end if;
  end if;
  insert into public.customer_identities
    (customer_id, provider, provider_user_id, email, email_verified, display_name, last_login_at)
  values
    (session_customer_id, p_provider, p_provider_user_id, nullif(trim(p_email), ''),
      coalesce(p_email_verified, false), nullif(trim(p_display_name), ''), now())
  on conflict (provider, provider_user_id) do update set
    email = excluded.email, email_verified = excluded.email_verified,
    display_name = excluded.display_name, last_login_at = now();
  select customer_id into existing_customer_id from public.customer_identities
    where provider = p_provider and provider_user_id = p_provider_user_id limit 1;
  if existing_customer_id is distinct from session_customer_id then
    raise exception 'identity already linked to another account';
  end if;
  return jsonb_build_object('customer_id', session_customer_id, 'linked', true);
end;
$$;

create or replace function public.register_external_customer(
  p_provider text,
  p_provider_user_id text,
  p_email text,
  p_email_verified boolean,
  p_display_name text,
  p_phone text,
  p_name text,
  p_governorate text,
  p_qadmous_branch text,
  p_city text,
  p_details text,
  p_token_hash text,
  p_expires_at timestamptz
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  clean_name text := trim(coalesce(p_name, ''));
  new_customer_id uuid;
  new_session_id uuid;
begin
  if p_provider not in ('google', 'apple') then raise exception 'invalid provider'; end if;
  if coalesce(trim(p_provider_user_id), '') = '' then raise exception 'invalid provider identity'; end if;
  if length(p_provider_user_id) > 512 then raise exception 'invalid provider identity'; end if;
  if length(cleaned_phone) < 8 then raise exception 'invalid delivery phone'; end if;
  if length(clean_name) < 3 then raise exception 'invalid customer name'; end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then raise exception 'invalid token hash'; end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;
  if exists (select 1 from public.customer_identities where provider = p_provider and provider_user_id = p_provider_user_id) then
    raise exception 'provider identity already registered';
  end if;
  if exists (select 1 from public.customers where phone = cleaned_phone) then
    raise exception 'delivery phone already belongs to another account';
  end if;
  if coalesce(p_email_verified, false) and coalesce(trim(p_email), '') <> '' then
    perform pg_advisory_xact_lock(hashtextextended(lower(trim(p_email)), 0));
    if exists (
      select 1 from public.customer_identities
      where lower(email) = lower(trim(p_email)) and email_verified
    ) then
      raise exception 'verified email already belongs to another account';
    end if;
  end if;

  insert into public.customers (
    phone, name, governorate, qadmous_branch, city, details,
    phone_login_enabled, phone_verified_at, updated_at
  ) values (
    cleaned_phone, clean_name, coalesce(nullif(trim(p_governorate), ''), 'دمشق'),
    trim(coalesce(p_qadmous_branch, '')), trim(coalesce(p_city, '')),
    trim(coalesce(p_details, '')), false, null, now()
  ) returning id into new_customer_id;

  insert into public.customer_identities (
    customer_id, provider, provider_user_id, email, email_verified, display_name, last_login_at
  ) values (
    new_customer_id, p_provider, p_provider_user_id, nullif(trim(coalesce(p_email, '')), ''),
    coalesce(p_email_verified, false), nullif(trim(coalesce(p_display_name, '')), ''), now()
  );

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (new_customer_id, cleaned_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return jsonb_build_object('customerId', new_customer_id, 'sessionId', new_session_id,
    'phone', cleaned_phone, 'name', clean_name);
end;
$$;

create or replace function public.get_customer_auth_methods(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  target_customer public.customers%rowtype;
  google_identity public.customer_identities%rowtype;
  apple_identity public.customer_identities%rowtype;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  select * into target_customer from public.customers where id = target_customer_id;
  select * into google_identity from public.customer_identities
    where customer_id = target_customer_id and provider = 'google' order by created_at limit 1;
  select * into apple_identity from public.customer_identities
    where customer_id = target_customer_id and provider = 'apple' order by created_at limit 1;

  return jsonb_build_object(
    'deliveryPhone', coalesce(target_customer.phone, ''),
    'phoneLinked', coalesce(target_customer.phone_login_enabled, false),
    'phoneVerifiedAt', target_customer.phone_verified_at,
    'googleLinked', google_identity.id is not null,
    'googleEmail', coalesce(google_identity.email, ''),
    'googleName', coalesce(google_identity.display_name, ''),
    'appleLinked', apple_identity.id is not null,
    'appleEmail', coalesce(apple_identity.email, ''),
    'appleName', coalesce(apple_identity.display_name, '')
  );
end;
$$;

create or replace function public.resolve_customer_for_account_deletion(p_session_token text)
returns uuid
language plpgsql
security definer
set search_path = extensions, public, pg_temp
as $$
declare
  token_digest text := encode(digest(coalesce(p_session_token, ''), 'sha256'), 'hex');
  found_session public.customer_sessions%rowtype;
begin
  if length(coalesce(p_session_token, '')) < 32 then
    raise exception 'invalid customer session';
  end if;
  select * into found_session
  from public.customer_sessions
  where token_hash = token_digest
    and revoked_at is null
    and expires_at > now()
  limit 1
  for update;
  if not found then raise exception 'invalid customer session'; end if;
  -- Account deletion remains available to a blocked owner. This resolver is
  -- private to the lifecycle Edge Function and authorizes no other action.
  update public.customer_sessions set last_used_at = now() where id = found_session.id;
  return found_session.customer_id;
end;
$$;

create or replace function public.delete_customer_account(p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  replacement_phone text;
begin
  target_customer_id := public.resolve_customer_for_account_deletion(p_session_token);
  replacement_phone := 'deleted-' || replace(target_customer_id::text, '-', '');

  delete from public.addresses where customer_id = target_customer_id;
  delete from public.apple_authorizations where customer_id = target_customer_id;
  delete from public.customer_identities where customer_id = target_customer_id;
  update public.device_tokens set customer_id = null, phone = '', enabled = false,
    notifications_enabled = false, invalidated_at = now(), updated_at = now()
    where customer_id = target_customer_id;
  update public.customers set phone = replacement_phone, name = 'Deleted account',
    governorate = '', qadmous_branch = '', city = '', details = '',
    phone_login_enabled = false, phone_verified_at = null, updated_at = now()
    where id = target_customer_id;
  update public.customer_sessions set revoked_at = now() where customer_id = target_customer_id;

  return jsonb_build_object(
    'deleted', true,
    'retained', jsonb_build_array('orders', 'payments', 'wallet ledger required for transaction records')
  );
end;
$$;

create or replace function public.get_customer_id_for_session(p_session_token text)
returns uuid
language sql
security definer
set search_path = public
as $$
  select public.require_customer_session(p_session_token, null);
$$;

grant execute on function public.upsert_device_token_v2(text,text,text,text,text,text,text,text,text,text) to anon, authenticated;
grant execute on function public.detach_device_token(text,text) to anon, authenticated;
grant execute on function public.link_customer_identity(text,text,text,text,boolean,text) to anon, authenticated;
grant execute on function public.get_customer_auth_methods(text) to anon, authenticated, service_role;
grant execute on function public.delete_customer_account(text) to anon, authenticated;
revoke all on function public.resolve_customer_for_account_deletion(text) from public, anon, authenticated;
grant execute on function public.resolve_customer_for_account_deletion(text) to service_role;
revoke all on function public.get_customer_id_for_session(text) from public, anon, authenticated;
grant execute on function public.get_customer_id_for_session(text) to service_role;
revoke all on function public.register_external_customer(text,text,text,boolean,text,text,text,text,text,text,text,text,timestamptz) from public, anon, authenticated;
grant execute on function public.register_external_customer(text,text,text,boolean,text,text,text,text,text,text,text,text,timestamptz) to service_role;
