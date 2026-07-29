-- Otlobli v86.3: separate delivery contact data from verified sign-in methods.
--
-- Existing customers keep phone sign-in enabled. A customer created through
-- Google starts with an unverified delivery phone; successful WhatsApp OTP
-- verification promotes that same number to a login method.

alter table public.customers
  add column if not exists phone_login_enabled boolean not null default true;

alter table public.customers
  add column if not exists phone_verified_at timestamptz;

update public.customers
set phone_verified_at = coalesce(phone_verified_at, created_at, now())
where phone_login_enabled = true
  and phone_verified_at is null;

create or replace function public.create_customer_session(
  p_phone text,
  p_token_hash text,
  p_expires_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  cleaned_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9]', '', 'g');
  target_customer_id uuid;
  new_session_id uuid;
begin
  if length(cleaned_phone) < 8 then
    raise exception 'invalid phone';
  end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid token hash';
  end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;

  select id into target_customer_id
  from public.customers
  where phone = cleaned_phone
  limit 1
  for update;

  if target_customer_id is null then
    target_customer_id := public.ensure_customer(cleaned_phone, 'عميل طلبية', 'دمشق', '', '', '');
  end if;

  -- This function is called only after a successful OTP verification by the
  -- trusted WhatsApp service, so the phone becomes a verified sign-in method.
  update public.customers
  set phone_login_enabled = true,
      phone_verified_at = coalesce(phone_verified_at, now()),
      updated_at = now()
  where id = target_customer_id;

  delete from public.customer_sessions
  where expires_at <= now() or revoked_at is not null;

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (target_customer_id, cleaned_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return new_session_id;
end;
$$;

revoke all on function public.create_customer_session(text, text, timestamptz)
  from public, anon, authenticated;
grant execute on function public.create_customer_session(text, text, timestamptz)
  to service_role;

create or replace function public.register_google_customer(
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
)
returns jsonb
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
  if coalesce(trim(p_provider_user_id), '') = '' then
    raise exception 'invalid google identity';
  end if;
  if length(cleaned_phone) < 8 then
    raise exception 'invalid delivery phone';
  end if;
  if length(clean_name) < 3 then
    raise exception 'invalid customer name';
  end if;
  if coalesce(p_token_hash, '') !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid token hash';
  end if;
  if p_expires_at is null or p_expires_at <= now() or p_expires_at > now() + interval '90 days' then
    raise exception 'invalid session expiry';
  end if;

  if exists (
    select 1
    from public.customer_identities
    where provider = 'google'
      and provider_user_id = p_provider_user_id
  ) then
    raise exception 'google identity already registered';
  end if;

  -- Never attach Google to an account merely because the user typed the same
  -- phone. That account can be claimed only by proving the phone through OTP,
  -- then linking Google from the authenticated account.
  if exists (select 1 from public.customers where phone = cleaned_phone) then
    raise exception 'delivery phone already belongs to another account';
  end if;

  insert into public.customers (
    phone,
    name,
    governorate,
    qadmous_branch,
    city,
    details,
    phone_login_enabled,
    phone_verified_at,
    updated_at
  )
  values (
    cleaned_phone,
    clean_name,
    coalesce(nullif(trim(p_governorate), ''), 'دمشق'),
    trim(coalesce(p_qadmous_branch, '')),
    trim(coalesce(p_city, '')),
    trim(coalesce(p_details, '')),
    false,
    null,
    now()
  )
  returning id into new_customer_id;

  insert into public.customer_identities (
    customer_id,
    provider,
    provider_user_id,
    email,
    email_verified,
    display_name,
    last_login_at
  )
  values (
    new_customer_id,
    'google',
    p_provider_user_id,
    nullif(trim(coalesce(p_email, '')), ''),
    coalesce(p_email_verified, false),
    nullif(trim(coalesce(p_display_name, '')), ''),
    now()
  );

  insert into public.customer_sessions (customer_id, phone, token_hash, expires_at)
  values (new_customer_id, cleaned_phone, p_token_hash, p_expires_at)
  returning id into new_session_id;

  return jsonb_build_object(
    'customerId', new_customer_id,
    'sessionId', new_session_id,
    'phone', cleaned_phone,
    'name', clean_name
  );
end;
$$;

revoke all on function public.register_google_customer(
  text, text, boolean, text, text, text, text, text, text, text, text, timestamptz
) from public, anon, authenticated;
grant execute on function public.register_google_customer(
  text, text, boolean, text, text, text, text, text, text, text, text, timestamptz
) to service_role;

create or replace function public.get_customer_auth_methods(
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  target_customer public.customers%rowtype;
  google_identity public.customer_identities%rowtype;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);

  select * into target_customer
  from public.customers
  where id = target_customer_id;

  select * into google_identity
  from public.customer_identities
  where customer_id = target_customer_id
    and provider = 'google'
  order by created_at
  limit 1;

  return jsonb_build_object(
    'deliveryPhone', coalesce(target_customer.phone, ''),
    'phoneLinked', coalesce(target_customer.phone_login_enabled, false),
    'phoneVerifiedAt', target_customer.phone_verified_at,
    'googleLinked', found,
    'googleEmail', case when found then coalesce(google_identity.email, '') else '' end,
    'googleName', case when found then coalesce(google_identity.display_name, '') else '' end
  );
end;
$$;

revoke all on function public.get_customer_auth_methods(text) from public;
grant execute on function public.get_customer_auth_methods(text) to anon, authenticated, service_role;
