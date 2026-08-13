-- In-app shake reports: private screenshot storage plus an admin-managed inbox.
create table if not exists public.app_issue_reports (
  id uuid primary key default gen_random_uuid(),
  note text not null check (char_length(note) between 3 and 800),
  screenshot_path text not null,
  device_id text not null default '',
  customer_phone text not null default '',
  customer_name text not null default '',
  screen text not null default '',
  store text not null default '',
  app_version text not null default '',
  platform text not null default '',
  device_model text not null default '',
  status text not null default 'new' check (status in ('new', 'in_review', 'resolved')),
  admin_note text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists app_issue_reports_created_at_idx
  on public.app_issue_reports (created_at desc);
create index if not exists app_issue_reports_status_idx
  on public.app_issue_reports (status, created_at desc);

alter table public.app_issue_reports enable row level security;

-- Screenshots are never public. The app-reports edge function uses the service
-- role and the admin endpoint returns short-lived signed URLs only.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'app-issue-reports',
  'app-issue-reports',
  false,
  1572864,
  array['image/jpeg', 'image/png', 'image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

