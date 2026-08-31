-- Make the store subscription lifecycle single-current, tenant-bound, and
-- auditable. This migration deliberately creates no sandbox review window;
-- an operator must open a short window explicitly for a review submission.

alter table public.store_entitlements
  add column if not exists superseded_at timestamptz,
  add column if not exists superseded_by uuid;

-- Terminal purchase history stays attached to the store, not forever to the
-- deleted auth identity. If ownership survives account deletion, the current
-- internal entitlement is ended before the former purchaser is anonymized.
alter table public.store_entitlements
  drop constraint if exists store_entitlements_user_id_fkey;
alter table public.store_entitlements
  alter column user_id drop not null;
alter table public.store_entitlements
  add constraint store_entitlements_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

alter table public.store_entitlements
  drop constraint if exists store_entitlements_superseded_by_fk;
alter table public.store_entitlements
  add constraint store_entitlements_superseded_by_fk
  foreign key (superseded_by)
  references public.store_entitlements(id)
  on delete set null;

alter table public.store_entitlements
  drop constraint if exists store_entitlements_superseded_state_check;
alter table public.store_entitlements
  add constraint store_entitlements_superseded_state_check check (
    (superseded_at is null and superseded_by is null)
    or superseded_at is not null
  );

alter table public.subscriptions
  add column if not exists store_entitlement_id uuid;

update public.subscriptions subscription
set store_entitlement_id = entitlement.id
from public.store_entitlements entitlement
where subscription.source = 'store'
  and subscription.store_entitlement_id is null
  and entitlement.store_id = subscription.store_id
  and entitlement.platform = subscription.billing_provider
  and entitlement.original_transaction_id =
    subscription.original_transaction_id
  and entitlement.environment = subscription.store_environment;

do $$
begin
  if exists (
    select 1
    from public.subscriptions subscription
    where subscription.source = 'store'
      and subscription.store_entitlement_id is null
  ) then
    raise exception 'DAMANAK_STORE_ENTITLEMENT_BACKFILL_INCOMPLETE';
  end if;
end;
$$;

update public.store_entitlements entitlement
set superseded_at = coalesce(
      entitlement.superseded_at,
      entitlement.updated_at,
      entitlement.verified_at,
      pg_catalog.now()
    ),
    superseded_by = subscription.store_entitlement_id
from public.subscriptions subscription
where subscription.source = 'store'
  and subscription.store_id = entitlement.store_id
  and subscription.store_entitlement_id is not null
  and entitlement.id <> subscription.store_entitlement_id
  and entitlement.superseded_at is null;

update public.store_entitlements entitlement
set superseded_at = coalesce(
      entitlement.superseded_at,
      entitlement.updated_at,
      entitlement.verified_at,
      pg_catalog.now()
    )
where entitlement.superseded_at is null
  and not exists (
    select 1
    from public.subscriptions subscription
    where subscription.source = 'store'
      and subscription.store_id = entitlement.store_id
      and subscription.store_entitlement_id = entitlement.id
  );

create unique index if not exists store_entitlements_one_current_per_store
  on public.store_entitlements(store_id)
  where superseded_at is null;

-- The direct current-entitlement pointer must identify a row in the same
-- tenant. The global id primary key alone cannot enforce that relationship.
create unique index if not exists store_entitlements_store_id_id_unique
  on public.store_entitlements(store_id, id);

alter table public.subscriptions
  drop constraint if exists subscriptions_current_store_entitlement_fk;
alter table public.subscriptions
  add constraint subscriptions_current_store_entitlement_fk
  foreign key (store_id, store_entitlement_id)
  references public.store_entitlements(store_id, id);

alter table public.subscriptions
  drop constraint if exists subscriptions_current_store_entitlement_check;
alter table public.subscriptions
  add constraint subscriptions_current_store_entitlement_check check (
    (source = 'store' and store_entitlement_id is not null)
    or (source <> 'store' and store_entitlement_id is null)
  );

create table if not exists private.google_purchase_token_links (
  token_hash text primary key check (token_hash ~ '^[0-9a-f]{64}$'),
  linked_token_hash text check (
    linked_token_hash is null
    or linked_token_hash ~ '^[0-9a-f]{64}$'
  ),
  platform text not null default 'google_play'
    check (platform = 'google_play'),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  original_transaction_id text not null,
  first_seen_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz not null default pg_catalog.now(),
  foreign key (platform, original_transaction_id)
    references public.store_entitlements(platform, original_transaction_id)
    on delete cascade
);

