-- AI document imports are review-only and keep an auditable cost record.

create table if not exists public.ai_import_jobs (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  status text not null check (status in ('started', 'completed', 'failed')),
  filename text not null check (char_length(filename) between 1 and 180),
  mime_type text not null check (mime_type in (
    'application/pdf', 'image/jpeg', 'image/png', 'image/webp'
  )),
  size_bytes bigint not null check (size_bytes between 1 and 8388608),
  model text not null,
  input_tokens integer check (input_tokens is null or input_tokens >= 0),
  output_tokens integer check (output_tokens is null or output_tokens >= 0),
  estimated_cost_usd numeric(12, 6)
    check (estimated_cost_usd is null or estimated_cost_usd >= 0),
  product_count integer not null default 0 check (product_count between 0 and 100),
  error_code text,
  created_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists ai_import_jobs_store_created_idx
on public.ai_import_jobs(store_id, created_at desc);

alter table public.ai_import_jobs enable row level security;

create policy ai_import_jobs_select_managers
on public.ai_import_jobs for select to authenticated
using (public.has_store_role(store_id, array['owner', 'manager']));

revoke all on table public.ai_import_jobs from anon, authenticated;
grant select on table public.ai_import_jobs to authenticated;
