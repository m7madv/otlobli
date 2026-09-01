-- Live regression contract for migration
-- 20260901200000_damanak_free_access_and_billing_repair.sql.
-- Run only after the migration is applied. Every persistent write rolls back.

begin;
set transaction isolation level repeatable read;
set local statement_timeout = '60s';
set local lock_timeout = '5s';

create temporary table production_entitlements_before
on commit drop
as
select entitlement.id, pg_catalog.to_jsonb(entitlement) as payload
from public.store_entitlements entitlement
where entitlement.environment = 'production';

create temporary table production_subscriptions_before
on commit drop
as
select subscription.id, pg_catalog.to_jsonb(subscription) as payload
from public.subscriptions subscription
where subscription.source = 'store'
  and subscription.store_environment = 'production';

create temporary table google_sandbox_entitlements_before
on commit drop
as
select entitlement.id, pg_catalog.to_jsonb(entitlement) as payload
from public.store_entitlements entitlement
where entitlement.platform = 'google_play'
  and entitlement.environment = 'sandbox';

create temporary table google_sandbox_subscriptions_before
on commit drop
as
select subscription.id, pg_catalog.to_jsonb(subscription) as payload
from public.subscriptions subscription
where subscription.source = 'store'
  and subscription.billing_provider = 'google_play'
  and subscription.store_environment = 'sandbox';

create temporary table purchase_limits_before
on commit drop
as
select
  limits.user_id,
  limits.store_id,
  pg_catalog.to_jsonb(limits) as payload
from private.store_purchase_verification_limits limits;

create temporary table refresh_limits_before
on commit drop
as
select
  limits.user_id,
  limits.store_id,
  pg_catalog.to_jsonb(limits) as payload
from private.store_subscription_refresh_limits limits;

create or replace function pg_temp.assume_actor(
  target_user uuid,
  target_role text,
  target_session text
)
returns void
language plpgsql
as $fn$
begin
  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    target_role,
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    coalesce(target_user::text, ''),
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claims',
    pg_catalog.jsonb_strip_nulls(
      pg_catalog.jsonb_build_object(
        'role', target_role,
        'sub', target_user::text,
        'session_id', target_session
      )
    )::text,
    true
  );
end;
$fn$;

create or replace function pg_temp.insert_test_warranty(
  target_store uuid,
  target_customer uuid,
  target_creator uuid,
  target_created_at timestamptz
)
returns void
language sql
as $fn$
  insert into public.warranties (
    warranty_number,
    store_id,
    customer_id,
    customer_name,
    customer_phone,
    product_name,
    purchase_date,
    expiry_date,
    created_by,
    created_at,
    currency_code
  ) values (
    'LIVE-' || pg_catalog.upper(
      pg_catalog.substr(extensions.gen_random_uuid()::text, 1, 12)
    ),
    target_store,
    target_customer,
    'عميل اختبار',
    '70000000',
    'منتج اختبار',
    current_date,
    current_date + 365,
    target_creator,
    target_created_at,
    'QAR'
  )
$fn$;