create index if not exists google_purchase_token_links_predecessor_idx
  on private.google_purchase_token_links(linked_token_hash)
  where linked_token_hash is not null;

alter table private.google_purchase_token_links
  drop constraint if exists google_purchase_token_links_user_id_fkey;
alter table private.google_purchase_token_links
  alter column user_id drop not null;
alter table private.google_purchase_token_links
  add constraint google_purchase_token_links_user_id_fkey
  foreign key (user_id)
  references auth.users(id)
  on delete set null;

revoke all on table private.google_purchase_token_links
  from public, anon, authenticated;

delete from private.store_receipt_secrets receipt
where not exists (
  select 1
  from public.store_entitlements entitlement
  where entitlement.platform = receipt.platform
    and entitlement.original_transaction_id = receipt.original_transaction_id
);

alter table private.store_receipt_secrets
  drop constraint if exists store_receipt_secrets_entitlement_fk;
alter table private.store_receipt_secrets
  add constraint store_receipt_secrets_entitlement_fk
  foreign key (platform, original_transaction_id)
  references public.store_entitlements(platform, original_transaction_id)
  on delete cascade;

insert into private.google_purchase_token_links (
  token_hash,
  platform,
  store_id,
  user_id,
  original_transaction_id
)
select
  pg_catalog.encode(
    extensions.digest(receipt.purchase_token, 'sha256'),
    'hex'
  ),
  entitlement.platform,
  entitlement.store_id,
  entitlement.user_id,
  entitlement.original_transaction_id
from private.store_receipt_secrets receipt
join public.store_entitlements entitlement
  on entitlement.platform = receipt.platform
 and entitlement.original_transaction_id = receipt.original_transaction_id
where receipt.platform = 'google_play'
on conflict (token_hash) do update set
  last_seen_at = pg_catalog.now()
where private.google_purchase_token_links.store_id = excluded.store_id
  and private.google_purchase_token_links.user_id is not distinct from
    excluded.user_id
  and private.google_purchase_token_links.original_transaction_id =
    excluded.original_transaction_id;

do $$
begin
  if exists (
    select 1
    from private.store_receipt_secrets receipt
    join public.store_entitlements entitlement
      on entitlement.platform = receipt.platform
     and entitlement.original_transaction_id =
       receipt.original_transaction_id
    left join private.google_purchase_token_links token_link
      on token_link.token_hash = pg_catalog.encode(
        extensions.digest(receipt.purchase_token, 'sha256'),
        'hex'
      )
    where receipt.platform = 'google_play'
      and (
        token_link.token_hash is null
        or token_link.store_id <> entitlement.store_id
        or token_link.user_id is distinct from entitlement.user_id
        or token_link.original_transaction_id <>
          entitlement.original_transaction_id
      )
  ) then
    raise exception 'DAMANAK_GOOGLE_LINEAGE_BACKFILL_CONFLICT';
  end if;
end;
$$;

create table if not exists private.store_sandbox_review_windows (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform = 'app_store'),
  opens_at timestamptz not null,
  closes_at timestamptz not null,
  grant_ttl_seconds integer not null default 86400
    check (grant_ttl_seconds between 300 and 86400),
  max_grants integer not null default 8 check (max_grants between 1 and 20),
  grants_used integer not null default 0 check (grants_used >= 0),
  release_version text not null check (
    char_length(pg_catalog.btrim(release_version)) between 1 and 50
  ),
  submission_id text not null check (
    char_length(pg_catalog.btrim(submission_id)) between 8 and 100
  ),
  created_by text not null check (
    char_length(pg_catalog.btrim(created_by)) between 3 and 200
  ),
  note text not null default '',
  created_at timestamptz not null default pg_catalog.now(),
  revoked_at timestamptz,
  check (closes_at > opens_at),
  check (closes_at <= opens_at + interval '72 hours'),
  check (grants_used <= max_grants)
);

create table if not exists private.store_sandbox_review_grants (
  id uuid primary key default gen_random_uuid(),
  window_id uuid not null
    references private.store_sandbox_review_windows(id) on delete restrict,
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  platform text not null check (platform in ('app_store', 'google_play')),
  original_transaction_id text not null,
  granted_at timestamptz not null default pg_catalog.now(),
  expires_at timestamptz not null,
  unique (window_id, store_id, user_id, platform),
  check (expires_at > granted_at),
  check (expires_at <= granted_at + interval '24 hours')
);

