-- Separate the recurring free allowance from App Store / Google Play billing.
-- A free grant is bound to one protected installation in the official app.
-- This is not hardware attestation; App Attest/DeviceCheck and Play Integrity
-- remain required before describing the binding as proof of a physical device.

insert into public.plans (
  id,
  name_ar,
  monthly_price,
  yearly_price,
  max_members,
  monthly_warranties,
  is_active,
  sort_order,
  monthly_ai_imports,
  monthly_ai_claim_reviews,
  max_branches,
  api_access,
  webhook_access,
  custom_branding
) values (
  'free',
  'مجانية',
  0,
  0,
  1,
  20,
  false,
  0,
  0,
  0,
  1,
  false,
  false,
  false
)
on conflict (id) do update set
  name_ar = excluded.name_ar,
  monthly_price = excluded.monthly_price,
  yearly_price = excluded.yearly_price,
  max_members = excluded.max_members,
  monthly_warranties = excluded.monthly_warranties,
  is_active = excluded.is_active,
  sort_order = excluded.sort_order,
  monthly_ai_imports = excluded.monthly_ai_imports,
  monthly_ai_claim_reviews = excluded.monthly_ai_claim_reviews,
  max_branches = excluded.max_branches,
  api_access = excluded.api_access,
  webhook_access = excluded.webhook_access,
  custom_branding = excluded.custom_branding;

-- The public subscription row remains a compatibility envelope for Builds
-- 23-29. Build 30 never trusts this marker for authorization; it resolves the
-- private free grant through current_store_access. Keeping the envelope on the
-- inactive Free row prevents old PostgREST embeds from returning plans=null
-- while the explicit is_active=true catalog filter keeps it out of purchase
-- cards. Authorization still comes only from the private grant/session.
alter table public.subscriptions
  add column if not exists free_access_mirror boolean not null default false;

alter table public.subscriptions
  drop constraint if exists subscriptions_free_access_mirror_check;
alter table public.subscriptions
  add constraint subscriptions_free_access_mirror_check check (
    not free_access_mirror
    or (
      plan_id = 'free'
      and status = 'active'
      and source = 'manual'
      and trial_ends_at is null
      and current_period_start is null
      and current_period_end is null
      and billing_provider is null
      and store_product_id is null
      and billing_cycle is null
      and original_transaction_id is null
      and not auto_renews
      and last_store_verified_at is null
      and store_environment is null
      and store_entitlement_id is null
    )
  );

create or replace function public.normalize_subscription_free_access_mirror()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.free_access_mirror and not (
    new.plan_id = 'free'
    and new.status = 'active'
    and new.source = 'manual'
    and new.trial_ends_at is null
    and new.current_period_start is null
    and new.current_period_end is null
    and new.billing_provider is null
    and new.store_product_id is null
    and new.billing_cycle is null
    and new.original_transaction_id is null
    and not new.auto_renews
    and new.last_store_verified_at is null
    and new.store_environment is null
    and new.store_entitlement_id is null
  ) then
    new.free_access_mirror := false;
  end if;
  return new;
end;
$$;

drop trigger if exists subscriptions_normalize_free_access_mirror
  on public.subscriptions;
create trigger subscriptions_normalize_free_access_mirror
before insert or update
on public.subscriptions
for each row execute function public.normalize_subscription_free_access_mirror();

revoke all on function public.normalize_subscription_free_access_mirror()
  from public, anon, authenticated;

drop policy if exists plans_select_authenticated on public.plans;
create policy plans_select_authenticated
on public.plans
for select
to authenticated
using (
  is_active
  or (
    id = 'free'
    and exists (
      select 1
      from public.subscriptions subscription
      where subscription.plan_id = public.plans.id
        and subscription.free_access_mirror
        and public.is_store_member(subscription.store_id)
    )
  )
);

create table if not exists private.free_account_claims (
  account_hash bytea primary key check (
    pg_catalog.octet_length(account_hash) = 32
  ),
  claimed_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz not null default pg_catalog.now()
);

create table if not exists private.free_device_claims (
  device_hash bytea primary key check (
    pg_catalog.octet_length(device_hash) = 32
  ),
  account_hash bytea not null unique
    references private.free_account_claims(account_hash) on delete restrict,
  claimed_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz not null default pg_catalog.now()
);

create table if not exists private.free_session_claims (
  session_hash bytea not null check (
    pg_catalog.octet_length(session_hash) = 32
  ),
  store_id uuid not null references public.stores(id) on delete cascade,
  account_hash bytea not null
    references private.free_account_claims(account_hash) on delete restrict,
  device_hash bytea not null
    references private.free_device_claims(device_hash) on delete restrict,
  expires_at timestamptz not null,
  created_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz not null default pg_catalog.now(),
  primary key (session_hash, store_id),
  unique (store_id, account_hash, device_hash)
);

create table if not exists private.free_plan_grants (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null unique
    references public.stores(id) on delete cascade,
  account_hash bytea not null unique
    references private.free_account_claims(account_hash) on delete restrict,
  device_hash bytea unique
    references private.free_device_claims(device_hash) on delete restrict,
  status text not null default 'pending_device' check (
    status in ('pending_device', 'active', 'revoked')
  ),
  assurance_level text not null default 'legacy_installation' check (
    assurance_level in (
      'legacy_installation', 'apple_attested', 'play_integrity'
    )
  ),
  granted_at timestamptz,
  created_at timestamptz not null default pg_catalog.now(),
  updated_at timestamptz not null default pg_catalog.now(),
  last_seen_at timestamptz,
  check (
    (status = 'pending_device' and device_hash is null and granted_at is null)
    or (status = 'active' and device_hash is not null and granted_at is not null)
    or status = 'revoked'
  )
);

comment on table private.free_plan_grants is
  'Base free access, separate from store billing. legacy_installation is a protected app installation, not physical-device attestation.';

revoke all on table private.free_account_claims
  from public, anon, authenticated;
revoke all on table private.free_device_claims
  from public, anon, authenticated;
revoke all on table private.free_session_claims
  from public, anon, authenticated;
revoke all on table private.free_plan_grants
  from public, anon, authenticated;

create or replace function private.direct_subscription_is_usable(
  target_store_id uuid
)
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
      and not subscription.free_access_mirror
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

create or replace function private.free_plan_is_usable(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from private.free_plan_grants grant_row
    where grant_row.store_id = target_store_id
      and grant_row.status = 'active'
      and (
        coalesce((select auth.role()), 'service_role')
          not in ('authenticated', 'anon')
        or (
          (select auth.role()) = 'authenticated'
          and exists (
            select 1
            from private.free_session_claims session_claim
            where session_claim.store_id = target_store_id
              and session_claim.account_hash = grant_row.account_hash
              and session_claim.device_hash = grant_row.device_hash
              and session_claim.expires_at > pg_catalog.now()
              and session_claim.session_hash = extensions.digest(
                'damanak:free-session:v1:' ||
                  coalesce((select auth.jwt() ->> 'session_id'), ''),
                'sha256'
              )
          )
        )
      )
  )
$$;

create or replace function private.effective_store_plan_id(
  target_store_id uuid
)
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(
    (
      select subscription.plan_id
      from public.subscriptions subscription
      where subscription.store_id = target_store_id
        and private.direct_subscription_is_usable(target_store_id)
      limit 1
    ),
    (
      select 'free'::text
      where private.free_plan_is_usable(target_store_id)
        and not exists (
          select 1
          from public.subscriptions blocked_billing
          where blocked_billing.store_id = target_store_id
            and blocked_billing.source = 'store'
            and blocked_billing.status = 'past_due'
            and blocked_billing.store_environment = 'production'
            and blocked_billing.current_period_end > pg_catalog.now()
        )
      limit 1
    )
  )
