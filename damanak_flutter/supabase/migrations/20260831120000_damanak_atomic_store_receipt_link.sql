-- Store receipts are tenant-bound assets. Serialize every original purchase
-- before it can affect a subscription, and keep sandbox grants behind a
-- short-lived, server-managed allowlist.

create table if not exists private.store_sandbox_testers (
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('app_store', 'google_play')),
  expires_at timestamptz not null,
  created_at timestamptz not null default pg_catalog.now(),
  note text not null default '',
  primary key (store_id, user_id, platform),
  check (expires_at > created_at and expires_at <= created_at + interval '24 hours')
);

revoke all on table private.store_sandbox_testers
  from public, anon, authenticated;

alter table public.subscriptions
  add column if not exists store_environment text;

alter table public.subscriptions
  drop constraint if exists subscriptions_store_environment_check;
alter table public.subscriptions
  add constraint subscriptions_store_environment_check check (
    store_environment is null
    or store_environment in ('sandbox', 'production')
  );

update public.subscriptions subscription
set store_environment = entitlement.environment
from public.store_entitlements entitlement
where subscription.store_id = entitlement.store_id
  and subscription.billing_provider = entitlement.platform
  and subscription.original_transaction_id = entitlement.original_transaction_id
  and subscription.store_environment is null;

do $$
begin
  if exists (
    select 1
    from public.subscriptions
    where source = 'store'
      and (
        billing_provider is null
        or original_transaction_id is null
        or store_environment is null
        or current_period_end is null
      )
  ) then
    raise exception 'DAMANAK_INCOMPLETE_STORE_SUBSCRIPTION';
  end if;
  if exists (
    select billing_provider, original_transaction_id
    from public.subscriptions
    where source = 'store'
    group by billing_provider, original_transaction_id
    having count(*) > 1
  ) then
    raise exception 'DAMANAK_DUPLICATE_STORE_SUBSCRIPTION';
  end if;
end;
$$;

create unique index if not exists subscriptions_store_receipt_unique
  on public.subscriptions(billing_provider, original_transaction_id)
  where source = 'store';

alter table public.subscriptions
  drop constraint if exists subscriptions_store_receipt_complete_check;
alter table public.subscriptions
  add constraint subscriptions_store_receipt_complete_check check (
    source <> 'store'
    or (
      billing_provider is not null
      and original_transaction_id is not null
      and store_environment is not null
      and current_period_end is not null
    )
  );

alter table public.store_entitlements
  drop constraint if exists store_entitlements_store_link_unique;
alter table public.store_entitlements
  add constraint store_entitlements_store_link_unique unique (
    store_id, platform, original_transaction_id, environment
  );

alter table public.subscriptions
  drop constraint if exists subscriptions_store_entitlement_fk;
alter table public.subscriptions
  add constraint subscriptions_store_entitlement_fk foreign key (
    store_id, billing_provider, original_transaction_id, store_environment
  ) references public.store_entitlements(
    store_id, platform, original_transaction_id, environment
  ) deferrable initially deferred;

create or replace function public.subscription_is_usable(target_store_id uuid)
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
      and (
        (
          subscription.status = 'trialing'
          and subscription.trial_ends_at > pg_catalog.now()
        )
        or
        (
          subscription.status = 'active'
          and (
            (
              subscription.source = 'store'
              and subscription.current_period_end > pg_catalog.now()
            )
            or
            (
              subscription.source <> 'store'
              and (
                subscription.current_period_end is null
                or subscription.current_period_end > pg_catalog.now()
              )
            )
          )
        )
      )
  )
$$;

