-- Damanak 4.1: App Store / Google Play subscriptions are the only paid path.
-- Client applications may read entitlements but can never grant them.

alter table public.subscriptions
  add column if not exists billing_provider text,
  add column if not exists store_product_id text,
  add column if not exists billing_cycle text,
  add column if not exists original_transaction_id text,
  add column if not exists auto_renews boolean not null default false,
  add column if not exists last_store_verified_at timestamptz;

alter table public.subscriptions
  drop constraint if exists subscriptions_billing_provider_check;
alter table public.subscriptions
  add constraint subscriptions_billing_provider_check check (
    billing_provider is null or billing_provider in ('app_store', 'google_play')
  );

alter table public.subscriptions
  drop constraint if exists subscriptions_billing_cycle_check;
alter table public.subscriptions
  add constraint subscriptions_billing_cycle_check check (
    billing_cycle is null or billing_cycle in ('monthly', 'yearly')
  );

create table public.store_product_catalog (
  platform text not null check (platform in ('app_store', 'google_play')),
  product_id text not null,
  base_plan_id text not null default '',
  plan_id text not null references public.plans(id),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (platform, product_id, base_plan_id),
  unique (platform, plan_id, billing_cycle)
);

insert into public.store_product_catalog(
  platform, product_id, base_plan_id, plan_id, billing_cycle
) values
  ('app_store', 'com.damanak.subscription.starter.monthly', '', 'starter', 'monthly'),
  ('app_store', 'com.damanak.subscription.starter.yearly', '', 'starter', 'yearly'),
  ('app_store', 'com.damanak.subscription.growth.monthly', '', 'growth', 'monthly'),
  ('app_store', 'com.damanak.subscription.growth.yearly', '', 'growth', 'yearly'),
  ('app_store', 'com.damanak.subscription.scale.monthly', '', 'scale', 'monthly'),
  ('app_store', 'com.damanak.subscription.scale.yearly', '', 'scale', 'yearly'),
  ('google_play', 'com.damanak.subscription.starter', 'monthly', 'starter', 'monthly'),
  ('google_play', 'com.damanak.subscription.starter', 'yearly', 'starter', 'yearly'),
  ('google_play', 'com.damanak.subscription.growth', 'monthly', 'growth', 'monthly'),
  ('google_play', 'com.damanak.subscription.growth', 'yearly', 'growth', 'yearly'),
  ('google_play', 'com.damanak.subscription.scale', 'monthly', 'scale', 'monthly'),
  ('google_play', 'com.damanak.subscription.scale', 'yearly', 'scale', 'yearly')
on conflict (platform, product_id, base_plan_id) do update set
  plan_id = excluded.plan_id,
  billing_cycle = excluded.billing_cycle,
  is_active = true,
  updated_at = now();

create table public.store_entitlements (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete restrict,
  platform text not null check (platform in ('app_store', 'google_play')),
  product_id text not null,
  base_plan_id text not null default '',
  plan_id text not null references public.plans(id),
  billing_cycle text not null check (billing_cycle in ('monthly', 'yearly')),
  transaction_id text not null,
  original_transaction_id text not null,
  status text not null check (
    status in ('active', 'grace', 'past_due', 'canceled', 'expired', 'revoked')
  ),
  environment text not null check (environment in ('sandbox', 'production')),
  period_start timestamptz,
  period_end timestamptz,
  auto_renews boolean not null default false,
  verified_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (platform, original_transaction_id),
  unique (platform, transaction_id)
);

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table private.store_receipt_secrets (
  platform text not null check (platform in ('app_store', 'google_play')),
  original_transaction_id text not null,
  purchase_token text not null,
  updated_at timestamptz not null default now(),
  primary key (platform, original_transaction_id)
);

revoke all on table private.store_receipt_secrets
  from public, anon, authenticated;

create index store_entitlements_store_status_idx
  on public.store_entitlements(store_id, status, period_end desc);

create trigger store_product_catalog_updated_at
before update on public.store_product_catalog
for each row execute function public.set_updated_at();

create trigger store_entitlements_updated_at
before update on public.store_entitlements
for each row execute function public.set_updated_at();

alter table public.store_product_catalog enable row level security;
alter table public.store_entitlements enable row level security;

create policy store_product_catalog_read
on public.store_product_catalog for select to authenticated
using (is_active);

create policy store_entitlements_read_members
on public.store_entitlements for select to authenticated
using (public.is_store_member(store_id));

revoke all on table public.store_product_catalog from anon, authenticated;
revoke all on table public.store_entitlements from anon, authenticated;
grant select on table public.store_product_catalog to authenticated;
grant select on table public.store_entitlements to authenticated;