revoke all on table private.store_sandbox_review_windows
  from public, anon, authenticated;
revoke all on table private.store_sandbox_review_grants
  from public, anon, authenticated;

create or replace function private.claim_store_sandbox_access(
  target_store_id uuid,
  target_user_id uuid,
  billing_platform text,
  external_original_transaction_id text,
  allow_new_grant boolean
)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  explicit_expiry timestamptz;
  review_window private.store_sandbox_review_windows%rowtype;
  existing_grant private.store_sandbox_review_grants%rowtype;
  granted_expiry timestamptz;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select tester.expires_at
  into explicit_expiry
  from private.store_sandbox_testers tester
  where tester.store_id = target_store_id
    and tester.user_id = target_user_id
    and tester.platform = billing_platform
    and tester.expires_at > pg_catalog.now()
  for share;
  if explicit_expiry is not null then
    return explicit_expiry;
  end if;

  select grant_row.*
  into existing_grant
  from private.store_sandbox_review_grants grant_row
  join private.store_sandbox_review_windows review
    on review.id = grant_row.window_id
  where grant_row.store_id = target_store_id
    and grant_row.user_id = target_user_id
    and grant_row.platform = billing_platform
    and review.revoked_at is null
    and review.opens_at <= pg_catalog.now()
    and review.closes_at > pg_catalog.now()
  order by review.closes_at, review.created_at
  for update of grant_row
  limit 1;
  if found then
    if existing_grant.original_transaction_id <>
      external_original_transaction_id then
      raise exception 'SANDBOX_REVIEW_GRANT_CONFLICT';
    end if;
    if existing_grant.expires_at <= pg_catalog.now() then
      raise exception 'SANDBOX_REVIEW_GRANT_EXPIRED';
    end if;
    return existing_grant.expires_at;
  end if;

  -- A terminal provider response may reuse an existing bounded review grant,
  -- but it must never create a fresh grant. Only a newly verified active or
  -- grace entitlement may consume a review-window seat.
  if not coalesce(allow_new_grant, false) then
    raise exception 'SANDBOX_REVIEW_GRANT_REQUIRED';
  end if;

  select review.*
  into review_window
  from private.store_sandbox_review_windows review
  where review.platform = billing_platform
    and review.revoked_at is null
    and review.opens_at <= pg_catalog.now()
    and review.closes_at > pg_catalog.now()
    and review.grants_used < review.max_grants
  order by review.closes_at, review.created_at
  for update
  limit 1;
  if not found then
    raise exception 'SANDBOX_REVIEW_WINDOW_CLOSED';
  end if;

  granted_expiry := least(
    review_window.closes_at,
    pg_catalog.now() +
      pg_catalog.make_interval(secs => review_window.grant_ttl_seconds)
  );
  insert into private.store_sandbox_review_grants (
    window_id,
    store_id,
    user_id,
    platform,
    original_transaction_id,
    expires_at
  ) values (
    review_window.id,
    target_store_id,
    target_user_id,
    billing_platform,
    external_original_transaction_id,
    granted_expiry
  );
  update private.store_sandbox_review_windows
  set grants_used = grants_used + 1
  where id = review_window.id;

  insert into public.audit_logs (
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    target_store_id,
    target_user_id,
    'sandbox_review_access_granted',
    'sandbox_review_window',
    review_window.id,
    pg_catalog.jsonb_build_object(
      'platform', billing_platform,
      'release_version', review_window.release_version,
      'submission_id', review_window.submission_id,
      'expires_at', granted_expiry
    )
  );
  return granted_expiry;
end;
$$;