create or replace function public.store_plan_allows(
  target_store_id uuid,
  entitlement_name text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((
    select case entitlement_name
      when 'api' then plan.api_access
      when 'webhook' then plan.webhook_access
      when 'branding' then plan.custom_branding
      else false
    end
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id
      and public.subscription_is_usable(target_store_id)
    limit 1
  ), false)
$$;

create or replace function public.apply_verified_store_entitlement(
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
  entitlement_auto_renews boolean
)
returns public.subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  catalog_row public.store_product_catalog%rowtype;
  linked_store_id uuid;
  linked_user_id uuid;
  linked_environment text;
  current_subscription_environment text;
  verified_environment text := store_environment;
  sandbox_expires_at timestamptz;
  effective_period_end timestamptz := entitlement_period_end;
  written_store_id uuid;
  subscription_row public.subscriptions%rowtype;
  normalized_status text;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if billing_platform not in ('app_store', 'google_play')
     or entitlement_status not in (
       'active', 'grace', 'past_due', 'canceled', 'expired', 'revoked'
     )
     or verified_environment not in ('sandbox', 'production')
     or nullif(pg_catalog.btrim(external_transaction_id), '') is null
     or nullif(pg_catalog.btrim(external_original_transaction_id), '') is null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
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

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      billing_platform || ':' || external_original_transaction_id,
      0
    )
  );

  select entitlement.store_id, entitlement.user_id, entitlement.environment
  into linked_store_id, linked_user_id, linked_environment
  from public.store_entitlements entitlement
  where entitlement.platform = billing_platform
    and entitlement.original_transaction_id = external_original_transaction_id;

  if linked_store_id is not null and (
    linked_store_id <> target_store_id or linked_user_id <> target_user_id
  ) then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;
  if verified_environment = 'sandbox' and linked_environment = 'production' then
    raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
  end if;

  select subscription.store_environment
  into current_subscription_environment
  from public.subscriptions subscription
  where subscription.store_id = target_store_id
  for update;

  if verified_environment = 'sandbox' then
    if current_subscription_environment = 'production' then
      raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
    end if;
    select tester.expires_at
    into sandbox_expires_at
    from private.store_sandbox_testers tester
    where tester.store_id = target_store_id
      and tester.user_id = target_user_id
      and tester.platform = billing_platform
      and tester.expires_at > pg_catalog.now()
    for share;
    if sandbox_expires_at is null then
      raise exception 'SANDBOX_TESTER_NOT_ALLOWED';
    end if;
    if effective_period_end is null then
      effective_period_end := sandbox_expires_at;
    else
      effective_period_end := least(effective_period_end, sandbox_expires_at);
    end if;
  end if;

  if entitlement_status in ('active', 'grace') and (
    effective_period_end is null or effective_period_end <= pg_catalog.now()
  ) then
    raise exception 'STORE_ACTIVE_PERIOD_INVALID';
  end if;

  select * into catalog_row
  from public.store_product_catalog catalog
  where catalog.platform = billing_platform
    and catalog.product_id = billed_product_id
    and catalog.base_plan_id = coalesce(billed_base_plan_id, '')
    and catalog.is_active
  for share;
  if not found then
    raise exception 'STORE_PRODUCT_UNMAPPED';
  end if;

  insert into public.store_entitlements as current_entitlement (
    store_id, user_id, platform, product_id, base_plan_id, plan_id,
    billing_cycle, transaction_id, original_transaction_id, status,
    environment, period_start, period_end, auto_renews, verified_at
  ) values (
    target_store_id, target_user_id, billing_platform, billed_product_id,
    coalesce(billed_base_plan_id, ''), catalog_row.plan_id,
    catalog_row.billing_cycle, external_transaction_id,
    external_original_transaction_id, entitlement_status, verified_environment,
    entitlement_period_start, effective_period_end,
    entitlement_auto_renews, pg_catalog.now()
  )
  on conflict (platform, original_transaction_id) do update set
    user_id = excluded.user_id,
    product_id = excluded.product_id,
    base_plan_id = excluded.base_plan_id,
    plan_id = excluded.plan_id,
    billing_cycle = excluded.billing_cycle,
    transaction_id = excluded.transaction_id,
    status = excluded.status,
    environment = excluded.environment,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    auto_renews = excluded.auto_renews,
    verified_at = pg_catalog.now(),
    updated_at = pg_catalog.now()
  where current_entitlement.store_id = excluded.store_id
    and current_entitlement.user_id = excluded.user_id
    and not (
      current_entitlement.environment = 'production'
      and excluded.environment = 'sandbox'
    )
  returning store_id into written_store_id;

  if written_store_id is null then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  normalized_status := case
    when entitlement_status in ('active', 'grace') then 'active'
    when entitlement_status = 'past_due' then 'past_due'
    else 'canceled'
  end;

  update public.subscriptions
  set plan_id = catalog_row.plan_id,
      status = normalized_status,
      trial_ends_at = null,
      current_period_start = entitlement_period_start,
      current_period_end = effective_period_end,
      source = 'store',
      billing_provider = billing_platform,
      store_product_id = billed_product_id,
      billing_cycle = catalog_row.billing_cycle,
      original_transaction_id = external_original_transaction_id,
    store_environment = verified_environment,
      auto_renews = entitlement_auto_renews,
      last_store_verified_at = pg_catalog.now(),
      updated_at = pg_catalog.now()
  where store_id = target_store_id
  returning * into subscription_row;

  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  insert into public.audit_logs (
    store_id, user_id, action, entity_type, entity_id, metadata
  ) values (
    target_store_id,
    target_user_id,
    'store_subscription_verified',
    'subscription',
    subscription_row.id,
    pg_catalog.jsonb_build_object(
      'platform', billing_platform,
      'product_id', billed_product_id,
      'billing_cycle', catalog_row.billing_cycle,
      'status', entitlement_status,
      'environment', verified_environment,
      'effective_period_end', effective_period_end
    )
  );

  return subscription_row;
end;
$$;

revoke all on function public.apply_verified_store_entitlement(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean
) from public, anon, authenticated;
grant execute on function public.apply_verified_store_entitlement(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean
) to service_role;

create or replace function public.apply_verified_store_entitlement_with_receipt(
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
  raw_purchase_token text
)
returns public.subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  subscription_row public.subscriptions%rowtype;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  subscription_row := public.apply_verified_store_entitlement(
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    billed_base_plan_id,
    external_transaction_id,
    external_original_transaction_id,
    entitlement_status,
    store_environment,
    entitlement_period_start,
    entitlement_period_end,
    entitlement_auto_renews
  );

  if billing_platform = 'google_play' then
    if char_length(coalesce(raw_purchase_token, '')) < 20 then
      raise exception 'GOOGLE_PURCHASE_TOKEN_REQUIRED';
    end if;
    insert into private.store_receipt_secrets (
      platform, original_transaction_id, purchase_token, updated_at
    ) values (
      billing_platform,
      external_original_transaction_id,
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
  timestamptz, timestamptz, boolean, text
) from public, anon, authenticated;
grant execute on function public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text
) to service_role;

do $$
begin
  if exists (
    select 1
    from information_schema.routine_privileges privilege
    where privilege.specific_schema = 'public'
      and privilege.grantee in ('anon', 'authenticated')
      and privilege.privilege_type = 'EXECUTE'
      and privilege.routine_name in (
        'apply_verified_store_entitlement',
        'apply_verified_store_entitlement_with_receipt'
      )
  ) then
    raise exception 'DAMANAK_STORE_RECEIPT_EXECUTE_EXPOSED';
  end if;
end;
$$;
