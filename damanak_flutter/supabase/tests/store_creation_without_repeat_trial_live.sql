-- Live regression contract for migration 20260901010000.
-- Run only after the migration is applied to the selected database:
--   supabase db query --linked --file supabase/tests/store_creation_without_repeat_trial_live.sql
-- Synthetic identities and every dependent row are always rolled back.

begin;
set local statement_timeout = '30s';
set local lock_timeout = '5s';

create temporary table store_creation_test_context (
  eligible_store uuid not null,
  device_locked_store uuid not null,
  account_locked_store uuid not null
) on commit drop;

do $test$
declare
  eligible_user uuid := extensions.gen_random_uuid();
  device_locked_user uuid := extensions.gen_random_uuid();
  account_locked_user uuid := extensions.gen_random_uuid();
  eligible_device text := extensions.gen_random_uuid()::text;
  retry_device text := extensions.gen_random_uuid()::text;
  account_locked_device text := extensions.gen_random_uuid()::text;
  eligible_store uuid;
  retried_store uuid;
  device_locked_store uuid;
  account_locked_store uuid;
  historical_customer_id uuid;
  warranty_id uuid;
  historical_request_id uuid;
  first_submission_id uuid := extensions.gen_random_uuid();
  blocked_submission_id uuid := extensions.gen_random_uuid();
  invite_result jsonb;
  claim_result jsonb;
  hit_message text;
  new_function_definition text;
  register_function_definition text;
  legacy_function_definition text;
  account_lock_position integer;
  device_lock_position integer;
