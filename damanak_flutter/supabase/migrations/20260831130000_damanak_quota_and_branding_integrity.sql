-- Quotas count issued business records, not only records that remain active.
-- Activation paths are checked on both INSERT and UPDATE, and plan branding
-- cannot survive as a public paid feature after entitlement loss.

create or replace function public.enforce_warranty_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
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

  if not public.subscription_is_usable(new.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':warranties', 0)
  );

  select plan.monthly_warranties
  into included_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id;
  if included_limit is null then
    raise exception 'SUBSCRIPTION_PLAN_NOT_FOUND';
  end if;

  effective_limit := included_limit
    + pg_catalog.ceil(included_limit::numeric * 0.10)::integer;

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

drop policy if exists warranties_delete_managers on public.warranties;
revoke delete on table public.warranties from authenticated;

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
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id
    and public.subscription_is_usable(new.store_id);
  if branch_limit is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select count(*)
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

drop trigger if exists branches_entitlement on public.branches;
create trigger branches_entitlement
before insert or update of is_active, store_id on public.branches
for each row execute function public.enforce_branch_entitlement();

create or replace function public.trim_branches_to_subscription_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  branch_limit integer;
begin
  if not public.subscription_is_usable(new.store_id) then
    return new;
  end if;
  select plan.max_branches
  into branch_limit
  from public.plans plan
  where plan.id = new.plan_id;
  if branch_limit is null then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  with ranked as (
    select
      branch.id,
      pg_catalog.row_number() over (
        order by branch.is_main desc, branch.created_at, branch.id
      ) as position
    from public.branches branch
    where branch.store_id = new.store_id
      and branch.is_active
  )
  update public.branches branch
  set is_active = false,
      updated_at = pg_catalog.now()
  from ranked
  where branch.id = ranked.id
    and ranked.position > branch_limit;
  return new;
end;
$$;

drop trigger if exists subscriptions_trim_branches_to_plan
  on public.subscriptions;
create trigger subscriptions_trim_branches_to_plan
after insert or update of plan_id, status, trial_ends_at, current_period_end
on public.subscriptions
for each row execute function public.trim_branches_to_subscription_limit();

create or replace function public.enforce_usable_subscription_for_core_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_store_id uuid;
  actor_role text := coalesce((select auth.role()), '');
begin
  if actor_role in ('', 'service_role') then
    return new;
  end if;
  if actor_role <> 'authenticated' then
    raise exception 'AUTH_REQUIRED';
  end if;
  if current_setting('damanak.write_context', true) = 'return_sale' then
    return new;
  end if;
  if tg_table_name = 'register_sessions' and tg_op = 'UPDATE'
     and to_jsonb(old)->>'status' = 'open'
     and to_jsonb(new)->>'status' = 'closed'
     and to_jsonb(new)->>'id' = to_jsonb(old)->>'id'
     and to_jsonb(new)->>'store_id' = to_jsonb(old)->>'store_id'
     and to_jsonb(new)->>'branch_id' = to_jsonb(old)->>'branch_id'
     and to_jsonb(new)->>'opened_by' = to_jsonb(old)->>'opened_by'
     and to_jsonb(new)->>'opened_at' = to_jsonb(old)->>'opened_at' then
    return new;
  end if;
  target_store_id := nullif(to_jsonb(new)->>'store_id', '')::uuid;
  if target_store_id is null then
    raise exception 'STORE_REQUIRED';
  end if;
  if not public.subscription_is_usable(target_store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  return new;
end;
$$;

create or replace function public.enforce_store_branding_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  branding_changed boolean;
  clearing_branding boolean;
begin
  branding_changed :=
    new.logo_url is distinct from old.logo_url
    or new.brand_color is distinct from old.brand_color
    or new.customer_portal_title is distinct from old.customer_portal_title
    or new.warranty_policy is distinct from old.warranty_policy
    or new.warranty_exclusions is distinct from old.warranty_exclusions;
  clearing_branding :=
    new.logo_url = ''
    and new.brand_color = '#087F5B'
    and new.customer_portal_title = 'بطاقة ضمان موثّقة'
    and new.warranty_policy = ''
    and new.warranty_exclusions = '';
  if branding_changed
     and not clearing_branding
     and not public.store_plan_allows(new.id, 'branding') then
    raise exception 'PLAN_BRANDING_REQUIRED';
  end if;
  return new;
end;
$$;

drop trigger if exists stores_branding_entitlement on public.stores;
create trigger stores_branding_entitlement
before update of
  logo_url, brand_color, customer_portal_title,
  warranty_policy, warranty_exclusions
on public.stores
for each row execute function public.enforce_store_branding_entitlement();

create or replace function public.enforce_product_branding_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  policy_requested boolean :=
    pg_catalog.btrim(coalesce(new.warranty_policy, '')) <> ''
    or pg_catalog.btrim(coalesce(new.warranty_exclusions, '')) <> '';
  policy_changed boolean := tg_op = 'INSERT' or (
    new.warranty_policy is distinct from old.warranty_policy
    or new.warranty_exclusions is distinct from old.warranty_exclusions
  );
begin
  if policy_requested
     and policy_changed
     and not public.store_plan_allows(new.store_id, 'branding') then
    raise exception 'PLAN_BRANDING_REQUIRED';
  end if;
  return new;
end;
$$;

drop trigger if exists products_branding_entitlement on public.products;
create trigger products_branding_entitlement
before insert or update of warranty_policy, warranty_exclusions
on public.products
for each row execute function public.enforce_product_branding_entitlement();

revoke all on function public.enforce_warranty_entitlement()
  from public, anon, authenticated;
revoke all on function public.enforce_branch_entitlement()
  from public, anon, authenticated;
revoke all on function public.trim_branches_to_subscription_limit()
  from public, anon, authenticated;
revoke all on function public.enforce_usable_subscription_for_core_write()
  from public, anon, authenticated;
revoke all on function public.enforce_store_branding_entitlement()
  from public, anon, authenticated;
revoke all on function public.enforce_product_branding_entitlement()
  from public, anon, authenticated;

revoke all on function public.return_sale(uuid, uuid, jsonb, text, text)
  from public, anon, authenticated;
grant execute on function public.return_sale(uuid, uuid, jsonb, text, text)
  to authenticated;