$$;

create or replace function public.subscription_is_usable(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.effective_store_plan_id(target_store_id) is not null
$$;

create or replace function public.current_store_access(
  target_store_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  access_snapshot jsonb;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;

  -- Keep an unexpired paid billing state visible even when it is past_due, so
  -- a second provider or a downgrade cannot be opened behind a free fallback.
  select pg_catalog.to_jsonb(subscription) || pg_catalog.jsonb_build_object(
    'plans', pg_catalog.to_jsonb(plan),
    'has_store_billing_lineage', exists (
      select 1
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    ),
    'store_billing_lineage_verified_at', (
      select pg_catalog.max(billing_record.verified_at)
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    )
  )
  into access_snapshot
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
    and (
      private.direct_subscription_is_usable(target_store_id)
      or (
        subscription.source = 'store'
        and subscription.status = 'past_due'
        and subscription.store_environment = 'production'
        and subscription.current_period_end > pg_catalog.now()
      )
    )
  limit 1;
  if access_snapshot is not null then
    return access_snapshot;
  end if;

  select pg_catalog.jsonb_build_object(
    'id', grant_row.id,
    'store_id', grant_row.store_id,
    'plan_id', plan.id,
    'status', 'active',
    'trial_ends_at', null,
    'current_period_start', null,
    'current_period_end', null,
    'source', 'free',
    'billing_provider', null,
    'store_product_id', null,
    'billing_cycle', null,
    'original_transaction_id', null,
    'auto_renews', false,
    'last_store_verified_at', null,
    'store_environment', null,
    'store_entitlement_id', null,
    'has_store_billing_lineage', exists (
      select 1
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    ),
    'store_billing_lineage_verified_at', (
      select pg_catalog.max(billing_record.verified_at)
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    ),
    'created_at', grant_row.created_at,
    'updated_at', grant_row.updated_at,
    'plans', pg_catalog.to_jsonb(plan)
  )
  into access_snapshot
  from private.free_plan_grants grant_row
  join public.plans plan on plan.id = 'free'
  where grant_row.store_id = target_store_id
    and private.free_plan_is_usable(target_store_id);
  if access_snapshot is not null then
    return access_snapshot;
  end if;

  -- Builds 23-29 need a subscription-shaped compatibility mirror. Build 30
  -- must never treat that mirror as free access unless this session is bound
  -- to the protected installation, so expose a fail-closed starter placeholder
  -- when the private grant is unavailable to the current session.
  select pg_catalog.jsonb_build_object(
    'id', subscription.id,
    'store_id', subscription.store_id,
    'plan_id', plan.id,
    'status', 'canceled',
    'trial_ends_at', null,
    'current_period_start', null,
    'current_period_end', null,
    'source', 'trial',
    'billing_provider', null,
    'store_product_id', null,
    'billing_cycle', null,
    'original_transaction_id', null,
    'auto_renews', false,
    'last_store_verified_at', null,
    'store_environment', null,
    'store_entitlement_id', null,
    'has_store_billing_lineage', false,
    'store_billing_lineage_verified_at', null,
    'created_at', subscription.created_at,
    'updated_at', subscription.updated_at,
    'plans', pg_catalog.to_jsonb(plan)
  )
  into access_snapshot
  from public.subscriptions subscription
  join public.plans plan on plan.id = 'starter'
  where subscription.store_id = target_store_id
    and subscription.free_access_mirror
  limit 1;
  if access_snapshot is not null then
    return access_snapshot;
  end if;

  select pg_catalog.to_jsonb(subscription) || pg_catalog.jsonb_build_object(
    'plans', pg_catalog.to_jsonb(plan),
    'has_store_billing_lineage', exists (
      select 1
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    ),
    'store_billing_lineage_verified_at', (
      select pg_catalog.max(billing_record.verified_at)
      from public.store_entitlements billing_record
      where billing_record.store_id = target_store_id
        and billing_record.superseded_at is null
        and (
          (
            billing_record.status in ('active', 'grace')
            and (
              billing_record.auto_renews
              or billing_record.period_end > pg_catalog.now()
            )
          )
          or (
            billing_record.status = 'past_due'
            and billing_record.environment = 'production'
            and billing_record.period_end > pg_catalog.now()
          )
        )
    )
  )
  into access_snapshot
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
  limit 1;
  if access_snapshot is null then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;
  return access_snapshot;
end;
$$;

revoke all on function private.direct_subscription_is_usable(uuid)
  from public, anon, authenticated;
revoke all on function private.free_plan_is_usable(uuid)
  from public, anon, authenticated;
revoke all on function private.effective_store_plan_id(uuid)
  from public, anon, authenticated;
revoke all on function public.current_store_access(uuid)
  from public, anon, authenticated;
grant execute on function public.current_store_access(uuid)
  to authenticated;

create or replace function public.claim_free_plan_device(
  target_store_id uuid,
  device_claim text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  current_account_hash bytea;
  current_device_hash bytea;
  linked_account_hash bytea;
  linked_device_hash bytea;
  current_session_id text := coalesce(
    (select auth.jwt() ->> 'session_id'),
    ''
  );
  current_session_hash bytea;
  grant_row private.free_plan_grants%rowtype;
  was_active boolean := false;
  normalized_claim text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(device_claim, ''))
  );
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if pg_catalog.char_length(current_session_id) < 8 then
    raise exception 'FREE_SESSION_REQUIRED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'FREE_DEVICE_CLAIM_INVALID';
  end if;
  if not exists (
    select 1
    from public.store_members member
    join public.stores store on store.id = member.store_id
    where member.store_id = target_store_id
      and member.user_id = actor
      and member.role = 'owner'
      and member.status = 'active'
      and store.owner_id = actor
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  current_account_hash := extensions.digest(
    'damanak:free-account:v1:' || actor::text,
    'sha256'
  );
  current_device_hash := extensions.digest(
    'damanak:free-device:v1:' || normalized_claim,
    'sha256'
  );
  current_session_hash := extensions.digest(
    'damanak:free-session:v1:' || current_session_id,
    'sha256'
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:free-account-lock:v1:' ||
        pg_catalog.encode(current_account_hash, 'hex'),
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:free-device-lock:v1:' ||
        pg_catalog.encode(current_device_hash, 'hex'),
      0
    )
  );

  select *
  into grant_row
  from private.free_plan_grants grant_entry
  where grant_entry.store_id = target_store_id
  for update;

  if not found then
    if exists (
      select 1
      from private.free_account_claims account_claim
      where account_claim.account_hash = current_account_hash
    ) then
      return false;
    end if;
    insert into private.free_account_claims(account_hash)
    values (current_account_hash);
    insert into private.free_plan_grants(store_id, account_hash)
    values (target_store_id, current_account_hash)
    returning * into grant_row;
  elsif grant_row.account_hash <> current_account_hash
      or grant_row.status = 'revoked' then
    return false;
  else
    insert into private.free_account_claims(account_hash)
    values (current_account_hash)
    on conflict (account_hash) do update
    set last_seen_at = pg_catalog.now();
  end if;

  was_active := grant_row.status = 'active';
  select claim.account_hash
  into linked_account_hash
  from private.free_device_claims claim
  where claim.device_hash = current_device_hash
  for update;
  if found and linked_account_hash <> current_account_hash then
    return false;
  end if;

  select claim.device_hash
  into linked_device_hash
  from private.free_device_claims claim
  where claim.account_hash = current_account_hash
  for update;
  if found and linked_device_hash <> current_device_hash then
    return false;
  end if;

  insert into private.free_device_claims(device_hash, account_hash)
  values (current_device_hash, current_account_hash)
  on conflict (device_hash) do update
  set last_seen_at = pg_catalog.now()
  where private.free_device_claims.account_hash = excluded.account_hash;

  update private.free_plan_grants
  set device_hash = current_device_hash,
      status = 'active',
      granted_at = coalesce(granted_at, pg_catalog.now()),
      last_seen_at = pg_catalog.now(),
      updated_at = pg_catalog.now()
  where id = grant_row.id;

  delete from private.free_session_claims session_claim
  where session_claim.expires_at <= pg_catalog.now();
  insert into private.free_session_claims(
    session_hash,
    store_id,
    account_hash,
    device_hash,
    expires_at
  ) values (
    current_session_hash,
    target_store_id,
    current_account_hash,
    current_device_hash,
    pg_catalog.now() + interval '30 days'
  )
  on conflict (store_id, account_hash, device_hash) do update
  set session_hash = excluded.session_hash,
      expires_at = excluded.expires_at,
      last_seen_at = pg_catalog.now();

  if not was_active then
    insert into public.audit_logs(
      store_id,
      user_id,
      action,
      entity_type,
      entity_id,
      metadata
    ) values (
      target_store_id,
      actor,
      'free_plan_activated',
      'free_plan_grant',
      grant_row.id,
      pg_catalog.jsonb_build_object(
        'plan_id', 'free',
        'monthly_warranties', 20,
        'device_policy', 'one_protected_installation',
        'assurance_level', 'legacy_installation'
      )
    );
  end if;

  perform private.ensure_default_store_branch(target_store_id);
  perform private.reconcile_store_member_limit(target_store_id);
  perform private.reconcile_store_branch_limit(target_store_id);
  return true;
end;
$$;

revoke all on function public.claim_free_plan_device(uuid, text)
  from public, anon, authenticated;
grant execute on function public.claim_free_plan_device(uuid, text)
  to authenticated;

-- Build 29 still calls this name. It may bind the installation but continues
-- to read the legacy billing placeholder; Build 30 reads current_store_access.
create or replace function public.register_trial_device(
  target_store_id uuid,
  device_claim text
)
returns boolean
language sql
security definer
set search_path = ''
as $$
  select public.claim_free_plan_device(target_store_id, device_claim)
$$;

revoke all on function public.register_trial_device(uuid, text)
  from public, anon, authenticated;
grant execute on function public.register_trial_device(uuid, text)
  to authenticated;

-- Route every live legacy creation entrypoint through the same free-access
-- transition. The proven Build 25 creator is retained under a revoked internal
-- name solely as an idempotent store/bootstrap primitive; any trial it creates
-- is canceled in the same transaction before the free-device claim is applied.
alter function public.create_store_with_subscription(
  text, text, text, text, text
) set schema private;

alter function private.create_store_with_subscription(
  text, text, text, text, text
) rename to create_store_with_subscription_legacy_core;

revoke all on function private.create_store_with_subscription_legacy_core(
  text, text, text, text, text
) from public, anon, authenticated, service_role;

create or replace function public.create_store_with_subscription(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_store_id uuid;
begin
  created_store_id := private.create_store_with_subscription_legacy_core(
    store_name,
    store_phone,
    store_city,
    store_country_code,
    device_claim
  );

  update public.subscriptions subscription
  set plan_id = 'starter',
      status = 'canceled',
      trial_ends_at = null,
      current_period_start = null,
      current_period_end = null,
      source = 'trial',
      billing_provider = null,
      store_product_id = null,
      billing_cycle = null,
      original_transaction_id = null,
      auto_renews = false,
      last_store_verified_at = null,
      store_environment = null,
      store_entitlement_id = null,
      free_access_mirror = false,
      updated_at = pg_catalog.now()
  where subscription.store_id = created_store_id
    and subscription.source = 'trial';

  perform public.claim_free_plan_device(created_store_id, device_claim);
  return created_store_id;
end;
$$;

revoke all on function public.create_store_with_subscription(
  text, text, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.create_store_with_subscription(
  text, text, text, text, text
) to authenticated;

create or replace function public.create_store_with_trial(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language sql
security definer
set search_path = ''
as $$
  select public.create_store_with_subscription(
    store_name,
    store_phone,
    store_city,
    store_country_code,
    device_claim
  )
$$;

revoke all on function public.create_store_with_trial(
  text, text, text, text, text
) from public, anon, authenticated, service_role;
grant execute on function public.create_store_with_trial(
  text, text, text, text, text
) to authenticated;

create or replace function public.create_store_with_free_access(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  created_store_id uuid;
begin
  created_store_id := public.create_store_with_subscription(
    store_name,
    store_phone,
    store_city,
    store_country_code,
    device_claim
  );

  -- The compatibility entrypoint already canceled every legacy trial and
  -- attempted the same idempotent claim. Repeat the claim to refresh this
  -- authenticated session without creating another grant.
  perform public.claim_free_plan_device(created_store_id, device_claim);
  return created_store_id;
end;
$$;

revoke all on function public.create_store_with_free_access(
  text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.create_store_with_free_access(
  text, text, text, text, text
) to authenticated;

comment on function public.create_store_with_free_access(
  text, text, text, text, text
) is 'Build 30 onboarding: creates the billing placeholder and atomically claims the recurring 20-warranty free plan for one protected installation.';

create or replace function public.store_requires_initial_payment(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not public.subscription_is_usable(target_store_id)
    and exists (
      select 1
      from public.subscriptions subscription
      where subscription.store_id = target_store_id
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
    from public.plans plan
    where plan.id = private.effective_store_plan_id(target_store_id)
  ), false)
$$;

create or replace function public.enforce_warranty_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  effective_plan_id text;
  included_limit integer;
  effective_limit integer;
  used_count bigint;
  actor uuid := (select auth.uid());
begin
  if (select auth.role()) = 'authenticated' then
    if actor is null then
      raise exception 'AUTH_REQUIRED';
    end if;
    new.created_by := actor;
    new.created_at := pg_catalog.now();
    new.updated_at := pg_catalog.now();
    new.voided_at := null;
  end if;

  effective_plan_id := private.effective_store_plan_id(new.store_id);
  if effective_plan_id is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':warranties', 0)
  );

  select plan.monthly_warranties
  into included_limit
  from public.plans plan
  where plan.id = effective_plan_id;
  if included_limit is null then
    raise exception 'SUBSCRIPTION_PLAN_NOT_FOUND';
  end if;

  effective_limit := case
    when effective_plan_id = 'free' then included_limit
    else included_limit +
      pg_catalog.ceil(included_limit::numeric * 0.10)::integer
  end;

  select pg_catalog.count(*)
  into used_count
  from public.warranties warranty
  where warranty.store_id = new.store_id
    and warranty.created_at >= pg_catalog.date_trunc(
      'month', pg_catalog.now()
    )
    and warranty.created_at < pg_catalog.date_trunc(
      'month', pg_catalog.now()
    ) + interval '1 month';

  if used_count >= effective_limit then
    raise exception 'WARRANTY_LIMIT_REACHED';
  end if;

  if new.warranty_number is null or new.warranty_number = '' then
    new.warranty_number :=
      'DMN-' || pg_catalog.to_char(pg_catalog.now(), 'YYMM') || '-S' ||
      pg_catalog.upper(
        pg_catalog.lpad(
          pg_catalog.to_hex(
            pg_catalog.nextval(
              'public.warranty_number_seq'::pg_catalog.regclass
            )
          ),
          12,
          '0'
        )
      );
  end if;
  return new;
end;
$$;

create or replace function public.enforce_branch_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  branch_limit integer;
  current_count integer;
begin
  if not new.is_active then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and old.is_active
     and new.store_id = old.store_id then
    return new;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  select plan.max_branches
  into branch_limit
  from public.plans plan
  where plan.id = private.effective_store_plan_id(new.store_id);
  if branch_limit is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  select pg_catalog.count(*)
  into current_count
  from public.branches branch
  where branch.store_id = new.store_id
    and branch.is_active
    and branch.id <> new.id;
  if current_count >= branch_limit then
    raise exception 'BRANCH_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

create or replace function private.ensure_default_store_branch(
  target_store_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  store_row public.stores%rowtype;
  branch_limit integer;
  active_branch_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':branches', 0)
  );
  select plan.max_branches
  into branch_limit
  from public.plans plan
  where plan.id = private.effective_store_plan_id(target_store_id);
  if branch_limit is null then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.code = 'MAIN'
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;
  update public.branches branch
  set is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and branch.is_active
    and not branch.is_main
    and not exists (
      select 1
      from public.branches other
      where other.store_id = target_store_id
        and other.is_active
        and other.is_main
    );
  if found then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;
  select pg_catalog.count(*)
  into active_branch_count
  from public.branches branch
  where branch.store_id = target_store_id
    and branch.is_active;
  if active_branch_count >= branch_limit then
    return;
  end if;
  update public.branches branch
  set is_active = true,
      is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and not branch.is_active;
  if found then
    return;
  end if;
  select *
  into store_row
  from public.stores store
  where store.id = target_store_id;
  if store_row.id is null then
    return;
  end if;
  insert into public.branches(
    store_id, name, code, city, address, phone, is_main
  ) values (
    store_row.id,
    'الفرع الرئيسي',
    'MAIN',
    store_row.city,
    store_row.address,
    store_row.phone,
    true
  )
  on conflict (store_id, code) do nothing;
end;
$$;

create or replace function private.reconcile_store_member_limit(
  target_store_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed_members integer;
  active_owners integer;
begin
  select plan.max_members
  into allowed_members
  from public.plans plan
  where plan.id = private.effective_store_plan_id(target_store_id);
  if allowed_members is null then
    return;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':members', 0)
  );
  select pg_catalog.count(*)
  into active_owners
  from public.store_members member
  where member.store_id = target_store_id
    and member.status = 'active'
    and member.role = 'owner';

  with ranked as (
    select
      member.user_id,
      pg_catalog.row_number() over (
        order by member.joined_at, member.user_id
      ) as position
    from public.store_members member
    where member.store_id = target_store_id
      and member.status = 'active'
      and member.role <> 'owner'
  ), suspended as (
    update public.store_members member
    set status = 'suspended',
        updated_at = pg_catalog.now()
    from ranked
    where member.store_id = target_store_id
      and member.user_id = ranked.user_id
      and ranked.position > greatest(allowed_members - active_owners, 0)
    returning member.user_id
  )
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  )
  select
    target_store_id,
    (select auth.uid()),
    'member_suspended_for_plan_limit',
    'member',
    suspended.user_id,
    pg_catalog.jsonb_build_object('max_members', allowed_members)
  from suspended;
end;
$$;

create or replace function private.reconcile_store_branch_limit(
  target_store_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  branch_limit integer;
begin
  select plan.max_branches
  into branch_limit
  from public.plans plan
  where plan.id = private.effective_store_plan_id(target_store_id);
  if branch_limit is null then
    return;
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':branches', 0)
  );
  with ranked as (
    select
      branch.id,
      pg_catalog.row_number() over (
        order by branch.is_main desc, branch.created_at, branch.id
      ) as position
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.is_active
  )
  update public.branches branch
  set is_active = false,
      updated_at = pg_catalog.now()
  from ranked
  where branch.id = ranked.id
    and ranked.position > branch_limit;
