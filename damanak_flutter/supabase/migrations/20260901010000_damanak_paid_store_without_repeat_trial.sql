-- Build 25 can always create or recover the caller's owned store. A one-time
-- Starter trial is still granted only when both the account and installation
-- are new. Build 24 keeps using create_store_with_trial unchanged so an older
-- client can never enter a newly created, payment-locked workspace.

create or replace function public.store_requires_initial_payment(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = target_store_id
      and subscription.plan_id = 'starter'
      and subscription.status = 'canceled'
      and subscription.source = 'trial'
      and subscription.trial_ends_at is null
      and subscription.current_period_start is null
      and subscription.current_period_end is null
      and subscription.billing_provider is null
      and subscription.store_product_id is null
      and subscription.billing_cycle is null
      and subscription.original_transaction_id is null
      and not subscription.auto_renews
      and subscription.last_store_verified_at is null
      and subscription.store_environment is null
      and subscription.store_entitlement_id is null
  )
$$;

comment on function public.store_requires_initial_payment(uuid) is
  'Identifies the non-entitled Build 25 initial-payment placeholder; it does not classify expired historical subscriptions.';

-- The account lock bounds the five-device limit. The device lock makes a
-- simultaneous registration from two accounts deterministic. The fallback
-- ON CONFLICT branch also remains safe while Build 24 is still active because
-- that legacy RPC predates these advisory-lock namespaces.
create or replace function public.register_trial_device(
  target_store_id uuid,
  device_claim text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_account_hash bytea;
  current_device_hash bytea;
  linked_account_hash bytea;
  registered_devices integer;
  inserted_rows integer;
  normalized_claim text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(device_claim, ''))
  );