revoke all on function private.claim_store_sandbox_access(
  uuid, uuid, text, text, boolean
) from public, anon, authenticated;
grant execute on function private.claim_store_sandbox_access(
  uuid, uuid, text, text, boolean
) to service_role;

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
  linked_entitlement public.store_entitlements%rowtype;
  transaction_entitlement public.store_entitlements%rowtype;
  current_entitlement public.store_entitlements%rowtype;
  subscription_row public.subscriptions%rowtype;
  verified_environment text := store_environment;
  effective_entitlement_status text := entitlement_status;
  sandbox_expires_at timestamptz;
  effective_period_end timestamptz := entitlement_period_end;
  candidate_id uuid := gen_random_uuid();
  written_store_id uuid;
  normalized_status text;
  current_blocks_replacement boolean := false;
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
     or nullif(
       pg_catalog.btrim(external_original_transaction_id), ''
     ) is null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;
  -- Every mutation of one store follows this lock order: store, receipt, row.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_store_id::text || ':store-subscription',
      0
    )
  );

  -- Recheck authorization after the store lock. Account deletion and purchase
  -- verification use the same lock, so a stale pre-lock membership decision
  -- can never write after ownership has moved.
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
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      billing_platform || ':transaction:' || external_transaction_id,
      0
    )
  );

  select *
  into subscription_row
  from public.subscriptions subscription
  where subscription.store_id = target_store_id
  for update;
  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  select *
  into linked_entitlement
  from public.store_entitlements entitlement
  where entitlement.platform = billing_platform
    and entitlement.original_transaction_id =
      external_original_transaction_id
  for update;
  if found then
    candidate_id := linked_entitlement.id;
    if linked_entitlement.store_id <> target_store_id
       or linked_entitlement.user_id is distinct from target_user_id then
      raise exception 'STORE_PURCHASE_ALREADY_LINKED';
    end if;
    if linked_entitlement.environment = 'production'
       and verified_environment = 'sandbox' then
      raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
    end if;
  end if;

  select *
  into transaction_entitlement
  from public.store_entitlements entitlement
  where entitlement.platform = billing_platform
    and entitlement.transaction_id = external_transaction_id
  for update;
  if found and (
    transaction_entitlement.store_id <> target_store_id
    or transaction_entitlement.user_id is distinct from target_user_id
    or transaction_entitlement.original_transaction_id <>
      external_original_transaction_id
  ) then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  if subscription_row.store_entitlement_id is not null then
    select *
    into current_entitlement
    from public.store_entitlements entitlement
    where entitlement.id = subscription_row.store_entitlement_id
    for update;
    if found then
      current_blocks_replacement :=
        current_entitlement.status in ('active', 'grace', 'past_due')
        and current_entitlement.period_end > pg_catalog.now();
      if current_entitlement.environment = 'production'
         and verified_environment = 'sandbox' then
        raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
      end if;
      if current_entitlement.id <> candidate_id
         and current_blocks_replacement
         and not (
           current_entitlement.environment = 'sandbox'
           and verified_environment = 'production'
         ) then
        if current_entitlement.platform <> billing_platform then
          raise exception 'ACTIVE_STORE_PROVIDER_CHANGE_BLOCKED';
        end if;
        raise exception 'ACTIVE_STORE_SUBSCRIPTION_REPLACEMENT_BLOCKED';
      end if;
    end if;
  end if;

  if verified_environment = 'sandbox'
     and entitlement_status <> 'revoked' then
    sandbox_expires_at := private.claim_store_sandbox_access(
      target_store_id,
      target_user_id,
      billing_platform,
      external_original_transaction_id,
      entitlement_status in ('active', 'grace')
    );
    -- Sandbox subscription periods are deliberately accelerated. Once an
    -- active/grace receipt has consumed a bounded grant, provider expiry alone
    -- must not eject App Review before that grant ends. Revocation never takes
    -- this path, and an expired grant can never be renewed implicitly.
    effective_period_end := sandbox_expires_at;
    if entitlement_status not in ('active', 'grace') then
      effective_entitlement_status := 'active';
    end if;
  end if;

  if effective_entitlement_status in ('active', 'grace') and (
    effective_period_end is null
    or effective_period_end <= pg_catalog.now()
  ) then
    raise exception 'STORE_ACTIVE_PERIOD_INVALID';
  end if;

  select *
  into catalog_row
  from public.store_product_catalog catalog
  where catalog.platform = billing_platform
    and catalog.product_id = billed_product_id
    and catalog.base_plan_id = coalesce(billed_base_plan_id, '')
    and catalog.is_active
  for share;
  if not found then
    raise exception 'STORE_PRODUCT_UNMAPPED';
  end if;

  insert into public.store_entitlements as existing (
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
    superseded_at,
    superseded_by
  ) values (
    candidate_id,
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    coalesce(billed_base_plan_id, ''),
    catalog_row.plan_id,
    catalog_row.billing_cycle,
    external_transaction_id,
    external_original_transaction_id,
    effective_entitlement_status,
    verified_environment,
    entitlement_period_start,
    effective_period_end,
    entitlement_auto_renews,
    pg_catalog.now(),
    pg_catalog.now(),
    null
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
    updated_at = pg_catalog.now(),
    superseded_at = pg_catalog.now(),
    superseded_by = null
  where existing.store_id = excluded.store_id
    and existing.user_id is not distinct from excluded.user_id
    and not (
      existing.environment = 'production'
      and excluded.environment = 'sandbox'
    )
  returning store_id, id into written_store_id, candidate_id;
  if written_store_id is null then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  update public.store_entitlements entitlement
  set superseded_at = pg_catalog.now(),
      superseded_by = candidate_id,
      refresh_locked_at = null
  where entitlement.store_id = target_store_id
    and entitlement.id <> candidate_id
    and entitlement.superseded_at is null;

  update public.store_entitlements entitlement
  set superseded_at = null,
      superseded_by = null
  where entitlement.id = candidate_id;

  normalized_status := case
    when effective_entitlement_status in ('active', 'grace') then 'active'
    when effective_entitlement_status = 'past_due' then 'past_due'
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
      store_entitlement_id = candidate_id,
      auto_renews = entitlement_auto_renews,
      last_store_verified_at = pg_catalog.now(),
      updated_at = pg_catalog.now()
  where store_id = target_store_id
  returning * into subscription_row;

  insert into public.audit_logs (
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
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
      'status', effective_entitlement_status,
      'provider_status', entitlement_status,
      'environment', verified_environment,
      'effective_period_end', effective_period_end,
      'store_entitlement_id', candidate_id
    )
  );
  return subscription_row;
