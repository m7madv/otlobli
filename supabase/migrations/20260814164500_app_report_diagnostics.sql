-- Optional online diagnostics extend the existing private report inbox. Visual
-- Android shake reports remain compatible; iOS and Android may now submit a
-- consented, sanitized event trace without a screenshot.
alter table public.app_issue_reports
  alter column screenshot_path set default '';

alter table public.app_issue_reports
  add column if not exists report_kind text not null default 'visual',
  add column if not exists diagnostics jsonb not null default '{}'::jsonb;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'app_issue_reports_report_kind_check'
      and conrelid = 'public.app_issue_reports'::regclass
  ) then
    alter table public.app_issue_reports
      add constraint app_issue_reports_report_kind_check
      check (report_kind in ('visual', 'diagnostic'));
  end if;
end $$;