begin
  if (select auth.uid()) is null then
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
      and member.user_id = (select auth.uid())
      and member.role = 'owner'
      and member.status = 'active'
      and store.owner_id = (select auth.uid())
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  current_account_hash := extensions.digest(
    'damanak:trial-account:v1:' || (select auth.uid())::text,
    'sha256'
  );
  current_device_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-account-lock:v1:' ||
        pg_catalog.encode(current_account_hash, 'hex'),
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-device-lock:v1:' ||
        pg_catalog.encode(current_device_hash, 'hex'),
      0
    )
  );

  insert into private.trial_account_claims(account_hash)
  values (current_account_hash)
  on conflict (account_hash) do update
  set last_seen_at = pg_catalog.now();

  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = current_device_hash
  for update;
  if found then
    if linked_account_hash <> current_account_hash then
      return false;
    end if;
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = current_device_hash;
    return true;
  end if;

  select pg_catalog.count(*)
  into registered_devices
  from private.trial_device_claims claim
  where claim.account_hash = current_account_hash;
  if registered_devices >= 5 then
    return false;
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (current_device_hash, current_account_hash)
  on conflict (device_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 1 then
    return true;
  end if;

  -- A concurrent legacy Build 24 transaction may have won the unique key
  -- without taking the advisory lock. Re-read its committed owner safely.
  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = current_device_hash;
  if linked_account_hash = current_account_hash then
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = current_device_hash;
    return true;
  end if;
  return false;
end;
$$;

create or replace function public.create_store_with_subscription(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  created_store_id uuid;
  existing_store_id uuid;
  inserted_rows integer;
  account_claim_hash bytea;
  device_claim_hash bytea;
  linked_account_hash bytea;
  device_already_claimed boolean;
  account_claim_inserted boolean := false;
  device_claim_inserted boolean := false;
  registered_devices integer;
  trial_granted boolean := false;
  normalized_claim text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(device_claim, ''))
  );
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(pg_catalog.btrim(coalesce(store_name, ''))) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if coalesce(store_country_code, '') not in (
    'SA', 'AE', 'KW', 'QA', 'BH', 'OM'
  ) then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;

  account_claim_hash := extensions.digest(
    'damanak:trial-account:v1:' || actor::text,
    'sha256'
  );
  device_claim_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  -- Every caller follows account then device order. Besides protecting the
  -- eligibility decision, the account lock is the idempotency boundary for
  -- two simultaneous onboarding requests from the same authenticated user.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-account-lock:v1:' ||
        pg_catalog.encode(account_claim_hash, 'hex'),
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-device-lock:v1:' ||
        pg_catalog.encode(device_claim_hash, 'hex'),
      0
    )
  );

  select store.id
  into existing_store_id
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = actor
   and member.role = 'owner'
   and member.status = 'active'
  where store.owner_id = actor
  order by store.created_at, store.id
  limit 1;
  if existing_store_id is not null then
    insert into private.trial_account_claims(account_hash)
    values (account_claim_hash)
    on conflict (account_hash) do update
    set last_seen_at = pg_catalog.now();

    select claim.account_hash
    into linked_account_hash
    from private.trial_device_claims claim
    where claim.device_hash = device_claim_hash
    for update;
    if found and linked_account_hash = account_claim_hash then
      update private.trial_device_claims
      set last_seen_at = pg_catalog.now()
      where device_hash = device_claim_hash;
    elsif not found then
      select pg_catalog.count(*)
      into registered_devices
      from private.trial_device_claims claim
      where claim.account_hash = account_claim_hash;
      if registered_devices < 5 then
        insert into private.trial_device_claims(device_hash, account_hash)
        values (device_claim_hash, account_claim_hash)
        on conflict (device_hash) do nothing;
        -- A legacy caller may win the device key while ignoring our lock. It
        -- is never overwritten, regardless of which account won the race.
        update private.trial_device_claims
        set last_seen_at = pg_catalog.now()
        where device_hash = device_claim_hash
          and account_hash = account_claim_hash;
      end if;
    end if;
    return existing_store_id;
  end if;

  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = device_claim_hash
  for update;
  device_already_claimed := found;

  -- INSERT, not a preceding EXISTS read, decides account eligibility. This
  -- closes the gap with a concurrent Build 24 caller that does not honor the
  -- advisory lock but still contends on the primary key.
  insert into private.trial_account_claims(account_hash)
  values (account_claim_hash)
  on conflict (account_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  account_claim_inserted := inserted_rows = 1;
  if not account_claim_inserted then
    update private.trial_account_claims
    set last_seen_at = pg_catalog.now()
    where account_hash = account_claim_hash;
  end if;

  -- Bind every previously unseen installation to this account (up to the
  -- existing five-device ceiling), even when no trial is granted. Otherwise a
  -- logout followed by a new account on that installation could reopen trial.
  if not device_already_claimed then
    select pg_catalog.count(*)
    into registered_devices
    from private.trial_device_claims claim
    where claim.account_hash = account_claim_hash;
    if registered_devices < 5 then
      insert into private.trial_device_claims(device_hash, account_hash)
      values (device_claim_hash, account_claim_hash)
      on conflict (device_hash) do nothing;
      get diagnostics inserted_rows = row_count;
      device_claim_inserted := inserted_rows = 1;
      if not device_claim_inserted then
        select claim.account_hash
        into linked_account_hash
        from private.trial_device_claims claim
        where claim.device_hash = device_claim_hash;
        if linked_account_hash = account_claim_hash then
          update private.trial_device_claims
          set last_seen_at = pg_catalog.now()
          where device_hash = device_claim_hash;
        end if;
      end if;
    end if;
  elsif linked_account_hash = account_claim_hash then
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = device_claim_hash;
  end if;
  trial_granted := account_claim_inserted and device_claim_inserted;

  -- A concurrent Build 24 call does not take our advisory lock. If it won the
  -- account primary key and committed its store while this call waited, return
  -- that now-visible store instead of creating a second locked workspace.
  select store.id
  into existing_store_id
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = actor
   and member.role = 'owner'
   and member.status = 'active'
  where store.owner_id = actor
  order by store.created_at, store.id
  limit 1;
  if existing_store_id is not null then
    return existing_store_id;
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    pg_catalog.btrim(store_name),
    pg_catalog.btrim(coalesce(store_phone, '')),
    pg_catalog.btrim(coalesce(store_city, '')),
    store_country_code,
    actor
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, actor, 'owner');

  -- canceled + trial + NULL end dates is the explicit initial-payment state.
  -- It is deliberately unusable and has no StoreKit/Play entitlement row.
  insert into public.subscriptions(
    store_id,
    plan_id,
    status,
    trial_ends_at,
    current_period_start,
    current_period_end,
    source
  ) values (
    created_store_id,
    'starter',
    case when trial_granted then 'trialing' else 'canceled' end,
    case
      when trial_granted then pg_catalog.now() + interval '14 days'
      else null
    end,
    null,
    null,
    'trial'
  );

  insert into public.audit_logs(
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    created_store_id,
    actor,
    'store_created',
    'store',
    created_store_id,
    pg_catalog.jsonb_build_object(
      'trial_guard', 'account_and_device_v1',
      'trial_granted', trial_granted,
      'initial_payment_required', not trial_granted,
      'subscription_required', not trial_granted
    )
  );

  return created_store_id;
end;
$$;