end;
$$;

create or replace function public.enforce_subscription_member_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.reconcile_store_member_limit(new.store_id);
  return new;
end;
$$;

create or replace function public.trim_branches_to_subscription_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.reconcile_store_branch_limit(new.store_id);
  return new;
end;
$$;

drop trigger if exists subscriptions_enforce_member_limit
  on public.subscriptions;
create trigger subscriptions_enforce_member_limit
after insert or update of
  plan_id, status, trial_ends_at, current_period_end, source
on public.subscriptions
for each row execute function public.enforce_subscription_member_limit();

drop trigger if exists subscriptions_trim_branches_to_plan
  on public.subscriptions;
create trigger subscriptions_trim_branches_to_plan
after insert or update of
  plan_id, status, trial_ends_at, current_period_end, source
on public.subscriptions
for each row execute function public.trim_branches_to_subscription_limit();

create or replace function public.reconcile_free_plan_grant_limits()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_store_id uuid := case
    when tg_op = 'DELETE' then old.store_id
    else new.store_id
  end;
begin
  if tg_op <> 'DELETE' and new.status = 'active' then
    update public.subscriptions subscription
    set plan_id = 'free',
        status = 'active',
        trial_ends_at = null,
        current_period_start = null,
        current_period_end = null,
        source = 'manual',
        billing_provider = null,
        store_product_id = null,
        billing_cycle = null,
        original_transaction_id = null,
        auto_renews = false,
        last_store_verified_at = null,
        store_environment = null,
        store_entitlement_id = null,
        free_access_mirror = true,
        updated_at = pg_catalog.now()
    where subscription.store_id = target_store_id
      and (
        subscription.source = 'trial'
        or (
          subscription.source = 'manual'
          and subscription.free_access_mirror
        )
        or (
          subscription.source = 'store'
          and subscription.status = 'canceled'
          and (
            subscription.current_period_end is null
            or subscription.current_period_end <= pg_catalog.now()
          )
        )
      );
  elsif tg_op = 'DELETE' or new.status <> 'active' then
    update public.subscriptions subscription
    set plan_id = 'starter',
        status = 'canceled',
        source = 'trial',
        free_access_mirror = false,
        updated_at = pg_catalog.now()
    where subscription.store_id = target_store_id
      and subscription.free_access_mirror;
  end if;

  if public.subscription_is_usable(target_store_id) then
    perform private.ensure_default_store_branch(target_store_id);
    perform private.reconcile_store_member_limit(target_store_id);
    perform private.reconcile_store_branch_limit(target_store_id);
  end if;
  return case when tg_op = 'DELETE' then old else new end;
