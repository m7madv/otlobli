-- Live regression contract for migration 20260901012000.
-- Run only after the migration is applied to the selected database:
--   supabase db query --linked --file supabase/tests/orphan_store_lineage_recovery_live.sql
-- Synthetic identities and every dependent row are always rolled back.

begin;
set local statement_timeout = '30s';
set local lock_timeout = '5s';

alter table public.subscriptions disable trigger user;
alter table public.store_entitlements disable trigger user;

do $test$
declare
  direct_owner uuid := extensions.gen_random_uuid();
  linked_owner uuid := extensions.gen_random_uuid();
  competing_owner uuid := extensions.gen_random_uuid();
  live_old_user uuid := extensions.gen_random_uuid();
  live_old_owner uuid := extensions.gen_random_uuid();
  direct_store uuid := extensions.gen_random_uuid();
  linked_store uuid := extensions.gen_random_uuid();
  competing_store uuid := extensions.gen_random_uuid();
  live_old_store uuid := extensions.gen_random_uuid();
  deleted_direct_account uuid := extensions.gen_random_uuid();
  deleted_linked_account uuid := extensions.gen_random_uuid();
  deleted_linked_store uuid := extensions.gen_random_uuid();
  absent_old_account uuid := extensions.gen_random_uuid();
  direct_token text := 'damanak-orphan-direct-' || extensions.gen_random_uuid()::text;
  linked_previous_token text :=
    'damanak-orphan-previous-' || extensions.gen_random_uuid()::text;
  linked_current_token text :=
    'damanak-orphan-current-' || extensions.gen_random_uuid()::text;
  default_guard_previous_token text :=
    'damanak-default-previous-' || extensions.gen_random_uuid()::text;
  default_guard_current_token text :=
    'damanak-default-current-' || extensions.gen_random_uuid()::text;
  live_user_token text :=
    'damanak-live-user-' || extensions.gen_random_uuid()::text;
  live_store_token text :=
    'damanak-live-store-' || extensions.gen_random_uuid()::text;
  known_predecessor_current_token text :=
    'damanak-known-predecessor-' || extensions.gen_random_uuid()::text;
  entitled_target_token text :=
    'damanak-entitled-target-' || extensions.gen_random_uuid()::text;
  direct_hash text;
  linked_previous_hash text;
  linked_current_hash text;
  default_guard_previous_hash text;
  default_guard_current_hash text;
  live_user_hash text;
  live_store_hash text;
  known_predecessor_current_hash text;
  entitled_target_hash text;
  linked_original text;
  hit_message text;
  row_count integer;
  current_receipt text;
