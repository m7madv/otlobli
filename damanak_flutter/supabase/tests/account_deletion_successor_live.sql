-- Live regression contract for migration 20260831170000.
-- Run with:
--   supabase db query --linked --file supabase/tests/account_deletion_successor_live.sql
-- Synthetic users and store data are always rolled back.

begin;
set local statement_timeout = '20s';
set local lock_timeout = '5s';

-- The normal auth-to-profile trigger and the production subscription
-- member-limit trigger both stay live; every synthetic row still rolls back.

do $test$
declare
  deleting_owner uuid := gen_random_uuid();
  successor uuid := gen_random_uuid();
  test_store uuid := gen_random_uuid();
  entitlement_id uuid := gen_random_uuid();
  original_id text := 'DMN-DELETE-LIVE-' || gen_random_uuid()::text;
  successor_role text;
  successor_status text;
  surviving_owner uuid;
  subscription_status text;
  entitlement_status text;
  entitlement_user uuid;
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
      deleting_owner,
      'authenticated',
      'authenticated',
      'delete-owner-' || deleting_owner::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      successor,
      'authenticated',
      'authenticated',
      'delete-successor-' || successor::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    );

  insert into public.stores (id, name, owner_id, country_code, currency_code)
  values (test_store, 'متجر حذف تجريبي', deleting_owner, 'QA', 'QAR');

  insert into public.store_members (store_id, user_id, role, status)
  values
    (test_store, deleting_owner, 'owner', 'active'),
    (test_store, successor, 'manager', 'active');

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
    auto_renews
  ) values (
    entitlement_id,
    test_store,
    deleting_owner,
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    'growth',
    'monthly',
    original_id || '-transaction',
    original_id,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true
  );

  insert into public.subscriptions (
    store_id,
    plan_id,
    status,
    current_period_start,
    current_period_end,
    source,
    billing_provider,
    store_product_id,
    billing_cycle,
    original_transaction_id,
    auto_renews,
    last_store_verified_at,
    store_environment,
    store_entitlement_id
  ) values (
    test_store,
    'growth',
    'active',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    'store',
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    original_id,
    true,
    pg_catalog.now(),
    'production',
    entitlement_id
  );

  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'authenticated',
    true
  );
  perform pg_catalog.set_config(
    'request.jwt.claim.sub',
    deleting_owner::text,
    true
  );
  perform public.delete_current_account();

  if exists (select 1 from auth.users where id = deleting_owner) then
    raise exception 'The deleting synthetic owner still exists';
  end if;

  select store.owner_id
  into surviving_owner
  from public.stores store
  where store.id = test_store;
  select member.role, member.status
  into successor_role, successor_status
  from public.store_members member
  where member.store_id = test_store
    and member.user_id = successor;
  select subscription.status
  into subscription_status
  from public.subscriptions subscription
  where subscription.store_id = test_store;
  select entitlement.status, entitlement.user_id
  into entitlement_status, entitlement_user
  from public.store_entitlements entitlement
  where entitlement.id = entitlement_id;

  if surviving_owner <> successor
     or successor_role <> 'owner'
     or successor_status <> 'active'
     or subscription_status <> 'canceled'
     or entitlement_status <> 'canceled'
     or entitlement_user is not null then
    raise exception
      'Account deletion did not preserve one active successor owner';
  end if;
end
$test$;

rollback;

select 'account deletion successor passed; transaction rolled back' as result;