end;
$$;

drop trigger if exists free_plan_grants_reconcile
  on private.free_plan_grants;
create trigger free_plan_grants_reconcile
after insert or update or delete
on private.free_plan_grants
for each row execute function public.reconcile_free_plan_grant_limits();

create or replace function public.enforce_effective_member_limit_on_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  allowed_members integer;
  active_members integer;
begin
  if new.status <> 'active' then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and old.status = 'active'
     and old.store_id = new.store_id then
    return new;
  end if;
  select plan.max_members
  into allowed_members
  from public.plans plan
  where plan.id = private.effective_store_plan_id(new.store_id);
  if allowed_members is null then
    if new.role = 'owner'
       and exists (
         select 1
         from public.stores store
         where store.id = new.store_id
           and store.owner_id = new.user_id
       )
       and not exists (
         select 1
         from public.store_members member
         where member.store_id = new.store_id
           and member.status = 'active'
       ) then
      return new;
    end if;
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':members', 0)
  );
  select pg_catalog.count(*)
  into active_members
  from public.store_members member
  where member.store_id = new.store_id
    and member.status = 'active'
    and member.user_id <> new.user_id;
  if active_members >= allowed_members then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;
  return new;
end;
$$;

drop trigger if exists store_members_effective_plan_limit
  on public.store_members;