begin
  insert into auth.users (
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) values
    (
      eligible_user,
      'authenticated',
      'authenticated',
      'eligible-' || eligible_user::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      device_locked_user,
      'authenticated',
      'authenticated',
      'device-locked-' || device_locked_user::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      account_locked_user,
      'authenticated',
      'authenticated',
      'account-locked-' || account_locked_user::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    );

  -- This identity represents an account that consumed a trial before it had
  -- a surviving owned store (for example, after a historical deletion).
  insert into private.trial_account_claims(account_hash)
  values (
    extensions.digest(
      'damanak:trial-account:v1:' || account_locked_user::text,
      'sha256'
    )
  );

  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'authenticated',
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    eligible_user::text,
    true
  );

  eligible_store := public.create_store_with_subscription(
    'متجر مؤهل للتجربة',
    '70000001',
    'الدوحة',
    'QA',
    eligible_device
  );
  retried_store := public.create_store_with_subscription(
    'اسم مختلف في إعادة المحاولة',
    '70000999',
    'الريان',
    'QA',
    retry_device
  );
  if retried_store <> eligible_store then
    raise exception 'The Build 25 onboarding RPC is not idempotent';
  end if;
  if (
    select pg_catalog.count(*)
    from public.stores store
    where store.owner_id = eligible_user
  ) <> 1 then
    raise exception 'An onboarding retry created a duplicate owned store';
  end if;
  if not exists (
    select 1
    from private.trial_device_claims claim
    where claim.device_hash = extensions.digest(
      'damanak:trial-device:v1:' || retry_device,
      'sha256'
    )
      and claim.account_hash = extensions.digest(
        'damanak:trial-account:v1:' || eligible_user::text,
        'sha256'
      )
  ) then
    raise exception 'An idempotent retry did not bind its new installation';
  end if;

  if not exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = eligible_store
      and subscription.plan_id = 'starter'
      and subscription.status = 'trialing'
      and subscription.source = 'trial'
      and subscription.trial_ends_at >
        pg_catalog.now() + interval '13 days'
      and public.subscription_is_usable(eligible_store)
      and not public.store_requires_initial_payment(eligible_store)
  ) then
    raise exception 'An eligible account and installation did not get one trial';
  end if;
  if (
    select pg_catalog.count(*)
    from public.branches branch
    where branch.store_id = eligible_store
      and branch.code = 'MAIN'
      and branch.is_main
      and branch.is_active
  ) <> 1 then
    raise exception 'A usable trial did not receive exactly one MAIN branch';
  end if;

  -- Build 24 remains strict. Its failed attempt rolls back its temporary
  -- account claim, after which Build 25 creates the required locked store.
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    device_locked_user::text,
    true
  );
  begin
    perform public.create_store_with_trial(
      'محاولة Build 24 على جهاز مستخدم',
      '70000002',
      'الدوحة',
      'QA',
      eligible_device
    );
    raise exception 'Build 24 unexpectedly created a payment-locked store';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'TRIAL_ALREADY_USED_ON_DEVICE' then
      raise;
    end if;
  end;
  if exists (
    select 1 from public.stores store
    where store.owner_id = device_locked_user
  ) then
    raise exception 'The rejected Build 24 attempt left a store behind';
  end if;

  device_locked_store := public.create_store_with_subscription(
    'متجر يحتاج أول دفعة بسبب الجهاز',
    '70000002',
    'الدوحة',
    'QA',
    eligible_device
  );

  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    account_locked_user::text,
    true
  );
  begin
    perform public.create_store_with_trial(
      'محاولة Build 24 بحساب مستخدم',
      '70000003',
      'الدوحة',
      'QA',
      account_locked_device
    );
    raise exception 'Build 24 unexpectedly changed its trial-only contract';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'TRIAL_ALREADY_USED_BY_ACCOUNT' then
      raise;
    end if;
  end;

  account_locked_store := public.create_store_with_subscription(
    'متجر يحتاج أول دفعة بسبب الحساب',
    '70000003',
    'الدوحة',
    'QA',
    account_locked_device
  );

  if (
    select pg_catalog.count(*)
    from public.subscriptions subscription
    where subscription.store_id in (
      device_locked_store,
      account_locked_store
    )
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
  ) <> 2 then
    raise exception 'An ineligible store did not receive the inert placeholder';
  end if;
  if not public.store_requires_initial_payment(device_locked_store)
     or not public.store_requires_initial_payment(account_locked_store)
     or public.subscription_is_usable(device_locked_store)
     or public.subscription_is_usable(account_locked_store) then
    raise exception 'An initial-payment marker was classified incorrectly';
  end if;
  if exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.store_id in (
      device_locked_store,
      account_locked_store
    )
  ) then
    raise exception 'An initial-payment store received a paid entitlement row';
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id in (
      device_locked_store,
      account_locked_store
    )
  ) then
    raise exception 'The subscription trigger created a branch before payment';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = account_locked_store
      and member.user_id = account_locked_user
      and member.role = 'owner'
      and member.status = 'active'
  ) then
    raise exception 'The locked store did not create its owner membership';
  end if;

  -- Even without a trial, the fresh device is bound to the consumed account.
  -- That prevents a logout/new-account cycle from reopening the free period.
  if not exists (
    select 1
    from private.trial_device_claims claim
    where claim.device_hash = extensions.digest(
      'damanak:trial-device:v1:' || account_locked_device,
      'sha256'
    )
      and claim.account_hash = extensions.digest(
        'damanak:trial-account:v1:' || account_locked_user::text,
        'sha256'
      )
  ) then
    raise exception 'An ineligible store did not bind its fresh installation';
  end if;
  if not public.register_trial_device(
    account_locked_store,
    account_locked_device
  ) then
    raise exception 'The owner could not register a fresh protected device';
  end if;
  if public.subscription_is_usable(account_locked_store) then
    raise exception 'Registering a device granted subscription access';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    device_locked_user::text,
    true
  );
  if public.register_trial_device(device_locked_store, eligible_device) then
    raise exception 'A second account took ownership of a claimed device';
  end if;

  -- Core writes and the initial-payment-specific invitation guard both reject
  -- the locked state, but the store and owner rows continue to exist.
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    account_locked_user::text,
    true
  );
  begin
    insert into public.products(store_id, name, created_by)
    values (
      account_locked_store,
      'منتج يجب رفضه',
      account_locked_user
    );
    raise exception 'An initial-payment store created a product';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'SUBSCRIPTION_INACTIVE' then
      raise;
    end if;
  end;
  begin
    perform public.create_store_invite(
      account_locked_store,
      'staff',
      1
    );
    raise exception 'An initial-payment store created an invitation';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'INITIAL_PAYMENT_REQUIRED' then
      raise;
    end if;
  end;

  -- The first valid subscription transition creates MAIN exactly once.
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    device_locked_user::text,
    true
  );
  update public.subscriptions
  set status = 'active',
      source = 'activation_code',
      trial_ends_at = null,
      current_period_start = pg_catalog.now(),
      current_period_end = pg_catalog.now() + interval '30 days'
  where store_id = device_locked_store;
  if not public.subscription_is_usable(device_locked_store)
     or public.store_requires_initial_payment(device_locked_store) then
    raise exception 'The valid activation did not unlock the store';
  end if;
  if (
    select pg_catalog.count(*)
    from public.branches branch
    where branch.store_id = device_locked_store
      and branch.code = 'MAIN'
      and branch.is_main
      and branch.is_active
  ) <> 1 then
    raise exception 'The first valid subscription did not create MAIN';
  end if;
  update public.subscriptions
  set current_period_end = current_period_end
  where store_id = device_locked_store;
  if (
    select pg_catalog.count(*)
    from public.branches branch
    where branch.store_id = device_locked_store
      and branch.code = 'MAIN'
  ) <> 1 then
    raise exception 'A subscription retry duplicated MAIN';
  end if;

  invite_result := public.create_store_invite(
    device_locked_store,
    'staff',
    1
  );
  if coalesce(invite_result->>'code', '') !~ '^DMN-[A-F0-9]{32}$' then
    raise exception 'A usable store could not create an invitation';
  end if;

  -- Create one legitimate warranty while the trial is usable, then expire the
  -- subscription. Historical warranty reads and new customer obligations stay
  -- available because the dedicated guard is initial-payment-only.
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    eligible_user::text,
    true
  );
  insert into public.customers(
    store_id,
    name,
    phone,
    created_by
  ) values (
    eligible_store,
    'عميل تاريخي',
    '70000004',
    eligible_user
  )
  returning id into historical_customer_id;

  insert into public.warranties(
    warranty_number,
    store_id,
    customer_id,
    customer_name,
    customer_phone,
    product_name,
    purchase_date,
    expiry_date,
    created_by
  ) values (
    'LIVE-' || pg_catalog.upper(
      pg_catalog.substr(extensions.gen_random_uuid()::text, 1, 12)
    ),
    eligible_store,
    historical_customer_id,
    'عميل تاريخي',
    '70000004',
    'منتج تاريخي',
    current_date,
    current_date + 365,
    eligible_user
  )
  returning id into warranty_id;

  update public.subscriptions
  set status = 'canceled',
      source = 'trial',
      trial_ends_at = pg_catalog.now() - interval '1 day',
      current_period_start = null,
      current_period_end = null
  where store_id = eligible_store;
  if public.subscription_is_usable(eligible_store)
     or public.store_requires_initial_payment(eligible_store) then
    raise exception 'An expired trial was confused with initial payment';
  end if;
  if not exists (
    select 1
    from public.warranties warranty
    where warranty.id = warranty_id
      and warranty.store_id = eligible_store
  ) then
    raise exception 'Historical warranty data disappeared after expiration';
  end if;
  if not public.can_access_warranty_records(eligible_store) then
    raise exception 'An expired owner lost historical warranty link access';
  end if;

  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'service_role',
    true
  );
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  claim_result := public.submit_public_warranty_claim(
    warranty_id,
    first_submission_id,
    'مطالبة تاريخية صالحة',
    'malfunction',
    ''
  );
  if coalesce((claim_result->>'duplicate')::boolean, true) then
    raise exception 'An expired historical warranty claim was not recorded';
  end if;
  historical_request_id := (claim_result->>'requestId')::uuid;
  update public.maintenance_requests
  set updated_at = updated_at
  where id = historical_request_id;

  -- Moving the synthetic row to the exact initial-payment tuple blocks only a
  -- new claim. An idempotent replay of the already-recorded claim remains a
  -- historical read and therefore still succeeds.
  update public.subscriptions
  set status = 'canceled',
      source = 'trial',
      trial_ends_at = null,
      current_period_start = null,
      current_period_end = null
  where store_id = eligible_store;
  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'authenticated',
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    eligible_user::text,
    true
  );
  if public.can_access_warranty_records(eligible_store) then
    raise exception 'An initial-payment store can issue a warranty link';
  end if;
  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'service_role',
    true
  );
  perform pg_catalog.set_config('request.jwt.claim.sub', '', true);
  claim_result := public.submit_public_warranty_claim(
    warranty_id,
    first_submission_id,
    'مطالبة تاريخية صالحة',
    'malfunction',
    ''
  );
  if not coalesce((claim_result->>'duplicate')::boolean, false) then
    raise exception 'An idempotent historical claim replay was blocked';
  end if;
  begin
    update public.maintenance_requests
    set updated_at = updated_at
    where id = historical_request_id;
    raise exception 'An initial-payment store updated a claim';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'INITIAL_PAYMENT_REQUIRED' then
      raise;
    end if;
  end;
  begin
    perform public.submit_public_warranty_claim(
      warranty_id,
      blocked_submission_id,
      'مطالبة جديدة يجب رفضها',
      'malfunction',
      ''
    );
    raise exception 'An initial-payment store accepted a public claim';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'INITIAL_PAYMENT_REQUIRED' then
      raise;
    end if;
  end;

  -- ACL contract: Build 25 owns the new entry point. The legacy Build 24 RPC
  -- remains executable but retains its strict trial-only error behavior.
  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.create_store_with_subscription(text,text,text,text,text)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'anon',
    'public.create_store_with_subscription(text,text,text,text,text)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'service_role',
    'public.create_store_with_subscription(text,text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'The Build 25 onboarding RPC ACL is not authenticated-only';
  end if;
  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.create_store_with_trial(text,text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'The Build 24 onboarding RPC lost its existing ACL';
  end if;
  if pg_catalog.has_function_privilege(
    'authenticated',
    'public.store_requires_initial_payment(uuid)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'anon',
    'public.store_requires_initial_payment(uuid)',
    'EXECUTE'
  ) then
    raise exception 'The internal initial-payment classifier is exposed';
  end if;
  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.can_access_warranty_records(uuid)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'anon',
    'public.can_access_warranty_records(uuid)',
    'EXECUTE'
  ) then
    raise exception 'The warranty-record access helper ACL is invalid';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_policy policy_row
    join pg_catalog.pg_class table_row
      on table_row.oid = policy_row.polrelid
    join pg_catalog.pg_namespace namespace_row
      on namespace_row.oid = table_row.relnamespace
    where namespace_row.nspname = 'public'
      and table_row.relname = 'warranties'
      and policy_row.polname = 'warranties_select_members'
      and pg_catalog.pg_get_expr(
        policy_row.polqual,
        policy_row.polrelid
      ) like '%can_access_warranty_records%'
  ) then
    raise exception 'Warranty link issuance is not guarded by RLS';
  end if;

  select pg_catalog.pg_get_functiondef(
    'public.create_store_with_subscription(text,text,text,text,text)'::regprocedure
  ) into new_function_definition;
  account_lock_position := pg_catalog.strpos(
    new_function_definition,
    'damanak:trial-account-lock:v1:'
  );
  device_lock_position := pg_catalog.strpos(
    new_function_definition,
    'damanak:trial-device-lock:v1:'
  );
  if account_lock_position = 0
     or device_lock_position <= account_lock_position
     or pg_catalog.strpos(
       new_function_definition,
       'on conflict (account_hash) do nothing'
     ) = 0 then
    raise exception 'The Build 25 RPC does not lock account before device';
  end if;

  select pg_catalog.pg_get_functiondef(
    'public.register_trial_device(uuid,text)'::regprocedure
  ) into register_function_definition;
  account_lock_position := pg_catalog.strpos(
    register_function_definition,
    'damanak:trial-account-lock:v1:'
  );
  device_lock_position := pg_catalog.strpos(
    register_function_definition,
    'damanak:trial-device-lock:v1:'
  );
  if account_lock_position = 0
     or device_lock_position <= account_lock_position
     or pg_catalog.strpos(
       register_function_definition,
       'on conflict (device_hash) do nothing'
     ) = 0 then
    raise exception 'register_trial_device is missing its race defenses';
  end if;

  select pg_catalog.pg_get_functiondef(
    'public.create_store_with_trial(text,text,text,text,text)'::regprocedure
  ) into legacy_function_definition;
  if pg_catalog.strpos(
    legacy_function_definition,
    'TRIAL_ALREADY_USED_BY_ACCOUNT'
  ) = 0 or pg_catalog.strpos(
    legacy_function_definition,
    'TRIAL_ALREADY_USED_ON_DEVICE'
  ) = 0 then
    raise exception 'The migration replaced the Build 24 trial-only RPC';
  end if;

  if not exists (
    select 1
    from pg_catalog.pg_trigger trigger_row
    join pg_catalog.pg_class table_row
      on table_row.oid = trigger_row.tgrelid
    join pg_catalog.pg_namespace namespace_row
      on namespace_row.oid = table_row.relnamespace
    where namespace_row.nspname = 'public'
      and table_row.relname = 'stores'
      and trigger_row.tgname = 'stores_create_default_branch'
      and trigger_row.tgdeferrable
      and trigger_row.tginitdeferred
      and not trigger_row.tgisinternal
  ) then
    raise exception 'The store MAIN trigger is no longer initially deferred';
  end if;

  insert into store_creation_test_context(
    eligible_store,
    device_locked_store,
    account_locked_store
  ) values (
    eligible_store,
    device_locked_store,
    account_locked_store
  );
end
$test$;

-- Execute every pending store trigger before verifying that the locked store
-- still has no branch. This is the regression for the deferred-trigger path.
set constraints stores_create_default_branch immediate;

do $deferred_test$
declare
  context_row store_creation_test_context%rowtype;
begin
  select * into context_row from store_creation_test_context;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = context_row.account_locked_store
  ) then
    raise exception 'The deferred store trigger created a pre-payment branch';
  end if;
  if (
    select pg_catalog.count(*)
    from public.branches branch
    where branch.store_id = context_row.device_locked_store
      and branch.code = 'MAIN'
      and branch.is_main
      and branch.is_active
  ) <> 1 then
    raise exception 'The deferred trigger changed the paid MAIN result';
  end if;
end
$deferred_test$;

rollback;

select 'Build 24 compatibility and Build 25 paid-store onboarding passed; transaction rolled back' as result;