do $test$
declare
  owner_a uuid := extensions.gen_random_uuid();
  owner_b uuid := extensions.gen_random_uuid();
  owner_c uuid := extensions.gen_random_uuid();
  session_a text := 'free-a-' || extensions.gen_random_uuid()::text;
  session_a_new text := 'free-a-new-' || extensions.gen_random_uuid()::text;
  session_b text := 'free-b-' || extensions.gen_random_uuid()::text;
  device_a text := extensions.gen_random_uuid()::text;
  device_a_second text := extensions.gen_random_uuid()::text;
  store_a uuid;
  store_b uuid;
  store_c uuid := extensions.gen_random_uuid();
  legacy_store uuid;
  customer_a uuid := extensions.gen_random_uuid();
  sandbox_entitlement_id uuid := extensions.gen_random_uuid();
  google_sandbox_entitlement_id uuid := extensions.gen_random_uuid();
  production_entitlement_id uuid;
  sandbox_original text :=
    'DMN-LIVE-SANDBOX-' || extensions.gen_random_uuid()::text;
  google_sandbox_original text :=
    'DMN-LIVE-GOOGLE-SANDBOX-' || extensions.gen_random_uuid()::text;
  production_original text :=
    'DMN-LIVE-PRODUCTION-' || extensions.gen_random_uuid()::text;
  access_snapshot jsonb;
  terminal_result boolean;
  hit_message text;
  warranty_count integer;
  production_entitlement_snapshot jsonb;
  production_subscription_snapshot jsonb;
  google_sandbox_entitlement_snapshot jsonb;
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
      owner_a,
      'authenticated',
      'authenticated',
      'free-a-' || owner_a::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      owner_b,
      'authenticated',
      'authenticated',
      'free-b-' || owner_b::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      owner_c,
      'authenticated',
      'authenticated',
      'production-' || owner_c::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    );

  insert into public.stores (
    id,
    name,
    phone,
    city,
    country_code,
    owner_id,
    currency_code
  ) values (
    store_c,
    'متجر إنتاج اصطناعي',
    '70000005',
    'الدوحة',
    'QA',
    owner_c,
    'QAR'
  );
  insert into public.store_members(store_id, user_id, role, status)
  values (store_c, owner_c, 'owner', 'active');
  insert into public.subscriptions (
    store_id,
    plan_id,
    status,
    source,
    auto_renews
  ) values (
    store_c,
    'starter',
    'canceled',
    'trial',
    false
  );

  if not exists (
    select 1
    from public.plans plan
    where plan.id = 'free'
      and plan.name_ar = 'مجانية'
      and plan.monthly_price = 0
      and plan.yearly_price = 0
      and plan.monthly_warranties = 20
      and plan.max_members = 1
      and plan.max_branches = 1
      and plan.monthly_ai_imports = 0
      and plan.monthly_ai_claim_reviews = 0
      and not plan.api_access
      and not plan.webhook_access
      and not plan.custom_branding
      and not plan.is_active
  ) then
    raise exception 'FREE_PLAN_CONFIGURATION_INVALID';
  end if;

  if pg_catalog.has_table_privilege(
    'authenticated',
    'public.subscriptions',
    'UPDATE'
  ) then
    raise exception 'AUTHENTICATED_CAN_UPDATE_SUBSCRIPTIONS';
  end if;
  if not pg_catalog.has_function_privilege(
    'authenticated',
    'public.create_store_with_subscription(text,text,text,text,text)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'service_role',
    'public.create_store_with_subscription(text,text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'LEGACY_CREATOR_ACL_INVALID';
  end if;
  if pg_catalog.has_function_privilege(
    'authenticated',
    'private.create_store_with_subscription_legacy_core(text,text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'FREE_CREATOR_CORE_IS_EXPOSED';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_policy policy_row
    join pg_catalog.pg_class table_row
      on table_row.oid = policy_row.polrelid
    join pg_catalog.pg_namespace namespace_row
      on namespace_row.oid = table_row.relnamespace
    where namespace_row.nspname = 'public'
      and table_row.relname = 'plans'
      and policy_row.polname = 'plans_select_authenticated'
      and pg_catalog.pg_get_expr(
        policy_row.polqual,
        policy_row.polrelid
      ) like '%free_access_mirror%'
  ) then
    raise exception 'FREE_PLAN_COMPATIBILITY_POLICY_MISSING';
  end if;

  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a);
  store_a := public.create_store_with_free_access(
    'متجر الخطة المجانية',
    '70000001',
    'الدوحة',
    'QA',
    device_a
  );

  legacy_store := public.create_store_with_subscription(
    'إعادة Build 29',
    '70000002',
    'الريان',
    'QA',
    device_a
  );
  if legacy_store <> store_a then
    raise exception 'BUILD_29_CREATOR_NOT_IDEMPOTENT';
  end if;
  legacy_store := public.create_store_with_trial(
    'إعادة Build 23',
    '70000003',
    'الدوحة',
    'QA',
    device_a
  );
  if legacy_store <> store_a then
    raise exception 'BUILD_23_CREATOR_NOT_ROUTED_TO_FREE';
  end if;
  if exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = store_a
      and subscription.status = 'trialing'
  ) then
    raise exception 'LEGACY_TRIAL_SURVIVED_FREE_TRANSITION';
  end if;
  if not exists (
    select 1
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = store_a
      and subscription.plan_id = 'free'
      and subscription.status = 'active'
      and subscription.source = 'manual'
      and subscription.free_access_mirror
      and plan.monthly_warranties = 20
      and subscription.trial_ends_at is null
      and subscription.current_period_start is null
      and subscription.current_period_end is null
      and pg_catalog.num_nonnulls(
        subscription.billing_provider,
        subscription.store_product_id,
        subscription.billing_cycle,
        subscription.original_transaction_id,
        subscription.last_store_verified_at,
        subscription.store_environment,
        subscription.store_entitlement_id
      ) = 0
      and not subscription.auto_renews
  ) then
    raise exception 'LEGACY_FREE_MIRROR_INVALID';
  end if;

  access_snapshot := public.current_store_access(store_a);
  if access_snapshot ->> 'plan_id' <> 'free'
     or access_snapshot ->> 'status' <> 'active'
     or access_snapshot ->> 'source' <> 'free'
     or (access_snapshot -> 'plans' ->> 'monthly_warranties')::integer <> 20
     or coalesce(
       (access_snapshot ->> 'has_store_billing_lineage')::boolean,
       true
     ) then
    raise exception 'BOUND_FREE_ACCESS_SNAPSHOT_INVALID';
  end if;

  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  access_snapshot := public.current_store_access(store_a);
  if access_snapshot ->> 'plan_id' <> 'starter'
     or access_snapshot ->> 'status' <> 'canceled'
     or access_snapshot ->> 'source' <> 'trial' then
    raise exception 'UNBOUND_SESSION_DID_NOT_FAIL_CLOSED';
  end if;
  if not public.claim_free_plan_device(store_a, device_a) then
    raise exception 'SAME_INSTALLATION_SESSION_REBIND_FAILED';
  end if;
  if (
    select pg_catalog.count(*)
    from private.free_session_claims session_claim
    where session_claim.store_id = store_a
  ) <> 1 then
    raise exception 'FREE_SESSION_ROWS_ACCUMULATED';
  end if;
  access_snapshot := public.current_store_access(store_a);
  if access_snapshot ->> 'plan_id' <> 'free' then
    raise exception 'NEW_BOUND_SESSION_DID_NOT_GET_FREE';
  end if;
  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a);
  access_snapshot := public.current_store_access(store_a);
  if access_snapshot ->> 'status' <> 'canceled' then
    raise exception 'REPLACED_SESSION_REMAINED_AUTHORIZED';
  end if;
  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  if public.claim_free_plan_device(store_a, device_a_second) then
    raise exception 'SECOND_INSTALLATION_WAS_ACCEPTED';
  end if;

  perform pg_temp.assume_actor(owner_b, 'authenticated', session_b);
  store_b := public.create_store_with_free_access(
    'متجر التثبيت المتعارض',
    '70000004',
    'الدوحة',
    'QA',
    device_a
  );
  if exists (
    select 1
    from private.free_plan_grants grant_row
    where grant_row.store_id = store_b
      and grant_row.status = 'active'
  ) or not public.store_requires_initial_payment(store_b) then
    raise exception 'SECOND_ACCOUNT_TOOK_FREE_DEVICE';
  end if;

  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  if public.store_plan_allows(store_a, 'api')
     or public.store_plan_allows(store_a, 'webhook')
     or public.store_plan_allows(store_a, 'branding') then
    raise exception 'FREE_PLAN_RECEIVED_PAID_FEATURE';
  end if;
  insert into public.customers (
    id,
    store_id,
    name,
    phone,
    created_by
  ) values (
    customer_a,
    store_a,
    'عميل اختبار',
    '70000000',
    owner_a
  );
  perform pg_temp.assume_actor(owner_a, 'service_role', session_a_new);
  perform pg_temp.insert_test_warranty(
    store_a,
    customer_a,
    owner_a,
    pg_catalog.date_trunc('month', pg_catalog.now()) - interval '1 second'
  );
  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  for warranty_count in 1..20 loop
    perform pg_temp.insert_test_warranty(
      store_a,
      customer_a,
      owner_a,
      pg_catalog.now()
    );
  end loop;
  begin
    perform pg_temp.insert_test_warranty(
      store_a,
      customer_a,
      owner_a,
      pg_catalog.now()
    );
    raise exception 'FREE_WARRANTY_21_WAS_ACCEPTED';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'WARRANTY_LIMIT_REACHED' then
      raise;
    end if;
  end;

  insert into public.store_entitlements (
    id,
    store_id,
    user_id,
    platform,
    product_id,
    plan_id,
    billing_cycle,
    transaction_id,
    original_transaction_id,
    status,
    environment,
    period_start,
    period_end,
    auto_renews,
    verified_at,
    next_verification_at
  ) values (
    sandbox_entitlement_id,
    store_a,
    owner_a,
    'app_store',
    'com.damanak.subscription.growth',
    'growth',
    'yearly',
    'DMN-LIVE-SANDBOX-TX-' || extensions.gen_random_uuid()::text,
    sandbox_original,
    'active',
    'sandbox',
    pg_catalog.now(),
    pg_catalog.now() + interval '1 year',
    true,
    pg_catalog.now(),
    pg_catalog.now() + interval '5 minutes'
  );
  update public.subscriptions subscription
  set plan_id = 'growth',
      status = 'active',
      trial_ends_at = null,
      current_period_start = pg_catalog.now(),
      current_period_end = pg_catalog.now() + interval '1 year',
      source = 'store',
      billing_provider = 'app_store',
      store_product_id = 'com.damanak.subscription.growth',
      billing_cycle = 'yearly',
      original_transaction_id = sandbox_original,
      auto_renews = true,
      last_store_verified_at = pg_catalog.now(),
      store_environment = 'sandbox',
      store_entitlement_id = sandbox_entitlement_id
  where subscription.store_id = store_a;

  update public.store_entitlements entitlement
  set plan_id = 'scale',
      product_id = 'com.damanak.subscription.scale'
  where entitlement.id = sandbox_entitlement_id;
  update public.subscriptions subscription
  set plan_id = 'scale',
      store_product_id = 'com.damanak.subscription.scale'
  where subscription.store_id = store_a;

  -- المستخدم لا يملك UPDATE على subscriptions، لكن المصالحة الموثقة يجب أن
  -- تستطيع تطبيق خطة أدنى أعادها المزود بعد تغيير خارجي.
  if pg_catalog.has_table_privilege(
    'authenticated',
    'public.subscriptions',
    'UPDATE'
  ) then
    raise exception 'AUTHENTICATED_CAN_MUTATE_SUBSCRIPTIONS';
  end if;
  update public.store_entitlements entitlement
  set plan_id = 'growth',
      product_id = 'com.damanak.subscription.growth'
  where entitlement.id = sandbox_entitlement_id;
  update public.subscriptions subscription
  set plan_id = 'growth',
      store_product_id = 'com.damanak.subscription.growth'
  where subscription.store_id = store_a;
  if not exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = store_a
      and subscription.plan_id = 'growth'
  ) then
    raise exception 'DIRECT_PROVIDER_DOWNGRADE_WAS_BLOCKED';
  end if;

  -- مصالحة حقيقية عبر RPC المزود: يبدأ المتجر الاصطناعي على توسع ثم يعيد
  -- Apple خطة نمو موثقة من السلسلة نفسها، فيجب أن تصبح نمو بلا trigger حاجب.
  perform pg_temp.assume_actor(owner_c, 'service_role', session_a_new);
  perform public.apply_verified_store_entitlement_with_receipt(
    store_c,
    owner_c,
    'app_store',
    'com.damanak.subscription.scale.monthly',
    '',
    'DMN-LIVE-PRODUCTION-SCALE-' || extensions.gen_random_uuid()::text,
    production_original,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '1 year',
    true,
    null,
    null,
    null,
    null
  );
  perform public.apply_verified_store_entitlement_with_receipt(
    store_c,
    owner_c,
    'app_store',
    'com.damanak.subscription.growth.monthly',
    '',
    'DMN-LIVE-PRODUCTION-GROWTH-' || extensions.gen_random_uuid()::text,
    production_original,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '1 year',
    true,
    null,
    null,
    null,
    null
  );
  if not exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = store_c
      and subscription.plan_id = 'growth'
      and subscription.source = 'store'
      and subscription.billing_provider = 'app_store'
      and subscription.store_environment = 'production'
  ) then
    raise exception 'VERIFIED_PROVIDER_DOWNGRADE_WAS_NOT_RECONCILED';
  end if;
  select entitlement.id
  into production_entitlement_id
  from public.store_entitlements entitlement
  where entitlement.store_id = store_c
    and entitlement.platform = 'app_store'
    and entitlement.original_transaction_id = production_original
    and entitlement.environment = 'production'
    and entitlement.superseded_at is null;
  if production_entitlement_id is null or not exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.id = production_entitlement_id
      and entitlement.plan_id = 'growth'
  ) then
    raise exception 'VERIFIED_PROVIDER_ENTITLEMENT_DOWNGRADE_MISSING';
  end if;

  perform pg_temp.assume_actor(owner_a, 'service_role', session_a_new);
  terminal_result := public.apply_verified_sandbox_terminal_entitlement(
    store_a,
    owner_a,
    'app_store',
    'DMN-LIVE-PAST-DUE-' || extensions.gen_random_uuid()::text,
    sandbox_original,
    'past_due',
    pg_catalog.now() - interval '1 month',
    pg_catalog.now() + interval '2 days',
    true
  );
  if not terminal_result or not exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.id = sandbox_entitlement_id
      and entitlement.status = 'past_due'
      and entitlement.next_verification_at >
        pg_catalog.now() + interval '99 years'
  ) then
    raise exception 'SANDBOX_PAST_DUE_REMAINED_REFRESHABLE';
  end if;
  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  access_snapshot := public.current_store_access(store_a);
  if access_snapshot ->> 'plan_id' <> 'free'
     or coalesce(
       (access_snapshot ->> 'has_store_billing_lineage')::boolean,
       true
     ) then
    raise exception 'SANDBOX_PAST_DUE_BLOCKED_FREE_ACCESS';
  end if;

  perform pg_temp.assume_actor(owner_a, 'service_role', session_a_new);
  terminal_result := public.apply_verified_sandbox_terminal_entitlement(
    store_a,
    owner_a,
    'app_store',
    'DMN-LIVE-CANCELED-' || extensions.gen_random_uuid()::text,
    sandbox_original,
    'canceled',
    pg_catalog.now() - interval '1 month',
    pg_catalog.now() - interval '1 minute',
    false
  );
  if not terminal_result then
    raise exception 'KNOWN_SANDBOX_CANCELLATION_WAS_NOT_APPLIED';
  end if;
  terminal_result := public.apply_verified_sandbox_terminal_entitlement(
    store_a,
    owner_a,
    'app_store',
    'DMN-LIVE-UNKNOWN-TX-' || extensions.gen_random_uuid()::text,
    'DMN-LIVE-UNKNOWN-ORIGINAL-' || extensions.gen_random_uuid()::text,
    'canceled',
    pg_catalog.now() - interval '1 month',
    pg_catalog.now() - interval '1 minute',
    false
  );
  if terminal_result then
    raise exception 'UNKNOWN_TERMINAL_RECEIPT_CREATED_ENTITLEMENT';
  end if;

  -- المسار المخفّض خاص بـApple Sandbox؛ لا يجوز أن يمس Google حتى لو كان
  -- صفه الاختباري terminal ومعروف السلسلة.
  insert into public.store_entitlements (
    id,
    store_id,
    user_id,
    platform,
    product_id,
    base_plan_id,
    plan_id,
    billing_cycle,
    transaction_id,
    original_transaction_id,
    status,
    environment,
    period_start,
    period_end,
    auto_renews,
    verified_at,
    next_verification_at
  ) values (
    google_sandbox_entitlement_id,
    store_b,
    owner_b,
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    'growth',
    'monthly',
    'DMN-LIVE-GOOGLE-SANDBOX-TX-' || extensions.gen_random_uuid()::text,
    google_sandbox_original,
    'canceled',
    'sandbox',
    pg_catalog.now() - interval '1 month',
    pg_catalog.now() - interval '1 minute',
    false,
    pg_catalog.now(),
    pg_catalog.now() + interval '100 years'
  );
  select pg_catalog.to_jsonb(entitlement)
  into google_sandbox_entitlement_snapshot
  from public.store_entitlements entitlement
  where entitlement.id = google_sandbox_entitlement_id;
  begin
    perform public.apply_verified_sandbox_terminal_entitlement(
      store_b,
      owner_b,
      'google_play',
      'DMN-LIVE-GOOGLE-SANDBOX-END-' || extensions.gen_random_uuid()::text,
      google_sandbox_original,
      'revoked',
      pg_catalog.now() - interval '1 month',
      pg_catalog.now() - interval '1 minute',
      false
    );
    raise exception 'GOOGLE_SANDBOX_ACCEPTED_APPLE_TERMINAL_PATH';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'INVALID_STORE_ENTITLEMENT' then
      raise;
    end if;
  end;
  if (
    select pg_catalog.to_jsonb(entitlement)
    from public.store_entitlements entitlement
    where entitlement.id = google_sandbox_entitlement_id
  ) is distinct from google_sandbox_entitlement_snapshot then
    raise exception 'GOOGLE_SANDBOX_TERMINAL_ROW_CHANGED';
  end if;

  perform pg_temp.assume_actor(owner_a, 'authenticated', session_a_new);
  if not public.register_trial_device(store_a, device_a) then
    raise exception 'LEGACY_FREE_DEVICE_REBIND_REJECTED';
  end if;
  if not exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = store_a
      and subscription.plan_id = 'free'
      and subscription.status = 'active'
      and subscription.source = 'manual'
      and subscription.free_access_mirror
      and subscription.store_entitlement_id is null
  ) then
    raise exception 'LEGACY_FREE_MIRROR_NOT_RESTORED_AFTER_TERMINAL: %',
      (
        select pg_catalog.to_jsonb(subscription)
        from public.subscriptions subscription
        where subscription.store_id = store_a
      );
  end if;
  if not exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.id = sandbox_entitlement_id
      and entitlement.status = 'canceled'
  ) then
    raise exception 'LEGACY_LOGIN_REACTIVATED_SANDBOX_TOMBSTONE';
  end if;

  perform pg_temp.assume_actor(owner_c, 'service_role', session_a_new);
  select pg_catalog.to_jsonb(entitlement)
  into production_entitlement_snapshot
  from public.store_entitlements entitlement
  where entitlement.id = production_entitlement_id;
  select pg_catalog.to_jsonb(subscription)
  into production_subscription_snapshot
  from public.subscriptions subscription
  where subscription.store_id = store_c;
  begin
    perform public.apply_verified_sandbox_terminal_entitlement(
      store_c,
      owner_c,
      'app_store',
      'DMN-LIVE-PRODUCTION-END-' || extensions.gen_random_uuid()::text,
      production_original,
      'canceled',
      pg_catalog.now() - interval '1 month',
      pg_catalog.now() - interval '1 minute',
      false
    );
    raise exception 'PRODUCTION_ACCEPTED_SANDBOX_TERMINAL';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'SANDBOX_CANNOT_REPLACE_PRODUCTION' then
      raise;
    end if;
  end;
  if (
    select pg_catalog.to_jsonb(entitlement)
    from public.store_entitlements entitlement
    where entitlement.id = production_entitlement_id
  ) is distinct from production_entitlement_snapshot or (
    select pg_catalog.to_jsonb(subscription)
    from public.subscriptions subscription
    where subscription.store_id = store_c
  ) is distinct from production_subscription_snapshot then
    raise exception 'PRODUCTION_SYNTHETIC_STATE_CHANGED';
  end if;

  if exists (
    select 1
    from production_entitlements_before snapshot
    left join public.store_entitlements entitlement
      on entitlement.id = snapshot.id
    where pg_catalog.to_jsonb(entitlement) is distinct from snapshot.payload
  ) or exists (
    select 1
    from production_subscriptions_before snapshot
    left join public.subscriptions subscription
      on subscription.id = snapshot.id
    where pg_catalog.to_jsonb(subscription) is distinct from snapshot.payload
  ) then
    raise exception 'EXISTING_PRODUCTION_BILLING_CHANGED';
  end if;
  if exists (
    (
      select snapshot.id, snapshot.payload
      from google_sandbox_entitlements_before snapshot
    )
    except
    (
      select entitlement.id, pg_catalog.to_jsonb(entitlement)
      from public.store_entitlements entitlement
      where entitlement.platform = 'google_play'
        and entitlement.environment = 'sandbox'
        and entitlement.id <> google_sandbox_entitlement_id
    )
  ) or exists (
    (
      select entitlement.id, pg_catalog.to_jsonb(entitlement)
      from public.store_entitlements entitlement
      where entitlement.platform = 'google_play'
        and entitlement.environment = 'sandbox'
        and entitlement.id <> google_sandbox_entitlement_id
    )
    except
    (
      select snapshot.id, snapshot.payload
      from google_sandbox_entitlements_before snapshot
    )
  ) or exists (
    (
      select snapshot.id, snapshot.payload
      from google_sandbox_subscriptions_before snapshot
    )
    except
    (
      select subscription.id, pg_catalog.to_jsonb(subscription)
      from public.subscriptions subscription
      where subscription.source = 'store'
        and subscription.billing_provider = 'google_play'
        and subscription.store_environment = 'sandbox'
    )
  ) or exists (
    (
      select subscription.id, pg_catalog.to_jsonb(subscription)
      from public.subscriptions subscription
      where subscription.source = 'store'
        and subscription.billing_provider = 'google_play'
        and subscription.store_environment = 'sandbox'
    )
    except
    (
      select snapshot.id, snapshot.payload
      from google_sandbox_subscriptions_before snapshot
    )
  ) then
    raise exception 'EXISTING_GOOGLE_SANDBOX_BILLING_CHANGED';
  end if;
  if exists (
    (
      select snapshot.user_id, snapshot.store_id, snapshot.payload
      from purchase_limits_before snapshot
    )
    except
    (
      select
        limits.user_id,
        limits.store_id,
        pg_catalog.to_jsonb(limits)
      from private.store_purchase_verification_limits limits
    )
  ) or exists (
    (
      select
        limits.user_id,
        limits.store_id,
        pg_catalog.to_jsonb(limits)
      from private.store_purchase_verification_limits limits
    )
    except
    (
      select snapshot.user_id, snapshot.store_id, snapshot.payload
      from purchase_limits_before snapshot
    )
  ) or exists (
    (
      select snapshot.user_id, snapshot.store_id, snapshot.payload
      from refresh_limits_before snapshot
    )
    except
    (
      select
        limits.user_id,
        limits.store_id,
        pg_catalog.to_jsonb(limits)
      from private.store_subscription_refresh_limits limits
    )
  ) or exists (
    (
      select
        limits.user_id,
        limits.store_id,
        pg_catalog.to_jsonb(limits)
      from private.store_subscription_refresh_limits limits
    )
    except
    (
      select snapshot.user_id, snapshot.store_id, snapshot.payload
      from refresh_limits_before snapshot
    )
  ) then
    raise exception 'RATE_LIMIT_HISTORY_CHANGED';
  end if;
  if exists (
    select 1
    from public.audit_logs audit
    where audit.action = 'sandbox_entitlement_reset'
      and (
        audit.metadata ->> 'environment' is distinct from 'sandbox'
        or audit.metadata ->> 'platform' is distinct from 'app_store'
      )
  ) or exists (
    select 1
    from public.audit_logs audit
    where audit.action = 'subscription_state_reset'
      and audit.metadata ->> 'previous_source' = 'store'
      and (
        audit.metadata ->> 'previous_environment' is distinct from 'sandbox'
        or audit.metadata ->> 'previous_billing_provider'
          is distinct from 'app_store'
      )
  ) then
    raise exception 'RESET_AUDIT_ESCAPED_APPLE_SANDBOX';
  end if;
end
$test$;

rollback;

select
  'free access, quota, compatibility, terminal state, and production isolation passed; transaction rolled back'
  as result;
