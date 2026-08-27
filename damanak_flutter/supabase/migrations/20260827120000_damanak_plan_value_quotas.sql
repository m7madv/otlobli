-- Raise only the published warranty quotas. Store pricing, product mappings,
-- member limits, and subscription eligibility remain unchanged.
do $$
declare
  configured_plan_count integer;
begin
  update public.plans
  set monthly_warranties = case id
    when 'starter' then 100
    when 'growth' then 600
    when 'scale' then 3000
    else monthly_warranties
  end
  where id in ('starter', 'growth', 'scale')
    and monthly_warranties is distinct from case id
      when 'starter' then 100
      when 'growth' then 600
      when 'scale' then 3000
      else monthly_warranties
    end;

  select count(*) into configured_plan_count
  from public.plans
  where (id = 'starter' and monthly_warranties = 100)
     or (id = 'growth' and monthly_warranties = 600)
     or (id = 'scale' and monthly_warranties = 3000);

  if configured_plan_count <> 3 then
    raise exception 'DAMANAK_PLAN_QUOTAS_INCOMPLETE';
  end if;
end;
$$;

-- A seven-day subscription grace would disagree with the renewal state
-- verified by App Store or Google Play. Keep eligibility strict and grant a
-- deterministic 10% operational buffer above the published monthly quota.
create or replace function public.enforce_warranty_entitlement()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  included_limit integer;
  effective_limit integer;
  used_count bigint;
begin
  if not public.subscription_is_usable(new.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  -- Serialize inserts for one store so concurrent sales cannot race past the
  -- effective limit. Different stores keep processing independently.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text, 0)
  );

  select plans.monthly_warranties into included_limit
  from public.subscriptions
  join public.plans on plans.id = subscriptions.plan_id
  where subscriptions.store_id = new.store_id;

  if included_limit is null then
    raise exception 'SUBSCRIPTION_PLAN_NOT_FOUND';
  end if;

  effective_limit := included_limit
    + ceil(included_limit::numeric * 0.10)::integer;

  select count(*) into used_count
  from public.warranties
  where store_id = new.store_id
    and voided_at is null
    and created_at >= date_trunc('month', now());

  if used_count >= effective_limit then
    raise exception 'WARRANTY_LIMIT_REACHED';
  end if;

  if new.warranty_number is null or new.warranty_number = '' then
    new.warranty_number := 'DMN-' || to_char(now(), 'YYMM') || '-' ||
      upper(substr(replace(new.id::text, '-', ''), 1, 8));
  end if;
  return new;
end;
$$;
