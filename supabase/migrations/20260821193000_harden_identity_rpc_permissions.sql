-- Keep identity verification and session issuance behind trusted Edge Functions.
-- SECURITY DEFINER functions are executable by PUBLIC by default in PostgreSQL,
-- so every privileged identity RPC is explicitly service-role only here.

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
  if coalesce(trim(p_provider_user_id), '') = '' or length(p_provider_user_id) > 512 then
    raise exception 'invalid provider user id';
  end if;
  session_customer_id := public.require_customer_session(p_session_token, null);

  -- Serialize every attempt to claim the same external identity. Without this
  -- lock, two sessions can both observe no owner before one INSERT wins.
  perform pg_advisory_xact_lock(hashtextextended(
    'customer_identity:' || p_provider || ':' || p_provider_user_id,
    0
  ));
  select customer_id into existing_customer_id
  from public.customer_identities
  where provider = p_provider and provider_user_id = p_provider_user_id
  limit 1;
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
    email = excluded.email,
    email_verified = excluded.email_verified,
    display_name = excluded.display_name,
    last_login_at = now();

  select customer_id into existing_customer_id
  from public.customer_identities
  where provider = p_provider and provider_user_id = p_provider_user_id
  limit 1;
  if existing_customer_id is distinct from session_customer_id then
    raise exception 'identity already linked to another account';
  end if;
  return jsonb_build_object('customer_id', session_customer_id, 'linked', true);
end;
$$;

create or replace function public.create_customer_session_for_customer(
  p_customer_id uuid,
  p_token_hash text,
  p_expires_at timestamptz
) returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  target_phone text;
  target_blocked boolean;
  new_session_id uuid;
begin
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid token hash';
  end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;

  select phone, blocked
  into target_phone, target_blocked
  from public.customers
  where id = p_customer_id
  limit 1;

  if target_phone is null then raise exception 'customer not found'; end if;
  if coalesce(target_blocked, false) then
    raise exception 'customer_blocked' using errcode = 'P0001';
  end if;

  delete from public.customer_sessions
  where expires_at <= now() or revoked_at is not null;

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (p_customer_id, target_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return new_session_id;
end;
$$;

create or replace function public.find_identity_customer(
  p_provider text,
  p_provider_user_id text
) returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if p_provider not in ('google', 'apple') then raise exception 'invalid provider'; end if;
  if coalesce(trim(p_provider_user_id), '') = '' or length(p_provider_user_id) > 512 then
    raise exception 'invalid provider user id';
  end if;

  select jsonb_build_object(
    'customer_id', customer.id,
    'phone', customer.phone,
    'name', customer.name
  ) into result
  from public.customer_identities identity
  join public.customers customer on customer.id = identity.customer_id
  where identity.provider = p_provider
    and identity.provider_user_id = p_provider_user_id
  limit 1;

  return result;
end;
$$;

create or replace function public.touch_identity_login(
  p_provider text,
  p_provider_user_id text
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_provider not in ('google', 'apple') then raise exception 'invalid provider'; end if;
  if coalesce(trim(p_provider_user_id), '') = '' or length(p_provider_user_id) > 512 then
    raise exception 'invalid provider user id';
  end if;
  update public.customer_identities
  set last_login_at = now()
  where provider = p_provider and provider_user_id = p_provider_user_id;
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

create or replace function public.phone_auth_readiness()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'ready',
      to_regclass('public.customer_sessions') is not null
      and to_regprocedure('public.create_customer_session(text,text,timestamp with time zone)') is not null,
    'contract', 'customer-session-v1'
  );
$$;

create or replace function public.auth_schema_readiness()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'ready',
      exists (
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = 'apple_authorizations' and column_name = 'client_id'
      )
      and exists (
        select 1 from information_schema.columns
        where table_schema = 'public' and table_name = 'apple_authorizations' and column_name = 'pending_expires_at'
      )
      and exists (
        select 1 from pg_constraint
        where conrelid = 'public.apple_authorizations'::regclass
          and contype = 'p'
          and pg_get_constraintdef(oid) = 'PRIMARY KEY (provider_user_id, client_id)'
      )
      and to_regprocedure('public.create_customer_session_for_customer(uuid,text,timestamp with time zone)') is not null
      and to_regprocedure('public.find_identity_customer(text,text)') is not null
      and to_regprocedure('public.touch_identity_login(text,text)') is not null
      and to_regprocedure('public.link_customer_identity(text,text,text,text,boolean,text)') is not null
      and to_regprocedure('public.resolve_customer_for_account_deletion(text)') is not null
      and to_regprocedure('public.delete_customer_account(text)') is not null
      and not has_function_privilege('anon', 'public.link_customer_identity(text,text,text,text,boolean,text)', 'EXECUTE')
      and not has_function_privilege('authenticated', 'public.delete_customer_account(text)', 'EXECUTE'),
    'version', 'auth-v86.212-1'
  );
$$;

revoke all on function public.create_customer_session_for_customer(uuid,text,timestamptz)
  from public, anon, authenticated;
grant execute on function public.create_customer_session_for_customer(uuid,text,timestamptz)
  to service_role;

revoke all on function public.find_identity_customer(text,text)
  from public, anon, authenticated;
grant execute on function public.find_identity_customer(text,text)
  to service_role;

revoke all on function public.touch_identity_login(text,text)
  from public, anon, authenticated;
grant execute on function public.touch_identity_login(text,text)
  to service_role;

revoke all on function public.phone_auth_readiness()
  from public, anon, authenticated;
grant execute on function public.phone_auth_readiness()
  to service_role;

revoke all on function public.auth_schema_readiness()
  from public, anon, authenticated;
grant execute on function public.auth_schema_readiness()
  to service_role;

revoke all on function public.resolve_customer_for_account_deletion(text)
  from public, anon, authenticated;
grant execute on function public.resolve_customer_for_account_deletion(text)
  to service_role;

revoke all on function public.link_customer_identity(text,text,text,text,boolean,text)
  from public, anon, authenticated;
grant execute on function public.link_customer_identity(text,text,text,text,boolean,text)
  to service_role;

revoke all on function public.delete_customer_account(text)
  from public, anon, authenticated;
grant execute on function public.delete_customer_account(text)
  to service_role;

revoke all on function public.get_customer_auth_methods(text)
  from public, anon, authenticated;
grant execute on function public.get_customer_auth_methods(text)
  to service_role;