-- Disable the legacy manual activation paths. Existing historical rows remain
-- for audit purposes, but new paid access can only be granted by verified
-- receipts through the service-role-only function below.
update public.activation_codes set is_active = false where is_active;
update public.subscription_requests
set status = 'rejected', updated_at = now()
where status in ('pending', 'contacted');

drop policy if exists subscription_requests_insert_owner
  on public.subscription_requests;
revoke insert on table public.subscription_requests from authenticated;
revoke execute on function public.redeem_subscription_code(uuid, text)
  from authenticated;

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
set search_path = public, extensions
as $$
declare
  catalog_row public.store_product_catalog%rowtype;
  linked_store_id uuid;
  subscription_row public.subscriptions%rowtype;
  normalized_status text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  if billing_platform not in ('app_store', 'google_play')
     or entitlement_status not in (
       'active', 'grace', 'past_due', 'canceled', 'expired', 'revoked'
     )
     or store_environment not in ('sandbox', 'production') then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;

  if not exists (
    select 1 from public.store_members
    where store_id = target_store_id
      and user_id = target_user_id
      and role = 'owner'
      and status = 'active'
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  select * into catalog_row
  from public.store_product_catalog
  where platform = billing_platform
    and product_id = billed_product_id
    and base_plan_id = coalesce(billed_base_plan_id, '')
    and is_active
  for share;

  if not found then
    raise exception 'STORE_PRODUCT_UNMAPPED';
  end if;

  select store_id into linked_store_id
  from public.store_entitlements
  where platform = billing_platform
    and original_transaction_id = external_original_transaction_id;

  if linked_store_id is not null and linked_store_id <> target_store_id then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  insert into public.store_entitlements(
    store_id, user_id, platform, product_id, base_plan_id, plan_id,
    billing_cycle, transaction_id, original_transaction_id, status,
    environment, period_start, period_end, auto_renews, verified_at
  ) values (
    target_store_id, target_user_id, billing_platform, billed_product_id,
    coalesce(billed_base_plan_id, ''), catalog_row.plan_id,
    catalog_row.billing_cycle, external_transaction_id,
    external_original_transaction_id, entitlement_status, store_environment,
    entitlement_period_start, entitlement_period_end,
    entitlement_auto_renews, now()
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
    verified_at = now(),
    updated_at = now();

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
      current_period_end = entitlement_period_end,
      source = 'store',
      billing_provider = billing_platform,
      store_product_id = billed_product_id,
      billing_cycle = catalog_row.billing_cycle,
      original_transaction_id = external_original_transaction_id,
      auto_renews = entitlement_auto_renews,
      last_store_verified_at = now(),
      updated_at = now()
  where store_id = target_store_id
  returning * into subscription_row;

  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  ) values (
    target_store_id,
    target_user_id,
    'store_subscription_verified',
    'subscription',
    subscription_row.id,
    jsonb_build_object(
      'platform', billing_platform,
      'product_id', billed_product_id,
      'billing_cycle', catalog_row.billing_cycle,
      'status', entitlement_status,
      'environment', store_environment
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

create or replace function public.save_store_receipt_secret(
  billing_platform text,
  external_original_transaction_id text,
  raw_purchase_token text
)
returns void
language plpgsql
security definer
set search_path = public, private
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if billing_platform <> 'google_play'
     or char_length(raw_purchase_token) < 20
     or not exists (
       select 1 from public.store_entitlements
       where platform = billing_platform
         and original_transaction_id = external_original_transaction_id
     ) then
    raise exception 'INVALID_STORE_RECEIPT_SECRET';
  end if;

  insert into private.store_receipt_secrets(
    platform, original_transaction_id, purchase_token, updated_at
  ) values (
    billing_platform, external_original_transaction_id,
    raw_purchase_token, now()
  )
  on conflict (platform, original_transaction_id) do update set
    purchase_token = excluded.purchase_token,
    updated_at = now();
end;
$$;

create or replace function public.get_store_receipt_secret(
  billing_platform text,
  external_original_transaction_id text
)
returns text
language plpgsql
security definer
set search_path = public, private
as $$
declare
  receipt_secret text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  select purchase_token into receipt_secret
  from private.store_receipt_secrets
  where platform = billing_platform
    and original_transaction_id = external_original_transaction_id;
  return receipt_secret;
end;
$$;

revoke all on function public.save_store_receipt_secret(text, text, text)
  from public, anon, authenticated;
revoke all on function public.get_store_receipt_secret(text, text)
  from public, anon, authenticated;
grant execute on function public.save_store_receipt_secret(text, text, text)
  to service_role;
grant execute on function public.get_store_receipt_secret(text, text)
  to service_role;