end;
$$;

revoke all on function public.apply_verified_store_entitlement(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean
) from public, anon, authenticated, service_role;

-- Only the receipt-aware wrapper is a service-role API. Keeping this inner
-- mutation function private to its postgres owner prevents refresh workers
-- from bypassing receipt generation and Google lineage checks.

drop function if exists public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text
);
drop function if exists public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text
);
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
  expected_current_purchase_token_hash text
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

    select *
    into current_link
    from private.google_purchase_token_links token_link
    where token_link.token_hash = purchase_token_hash
    for update;
    if found and (
      current_link.store_id <> target_store_id
      or current_link.user_id is distinct from target_user_id
    ) then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;

    -- A token with a recorded successor is an ancestor, never the current
    -- receipt. Replaying it must not roll the plan, period, or saved secret
    -- backwards after an upgrade or resubscription.
    if exists (
      select 1
      from private.google_purchase_token_links successor
      where successor.linked_token_hash = purchase_token_hash
        and successor.token_hash <> purchase_token_hash
    ) then
      raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
    end if;

    if linked_purchase_token_hash is not null then
      select *
      into previous_link
      from private.google_purchase_token_links token_link
      where token_link.token_hash = linked_purchase_token_hash
      for update;
      if not found then
        if current_link.token_hash is null then
          raise exception 'GOOGLE_LINKED_PURCHASE_UNRESOLVED';
        end if;

        -- Legacy databases retained only the newest raw token. When that
        -- newest token is already bound, Google's authenticated predecessor
        -- may be inserted into the same lineage. A collision with any other
        -- tenant remains a hard conflict.
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
      end if;
      if previous_link.store_id <> target_store_id
         or previous_link.user_id is distinct from target_user_id then
        raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
      end if;
      resolved_original_transaction_id :=
        previous_link.original_transaction_id;
      if current_link.token_hash is not null
         and current_link.original_transaction_id <>
           resolved_original_transaction_id then
        raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
      end if;
    elsif current_link.token_hash is not null then
      resolved_original_transaction_id :=
        current_link.original_transaction_id;
    elsif external_original_transaction_id <>
      'token_' || purchase_token_hash then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;
  elsif purchase_token_hash is not null
        or linked_purchase_token_hash is not null
        or raw_purchase_token is not null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
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
  timestamptz, timestamptz, boolean, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text, text
) to service_role;

drop index if exists public.store_entitlements_refresh_due_idx;
create index store_entitlements_refresh_due_idx
  on public.store_entitlements(next_verification_at, verified_at)
  where superseded_at is null
    and status in ('active', 'grace', 'past_due');

