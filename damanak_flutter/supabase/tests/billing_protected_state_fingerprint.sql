-- Read-only deployment guard for billing migrations.
-- Run immediately before and after deployment and compare every fingerprint.
with categories(category) as (
  values
    ('apple_production_entitlements'::text),
    ('apple_production_subscriptions'::text),
    ('google_entitlements'::text),
    ('google_subscriptions'::text),
    ('google_purchase_token_links'::text),
    ('purchase_limits'::text),
    ('receipt_secrets'::text),
    ('refresh_limits'::text)
),
state as (
  select
    'apple_production_entitlements'::text as category,
    entitlement.id::text as row_key,
    pg_catalog.to_jsonb(entitlement) as payload
  from public.store_entitlements entitlement
  where entitlement.platform = 'app_store'
    and entitlement.environment = 'production'

  union all

  select
    'apple_production_subscriptions',
    subscription.id::text,
    pg_catalog.to_jsonb(subscription)
  from public.subscriptions subscription
  where subscription.source = 'store'
    and subscription.billing_provider = 'app_store'
    and subscription.store_environment = 'production'

  union all

  select
    'google_entitlements',
    entitlement.id::text,
    pg_catalog.to_jsonb(entitlement)
  from public.store_entitlements entitlement
  where entitlement.platform = 'google_play'

  union all

  select
    'google_subscriptions',
    subscription.id::text,
    pg_catalog.to_jsonb(subscription)
  from public.subscriptions subscription
  where subscription.source = 'store'
    and subscription.billing_provider = 'google_play'

  union all

  select
    'google_purchase_token_links',
    links.token_hash,
    pg_catalog.to_jsonb(links)
  from private.google_purchase_token_links links

  union all

  select
    'purchase_limits',
    limits.user_id::text || '|' || limits.store_id::text,
    pg_catalog.to_jsonb(limits)
  from private.store_purchase_verification_limits limits

  union all

  select
    'receipt_secrets',
    receipt.platform || '|' || receipt.original_transaction_id,
    pg_catalog.to_jsonb(receipt)
  from private.store_receipt_secrets receipt

  union all

  select
    'refresh_limits',
    limits.user_id::text || '|' || limits.store_id::text,
    pg_catalog.to_jsonb(limits)
  from private.store_subscription_refresh_limits limits
),
fingerprints as (
  select
    categories.category,
    pg_catalog.count(state.row_key) as row_count,
    pg_catalog.encode(
      extensions.digest(
        coalesce(
          pg_catalog.string_agg(
            state.row_key || '|' || state.payload::text,
            E'\n' order by state.row_key
          ),
          ''
        ),
        'sha256'
      ),
      'hex'
    ) as sha256
  from categories
  left join state using (category)
  group by categories.category
),
metrics as (
  select
    'apple_sandbox_entitlements'::text as metric,
    pg_catalog.count(*)::bigint as value
  from public.store_entitlements
  where platform = 'app_store'
    and environment = 'sandbox'

  union all

  select
    'apple_sandbox_terminal_tombstones',
    pg_catalog.count(*)
  from public.store_entitlements
  where platform = 'app_store'
    and environment = 'sandbox'
    and status in ('canceled', 'expired', 'revoked')
    and not auto_renews

  union all

  select
    'trial_or_apple_sandbox_subscriptions',
    pg_catalog.count(*)
  from public.subscriptions
  where source = 'trial'
     or (
       source = 'store'
       and store_environment = 'sandbox'
       and billing_provider = 'app_store'
     )

  union all

  select
    'manual_activation_inconsistent_rows',
    pg_catalog.count(*)
  from public.subscriptions
  where source in ('manual', 'activation_code')
    and (
      billing_provider is not null
      or store_product_id is not null
      or billing_cycle is not null
      or original_transaction_id is not null
      or auto_renews
      or last_store_verified_at is not null
      or store_environment is not null
      or store_entitlement_id is not null
    )
)
select
  'fingerprint' as kind,
  category as name,
  row_count as value,
  sha256 as detail
from fingerprints

union all

select
  'metric',
  metric,
  value,
  null
from metrics
order by kind, name;
