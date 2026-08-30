-- Close the remaining authenticated write-path gaps without breaking the
-- installed claim-creation flow. New clients use the RPC below; older clients
-- remain safe because the insert trigger rewrites all privileged fields.

revoke update on table public.stores from authenticated;
grant update (
  name,
  phone,
  city,
  country_code,
  currency_code,
  tax_rate,
  prices_include_tax,
  tax_number,
  commercial_registration,
  address,
  invoice_prefix,
  default_warranty_months,
  logo_url,
  brand_color,
  customer_portal_title,
  warranty_policy,
  warranty_exclusions,
  updated_at
) on table public.stores to authenticated;

create or replace function public.enforce_authenticated_claim_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
begin
  if actor is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if not public.is_store_member(new.store_id) then
      raise exception 'CLAIM_STORE_ACCESS_DENIED';
    end if;
    if not exists (
      select 1
      from public.warranties warranty
      where warranty.id = new.warranty_id
        and warranty.store_id = new.store_id
        and warranty.voided_at is null
    ) then
      raise exception 'WARRANTY_NOT_FOUND';
    end if;
    new.claim_number := nextval('public.maintenance_claim_number_seq');
    new.status := 'new';
    new.channel := 'staff';
    new.resolution := 'none';
    new.assigned_to := null;
    new.service_branch_id := null;
    new.customer_notes := '';
    new.internal_notes := '';
    new.diagnosis := '';
    new.resolution_notes := '';
    new.decision_reason := '';
    new.sla_due_at := null;
    new.approved_at := null;
    new.completed_at := null;
    new.created_by := actor;
    new.updated_by := actor;
    new.created_at := now();
    new.updated_at := now();
    new.version := 1;
    new.public_submission_id := null;
    return new;
  end if;

  if new.id is distinct from old.id
     or new.store_id is distinct from old.store_id
     or new.warranty_id is distinct from old.warranty_id
     or new.claim_number is distinct from old.claim_number
     or new.channel is distinct from old.channel
     or new.public_submission_id is distinct from old.public_submission_id
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at then
    raise exception 'CLAIM_IMMUTABLE_FIELDS';
  end if;
  new.updated_by := actor;
  return new;
end;
$$;

drop trigger if exists maintenance_requests_00_authenticated_guard
  on public.maintenance_requests;
create trigger maintenance_requests_00_authenticated_guard
before insert or update on public.maintenance_requests
for each row execute function public.enforce_authenticated_claim_write();

