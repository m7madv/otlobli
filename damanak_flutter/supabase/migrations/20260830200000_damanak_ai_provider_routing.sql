-- Cost-bounded AI routing. Product catalog documents may use Gemini first;
-- customer claim data is deliberately outside this function and entitlement.

alter table public.plans
  add column if not exists monthly_ai_imports integer not null default 0,
  add column if not exists max_branches integer not null default 1,
  add column if not exists api_access boolean not null default false,
  add column if not exists webhook_access boolean not null default false,
  add column if not exists custom_branding boolean not null default false;

alter table public.plans drop constraint if exists plans_monthly_ai_imports_check;
alter table public.plans add constraint plans_monthly_ai_imports_check
  check (monthly_ai_imports between 0 and 10000);
alter table public.plans drop constraint if exists plans_max_branches_check;
alter table public.plans add constraint plans_max_branches_check
  check (max_branches between 1 and 1000);

update public.plans
set
  monthly_ai_imports = case id
    when 'starter' then 10
    when 'growth' then 100
    when 'scale' then 500
    else monthly_ai_imports
  end,
  max_branches = case id
    when 'starter' then 1
    when 'growth' then 3
    when 'scale' then 20
    else max_branches
  end,
  api_access = id = 'scale',
  webhook_access = id = 'scale',
  custom_branding = id in ('growth', 'scale')
where id in ('starter', 'growth', 'scale');

alter table public.ai_import_jobs
  add column if not exists provider text not null default 'openai',
  add column if not exists pricing_tier text not null default 'paid',
  add column if not exists fallback_used boolean not null default false,
  add column if not exists provider_attempts integer not null default 1;

alter table public.ai_import_jobs
  drop constraint if exists ai_import_jobs_provider_check;
alter table public.ai_import_jobs
  add constraint ai_import_jobs_provider_check
    check (provider in ('gemini', 'openai'));

alter table public.ai_import_jobs
  drop constraint if exists ai_import_jobs_pricing_tier_check;
alter table public.ai_import_jobs
  add constraint ai_import_jobs_pricing_tier_check
    check (pricing_tier in ('free', 'paid'));

alter table public.ai_import_jobs
  drop constraint if exists ai_import_jobs_provider_attempts_check;
alter table public.ai_import_jobs
  add constraint ai_import_jobs_provider_attempts_check
    check (provider_attempts between 1 and 2);

comment on column public.plans.monthly_ai_imports is
  'Server-enforced monthly allowance for review-only product catalog extraction.';

create or replace function public.enforce_branch_entitlement()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare branch_limit integer; current_count integer;
begin
  select plan.max_branches into branch_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id
    and subscription.status in ('trialing', 'active');
  if branch_limit is null then raise exception 'SUBSCRIPTION_INACTIVE'; end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  select count(*) into current_count from public.branches
  where store_id = new.store_id and is_active;
  if current_count >= branch_limit then raise exception 'BRANCH_LIMIT_REACHED'; end if;
  return new;
end;
$$;

drop trigger if exists branches_entitlement on public.branches;
create trigger branches_entitlement before insert on public.branches
for each row execute function public.enforce_branch_entitlement();

revoke all on function public.enforce_branch_entitlement() from public;
comment on column public.ai_import_jobs.provider is
  'Final provider that produced the review-only extraction; document contents are never logged.';