create or replace function public.claim_store_entitlement_refreshes(
  requested_limit integer default 10
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements entitlement
  set refresh_locked_at = null
  where entitlement.superseded_at is null
    and entitlement.refresh_locked_at <
      pg_catalog.now() - interval '15 minutes';

  with selected as (
    select entitlement.id
    from public.store_entitlements entitlement
    join public.subscriptions subscription
      on subscription.store_entitlement_id = entitlement.id
     and subscription.store_id = entitlement.store_id
     and subscription.source = 'store'
    where entitlement.superseded_at is null
      and entitlement.next_verification_at <= pg_catalog.now()
      and entitlement.refresh_locked_at is null
      and entitlement.status in ('active', 'grace', 'past_due')
    order by entitlement.next_verification_at, entitlement.verified_at
    for update of entitlement skip locked
    limit greatest(1, least(requested_limit, 100))
  ), claimed as (
    update public.store_entitlements entitlement
    set refresh_locked_at = pg_catalog.now()
    from selected
    where entitlement.id = selected.id
    returning entitlement.*
  )
  select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', claimed.id,
    'storeId', claimed.store_id,
    'userId', claimed.user_id,
    'platform', claimed.platform,
    'originalTransactionId', claimed.original_transaction_id,
    'purchaseToken', receipt.purchase_token
  ) order by claimed.next_verification_at), '[]'::jsonb)
  into result
  from claimed
  left join private.store_receipt_secrets receipt
    on receipt.platform = claimed.platform
   and receipt.original_transaction_id = claimed.original_transaction_id;
  return result;
end;
$$;

revoke all on function public.claim_store_entitlement_refreshes(integer)
  from public, anon, authenticated;
grant execute on function public.claim_store_entitlement_refreshes(integer)
  to service_role;

-- Successful production checks stay periodic but converge on period_end;
-- sandbox checks repeat quickly enough for accelerated store timelines.
-- Failures use a bounded exponential delay so an outage cannot create a
-- five-minute retry storm or postpone recovery indefinitely.
create or replace function public.release_store_entitlement_refresh(
  target_entitlement_id uuid,
  refresh_succeeded boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements entitlement
  set refresh_locked_at = null,
      refresh_failures = case
        when refresh_succeeded then 0
        else least(coalesce(entitlement.refresh_failures, 0) + 1, 1000)
      end,
      next_verification_at = case
        when not refresh_succeeded then
          pg_catalog.now() + least(
            interval '6 hours',
            interval '5 minutes' * pg_catalog.power(
              2::double precision,
              least(coalesce(entitlement.refresh_failures, 0), 7)::double precision
            )
          )
        when entitlement.environment = 'sandbox' then
          least(
            pg_catalog.now() + interval '5 minutes',
            greatest(
              pg_catalog.now() + interval '1 minute',
              coalesce(
                entitlement.period_end - interval '1 minute',
                pg_catalog.now() + interval '5 minutes'
              )
            )
          )
        when entitlement.status in ('active', 'grace') then
          least(
            pg_catalog.now() + interval '6 hours',
            greatest(
              pg_catalog.now() + interval '5 minutes',
              coalesce(
                entitlement.period_end - interval '1 hour',
                pg_catalog.now() + interval '6 hours'
              )
            )
          )
        when entitlement.status = 'past_due' then
          pg_catalog.now() + interval '30 minutes'
        else pg_catalog.now() + interval '24 hours'
      end
  where entitlement.id = target_entitlement_id;
end;
$$;

revoke all on function public.release_store_entitlement_refresh(uuid, boolean)
  from public, anon, authenticated;
grant execute on function public.release_store_entitlement_refresh(uuid, boolean)
  to service_role;

create or replace function public.current_warranty_usage(target_store_id uuid)
returns bigint
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  month_start timestamptz := pg_catalog.date_trunc(
    'month',
    pg_catalog.now()
  );
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  return (
    select pg_catalog.count(*)
    from public.warranties warranty
    where warranty.store_id = target_store_id
      and warranty.created_at >= month_start
      and warranty.created_at < month_start + interval '1 month'
  );
end;
$$;

revoke all on function public.current_warranty_usage(uuid)
  from public, anon, authenticated;
grant execute on function public.current_warranty_usage(uuid)
  to authenticated;

-- Account deletion remains immediate. A store without a successor is deleted
-- normally. If the store survives, its current entitlement is ended before
-- ownership moves so the successor never inherits billing tied to the deleted
-- purchaser. External App Store / Google Play cancellation remains the user's
-- responsibility and is intentionally not attempted from SQL.
create or replace function public.delete_current_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleting_user_id uuid := auth.uid();
  owned_store_id uuid;
  owned_store public.stores%rowtype;
  successor uuid;
  terminated_entitlement_id uuid;
begin
  if deleting_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  for owned_store_id in
    select store.id
    from public.stores store
    where store.owner_id = deleting_user_id
    order by store.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        owned_store_id::text || ':store-subscription',
        0
      )
    );
    select store.*
    into owned_store
    from public.stores store
    where store.id = owned_store_id
      and store.owner_id = deleting_user_id
    for update;
    if not found then
      continue;
    end if;

    select member.user_id
    into successor
    from public.store_members member
    where member.store_id = owned_store.id
      and member.user_id <> deleting_user_id
      and member.status = 'active'
    order by case member.role when 'manager' then 0 else 1 end,
      member.joined_at,
      member.user_id
    limit 1
    for update;

    if successor is null then
      delete from public.stores where id = owned_store.id;
    else
      terminated_entitlement_id := null;
      update public.store_entitlements entitlement
      set status = 'canceled',
          auto_renews = false,
          period_end = least(
            coalesce(entitlement.period_end, pg_catalog.now()),
            pg_catalog.now()
          ),
          refresh_locked_at = null,
          next_verification_at = pg_catalog.now(),
          updated_at = pg_catalog.now()
      where entitlement.store_id = owned_store.id
        and entitlement.superseded_at is null
        and entitlement.user_id = deleting_user_id
      returning entitlement.id into terminated_entitlement_id;

      if terminated_entitlement_id is not null then
        update public.subscriptions subscription
        set status = 'canceled',
            current_period_end = least(
              coalesce(subscription.current_period_end, pg_catalog.now()),
              pg_catalog.now()
            ),
            auto_renews = false,
            updated_at = pg_catalog.now()
        where subscription.store_id = owned_store.id
          and subscription.source = 'store'
          and subscription.store_entitlement_id = terminated_entitlement_id;

        insert into public.audit_logs (
          store_id,
          user_id,
          action,
          entity_type,
          entity_id,
          metadata
        ) values (
          owned_store.id,
          deleting_user_id,
          'store_subscription_terminated_for_account_deletion',
          'store_entitlement',
          terminated_entitlement_id,
          pg_catalog.jsonb_build_object(
            'successor_user_id', successor,
            'external_billing_cancellation_required', true
          )
        );
      end if;

      update public.store_members
      set role = 'owner'
      where store_id = owned_store.id and user_id = successor;
      update public.stores
      set owner_id = successor
      where id = owned_store.id;
    end if;
    successor := null;
    terminated_entitlement_id := null;
  end loop;
  delete from auth.users where id = deleting_user_id;
