create table if not exists public.support_requests (
  id uuid primary key default gen_random_uuid(),
  email text not null check (char_length(email) between 6 and 254),
  category text not null check (category in ('account', 'audio', 'billing', 'privacy', 'other')),
  subject text not null check (char_length(subject) between 3 and 120),
  message text not null check (char_length(message) between 20 and 4000),
  language text not null default 'en' check (language in ('en', 'ar')),
  request_key_hash text not null check (char_length(request_key_hash) = 64),
  status text not null default 'new' check (status in ('new', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.support_requests enable row level security;

revoke all on table public.support_requests from anon, authenticated;
grant all on table public.support_requests to service_role;

create index if not exists support_requests_status_created_idx
  on public.support_requests (status, created_at desc);

create index if not exists support_requests_rate_limit_idx
  on public.support_requests (request_key_hash, created_at desc);