create trigger store_members_effective_plan_limit
before insert or update of status, store_id
on public.store_members
for each row execute function
  public.enforce_effective_member_limit_on_write();

revoke all on function private.reconcile_store_member_limit(uuid)
  from public, anon, authenticated;
revoke all on function private.reconcile_store_branch_limit(uuid)
  from public, anon, authenticated;
revoke all on function public.reconcile_free_plan_grant_limits()
  from public, anon, authenticated;
revoke all on function public.enforce_effective_member_limit_on_write()
  from public, anon, authenticated;

create or replace function public.update_store_member(
  target_store_id uuid,
  target_user_id uuid,
  target_role text,
  target_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_role text;
  existing_role text;
  existing_status text;
  allowed_members integer;
  active_members integer;
begin
  select member.role into caller_role
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = (select auth.uid())
    and member.status = 'active';
  select member.role, member.status into existing_role, existing_status
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = target_user_id;

  if caller_role not in ('owner', 'manager') then
    raise exception 'ROLE_REQUIRED';
  end if;
  if existing_role is null then
    raise exception 'MEMBER_NOT_FOUND';
  end if;
  if target_user_id = (select auth.uid()) or existing_role = 'owner' then
    raise exception 'OWNER_PROTECTED';
  end if;
  if target_role not in ('manager', 'staff')
     or target_status not in ('active', 'suspended') then
    raise exception 'INVALID_MEMBER_UPDATE';
  end if;
  if caller_role = 'manager'
     and (existing_role = 'manager' or target_role = 'manager') then
    raise exception 'OWNER_REQUIRED';
  end if;

  if target_status = 'active' and existing_status <> 'active' then
    select plan.max_members
    into allowed_members
    from public.plans plan
    where plan.id = private.effective_store_plan_id(target_store_id);
    if allowed_members is null then
      raise exception 'SUBSCRIPTION_INACTIVE';
    end if;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(target_store_id::text || ':members', 0)
    );
    select pg_catalog.count(*) into active_members
    from public.store_members member
    where member.store_id = target_store_id
      and member.status = 'active';
    if active_members >= allowed_members then
      raise exception 'SEAT_LIMIT_REACHED';
    end if;
  end if;

  update public.store_members
  set role = target_role,
      status = target_status,
      updated_at = pg_catalog.now()
  where store_id = target_store_id and user_id = target_user_id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  ) values (
    target_store_id,
    (select auth.uid()),
    'member_updated',
    'member',
    target_user_id,
    pg_catalog.jsonb_build_object(
      'role', target_role,
      'status', target_status
    )
  );
end;
$$;

create or replace function public.join_store_by_code(invitation_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  normalized_code text := pg_catalog.upper(
    pg_catalog.btrim(coalesce(invitation_code, ''))
  );
  invite public.invite_codes%rowtype;
  allowed_members integer;
  active_members integer;
  existing_status text;
  attempt private.invite_join_attempts%rowtype;
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into attempt
  from private.invite_join_attempts attempts
  where attempts.user_id = actor
  for update;
  if attempt.blocked_until is not null
     and attempt.blocked_until > pg_catalog.now() then
    return pg_catalog.jsonb_build_object(
      'error', 'INVITE_RATE_LIMITED',
      'retry_after_seconds', greatest(
        1,
        pg_catalog.ceil(extract(
          epoch from attempt.blocked_until - pg_catalog.now()
        ))::integer
      )
    );
  elsif attempt.blocked_until is not null then
    delete from private.invite_join_attempts where user_id = actor;
  end if;

  if normalized_code ~ '^DMN-([A-F0-9]{10}|[A-F0-9]{16}|[A-F0-9]{32})$' then
    select * into invite
    from public.invite_codes
    where code_hash = extensions.digest(normalized_code, 'sha256')
      and is_active
      and expires_at > pg_catalog.now()
      and used_count < max_uses
    for update;
  end if;

  if invite.id is null then
    insert into private.invite_join_attempts as attempts(
      user_id, window_started_at, failed_attempts, blocked_until, updated_at
    ) values (
      actor, pg_catalog.now(), 1, null, pg_catalog.now()
    )
    on conflict (user_id) do update set
      window_started_at = case
        when attempts.window_started_at <=
          pg_catalog.now() - interval '15 minutes'
          then pg_catalog.now()
        else attempts.window_started_at
      end,
      failed_attempts = case
        when attempts.window_started_at <=
          pg_catalog.now() - interval '15 minutes'
          then 1
        else pg_catalog.least(attempts.failed_attempts + 1, 1000)
      end,
      blocked_until = case
        when (
          case
            when attempts.window_started_at <=
              pg_catalog.now() - interval '15 minutes'
              then 1
            else attempts.failed_attempts + 1
          end
        ) >= 10 then pg_catalog.now() + interval '15 minutes'
        else null
      end,
      updated_at = pg_catalog.now()
    returning * into attempt;

    return pg_catalog.jsonb_build_object(
      'error', case
        when attempt.blocked_until is null then 'INVITE_INVALID'
        else 'INVITE_RATE_LIMITED'
      end,
      'retry_after_seconds', case
        when attempt.blocked_until is null then null
        else greatest(
          1,
          pg_catalog.ceil(extract(
            epoch from attempt.blocked_until - pg_catalog.now()
          ))::integer
        )
      end
    );
  end if;

  delete from private.invite_join_attempts where user_id = actor;
  select plan.max_members
  into allowed_members
  from public.plans plan
  where plan.id = private.effective_store_plan_id(invite.store_id);
  if allowed_members is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(invite.store_id::text || ':members', 0)
  );
  select pg_catalog.count(*) into active_members
  from public.store_members member
  where member.store_id = invite.store_id
    and member.status = 'active';
  select member.status into existing_status
  from public.store_members member
  where member.store_id = invite.store_id
    and member.user_id = actor;
  if active_members >= allowed_members
     and coalesce(existing_status, '') <> 'active' then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  insert into public.store_members(store_id, user_id, role, status)
  values (invite.store_id, actor, invite.role, 'active')
  on conflict (store_id, user_id) do update set
    role = excluded.role,
    status = 'active',
    updated_at = pg_catalog.now();
  update public.invite_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = invite.id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id
  ) values (
    invite.store_id, actor, 'member_joined', 'member', actor
  );

  return pg_catalog.jsonb_build_object(
    'store_id', invite.store_id,
    'user_id', actor,
    'role', invite.role,
    'status', 'active'
  );
end;
$$;