end;
$$;

revoke all on function public.delete_current_account()
  from public, anon, authenticated;
grant execute on function public.delete_current_account()
  to authenticated;

-- Reassert the two authenticated RPC grants so the migration chain, schema
-- snapshot, and production ACL can be checked independently.
revoke all on function public.register_trial_device(uuid, text)
  from public, anon, authenticated;
grant execute on function public.register_trial_device(uuid, text)
  to authenticated;

do $$
declare
  account_delete_definition text;
begin
  select pg_catalog.pg_get_functiondef(
    pg_catalog.to_regprocedure('public.delete_current_account()')
  ) into account_delete_definition;
  if pg_catalog.strpos(
       account_delete_definition,
       'ACTIVE_STORE_SUBSCRIPTION_MUST_BE_RESOLVED'
     ) > 0
     or pg_catalog.strpos(
       account_delete_definition,
       'store_subscription_terminated_for_account_deletion'
     ) = 0
     or pg_catalog.strpos(
       account_delete_definition,
       'STORE_BILLING_IDENTITY_CANNOT_TRANSFER'
     ) > 0
     or pg_catalog.strpos(
       account_delete_definition,
       'STORE_BILLING_IDENTITY_RETAINED'
     ) > 0 then
    raise exception 'DAMANAK_ACCOUNT_DELETION_BILLING_CONTRACT_INVALID';
  end if;
  if exists (
    select 1
    from public.store_entitlements entitlement
    where entitlement.superseded_at is null
    group by entitlement.store_id
    having pg_catalog.count(*) > 1
  ) then
    raise exception 'DAMANAK_MULTIPLE_CURRENT_STORE_ENTITLEMENTS';
  end if;
  if exists (
    select 1
    from public.subscriptions subscription
    left join public.store_entitlements entitlement
      on entitlement.id = subscription.store_entitlement_id
     and entitlement.store_id = subscription.store_id
     and entitlement.superseded_at is null
    where subscription.source = 'store'
      and entitlement.id is null
  ) then
    raise exception 'DAMANAK_CURRENT_STORE_ENTITLEMENT_LINK_INVALID';
  end if;
  if not exists (
    select 1
    from pg_catalog.pg_constraint constraint_info
    where constraint_info.conname =
      'subscriptions_current_store_entitlement_fk'
      and constraint_info.contype = 'f'
      and constraint_info.conrelid = 'public.subscriptions'::regclass
      and constraint_info.confrelid =
        'public.store_entitlements'::regclass
      and array(
        select attribute.attname::text
        from unnest(constraint_info.conkey) with ordinality
          as key_column(attribute_number, position)
        join pg_catalog.pg_attribute attribute
          on attribute.attrelid = constraint_info.conrelid
         and attribute.attnum = key_column.attribute_number
        order by key_column.position
      ) = array['store_id', 'store_entitlement_id']
      and array(
        select attribute.attname::text
        from unnest(constraint_info.confkey) with ordinality
          as key_column(attribute_number, position)
        join pg_catalog.pg_attribute attribute
          on attribute.attrelid = constraint_info.confrelid
         and attribute.attnum = key_column.attribute_number
        order by key_column.position
      ) = array['store_id', 'id']
  ) then
    raise exception 'DAMANAK_STORE_ENTITLEMENT_TENANT_FK_INVALID';
  end if;
  if exists (
    select 1
    from information_schema.columns column_info
    where column_info.table_schema = 'public'
      and column_info.table_name = 'store_entitlements'
      and column_info.column_name = 'user_id'
      and column_info.is_nullable <> 'YES'
  ) or not exists (
    select 1
    from information_schema.referential_constraints constraint_info
    where constraint_info.constraint_schema = 'public'
      and constraint_info.constraint_name =
        'store_entitlements_user_id_fkey'
      and constraint_info.delete_rule = 'SET NULL'
  ) then
    raise exception 'DAMANAK_STORE_PURCHASER_ANONYMIZATION_INVALID';
  end if;
  if exists (
    select 1
    from information_schema.columns column_info
    where column_info.table_schema = 'private'
      and column_info.table_name = 'google_purchase_token_links'
      and column_info.column_name = 'user_id'
      and column_info.is_nullable <> 'YES'
  ) or not exists (
    select 1
    from information_schema.referential_constraints constraint_info
    where constraint_info.constraint_schema = 'private'
      and constraint_info.constraint_name =
        'google_purchase_token_links_user_id_fkey'
      and constraint_info.delete_rule = 'SET NULL'
  ) then
    raise exception 'DAMANAK_GOOGLE_PURCHASER_ANONYMIZATION_INVALID';
  end if;
  if exists (
    select 1
    from information_schema.routine_privileges privilege
    where privilege.specific_schema in ('public', 'private')
      and privilege.grantee in ('PUBLIC', 'anon', 'authenticated')
      and privilege.privilege_type = 'EXECUTE'
      and privilege.routine_name in (
        'apply_verified_store_entitlement',
        'apply_verified_store_entitlement_with_receipt',
        'claim_store_sandbox_access',
        'claim_store_entitlement_refreshes'
      )
  ) then
    raise exception 'DAMANAK_STORE_BILLING_EXECUTE_EXPOSED';
  end if;
  if coalesce(
    pg_catalog.has_function_privilege(
      'service_role',
      pg_catalog.to_regprocedure(
        'public.apply_verified_store_entitlement(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean)'
      ),
      'EXECUTE'
    ),
    false
  ) then
    raise exception 'DAMANAK_RAW_STORE_ENTITLEMENT_APPLY_EXPOSED';
  end if;
  if not coalesce(
    pg_catalog.has_function_privilege(
      'service_role',
      pg_catalog.to_regprocedure(
        'public.apply_verified_store_entitlement_with_receipt(uuid,uuid,text,text,text,text,text,text,text,timestamptz,timestamptz,boolean,text,text,text,text)'
      ),
      'EXECUTE'
    ),
    false
  ) then
    raise exception 'DAMANAK_RECEIPT_STORE_ENTITLEMENT_APPLY_UNAVAILABLE';
  end if;
end;
$$;