begin
  perform pg_catalog.set_config(
    'request.jwt.claim.role',
    'service_role',
    true
  );
  if auth.role() <> 'service_role' then
    raise exception 'The orphan recovery test could not assume service_role';
  end if;

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
      direct_owner,
      'authenticated',
      'authenticated',
      'orphan-direct-' || direct_owner::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      linked_owner,
      'authenticated',
      'authenticated',
      'orphan-linked-' || linked_owner::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      competing_owner,
      'authenticated',
      'authenticated',
      'orphan-competing-' || competing_owner::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      live_old_user,
      'authenticated',
      'authenticated',
      'orphan-live-user-' || live_old_user::text || '@example.invalid',
      '',
      pg_catalog.now(),
      '{}'::jsonb,
      '{}'::jsonb,
      pg_catalog.now(),
      pg_catalog.now()
    ),
    (
      live_old_owner,
      'authenticated',
      'authenticated',
      'orphan-live-old-' || live_old_owner::text || '@example.invalid',
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
    owner_id,
    country_code,
    currency_code
  ) values
    (direct_store, 'متجر استرجاع مباشر', direct_owner, 'QA', 'QAR'),
    (linked_store, 'متجر استرجاع مترابط', linked_owner, 'QA', 'QAR'),
    (competing_store, 'متجر مطالبة منافسة', competing_owner, 'QA', 'QAR'),
    (live_old_store, 'متجر قديم حي', live_old_owner, 'QA', 'QAR');

  insert into public.store_members (store_id, user_id, role, status)
  values
    (direct_store, direct_owner, 'owner', 'active'),
    (linked_store, linked_owner, 'owner', 'active'),
    (competing_store, competing_owner, 'owner', 'active'),
    (live_old_store, live_old_owner, 'owner', 'active');

  -- Real stores always have a subscription row before provider verification.
  -- These synthetic stores start with an ended trial and no entitlement.
  insert into public.subscriptions (
    store_id,
    plan_id,
    status,
    source,
    auto_renews
  ) values
    (direct_store, 'starter', 'canceled', 'trial', false),
    (linked_store, 'starter', 'canceled', 'trial', false),
    (competing_store, 'starter', 'canceled', 'trial', false);

  direct_hash := pg_catalog.encode(
    extensions.digest(direct_token, 'sha256'),
    'hex'
  );
  linked_previous_hash := pg_catalog.encode(
    extensions.digest(linked_previous_token, 'sha256'),
    'hex'
  );
  linked_current_hash := pg_catalog.encode(
    extensions.digest(linked_current_token, 'sha256'),
    'hex'
  );
  default_guard_previous_hash := pg_catalog.encode(
    extensions.digest(default_guard_previous_token, 'sha256'),
    'hex'
  );
  default_guard_current_hash := pg_catalog.encode(
    extensions.digest(default_guard_current_token, 'sha256'),
    'hex'
  );
  live_user_hash := pg_catalog.encode(
    extensions.digest(live_user_token, 'sha256'),
    'hex'
  );
  live_store_hash := pg_catalog.encode(
    extensions.digest(live_store_token, 'sha256'),
    'hex'
  );
  known_predecessor_current_hash := pg_catalog.encode(
    extensions.digest(known_predecessor_current_token, 'sha256'),
    'hex'
  );
  entitled_target_hash := pg_catalog.encode(
    extensions.digest(entitled_target_token, 'sha256'),
    'hex'
  );

  -- The old 16-argument path cannot adopt an unknown predecessor.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      competing_store,
      competing_owner,
      'google_play',
      'com.damanak.subscription.starter',
      'monthly',
      'DMN-ORPHAN-DEFAULT-' || extensions.gen_random_uuid()::text,
      'token_' || default_guard_current_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      default_guard_current_token,
      default_guard_current_hash,
      default_guard_previous_hash,
      null
    );
    raise exception 'Default RPC path adopted an unknown predecessor';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'GOOGLE_LINKED_PURCHASE_UNRESOLVED' then
      raise;
    end if;
  end;

  -- Build 23 account-only recovery succeeds only for a deleted account and a
  -- sole, unentitled target store.
  perform public.apply_verified_store_entitlement_with_receipt(
    direct_store,
    direct_owner,
    'google_play',
    'com.damanak.subscription.starter',
    'monthly',
    'DMN-ORPHAN-DIRECT-' || extensions.gen_random_uuid()::text,
    'token_' || direct_hash,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    direct_token,
    direct_hash,
    null,
    null,
    true,
    deleted_direct_account,
    null
  );

  if not exists (
    select 1
    from private.google_purchase_token_links token_link
    where token_link.token_hash = direct_hash
      and token_link.store_id = direct_store
      and token_link.user_id = direct_owner
      and token_link.original_transaction_id = 'token_' || direct_hash
  ) then
    raise exception 'Direct orphan recovery did not bind its current token';
  end if;

  -- A linked replacement/out-of-app recovery derives the durable lineage from
  -- the verified predecessor and inserts both missing rows atomically.
  perform public.apply_verified_store_entitlement_with_receipt(
    linked_store,
    linked_owner,
    'google_play',
    'com.damanak.subscription.growth',
    'monthly',
    'DMN-ORPHAN-LINKED-' || extensions.gen_random_uuid()::text,
    'token_' || linked_current_hash,
    'active',
    'production',
    pg_catalog.now(),
    pg_catalog.now() + interval '30 days',
    true,
    linked_current_token,
    linked_current_hash,
    linked_previous_hash,
    null,
    true,
    deleted_linked_account,
    deleted_linked_store
  );
  linked_original := 'token_' || linked_previous_hash;

  select pg_catalog.count(*)
  into row_count
  from private.google_purchase_token_links token_link
  where token_link.token_hash in (
      linked_previous_hash,
      linked_current_hash
    )
    and token_link.store_id = linked_store
    and token_link.user_id = linked_owner
    and token_link.original_transaction_id = linked_original;
  if row_count <> 2 then
    raise exception 'Linked orphan recovery did not bind both token rows';
  end if;
  if not exists (
    select 1
    from private.google_purchase_token_links token_link
    where token_link.token_hash = linked_current_hash
      and token_link.linked_token_hash = linked_previous_hash
  ) then
    raise exception 'Linked orphan recovery lost its predecessor edge';
  end if;
  select receipt.purchase_token
  into current_receipt
  from private.store_receipt_secrets receipt
  where receipt.platform = 'google_play'
    and receipt.original_transaction_id = linked_original;
  if current_receipt <> linked_current_token then
    raise exception 'Linked orphan recovery saved the wrong current receipt';
  end if;

  -- A live old account cannot be claimed.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      competing_store,
      competing_owner,
      'google_play',
      'com.damanak.subscription.starter',
      'monthly',
      'DMN-ORPHAN-LIVE-USER-' || extensions.gen_random_uuid()::text,
      'token_' || live_user_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      live_user_token,
      live_user_hash,
      null,
      null,
      true,
      live_old_user,
      null
    );
    raise exception 'A live old account was claimed';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED' then
      raise;
    end if;
  end;

  -- A surviving old store also blocks recovery even if the supplied old
  -- account UUID itself no longer exists.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      competing_store,
      competing_owner,
      'google_play',
      'com.damanak.subscription.starter',
      'monthly',
      'DMN-ORPHAN-LIVE-STORE-' || extensions.gen_random_uuid()::text,
      'token_' || live_store_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      live_store_token,
      live_store_hash,
      null,
      null,
      true,
      absent_old_account,
      live_old_store
    );
    raise exception 'A surviving old store was claimed';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED' then
      raise;
    end if;
  end;

  -- A second target cannot claim an already-bound current token.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      competing_store,
      competing_owner,
      'google_play',
      'com.damanak.subscription.starter',
      'monthly',
      'DMN-ORPHAN-KNOWN-CURRENT-' || extensions.gen_random_uuid()::text,
      'token_' || direct_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      direct_token,
      direct_hash,
      null,
      null,
      true,
      extensions.gen_random_uuid(),
      null
    );
    raise exception 'A competing target claimed an existing current token';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED' then
      raise;
    end if;
  end;

  -- Nor can a new current token claim an already-bound predecessor.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      competing_store,
      competing_owner,
      'google_play',
      'com.damanak.subscription.growth',
      'monthly',
      'DMN-ORPHAN-KNOWN-PREVIOUS-' || extensions.gen_random_uuid()::text,
      'token_' || known_predecessor_current_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      known_predecessor_current_token,
      known_predecessor_current_hash,
      linked_previous_hash,
      null,
      true,
      extensions.gen_random_uuid(),
      null
    );
    raise exception 'A competing target claimed an existing predecessor';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED' then
      raise;
    end if;
  end;

  -- Recovery cannot overwrite a target that already has any entitlement.
  begin
    perform public.apply_verified_store_entitlement_with_receipt(
      direct_store,
      direct_owner,
      'google_play',
      'com.damanak.subscription.scale',
      'monthly',
      'DMN-ORPHAN-ENTITLED-' || extensions.gen_random_uuid()::text,
      'token_' || entitled_target_hash,
      'active',
      'production',
      pg_catalog.now(),
      pg_catalog.now() + interval '30 days',
      true,
      entitled_target_token,
      entitled_target_hash,
      null,
      null,
      true,
      extensions.gen_random_uuid(),
      null
    );
    raise exception 'Recovery overwrote an entitled target store';
  exception when others then
    get stacked diagnostics hit_message = message_text;
    if hit_message <> 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED' then
      raise;
    end if;
  end;

  -- Every rejected subtransaction must remain atomic.
  select pg_catalog.count(*)
  into row_count
  from private.google_purchase_token_links token_link
  where token_link.token_hash in (
    default_guard_current_hash,
    live_user_hash,
    live_store_hash,
    known_predecessor_current_hash,
    entitled_target_hash
  );
  if row_count <> 0 then
    raise exception 'A rejected recovery wrote a token-link row';
  end if;
  if exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.store_id = competing_store
  ) then
    raise exception 'A rejected recovery wrote a target entitlement';
  end if;

  if not pg_catalog.has_function_privilege(
    'service_role',
    'public.apply_verified_store_entitlement_with_receipt(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean,text,text,text,text,boolean,uuid,uuid)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'anon',
    'public.apply_verified_store_entitlement_with_receipt(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean,text,text,text,text,boolean,uuid,uuid)',
    'EXECUTE'
  ) or pg_catalog.has_function_privilege(
    'authenticated',
    'public.apply_verified_store_entitlement_with_receipt(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean,text,text,text,text,boolean,uuid,uuid)',
    'EXECUTE'
  ) then
    raise exception 'The orphan recovery RPC ACL is not service-only';
  end if;
end
$test$;

rollback;

select 'orphan store lineage recovery passed; transaction rolled back'
  as result;
