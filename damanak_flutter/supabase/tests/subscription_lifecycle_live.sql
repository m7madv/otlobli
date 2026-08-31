-- Live integration contract for migration 20260831160000.
-- Run with:
--   supabase db query --linked --file supabase/tests/subscription_lifecycle_live.sql
-- Every write is enclosed in a transaction that is always rolled back.

begin;
set local statement_timeout = '20s';
set local lock_timeout = '5s';

-- Subscription side-effect triggers are outside this lifecycle test. USER
-- triggers are disabled transactionally; FK and check constraints remain live.
alter table public.subscriptions disable trigger user;
alter table public.store_entitlements disable trigger user;

do $test$
declare
  store_a uuid;
  store_b uuid;
  owner_a uuid;
  owner_b uuid;
  token_a text := 'damanak-live-token-a-' || gen_random_uuid()::text;
  token_b text := 'damanak-live-token-b-' || gen_random_uuid()::text;
  token_c text := 'damanak-live-token-c-' || gen_random_uuid()::text;
  token_a_hash text;
  token_b_hash text;
  token_c_hash text;
  original_a text;
  transaction_a text := 'DMN-LIVE-A-' || gen_random_uuid()::text;
  transaction_b text := 'DMN-LIVE-B-' || gen_random_uuid()::text;
  transaction_c text := 'DMN-LIVE-C-' || gen_random_uuid()::text;
  foreign_entitlement_id uuid := gen_random_uuid();
  foreign_original text := 'DMN-LIVE-FOREIGN-' || gen_random_uuid()::text;
  hit_constraint text;
  hit_message text;
  current_product text;
  current_receipt text;
  current_count integer;
  resolved_binding jsonb;