revoke all on function public.update_store_member(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.update_store_member(uuid, uuid, text, text)
  to authenticated;
revoke all on function public.join_store_by_code(text)
  from public, anon, authenticated;
grant execute on function public.join_store_by_code(text)
  to authenticated;

create or replace function public.claim_ai_import_job(
  target_store_id uuid,
  target_user_id uuid,
  target_filename text,
  target_mime_type text,
  target_size_bytes bigint,
  target_provider text,
  target_pricing_tier text,
  target_model text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  monthly_limit integer;
  monthly_used integer;
  daily_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role in ('owner', 'manager')
      and member.status = 'active'
  ) then
    raise exception 'IMPORT_MANAGER_REQUIRED';
  end if;
  if target_provider not in ('gemini', 'openai')
     or target_pricing_tier not in ('free', 'paid') then
    raise exception 'AI_PROVIDER_INVALID';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':ai-import', 0)
  );
  select plan.monthly_ai_imports
  into monthly_limit
  from public.plans plan
  where plan.id = private.effective_store_plan_id(target_store_id);
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'AI_IMPORT_NOT_INCLUDED';
  end if;

  select pg_catalog.count(*) into monthly_used
  from public.ai_import_jobs job
  where job.store_id = target_store_id
    and job.created_at >= pg_catalog.date_trunc(
      'month', pg_catalog.now()
    );
  select pg_catalog.count(*) into daily_used
  from public.ai_import_jobs job
  where job.store_id = target_store_id
    and job.created_at >= pg_catalog.now() - interval '24 hours';
  if monthly_used >= monthly_limit then
    raise exception 'AI_IMPORT_MONTHLY_LIMIT';
  end if;
  if daily_used >= 25 then
    raise exception 'AI_IMPORT_DAILY_SAFETY_LIMIT';
  end if;

  insert into public.ai_import_jobs(
    store_id, user_id, status, filename, mime_type, size_bytes,
    provider, pricing_tier, model
  ) values (
    target_store_id,
    target_user_id,
    'started',
    target_filename,
    target_mime_type,
    target_size_bytes,
    target_provider,
    target_pricing_tier,
    target_model
  ) returning id into created_id;

  return pg_catalog.jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;

create or replace function public.claim_ai_claim_review_job(
  target_store_id uuid,
  target_request_id uuid,
  target_user_id uuid,
  target_model text,
  target_include_attachments boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  monthly_limit integer;
  monthly_used integer;
  recent_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role in ('owner', 'manager')
      and member.status = 'active'
  ) or not exists (
    select 1
    from public.maintenance_requests request
    where request.id = target_request_id
      and request.store_id = target_store_id
  ) then
    raise exception 'CLAIM_REVIEW_ACCESS_DENIED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':claim-ai', 0)
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_request_id::text || ':claim-ai', 0)
  );
  select plan.monthly_ai_claim_reviews
  into monthly_limit
  from public.plans plan
  where plan.id = private.effective_store_plan_id(target_store_id);
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'CLAIM_AI_NOT_INCLUDED';
  end if;

  select pg_catalog.count(*) into monthly_used
  from public.ai_claim_reviews review
  where review.store_id = target_store_id
    and review.created_at >= pg_catalog.date_trunc(
      'month', pg_catalog.now()
    );
  select pg_catalog.count(*) into recent_used
  from public.ai_claim_reviews review
  where review.request_id = target_request_id
    and review.created_at >= pg_catalog.now() - interval '10 minutes';
  if monthly_used >= monthly_limit then
    raise exception 'CLAIM_AI_MONTHLY_LIMIT';
  end if;
  if recent_used >= 1 then
    raise exception 'CLAIM_AI_COOLDOWN';
  end if;

  insert into public.ai_claim_reviews(
    store_id,
    request_id,
    user_id,
    status,
    provider,
    model,
    included_attachments
  ) values (
    target_store_id,
    target_request_id,
    target_user_id,
    'started',
    'openai',
    target_model,
    target_include_attachments
  ) returning id into created_id;

  return pg_catalog.jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;

revoke all on function public.claim_ai_import_job(
  uuid, uuid, text, text, bigint, text, text, text
) from public, anon, authenticated;
grant execute on function public.claim_ai_import_job(
  uuid, uuid, text, text, bigint, text, text, text
) to service_role;
revoke all on function public.claim_ai_claim_review_job(
  uuid, uuid, uuid, text, boolean
) from public, anon, authenticated;
grant execute on function public.claim_ai_claim_review_job(
  uuid, uuid, uuid, text, boolean
) to service_role;

create or replace function public.claim_webhook_deliveries(
  requested_limit integer default 25
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  update public.webhook_deliveries delivery
  set status = 'pending',
      locked_at = null
  where delivery.status = 'processing'
    and delivery.locked_at < pg_catalog.now() - interval '15 minutes';

  with selected as (
    select delivery.id
    from public.webhook_deliveries delivery
    join public.store_webhooks hook on hook.id = delivery.webhook_id
    where delivery.status = 'pending'
      and delivery.next_attempt_at <= pg_catalog.now()
      and hook.is_active
      and public.store_plan_allows(delivery.store_id, 'webhook')
    order by delivery.created_at
    for update of delivery skip locked
    limit greatest(1, least(requested_limit, 100))
  ), claimed as (
    update public.webhook_deliveries delivery
    set status = 'processing',
        locked_at = pg_catalog.now()
    from selected
    where delivery.id = selected.id
    returning delivery.*
  )
  select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', claimed.id,
    'event_name', claimed.event_name,
    'payload', claimed.payload,
    'attempts', claimed.attempts,
    'endpoint_url', hook.endpoint_url,
    'signing_secret', hook.signing_secret,
    'is_active', hook.is_active
  ) order by claimed.created_at), '[]'::jsonb)
  into result
  from claimed
  join public.store_webhooks hook on hook.id = claimed.webhook_id;

  return result;
end;
$$;

revoke all on function public.claim_webhook_deliveries(integer)
  from public, anon, authenticated;
grant execute on function public.claim_webhook_deliveries(integer)
  to service_role;

create table if not exists private.store_subscription_refresh_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid not null references public.stores(id) on delete cascade,
  window_started_at timestamptz not null default pg_catalog.now(),
  window_attempts integer not null default 0 check (
    window_attempts between 0 and 6
  ),
  day_started_at date not null default (
    (pg_catalog.now() at time zone 'UTC')::date
  ),
  day_attempts integer not null default 0 check (
    day_attempts between 0 and 24
  ),
  updated_at timestamptz not null default pg_catalog.now(),
  primary key (user_id, store_id)
);

revoke all on table private.store_subscription_refresh_limits
  from public, anon, authenticated;