-- The stores trigger remains DEFERRABLE INITIALLY DEFERRED. Its target now
-- returns quietly for a non-usable subscription. A subscription transition to
-- usable independently creates/reactivates MAIN, including first paid access
-- for a store that started in the initial-payment state.
create or replace function private.ensure_default_store_branch(
  target_store_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  store_row public.stores%rowtype;
  branch_limit integer;
  active_branch_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':branches', 0)
  );
  if not public.subscription_is_usable(target_store_id) then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.code = 'MAIN'
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;

  -- Repair an active MAIN code that lost only its main flag. If another
  -- branch is already the active main, preserve that explicit choice and do
  -- not violate branches_one_main_per_store.
  update public.branches branch
  set is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and branch.is_active
    and not branch.is_main
    and not exists (
      select 1
      from public.branches other
      where other.store_id = target_store_id
        and other.is_active
        and other.is_main
    );
  if found then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;

  select plan.max_branches
  into branch_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id;
  select pg_catalog.count(*)
  into active_branch_count
  from public.branches branch
  where branch.store_id = target_store_id
    and branch.is_active;
  if branch_limit is null or active_branch_count >= branch_limit then
    return;
  end if;

  update public.branches branch
  set is_active = true,
      is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and not branch.is_active;
  if found then
    return;
  end if;

  select *
  into store_row
  from public.stores store
  where store.id = target_store_id;
  if store_row.id is null then
    return;
  end if;

  insert into public.branches(
    store_id,
    name,
    code,
    city,
    address,
    phone,
    is_main
  ) values (
    store_row.id,
    'الفرع الرئيسي',
    'MAIN',
    store_row.city,
    store_row.address,
    store_row.phone,
    true
  )
  on conflict (store_id, code) do nothing;
end;
$$;

create or replace function public.create_default_store_branch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.ensure_default_store_branch(new.id);
  return new;
end;
$$;

create or replace function public.ensure_default_store_branch_after_subscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.ensure_default_store_branch(new.store_id);
  return new;
end;
$$;

drop trigger if exists subscriptions_ensure_default_branch
  on public.subscriptions;
create trigger subscriptions_ensure_default_branch
after insert or update of
  plan_id,
  status,
  trial_ends_at,
  current_period_end,
  source
on public.subscriptions
for each row execute function
  public.ensure_default_store_branch_after_subscription();

comment on trigger stores_create_default_branch on public.stores is
  'Runs at the deferred store boundary and creates MAIN only when the subscription is usable.';
comment on trigger subscriptions_ensure_default_branch
on public.subscriptions is
  'Creates or reactivates MAIN on the first usable subscription transition.';

-- Initial-payment stores cannot create invitation or claim work records even
-- through SECURITY DEFINER/service-role paths. Historical records remain
-- readable and editable after a normal paid or trial subscription expires,
-- because that state is deliberately not classified as initial-payment.
create or replace function public.reject_initial_payment_store_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.store_requires_initial_payment(new.store_id) then
    raise exception 'INITIAL_PAYMENT_REQUIRED';
  end if;
  return new;
end;
$$;

drop trigger if exists invite_codes_00_initial_payment_guard
  on public.invite_codes;
create trigger invite_codes_00_initial_payment_guard
before insert on public.invite_codes
for each row execute function public.reject_initial_payment_store_write();

drop trigger if exists maintenance_requests_00_initial_payment_guard
  on public.maintenance_requests;
create trigger maintenance_requests_00_initial_payment_guard
before insert or update on public.maintenance_requests
for each row execute function public.reject_initial_payment_store_write();

-- warranty-card issues a new public link only after an authenticated member
-- can SELECT the warranty row. Keep that read available for normally expired
-- stores, but hide rows from the exact never-activated placeholder. Existing
-- public historical cards continue through the service-role read path.
create or replace function public.can_access_warranty_records(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_store_member(target_store_id)
    and not public.store_requires_initial_payment(target_store_id)
$$;

drop policy if exists warranties_select_members on public.warranties;
create policy warranties_select_members
on public.warranties for select to authenticated
using (public.can_access_warranty_records(store_id));

revoke all on function public.create_store_with_subscription(
  text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.create_store_with_subscription(
  text, text, text, text, text
) to authenticated;

revoke all on function public.register_trial_device(uuid, text)
  from public, anon, authenticated;
grant execute on function public.register_trial_device(uuid, text)
  to authenticated;

revoke all on function public.store_requires_initial_payment(uuid)
  from public, anon, authenticated;
revoke all on function public.can_access_warranty_records(uuid)
  from public, anon, authenticated;
grant execute on function public.can_access_warranty_records(uuid)
  to authenticated;
revoke all on function private.ensure_default_store_branch(uuid)
  from public, anon, authenticated;
revoke all on function public.create_default_store_branch()
  from public, anon, authenticated;
revoke all on function
  public.ensure_default_store_branch_after_subscription()
  from public, anon, authenticated;
revoke all on function public.reject_initial_payment_store_write()
  from public, anon, authenticated;

comment on function public.create_store_with_subscription(
  text, text, text, text, text
) is 'Build 25 idempotent onboarding: always returns an owned store and grants a 14-day Starter trial only when account and installation are both eligible.';

comment on function public.register_trial_device(uuid, text) is
  'Registers up to five protected installations under account-then-device transaction locks without granting subscription access.';

comment on function private.ensure_default_store_branch(uuid) is
  'Creates or reactivates MAIN only after the store subscription becomes usable.';

comment on function public.can_access_warranty_records(uuid) is
  'Allows authenticated member warranty reads except for the exact never-activated initial-payment state.';

comment on function public.reject_initial_payment_store_write() is
  'Rejects invitation and maintenance mutations only for the exact never-activated initial-payment state.';