create or replace function public.create_maintenance_request(
  target_store_id uuid,
  target_warranty_id uuid,
  claim_issue text,
  claim_category text default 'other',
  claim_priority text default 'normal'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_request public.maintenance_requests;
  normalized_issue text := trim(coalesce(claim_issue, ''));
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_MEMBER_REQUIRED';
  end if;
  if char_length(normalized_issue) not between 3 and 2000
     or claim_category not in (
       'malfunction', 'battery', 'software', 'physical_damage',
       'missing_parts', 'other'
     )
     or claim_priority not in ('low', 'normal', 'high', 'urgent') then
    raise exception 'CLAIM_INPUT_INVALID';
  end if;
  if not exists (
    select 1
    from public.warranties warranty
    where warranty.id = target_warranty_id
      and warranty.store_id = target_store_id
      and warranty.voided_at is null
  ) then
    raise exception 'WARRANTY_NOT_FOUND';
  end if;

  insert into public.maintenance_requests(
    store_id,
    warranty_id,
    issue,
    category,
    priority,
    created_by,
    updated_by
  ) values (
    target_store_id,
    target_warranty_id,
    normalized_issue,
    claim_category,
    claim_priority,
    (select auth.uid()),
    (select auth.uid())
  )
  returning * into created_request;
  return to_jsonb(created_request);
end;
$$;

-- Updates are allowed only through update_maintenance_request, which enforces
-- the field allow-list and optimistic version check. INSERT stays available to
-- the previous TestFlight build, but the trigger above makes it non-privileged.
revoke update on table public.maintenance_requests from authenticated;
drop policy if exists maintenance_update_members
  on public.maintenance_requests;

revoke all on function public.enforce_authenticated_claim_write()
  from public, anon, authenticated;
revoke all on function public.create_maintenance_request(
  uuid, uuid, text, text, text
) from public, anon, authenticated;
grant execute on function public.create_maintenance_request(
  uuid, uuid, text, text, text
) to authenticated;

create or replace function public.update_store_member(
  target_store_id uuid,
  target_user_id uuid,
  target_role text,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_role text;
  existing_role text;
  existing_status text;
  allowed_members integer;
  active_members integer;
begin
  select member.role into caller_role
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = (select auth.uid())
    and member.status = 'active';
  select member.role, member.status into existing_role, existing_status
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = target_user_id;

  if caller_role not in ('owner', 'manager') then
    raise exception 'ROLE_REQUIRED';
  end if;
  if existing_role is null then
    raise exception 'MEMBER_NOT_FOUND';
  end if;
  if target_user_id = (select auth.uid()) or existing_role = 'owner' then
    raise exception 'OWNER_PROTECTED';
  end if;
  if target_role not in ('manager', 'staff')
     or target_status not in ('active', 'suspended') then
    raise exception 'INVALID_MEMBER_UPDATE';
  end if;
  if caller_role = 'manager'
     and (existing_role = 'manager' or target_role = 'manager') then
    raise exception 'OWNER_REQUIRED';
  end if;

  if target_status = 'active' and existing_status <> 'active' then
    if not public.subscription_is_usable(target_store_id) then
      raise exception 'SUBSCRIPTION_INACTIVE';
    end if;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(target_store_id::text || ':members', 0)
    );
    select plan.max_members into allowed_members
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id;
    select count(*) into active_members
    from public.store_members member
    where member.store_id = target_store_id and member.status = 'active';
    if allowed_members is null or active_members >= allowed_members then
      raise exception 'SEAT_LIMIT_REACHED';
    end if;
  end if;

  update public.store_members
  set role = target_role, status = target_status, updated_at = now()
  where store_id = target_store_id and user_id = target_user_id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  ) values (
    target_store_id,
    (select auth.uid()),
    'member_updated',
    'member',
    target_user_id,
    jsonb_build_object('role', target_role, 'status', target_status)
  );
end;
$$;

create or replace function public.enforce_subscription_member_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed_members integer := 1;
  active_owners integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':members', 0)
  );
  if public.subscription_is_usable(new.store_id) then
    select plan.max_members into allowed_members
    from public.plans plan
    where plan.id = new.plan_id;
  end if;
  allowed_members := greatest(coalesce(allowed_members, 1), 1);
  select count(*) into active_owners
  from public.store_members member
  where member.store_id = new.store_id
    and member.status = 'active'
    and member.role = 'owner';

  with ranked as (
    select
      member.user_id,
      row_number() over (
        order by member.joined_at, member.user_id
      ) as position
    from public.store_members member
    where member.store_id = new.store_id
      and member.status = 'active'
      and member.role <> 'owner'
  ), suspended as (
    update public.store_members member
    set status = 'suspended', updated_at = now()
    from ranked
    where member.store_id = new.store_id
      and member.user_id = ranked.user_id
      and ranked.position > greatest(allowed_members - active_owners, 0)
    returning member.user_id
  )
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  )
  select
    new.store_id,
    (select auth.uid()),
    'member_suspended_for_plan_limit',
    'member',
    suspended.user_id,
    jsonb_build_object('max_members', allowed_members)
  from suspended;
  return new;
end;
$$;

drop trigger if exists subscriptions_enforce_member_limit
  on public.subscriptions;
create trigger subscriptions_enforce_member_limit
after insert or update of plan_id, status, trial_ends_at, current_period_end
on public.subscriptions
for each row execute function public.enforce_subscription_member_limit();