create or replace function public.reserve_store_subscription_refresh(
  target_store_id uuid,
  target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_time timestamptz := pg_catalog.clock_timestamp();
  current_utc_day date := (request_time at time zone 'UTC')::date;
  limit_row private.store_subscription_refresh_limits%rowtype;
  retry_after integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
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

  insert into private.store_subscription_refresh_limits(
    user_id, store_id, window_started_at, day_started_at
  ) values (
    target_user_id, target_store_id, request_time, current_utc_day
  )
  on conflict (user_id, store_id) do nothing;

  select * into limit_row
  from private.store_subscription_refresh_limits limits
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id
  for update;

  if limit_row.window_started_at <=
    request_time - interval '15 minutes' then
    limit_row.window_started_at := request_time;
    limit_row.window_attempts := 0;
  end if;
  if limit_row.day_started_at <> current_utc_day then
    limit_row.day_started_at := current_utc_day;
    limit_row.day_attempts := 0;
  end if;

  update private.store_subscription_refresh_limits limits
  set window_started_at = limit_row.window_started_at,
      window_attempts = limit_row.window_attempts,
      day_started_at = limit_row.day_started_at,
      day_attempts = limit_row.day_attempts,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  if limit_row.window_attempts >= 6 or limit_row.day_attempts >= 24 then
    retry_after := greatest(
      case when limit_row.window_attempts >= 6 then
        pg_catalog.ceil(extract(epoch from (
          limit_row.window_started_at + interval '15 minutes' - request_time
        )))::integer
      else 0 end,
      case when limit_row.day_attempts >= 24 then
        pg_catalog.ceil(extract(epoch from (
          ((current_utc_day + 1)::timestamp at time zone 'UTC') - request_time
        )))::integer
      else 0 end,
      1
    );
    return pg_catalog.jsonb_build_object(
      'allowed', false,
      'retry_after_seconds', retry_after
    );
  end if;

  update private.store_subscription_refresh_limits limits
  set window_attempts = window_attempts + 1,
      day_attempts = day_attempts + 1,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  return pg_catalog.jsonb_build_object(
    'allowed', true,
    'window_remaining', 5 - limit_row.window_attempts,
    'day_remaining', 23 - limit_row.day_attempts
  );
end;
$$;

revoke all on function public.reserve_store_subscription_refresh(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.reserve_store_subscription_refresh(uuid, uuid)
  to service_role;

-- The lifecycle migration deliberately stretched Sandbox access for App
-- Review. A terminal provider state must now remain terminal; otherwise an
-- expired or canceled receipt can reappear as an active subscription during
-- an explicit TestFlight window.
create or replace function public.apply_verified_sandbox_terminal_entitlement(
  target_store_id uuid,
  target_user_id uuid,
  billing_platform text,
  external_transaction_id text,
  external_original_transaction_id text,
  entitlement_status text,
  entitlement_period_start timestamptz,
  entitlement_period_end timestamptz,
  entitlement_auto_renews boolean
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  entitlement_row public.store_entitlements%rowtype;
  subscription_row public.subscriptions%rowtype;
  normalized_status text;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if billing_platform <> 'app_store'
     or entitlement_status not in (
       'past_due', 'canceled', 'expired', 'revoked'
     )
     or nullif(pg_catalog.btrim(external_transaction_id), '') is null
     or nullif(
       pg_catalog.btrim(external_original_transaction_id), ''
     ) is null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_store_id::text || ':store-subscription',
      0
    )
  );
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
  into entitlement_row
  from public.store_entitlements entitlement
  where entitlement.store_id = target_store_id
    and entitlement.user_id = target_user_id
    and entitlement.platform = billing_platform
    and entitlement.original_transaction_id =
      external_original_transaction_id
    and entitlement.superseded_at is null
  for update;
  if not found then
    -- A terminal receipt never creates ownership or moves a lineage. There is
    -- no entitlement to grant, so the caller may safely report not entitled.
    return false;
  end if;
  if entitlement_row.environment = 'production' then
    raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
  end if;

  update public.store_entitlements entitlement
  set transaction_id = external_transaction_id,
      status = entitlement_status,
      environment = 'sandbox',
      period_start = entitlement_period_start,
      period_end = entitlement_period_end,
      auto_renews = entitlement_auto_renews,
      verified_at = pg_catalog.now(),
      next_verification_at = pg_catalog.now() + interval '100 years',
      refresh_locked_at = null,
      refresh_failures = 0,
      updated_at = pg_catalog.now()
  where entitlement.id = entitlement_row.id;

  normalized_status := case
    when entitlement_status = 'past_due' then 'past_due'
    else 'canceled'
  end;
  select *
  into subscription_row
  from public.subscriptions subscription
  where subscription.store_id = target_store_id
  for update;
  if subscription_row.store_entitlement_id = entitlement_row.id
     or (
       subscription_row.source = 'store'
       and subscription_row.billing_provider = billing_platform
       and subscription_row.original_transaction_id =
         external_original_transaction_id
     ) then
    update public.subscriptions subscription
    set status = normalized_status,
        trial_ends_at = null,
        current_period_start = entitlement_period_start,
        current_period_end = entitlement_period_end,
        source = 'store',
        billing_provider = billing_platform,
        original_transaction_id = external_original_transaction_id,
        store_environment = 'sandbox',
        store_entitlement_id = entitlement_row.id,
        auto_renews = entitlement_auto_renews,
        last_store_verified_at = pg_catalog.now(),
        updated_at = pg_catalog.now()
    where subscription.id = subscription_row.id;
  end if;

  insert into public.audit_logs(
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    target_store_id,
    target_user_id,
    'sandbox_subscription_terminal_verified',
    'store_entitlement',
    entitlement_row.id,
    pg_catalog.jsonb_build_object(
      'platform', billing_platform,
      'status', entitlement_status,
      'lineage_retained', true
    )
  );
  return true;
end;
$$;

revoke all on function public.apply_verified_sandbox_terminal_entitlement(
  uuid, uuid, text, text, text, text, timestamptz, timestamptz, boolean
) from public, anon, authenticated;
grant execute on function public.apply_verified_sandbox_terminal_entitlement(
  uuid, uuid, text, text, text, text, timestamptz, timestamptz, boolean
) to service_role;

create or replace function public.schedule_reverified_store_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.verified_at is distinct from old.verified_at
     or new.status is distinct from old.status then
    new.refresh_locked_at := null;
    new.refresh_failures := 0;
    new.next_verification_at := case
      when new.status in ('active', 'grace')
        or (
          new.status = 'past_due'
          and new.environment = 'production'
        )
        then pg_catalog.now() + interval '5 minutes'
      else pg_catalog.now() + interval '100 years'
    end;
  end if;
  return new;
end;
$$;

drop trigger if exists store_entitlements_schedule_after_verification
  on public.store_entitlements;
create trigger store_entitlements_schedule_after_verification
before update of status, verified_at
on public.store_entitlements
for each row execute function public.schedule_reverified_store_entitlement();

revoke all on function public.schedule_reverified_store_entitlement()
  from public, anon, authenticated;

drop trigger if exists subscriptions_prevent_active_store_plan_downgrade
  on public.subscriptions;
drop function if exists public.prevent_active_store_plan_downgrade();

-- منع الخفض قرار شراء في Flutter وخدمة Billing قبل فتح المتجر. لا يملك
-- authenticated UPDATE على subscriptions. أما إيصال صحيح أعاده Apple/Google
-- بعد تغيير خارجي فيجب أن يُصالح كما هو؛ trigger على الجدول كان سيمنع مسار
-- التحقق الموثق ويترك مزايا أعلى مقابل سعر أدنى.

-- Reset legacy trials and Apple Sandbox billing only. Google Play lineage is
-- intentionally preserved: clearing its current receipt pointer would make the
-- existing predecessor/token CAS reject a legitimate restore. Production,
-- manual, and activation-code access are preserved. Apple security lineage is
-- retained as a revoked tombstone so an old receipt cannot silently move.
do $$
declare
  locked_store record;
begin
  for locked_store in
    select distinct affected.store_id
    from (
      select entitlement.store_id
      from public.store_entitlements entitlement
      where entitlement.environment = 'sandbox'
        and entitlement.platform = 'app_store'
      union
      select subscription.store_id
      from public.subscriptions subscription
      where subscription.source = 'trial'
         or (
            subscription.source = 'store'
            and subscription.store_environment = 'sandbox'
            and subscription.billing_provider = 'app_store'
         )
    ) affected
    order by affected.store_id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        locked_store.store_id::text || ':store-subscription',
        0
      )
    );
  end loop;
end;
$$;

update private.store_sandbox_review_windows review
set revoked_at = pg_catalog.now()
where review.platform = 'app_store'
  and review.revoked_at is null;

delete from private.store_sandbox_testers tester
where tester.platform = 'app_store';
insert into private.store_sandbox_testers(
  store_id,
  user_id,
  platform,
  expires_at,
  created_at,
  note
)
select
  entitlement.store_id,
  store.owner_id,
  'app_store',
  pg_catalog.now() + interval '24 hours',
  pg_catalog.now(),
  'Build 30 bounded tester retained from the latest active Apple Sandbox entitlement after the audited reset.'
