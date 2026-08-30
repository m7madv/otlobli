-- On-demand claim triage. This produces a review aid only and cannot change a
-- claim status, accept, reject, or contact the customer.

alter table public.plans
  add column if not exists monthly_ai_claim_reviews integer not null default 0;
alter table public.plans drop constraint if exists plans_monthly_ai_claim_reviews_check;
alter table public.plans add constraint plans_monthly_ai_claim_reviews_check
  check (monthly_ai_claim_reviews between 0 and 10000);
update public.plans set monthly_ai_claim_reviews = case id
  when 'starter' then 5
  when 'growth' then 50
  when 'scale' then 250
  else monthly_ai_claim_reviews end
where id in ('starter', 'growth', 'scale');

create table if not exists public.ai_claim_reviews (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  request_id uuid not null references public.maintenance_requests(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  status text not null check (status in ('started', 'completed', 'failed')),
  provider text not null default 'openai' check (provider = 'openai'),
  model text not null,
  included_attachments boolean not null default false,
  input_tokens integer check (input_tokens is null or input_tokens >= 0),
  output_tokens integer check (output_tokens is null or output_tokens >= 0),
  estimated_cost_usd numeric(12, 6)
    check (estimated_cost_usd is null or estimated_cost_usd >= 0),
  result jsonb,
  error_code text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists ai_claim_reviews_store_created_idx
  on public.ai_claim_reviews(store_id, created_at desc);
create index if not exists ai_claim_reviews_request_created_idx
  on public.ai_claim_reviews(request_id, created_at desc);

alter table public.ai_claim_reviews enable row level security;
create policy ai_claim_reviews_select_managers
on public.ai_claim_reviews for select to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

revoke all on table public.ai_claim_reviews from anon, authenticated;
grant select on table public.ai_claim_reviews to authenticated;

comment on table public.ai_claim_reviews is
  'Manager-triggered review aids. Never grants automated claim decisions.';