revoke all on function public.update_store_member(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.update_store_member(uuid, uuid, text, text)
  to authenticated;
revoke all on function public.enforce_subscription_member_limit()
  from public, anon, authenticated;

-- Expired stores stay readable for export and warranty obligations, but core
-- POS, catalog, inventory, supplier, and purchasing writes become read-only.
-- A table trigger protects both direct PostgREST writes and SECURITY DEFINER
-- RPCs, so hiding a button in the client cannot bypass the paywall.
create or replace function public.enforce_usable_subscription_for_core_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_store_id uuid;
begin
  if coalesce((select auth.role()), '') <> 'authenticated' then
    return new;
  end if;

  -- Refunds for a sale created while the store was active remain available as
  -- a customer obligation. Only return_sale can set this transaction-local
  -- context after it has validated membership and locked the sale.
  if current_setting('damanak.write_context', true) = 'return_sale' then
    return new;
  end if;

  -- Let an expired store close an already-open cash register; opening a new
  -- register or editing any stable identity fields stays blocked.
  if tg_table_name = 'register_sessions' and tg_op = 'UPDATE'
     and to_jsonb(old)->>'status' = 'open'
     and to_jsonb(new)->>'status' = 'closed'
     and to_jsonb(new)->>'id' = to_jsonb(old)->>'id'
     and to_jsonb(new)->>'store_id' = to_jsonb(old)->>'store_id'
     and to_jsonb(new)->>'branch_id' = to_jsonb(old)->>'branch_id'
     and to_jsonb(new)->>'opened_by' = to_jsonb(old)->>'opened_by'
     and to_jsonb(new)->>'opened_at' = to_jsonb(old)->>'opened_at' then
    return new;
  end if;

  target_store_id := nullif(to_jsonb(new)->>'store_id', '')::uuid;
  if target_store_id is null then
    raise exception 'STORE_REQUIRED';
  end if;
  if not public.subscription_is_usable(target_store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  return new;
end;
$$;

do $core_write_triggers$
declare
  table_name text;
begin
  foreach table_name in array array[
    'products',
    'branches',
    'customers',
    'inventory_levels',
    'stock_movements',
    'sales',
    'sale_lines',
    'sale_payments',
    'sale_returns',
    'register_sessions',
    'suppliers',
    'purchase_orders',
    'purchase_order_lines',
    'warranties'
  ] loop
    execute format(
      'drop trigger if exists %I on public.%I',
      table_name || '_usable_subscription_guard',
      table_name
    );
    execute format(
      'create trigger %I before insert or update on public.%I '
      || 'for each row execute function '
      || 'public.enforce_usable_subscription_for_core_write()',
      table_name || '_usable_subscription_guard',
      table_name
    );
  end loop;

end;
$core_write_triggers$;

revoke all on function public.enforce_usable_subscription_for_core_write()
  from public, anon, authenticated;

-- New invitations carry 128 bits of entropy. Existing 40-bit codes remain
-- valid for their original 48-hour lifetime and are protected by throttling.
-- Invite hashes are deliberately hidden from authenticated clients; all
-- matching stays inside SECURITY DEFINER functions.
drop policy if exists invites_select_managers on public.invite_codes;
revoke select on table public.invite_codes from authenticated;

create table if not exists private.invite_join_attempts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  failed_attempts integer not null default 0
    check (failed_attempts between 0 and 1000),
  blocked_until timestamptz,
  updated_at timestamptz not null default now()
);

revoke all on table private.invite_join_attempts
  from public, anon, authenticated;

create or replace function public.create_store_invite(
  target_store_id uuid,
  target_role text,
  allowed_uses integer default 1
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  raw_code text;
  expiry timestamptz := now() + interval '48 hours';
begin
  if not public.has_store_role(
    target_store_id, array['owner', 'manager']
  ) then
    raise exception 'ROLE_REQUIRED';
  end if;
  if target_role not in ('manager', 'staff') then
    raise exception 'INVALID_ROLE';
  end if;
  if public.has_store_role(target_store_id, array['manager'])
     and target_role = 'manager' then
    raise exception 'OWNER_REQUIRED';
  end if;
  if allowed_uses not between 1 and 10 then
    raise exception 'INVALID_USE_LIMIT';
  end if;

  raw_code := 'DMN-' || upper(
    pg_catalog.encode(extensions.gen_random_bytes(16), 'hex')
  );
  insert into public.invite_codes(
    store_id,
    code_hash,
    role,
    max_uses,
    expires_at,
    created_by
  ) values (
    target_store_id,
    extensions.digest(raw_code, 'sha256'),
    target_role,
    allowed_uses,
    expiry,
    (select auth.uid())
  );

  return jsonb_build_object(
    'code', raw_code,
    'role', target_role,
    'max_uses', allowed_uses,
    'expires_at', expiry
  );
end;
$$;

create or replace function public.join_store_by_code(invitation_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  normalized_code text := upper(trim(coalesce(invitation_code, '')));
  invite public.invite_codes%rowtype;
  allowed_members integer;
  active_members integer;
  existing_status text;
  attempt private.invite_join_attempts%rowtype;
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into attempt
  from private.invite_join_attempts attempts
  where attempts.user_id = actor
  for update;
  if attempt.blocked_until is not null
     and attempt.blocked_until > now() then
    return jsonb_build_object(
      'error', 'INVITE_RATE_LIMITED',
      'retry_after_seconds', greatest(
        1,
        ceil(extract(epoch from attempt.blocked_until - now()))::integer
      )
    );
  elsif attempt.blocked_until is not null then
    delete from private.invite_join_attempts where user_id = actor;
  end if;

  if normalized_code ~ '^DMN-([A-F0-9]{10}|[A-F0-9]{16}|[A-F0-9]{32})$' then
    select * into invite
    from public.invite_codes
    where code_hash = extensions.digest(normalized_code, 'sha256')
      and is_active
      and expires_at > now()
      and used_count < max_uses
    for update;
  end if;

  if invite.id is null then
    insert into private.invite_join_attempts as attempts(
      user_id, window_started_at, failed_attempts, blocked_until, updated_at
    ) values (
      actor, now(), 1, null, now()
    )
    on conflict (user_id) do update set
      window_started_at = case
        when attempts.window_started_at <= now() - interval '15 minutes'
          then now()
        else attempts.window_started_at
      end,
      failed_attempts = case
        when attempts.window_started_at <= now() - interval '15 minutes'
          then 1
        else least(attempts.failed_attempts + 1, 1000)
      end,
      blocked_until = case
        when (
          case
            when attempts.window_started_at <= now() - interval '15 minutes'
              then 1
            else attempts.failed_attempts + 1
          end
        ) >= 10 then now() + interval '15 minutes'
        else null
      end,
      updated_at = now()
    returning * into attempt;

    return jsonb_build_object(
      'error', case
        when attempt.blocked_until is null
          then 'INVITE_INVALID'
        else 'INVITE_RATE_LIMITED'
      end,
      'retry_after_seconds', case
        when attempt.blocked_until is null then null
        else greatest(
          1,
          ceil(extract(epoch from attempt.blocked_until - now()))::integer
        )
      end
    );
  end if;

  delete from private.invite_join_attempts where user_id = actor;
  if not public.subscription_is_usable(invite.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(invite.store_id::text || ':members', 0)
  );
  select plan.max_members into allowed_members
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = invite.store_id;
  if allowed_members is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select count(*) into active_members
  from public.store_members member
  where member.store_id = invite.store_id and member.status = 'active';
  select member.status into existing_status
  from public.store_members member
  where member.store_id = invite.store_id and member.user_id = actor;
  if active_members >= allowed_members
     and coalesce(existing_status, '') <> 'active' then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  insert into public.store_members(store_id, user_id, role, status)
  values (invite.store_id, actor, invite.role, 'active')
  on conflict (store_id, user_id) do update set
    role = excluded.role,
    status = 'active',
    updated_at = now();
  update public.invite_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = invite.id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id
  ) values (
    invite.store_id, actor, 'member_joined', 'member', actor
  );

  return jsonb_build_object(
    'store_id', invite.store_id,
    'user_id', actor,
    'role', invite.role,
    'status', 'active'
  );
end;
$$;

revoke all on function public.create_store_invite(uuid, text, integer)
  from public, anon, authenticated;
revoke all on function public.join_store_by_code(text)
  from public, anon, authenticated;
grant execute on function public.create_store_invite(uuid, text, integer)
  to authenticated;
grant execute on function public.join_store_by_code(text)
  to authenticated;

-- Reserve store-verification attempts before calling Apple or Google. This
-- prevents an authenticated owner from exhausting provider APIs with random
-- transaction identifiers. Scheduled server-side refreshes use their own
-- secret path and do not consume this user-initiated allowance.
create table if not exists private.store_purchase_verification_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  window_started_at timestamptz not null default now(),
  window_attempts integer not null default 0
    check (window_attempts between 0 and 10),
  day_started_at date not null default ((now() at time zone 'UTC')::date),
  day_attempts integer not null default 0
    check (day_attempts between 0 and 50),
  updated_at timestamptz not null default now(),
  primary key (user_id, store_id)
);

revoke all on table private.store_purchase_verification_limits
  from public, anon, authenticated;

create or replace function public.reserve_store_purchase_verification(
  target_store_id uuid,
  target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_time timestamptz := clock_timestamp();
  current_utc_day date := (request_time at time zone 'UTC')::date;
  limit_row private.store_purchase_verification_limits%rowtype;
  retry_after integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role = 'owner'
      and member.status = 'active'
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  insert into private.store_purchase_verification_limits(
    user_id, store_id, window_started_at, day_started_at
  ) values (
    target_user_id, target_store_id, request_time, current_utc_day
  )
  on conflict (user_id, store_id) do nothing;

  select * into limit_row
  from private.store_purchase_verification_limits limits
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id
  for update;

  if limit_row.window_started_at <= request_time - interval '15 minutes' then
    limit_row.window_started_at := request_time;
    limit_row.window_attempts := 0;
  end if;
  if limit_row.day_started_at <> current_utc_day then
    limit_row.day_started_at := current_utc_day;
    limit_row.day_attempts := 0;
  end if;

  update private.store_purchase_verification_limits limits
  set window_started_at = limit_row.window_started_at,
      window_attempts = limit_row.window_attempts,
      day_started_at = limit_row.day_started_at,
      day_attempts = limit_row.day_attempts,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  if limit_row.window_attempts >= 10 or limit_row.day_attempts >= 50 then
    retry_after := greatest(
      case when limit_row.window_attempts >= 10 then
        ceil(extract(epoch from (
          limit_row.window_started_at + interval '15 minutes' - request_time
        )))::integer
      else 0 end,
      case when limit_row.day_attempts >= 50 then
        ceil(extract(epoch from (
          ((current_utc_day + 1)::timestamp at time zone 'UTC') - request_time
        )))::integer
      else 0 end,
      1
    );
    return jsonb_build_object(
      'allowed', false,
      'retry_after_seconds', retry_after
    );
  end if;

  update private.store_purchase_verification_limits limits
  set window_attempts = window_attempts + 1,
      day_attempts = day_attempts + 1,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  return jsonb_build_object(
    'allowed', true,
    'window_remaining', 9 - limit_row.window_attempts,
    'day_remaining', 49 - limit_row.day_attempts
  );
end;
$$;

revoke all on function public.reserve_store_purchase_verification(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.reserve_store_purchase_verification(uuid, uuid)
  to service_role;

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
