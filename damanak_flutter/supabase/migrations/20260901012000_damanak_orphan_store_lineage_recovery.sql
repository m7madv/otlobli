-- Recover a provider-verified Google receipt only after the Edge verifier has
-- explicitly proved that its former account/store binding was deleted. The
-- default path remains unchanged. Linked predecessor adoption is serialized
-- by token-hash advisory locks and both rows are written in one transaction.

drop function if exists public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text, text
);

create function public.apply_verified_store_entitlement_with_receipt(
  target_store_id uuid,
  target_user_id uuid,
  billing_platform text,
  billed_product_id text,
  billed_base_plan_id text,
  external_transaction_id text,
  external_original_transaction_id text,
  entitlement_status text,
  store_environment text,
  entitlement_period_start timestamptz,
  entitlement_period_end timestamptz,
  entitlement_auto_renews boolean,
  raw_purchase_token text,
  purchase_token_hash text,
  linked_purchase_token_hash text,
  expected_current_purchase_token_hash text,
  allow_orphan_lineage_recovery boolean default false,
  orphan_old_account_id uuid default null,
  orphan_old_store_id uuid default null
)
returns public.subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  subscription_row public.subscriptions%rowtype;
  current_link private.google_purchase_token_links%rowtype;
  previous_link private.google_purchase_token_links%rowtype;
  current_receipt_token text;
  resolved_original_transaction_id text :=
    external_original_transaction_id;
  written_hash text;
  current_token_is_known boolean := false;
  previous_token_is_known boolean := false;
  orphan_recovery boolean :=
    coalesce(allow_orphan_lineage_recovery, false);
  current_subscription_id uuid;
  first_token_lock text;
  second_token_lock text;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_store_id::text || ':store-subscription',
      0
    )
  );

  if billing_platform = 'google_play' then
    if char_length(coalesce(raw_purchase_token, '')) < 20
       or purchase_token_hash !~ '^[0-9a-f]{64}$'
       or purchase_token_hash <>
         pg_catalog.encode(
           extensions.digest(raw_purchase_token, 'sha256'),
           'hex'
         )
       or (
         linked_purchase_token_hash is not null
         and linked_purchase_token_hash !~ '^[0-9a-f]{64}$'
       )
       or linked_purchase_token_hash = purchase_token_hash then
      raise exception 'GOOGLE_PURCHASE_TOKEN_REQUIRED';
    end if;

    first_token_lock := least(
      purchase_token_hash,
      coalesce(linked_purchase_token_hash, purchase_token_hash)
    );
    second_token_lock := greatest(
      purchase_token_hash,
      coalesce(linked_purchase_token_hash, purchase_token_hash)
    );
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        'google-purchase-token:' || first_token_lock,
        0
      )
    );
    if second_token_lock <> first_token_lock then
      perform pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(
          'google-purchase-token:' || second_token_lock,
          0
        )
      );
    end if;
  elsif purchase_token_hash is not null
        or linked_purchase_token_hash is not null
        or raw_purchase_token is not null
        or expected_current_purchase_token_hash is not null
        or orphan_recovery
        or orphan_old_account_id is not null
        or orphan_old_store_id is not null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;

  if expected_current_purchase_token_hash is not null then
    if expected_current_purchase_token_hash !~ '^[0-9a-f]{64}$'
       or nullif(
         pg_catalog.btrim(external_original_transaction_id),
         ''
       ) is null then
      raise exception 'STORE_RECEIPT_STALE';
    end if;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        billing_platform || ':' || external_original_transaction_id,
        0
      )
    );
    select receipt.purchase_token
    into current_receipt_token
    from private.store_receipt_secrets receipt
    where receipt.platform = billing_platform
      and receipt.original_transaction_id = external_original_transaction_id
    for update;
    if current_receipt_token is null
       or pg_catalog.encode(
         extensions.digest(current_receipt_token, 'sha256'),
         'hex'
       ) <> expected_current_purchase_token_hash then
      raise exception 'STORE_RECEIPT_STALE';
    end if;
  end if;

  if billing_platform = 'google_play' then
    select *
    into current_link
    from private.google_purchase_token_links token_link
    where token_link.token_hash = purchase_token_hash
    for update;
    current_token_is_known := found;

    if linked_purchase_token_hash is not null then
      select *
      into previous_link
      from private.google_purchase_token_links token_link
      where token_link.token_hash = linked_purchase_token_hash
      for update;
      previous_token_is_known := found;
    end if;

    if orphan_recovery then
      if expected_current_purchase_token_hash is not null
         or orphan_old_account_id is null
         or orphan_old_account_id = target_user_id
         or orphan_old_store_id = target_store_id
         or current_token_is_known
         or previous_token_is_known
         or external_original_transaction_id <>
           'token_' || purchase_token_hash
         or exists (
           select 1
           from auth.users old_user
           where old_user.id = orphan_old_account_id
         )
         or exists (
           select 1
           from public.stores old_store
           where old_store.owner_id = orphan_old_account_id
              or (
                orphan_old_store_id is not null
                and old_store.id = orphan_old_store_id
              )
         )
         or not exists (
           select 1
           from public.stores target_store
           where target_store.id = target_store_id
             and target_store.owner_id = target_user_id
         )
         or (
           select pg_catalog.count(*)
           from public.stores owned_store
           where owned_store.owner_id = target_user_id
         ) <> 1
         or exists (
           select 1
           from public.store_entitlements target_entitlement
           where target_entitlement.store_id = target_store_id
         )
         or exists (
           select 1
           from public.store_entitlements bound_entitlement
           where bound_entitlement.platform = 'google_play'
             and bound_entitlement.original_transaction_id in (
               'token_' || purchase_token_hash,
               'token_' || linked_purchase_token_hash
             )
         ) then
        raise exception 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED';
      end if;
      if linked_purchase_token_hash is not null then
        resolved_original_transaction_id :=
          'token_' || linked_purchase_token_hash;
      end if;
    elsif orphan_old_account_id is not null
          or orphan_old_store_id is not null then
      raise exception 'INVALID_STORE_ENTITLEMENT';
    end if;

    if current_token_is_known and (
      current_link.store_id <> target_store_id
      or current_link.user_id is distinct from target_user_id
    ) then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;

    -- A known token is idempotent only while it remains the saved receipt for
    -- the same current store entitlement.
    if current_token_is_known then
      select subscription.id
      into current_subscription_id
      from public.subscriptions subscription
      join public.store_entitlements entitlement
        on entitlement.id = subscription.store_entitlement_id
       and entitlement.store_id = subscription.store_id
      where subscription.store_id = target_store_id
        and subscription.source = 'store'
        and subscription.billing_provider = billing_platform
        and subscription.original_transaction_id =
          current_link.original_transaction_id
        and entitlement.platform = billing_platform
        and entitlement.original_transaction_id =
          current_link.original_transaction_id
        and entitlement.superseded_at is null
      for update of subscription, entitlement;
      if current_subscription_id is null then
        raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
      end if;

      perform pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(
          billing_platform || ':' ||
            current_link.original_transaction_id,
          0
        )
      );
      select receipt.purchase_token
      into current_receipt_token
      from private.store_receipt_secrets receipt
      where receipt.platform = billing_platform
        and receipt.original_transaction_id =
          current_link.original_transaction_id
      for update;
      if current_receipt_token is null
         or pg_catalog.encode(
           extensions.digest(current_receipt_token, 'sha256'),
           'hex'
         ) <> purchase_token_hash then
        raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
      end if;
    end if;

    if exists (
      select 1
      from private.google_purchase_token_links successor
      where successor.linked_token_hash = purchase_token_hash
        and successor.token_hash <> purchase_token_hash
    ) then
      raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
    end if;

    if linked_purchase_token_hash is not null then
      if orphan_recovery then
        -- Both absent rows are inserted only after the entitlement mutation.
        null;
      else
        if not previous_token_is_known then
          if not current_token_is_known then
            raise exception 'GOOGLE_LINKED_PURCHASE_UNRESOLVED';
          end if;

          written_hash := null;
          insert into private.google_purchase_token_links as existing (
            token_hash,
            store_id,
            user_id,
            original_transaction_id
          ) values (
            linked_purchase_token_hash,
            current_link.store_id,
            current_link.user_id,
            current_link.original_transaction_id
          )
          on conflict (token_hash) do update set
            last_seen_at = pg_catalog.now()
          where existing.store_id = excluded.store_id
            and existing.user_id is not distinct from excluded.user_id
            and existing.original_transaction_id =
              excluded.original_transaction_id
          returning token_hash into written_hash;
          if written_hash is null then
            raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
          end if;

          select *
          into previous_link
          from private.google_purchase_token_links token_link
          where token_link.token_hash = linked_purchase_token_hash
          for update;
          previous_token_is_known := found;
        end if;
        if previous_link.store_id <> target_store_id
           or previous_link.user_id is distinct from target_user_id then
          raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
        end if;

        if not current_token_is_known then
          perform pg_catalog.pg_advisory_xact_lock(
            pg_catalog.hashtextextended(
              billing_platform || ':' ||
                previous_link.original_transaction_id,
              0
            )
          );
          select receipt.purchase_token
          into current_receipt_token
          from private.store_receipt_secrets receipt
          where receipt.platform = billing_platform
            and receipt.original_transaction_id =
              previous_link.original_transaction_id
          for update;
          if current_receipt_token is null
             or pg_catalog.encode(
               extensions.digest(current_receipt_token, 'sha256'),
               'hex'
             ) <> linked_purchase_token_hash then
            raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
          end if;
        end if;

        resolved_original_transaction_id :=
          previous_link.original_transaction_id;
        if current_token_is_known
           and current_link.original_transaction_id <>
             resolved_original_transaction_id then
          raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
        end if;
      end if;
    elsif current_token_is_known then
      resolved_original_transaction_id :=
        current_link.original_transaction_id;
    elsif external_original_transaction_id <>
      'token_' || purchase_token_hash then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;
  end if;

  subscription_row := public.apply_verified_store_entitlement(
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    billed_base_plan_id,
    external_transaction_id,
    resolved_original_transaction_id,
    entitlement_status,
    store_environment,
    entitlement_period_start,
    entitlement_period_end,
    entitlement_auto_renews
  );

  if billing_platform = 'google_play' then
    if orphan_recovery and linked_purchase_token_hash is not null then
      written_hash := null;
      insert into private.google_purchase_token_links as existing (
        token_hash,
        linked_token_hash,
        store_id,
        user_id,
        original_transaction_id
      ) values (
        linked_purchase_token_hash,
        null,
        target_store_id,
        target_user_id,
        resolved_original_transaction_id
      )
      on conflict (token_hash) do nothing
      returning token_hash into written_hash;
      if written_hash is null then
        raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
      end if;
    end if;

    written_hash := null;
    insert into private.google_purchase_token_links as existing (
      token_hash,
      linked_token_hash,
      store_id,
      user_id,
      original_transaction_id
    ) values (
      purchase_token_hash,
      linked_purchase_token_hash,
      target_store_id,
      target_user_id,
      resolved_original_transaction_id
    )
    on conflict (token_hash) do update set
      linked_token_hash = coalesce(
        excluded.linked_token_hash,
        existing.linked_token_hash
      ),
      last_seen_at = pg_catalog.now()
    where existing.store_id = excluded.store_id
      and existing.user_id is not distinct from excluded.user_id
      and existing.original_transaction_id =
        excluded.original_transaction_id
      and (
        existing.linked_token_hash is null
        or excluded.linked_token_hash is null
        or existing.linked_token_hash = excluded.linked_token_hash
      )
    returning token_hash into written_hash;
    if written_hash is null then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;

    insert into private.store_receipt_secrets (
      platform,
      original_transaction_id,
      purchase_token,
      updated_at
    ) values (
      billing_platform,
      resolved_original_transaction_id,
      raw_purchase_token,
      pg_catalog.now()
    )
    on conflict (platform, original_transaction_id) do update set
      purchase_token = excluded.purchase_token,
      updated_at = pg_catalog.now();
  end if;
  return subscription_row;
end;
$$;

revoke all on function public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text, text,
  boolean, uuid, uuid
) from public, anon, authenticated, service_role;
grant execute on function public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text, text,
  boolean, uuid, uuid
) to service_role;