from public.store_entitlements entitlement
join public.stores store on store.id = entitlement.store_id
join public.store_members owner_member
  on owner_member.store_id = store.id
 and owner_member.user_id = store.owner_id
 and owner_member.role = 'owner'
 and owner_member.status = 'active'
where entitlement.environment = 'sandbox'
  and entitlement.platform = 'app_store'
  and entitlement.status in ('active', 'grace', 'past_due')
  and entitlement.superseded_at is null
order by entitlement.verified_at desc, entitlement.id
limit 1;

insert into public.audit_logs(
  store_id,
  user_id,
  action,
  entity_type,
  entity_id,
  metadata
)
select
  entitlement.store_id,
  entitlement.user_id,
  'sandbox_entitlement_reset',
  'store_entitlement',
  entitlement.id,
  pg_catalog.jsonb_build_object(
    'platform', entitlement.platform,
    'plan_id', entitlement.plan_id,
    'billing_cycle', entitlement.billing_cycle,
    'previous_status', entitlement.status,
    'environment', entitlement.environment,
    'lineage_retained', true
  )
from public.store_entitlements entitlement
where entitlement.environment = 'sandbox'
  and entitlement.platform = 'app_store';

insert into public.audit_logs(
  store_id,
  user_id,
  action,
  entity_type,
  entity_id,
  metadata
)
select
  subscription.store_id,
  store.owner_id,
  'subscription_state_reset',
  'subscription',
  subscription.id,
  pg_catalog.jsonb_build_object(
    'previous_source', subscription.source,
    'previous_plan_id', subscription.plan_id,
    'previous_status', subscription.status,
    'previous_environment', subscription.store_environment,
    'previous_billing_provider', subscription.billing_provider,
    'replacement', 'free_eligibility_pending_device'
  )
from public.subscriptions subscription
join public.stores store on store.id = subscription.store_id
where subscription.source = 'trial'
   or (
     subscription.source = 'store'
     and subscription.store_environment = 'sandbox'
     and subscription.billing_provider = 'app_store'
   );

update public.store_entitlements entitlement
set status = 'revoked',
    period_end = least(
      coalesce(entitlement.period_end, pg_catalog.now()),
      pg_catalog.now()
    ),
    auto_renews = false,
    next_verification_at = pg_catalog.now() + interval '100 years',
    refresh_locked_at = null,
    refresh_failures = 0,
    updated_at = pg_catalog.now()
where entitlement.environment = 'sandbox'
  and entitlement.platform = 'app_store';

update public.subscriptions subscription
set plan_id = 'starter',
    status = 'canceled',
    trial_ends_at = null,
    current_period_start = null,
    current_period_end = null,
    source = 'trial',
    billing_provider = null,
    store_product_id = null,
    billing_cycle = null,
    original_transaction_id = null,
    auto_renews = false,
    last_store_verified_at = null,
    store_environment = null,
    store_entitlement_id = null,
    updated_at = pg_catalog.now()
where subscription.source = 'trial'
   or (
     subscription.source = 'store'
     and subscription.store_environment = 'sandbox'
     and subscription.billing_provider = 'app_store'
   );

-- لا تصلح صفوف manual/activation_code غير المتسقة بصمت؛ قد تمثل وصولاً
-- إنتاجياً أو Google خارج نطاق تنظيف Apple Sandbox. إن وُجدت حالة قديمة
-- كهذه تفشل migration كلها وتحتاج مراجعة صفية صريحة قبل إعادة النشر.
do $$
begin
  if exists (
    select 1
    from public.subscriptions subscription
    where subscription.source in ('manual', 'activation_code')
      and (
        subscription.billing_provider is not null
        or subscription.store_product_id is not null
        or subscription.billing_cycle is not null
        or subscription.original_transaction_id is not null
        or subscription.auto_renews
        or subscription.last_store_verified_at is not null
        or subscription.store_environment is not null
        or subscription.store_entitlement_id is not null
      )
  ) then
    raise exception 'NON_STORE_BILLING_METADATA_REQUIRES_REVIEW';
  end if;
end;
$$;

alter table public.subscriptions
  drop constraint if exists subscriptions_non_store_metadata_clean_check;
alter table public.subscriptions
  add constraint subscriptions_non_store_metadata_clean_check check (
    source = 'store'
    or (
      billing_provider is null
      and store_product_id is null
      and billing_cycle is null
      and original_transaction_id is null
      and not auto_renews
      and last_store_verified_at is null
      and store_environment is null
      and store_entitlement_id is null
    )
  ) not valid;
alter table public.subscriptions
  validate constraint subscriptions_non_store_metadata_clean_check;

-- لا تمسح عدادات الحماية عند إصلاح حالة Apple الاختبارية. عداد الشراء
-- مشترك مع الإنتاج وGoogle، وجدول التحديث الجديد يبدأ فارغاً بطبيعته؛ مسحهما
-- يفتح نافذة تجاوز مؤقتة لمتاجر لا علاقة لها بعملية الإصلاح.

with owner_stores as (
  select
    store.id as store_id,
    extensions.digest(
      'damanak:free-account:v1:' || store.owner_id::text,
      'sha256'
    ) as account_hash,
    pg_catalog.row_number() over (
      partition by store.owner_id
      order by store.created_at, store.id
    ) as store_position
  from public.stores store
  where exists (
    select 1
    from public.store_members member
    where member.store_id = store.id
      and member.user_id = store.owner_id
      and member.role = 'owner'
      and member.status = 'active'
  )
)
insert into private.free_account_claims(account_hash)
select owner.account_hash
from owner_stores owner
where owner.store_position = 1
on conflict (account_hash) do update
set last_seen_at = pg_catalog.now();

with owner_stores as (
  select
    store.id as store_id,
    extensions.digest(
      'damanak:free-account:v1:' || store.owner_id::text,
      'sha256'
    ) as account_hash,
    pg_catalog.row_number() over (
      partition by store.owner_id
      order by store.created_at, store.id
    ) as store_position
  from public.stores store
  where exists (
    select 1
    from public.store_members member
    where member.store_id = store.id
      and member.user_id = store.owner_id
      and member.role = 'owner'
      and member.status = 'active'
  )
)
insert into private.free_plan_grants(store_id, account_hash)
select owner.store_id, owner.account_hash
from owner_stores owner
where owner.store_position = 1
on conflict do nothing;

update public.webhook_deliveries delivery
set status = 'failed',
    locked_at = null,
    last_error = 'WEBHOOK_PLAN_NOT_INCLUDED'
where delivery.status in ('pending', 'processing')
  and not public.store_plan_allows(delivery.store_id, 'webhook');

do $$
declare
  active_grant record;
begin
  for active_grant in
    select grant_row.store_id
    from private.free_plan_grants grant_row
    where grant_row.status = 'active'
  loop
    perform private.ensure_default_store_branch(active_grant.store_id);
    perform private.reconcile_store_member_limit(active_grant.store_id);
    perform private.reconcile_store_branch_limit(active_grant.store_id);
  end loop;
end;
$$;

comment on function public.reserve_store_subscription_refresh(uuid, uuid) is
  'Separate owner refresh limiter: 6 attempts per 15 minutes and 24 per UTC day. It never consumes the receipt-verification allowance.';
comment on constraint subscriptions_non_store_metadata_clean_check
  on public.subscriptions is
  'Non-store access may have its own period but never carries App Store or Google Play receipt metadata.';