begin
  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'service_role',
    true
  );
  if auth.role() <> 'service_role' then
    raise exception 'The live subscription test could not assume service_role';
  end if;

  select store.id, store.owner_id
  into store_a, owner_a
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = store.owner_id
   and member.role = 'owner'
   and member.status = 'active'
  join public.subscriptions subscription
    on subscription.store_id = store.id
  order by store.created_at, store.id
  limit 1;

  select store.id, store.owner_id
  into store_b, owner_b
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = store.owner_id
   and member.role = 'owner'
   and member.status = 'active'
  where store.id <> store_a
  order by store.created_at, store.id
  limit 1;

  if store_a is null or store_b is null then
    raise exception
      'The live subscription test requires two stores and one subscription';
  end if;

  token_a_hash := pg_catalog.encode(
    extensions.digest(token_a, 'sha256'),
    'hex'
  );
  token_b_hash := pg_catalog.encode(
    extensions.digest(token_b, 'sha256'),
    'hex'
  );
  token_c_hash := pg_catalog.encode(
    extensions.digest(token_c, 'sha256'),
    'hex'
  );
  original_a := 'token_' || token_a_hash;

  -- First purchase A becomes the only current entitlement and saved receipt.
  perform public.apply_verified_store_entitlement_with_receipt(
    store_a,
    owner_a,
    'google_play',
    'com.damanak.subscription.starter',
    'monthly',
    transaction_a,
    original_a,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    token_a,
    token_a_hash,
    null,
    null
  );

  -- Google upgrade B authenticates A as its predecessor, keeps one lineage,
  -- and atomically replaces the saved receipt with B.
  perform public.apply_verified_store_entitlement_with_receipt(
    store_a,
    owner_a,
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    transaction_b,
    'token_' || token_b_hash,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    token_b,
    token_b_hash,
    token_a_hash,
    null
  );

  select subscription.store_product_id
  into current_product
  from public.subscriptions subscription
  where subscription.store_id = store_a;

  select receipt.purchase_token
  into current_receipt
  from private.store_receipt_secrets receipt
  where receipt.platform = 'google_play'
    and receipt.original_transaction_id = original_a;

  select pg_catalog.count(*)
  into current_count
  from public.store_entitlements entitlement
  where entitlement.store_id = store_a
    and entitlement.superseded_at is null;

  if current_product <> 'com.damanak.subscription.growth'
     or current_receipt <> token_b
     or current_count <> 1 then
    raise exception 'A to B upgrade did not converge on one current receipt';
  end if;

  -- C cannot branch from A after B has already replaced A. The failed write
  -- must leave no token-link row and cannot alter the subscription or secret.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      store_a,
      owner_a,
      'google_play',
      'com.damanak.subscription.scale',
      'monthly',
      transaction_c,
      'token_' || token_c_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      token_c,
      token_c_hash,
      token_a_hash,
      null
    );
    raise exception 'A sibling Google token was accepted from stale A';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED' then
      raise;
    end if;
  end;

  if exists (
    select 1
    from private.google_purchase_token_links token_link
    where token_link.token_hash = token_c_hash
  ) then
    raise exception 'Rejected sibling C still wrote a token-link row';
  end if;

  -- Replaying the still-current B is idempotent and remains legitimate.
  perform public.apply_verified_store_entitlement_with_receipt(
    store_a,
    owner_a,
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    transaction_b,
    'token_' || token_b_hash,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    token_b,
    token_b_hash,
    token_a_hash,
    null
  );

  select subscription.store_product_id
  into current_product
  from public.subscriptions subscription
  where subscription.store_id = store_a;
  select receipt.purchase_token
  into current_receipt
  from private.store_receipt_secrets receipt
  where receipt.platform = 'google_play'
    and receipt.original_transaction_id = original_a;
  if current_product <> 'com.damanak.subscription.growth'
     or current_receipt <> token_b then
    raise exception 'Current-token replay did not preserve B';
  end if;

  resolved_binding := public.resolve_google_purchase_token_binding(token_b);
  if resolved_binding is null
     or resolved_binding ->> 'store_id' <> store_a::text
     or resolved_binding ->> 'user_id' <> owner_a::text
     or resolved_binding ->> 'original_transaction_id' <> original_a then
    raise exception 'Raw expired-token binding did not resolve its lineage';
  end if;
  if public.resolve_google_purchase_token_binding(
    'damanak-live-unknown-' || gen_random_uuid()::text
  ) is not null then
    raise exception 'An unknown raw token resolved to a lineage binding';
  end if;

  -- A delayed replay of ancestor A must not roll the plan or receipt backward.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      store_a,
      owner_a,
      'google_play',
      'com.damanak.subscription.starter',
      'monthly',
      transaction_a,
      original_a,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      token_a,
      token_a_hash,
      null,
      null
    );
    raise exception 'A superseded Google token was accepted';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED' then
      raise;
    end if;
  end;

  -- A refresh worker that claimed A before B was saved must lose the CAS race.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      store_a,
      owner_a,
      'google_play',
      'com.damanak.subscription.growth',
      'monthly',
      transaction_b,
      original_a,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      token_b,
      token_b_hash,
      token_a_hash,
      token_a_hash
    );
    raise exception 'A stale refresh claim overwrote the current receipt';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_RECEIPT_STALE' then
      raise;
    end if;
  end;

  select subscription.store_product_id
  into current_product
  from public.subscriptions subscription
  where subscription.store_id = store_a;
  select receipt.purchase_token
  into current_receipt
  from private.store_receipt_secrets receipt
  where receipt.platform = 'google_play'
    and receipt.original_transaction_id = original_a;
  if current_product <> 'com.damanak.subscription.growth'
     or current_receipt <> token_b then
    raise exception 'A rejected stale write still changed subscription state';
  end if;

  -- The direct subscription pointer cannot reference another tenant's row.
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
    superseded_at
  ) values (
    foreign_entitlement_id,
    store_b,
    owner_b,
    'google_play',
    'com.damanak.subscription.starter',
    'monthly',
    'starter',
    'monthly',
    foreign_original || '-transaction',
    foreign_original,
    'expired',
    'production',
    pg_catalog.now() - interval '31 days',
    pg_catalog.now() - interval '1 day',
    false,
    pg_catalog.now()
  );

  begin
    update public.subscriptions
    set store_entitlement_id = foreign_entitlement_id
    where store_id = store_a;
    raise exception 'A cross-store current entitlement pointer was accepted';
  exception when foreign_key_violation then
    get stacked diagnostics hit_constraint = constraint_name;
    if hit_constraint <> 'subscriptions_current_store_entitlement_fk' then
      raise;
    end if;
  end;

  -- A no-predecessor root remains legitimate after the current purchase has
  -- ended. Once C becomes the independent current lineage, however, replaying
  -- B from the old A lineage must not move the subscription backwards.
  update public.store_entitlements entitlement
  set status = 'expired',
      period_end = pg_catalog.now() - interval '1 second',
      auto_renews = false
  where entitlement.id = (
    select subscription.store_entitlement_id
    from public.subscriptions subscription
    where subscription.store_id = store_a
  );
  update public.subscriptions subscription
  set status = 'canceled',
      current_period_end = pg_catalog.now() - interval '1 second',
      auto_renews = false
  where subscription.store_id = store_a;

  perform public.apply_verified_store_entitlement_with_receipt(
    store_a,
    owner_a,
    'google_play',
    'com.damanak.subscription.scale',
    'monthly',
    transaction_c,
    'token_' || token_c_hash,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    token_c,
    token_c_hash,
    null,
    null
  );

  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      store_a,
      owner_a,
      'google_play',
      'com.damanak.subscription.growth',
      'monthly',
      transaction_b,
      original_a,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      token_b,
      token_b_hash,
      token_a_hash,
      null
    );
    raise exception 'An old known lineage replaced independent current C';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED' then
      raise;
    end if;
  end;

  select subscription.store_product_id
  into current_product
  from public.subscriptions subscription
  where subscription.store_id = store_a;
  select receipt.purchase_token
  into current_receipt
  from private.store_receipt_secrets receipt
  where receipt.platform = 'google_play'
    and receipt.original_transaction_id = 'token_' || token_c_hash;
  if current_product <> 'com.damanak.subscription.scale'
     or current_receipt <> token_c then
    raise exception 'Rejected old-lineage replay did not preserve current C';
  end if;

  if pg_catalog.has_function_privilege(
    'service_role',
    'public.apply_verified_store_entitlement(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean)',
    'EXECUTE'
  ) then
    raise exception 'The receipt-bypassing entitlement RPC is executable';
  end if;
  if not pg_catalog.has_function_privilege(
    'service_role',
    'public.apply_verified_store_entitlement_with_receipt(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean,text,text,text,text)',
    'EXECUTE'
  ) then
    raise exception 'The receipt-aware entitlement RPC is unavailable';
  end if;
  if not pg_catalog.has_function_privilege(
    'service_role',
    'public.resolve_google_purchase_token_binding(text)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'anon',
    'public.resolve_google_purchase_token_binding(text)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'authenticated',
    'public.resolve_google_purchase_token_binding(text)',
    'EXECUTE'
  ) then
    raise exception 'The raw Google token resolver ACL is not service-only';
  end if;
end
$test$;

rollback;

select 'subscription lifecycle integrity passed; transaction rolled back'
  as result;
