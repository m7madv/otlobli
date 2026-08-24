begin;

create extension if not exists pgcrypto;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subscription_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  entitlement text not null default 'free' check (entitlement in ('free', 'pro')),
  product_id text,
  store text,
  expires_at timestamptz,
  revenuecat_event_id text,
  revenuecat_event_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.usage_periods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  period_key text not null,
  plan text not null check (plan in ('free', 'pro')),
  starts_at timestamptz not null,
  ends_at timestamptz,
  quota_minutes integer not null check (quota_minutes >= 0),
  used_minutes integer not null default 0 check (used_minutes >= 0),
  reserved_minutes integer not null default 0 check (reserved_minutes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, period_key),
  check (used_minutes + reserved_minutes <= quota_minutes)
);

create table public.service_budget_months (
  period_key text primary key check (period_key ~ '^[0-9]{4}-[0-9]{2}$'),
  max_audio_minutes integer not null default 500 check (max_audio_minutes > 0),
  used_audio_minutes integer not null default 0 check (used_audio_minutes >= 0),
  reserved_audio_minutes integer not null default 0 check (reserved_audio_minutes >= 0),
  updated_at timestamptz not null default now(),
  check (used_audio_minutes + reserved_audio_minutes <= max_audio_minutes)
);

create table public.processing_jobs (
  id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  usage_period_id uuid references public.usage_periods(id) on delete set null,
  service_budget_period_key text references public.service_budget_months(period_key),
  status text not null check (status in ('reserving', 'processing', 'completed', 'failed')),
  storage_path text not null,
  duration_seconds integer not null check (duration_seconds > 0),
  billed_minutes integer not null check (billed_minutes > 0),
  ai_started boolean not null default false,
  result jsonb,
  error_code text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  primary key (user_id, id)
);

create table public.usage_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  job_id uuid not null,
  usage_period_id uuid not null references public.usage_periods(id) on delete cascade,
  kind text not null check (kind in ('reserve', 'charge', 'refund')),
  minutes integer not null check (minutes > 0),
  created_at timestamptz not null default now(),
  unique (user_id, job_id, kind),
  foreign key (user_id, job_id) references public.processing_jobs(user_id, id) on delete cascade
);

create table public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  status text not null default 'requested' check (status in ('requested', 'completed', 'failed'))
);

create table public.support_requests (
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

create table public.revenuecat_webhook_events (
  event_id text primary key,
  event_type text not null,
  app_user_id uuid,
  received_at timestamptz not null default now()
);

create index processing_jobs_expires_idx on public.processing_jobs(expires_at);
create index usage_periods_user_active_idx on public.usage_periods(user_id, starts_at desc);
create index support_requests_status_created_idx on public.support_requests(status, created_at desc);
create index support_requests_rate_limit_idx on public.support_requests(request_key_hash, created_at desc);

alter table public.profiles enable row level security;
alter table public.subscription_state enable row level security;
alter table public.usage_periods enable row level security;
alter table public.service_budget_months enable row level security;
alter table public.processing_jobs enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
alter table public.support_requests enable row level security;

revoke all on table public.support_requests from anon, authenticated;
grant all on table public.support_requests to service_role;

create policy "profiles_read_own" on public.profiles for select
  using (auth.uid() = user_id);
create policy "subscription_read_own" on public.subscription_state for select
  using (auth.uid() = user_id);
create policy "usage_periods_read_own" on public.usage_periods for select
  using (auth.uid() = user_id);
create policy "jobs_read_own" on public.processing_jobs for select
  using (auth.uid() = user_id);
create policy "ledger_read_own" on public.usage_ledger for select
  using (auth.uid() = user_id);
create policy "deletion_request_read_own" on public.account_deletion_requests for select
  using (auth.uid() = user_id);

create or replace function public.handle_voicebrief_user_created()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(user_id) values (new.id) on conflict do nothing;
  insert into public.subscription_state(user_id) values (new.id) on conflict do nothing;
  insert into public.usage_periods(
    user_id, period_key, plan, starts_at, ends_at, quota_minutes
  ) values (
    new.id, 'free-lifetime', 'free', now(), null, 10
  ) on conflict do nothing;
  return new;
end;
$$;

create trigger on_voicebrief_auth_user_created
after insert on auth.users
for each row execute function public.handle_voicebrief_user_created();

create or replace function public.reserve_voicebrief_minutes(
  p_user_id uuid,
  p_job_id uuid,
  p_storage_path text,
  p_duration_seconds integer
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := p_user_id;
  v_job public.processing_jobs%rowtype;
  v_period public.usage_periods%rowtype;
  v_budget public.service_budget_months%rowtype;
  v_budget_period_key text := to_char(timezone('UTC', now()), 'YYYY-MM');
  v_minutes integer;
begin
  if v_user_id is null then raise exception 'invalid_user'; end if;
  if p_duration_seconds <= 0 or p_duration_seconds > 21600 then
    raise exception 'invalid_duration';
  end if;
  if p_storage_path !~ ('^' || v_user_id::text || '/' || p_job_id::text || '/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$') then
    raise exception 'invalid_storage_path';
  end if;
  v_minutes := greatest(1, ceil(p_duration_seconds::numeric / 60)::integer);

  select * into v_job from public.processing_jobs
    where user_id = v_user_id and id = p_job_id for update;
  if found and v_job.status = 'completed' then
    return jsonb_build_object('state', 'completed', 'result', v_job.result);
  elsif found and v_job.status in ('reserving', 'processing') then
    return jsonb_build_object('state', 'in_progress');
  end if;

  select up.* into v_period
  from public.usage_periods up
  join public.subscription_state ss on ss.user_id = up.user_id
  where up.user_id = v_user_id
    and (
      (ss.entitlement = 'pro' and up.plan = 'pro' and up.starts_at <= now() and up.ends_at > now())
      or (ss.entitlement <> 'pro' and up.period_key = 'free-lifetime')
    )
  order by case when up.plan = 'pro' then 0 else 1 end, up.starts_at desc
  limit 1
  for update of up;

  if not found then raise exception 'usage_period_missing'; end if;
  if v_period.used_minutes + v_period.reserved_minutes + v_minutes > v_period.quota_minutes then
    return jsonb_build_object('state', 'quota_exhausted');
  end if;

  insert into public.service_budget_months(period_key, max_audio_minutes)
    values (v_budget_period_key, 500)
    on conflict do nothing;
  select * into v_budget from public.service_budget_months
    where period_key = v_budget_period_key for update;
  if v_budget.used_audio_minutes + v_budget.reserved_audio_minutes + v_minutes
      > v_budget.max_audio_minutes then
    return jsonb_build_object('state', 'service_budget_exhausted');
  end if;

  insert into public.processing_jobs(
    id, user_id, usage_period_id, service_budget_period_key, status,
    storage_path, duration_seconds, billed_minutes, ai_started, result,
    error_code, updated_at, expires_at
  ) values (
    p_job_id, v_user_id, v_period.id, v_budget_period_key, 'reserving',
    p_storage_path, p_duration_seconds, v_minutes, false, null, null, now(),
    now() + interval '24 hours'
  ) on conflict (user_id, id) do update set
    usage_period_id = excluded.usage_period_id,
    service_budget_period_key = excluded.service_budget_period_key,
    status = 'reserving',
    storage_path = excluded.storage_path,
    duration_seconds = excluded.duration_seconds,
    billed_minutes = excluded.billed_minutes,
    ai_started = false,
    result = null,
    error_code = null,
    updated_at = now(),
    expires_at = now() + interval '24 hours';

  update public.usage_periods set
    reserved_minutes = reserved_minutes + v_minutes,
    updated_at = now()
  where id = v_period.id;

  update public.service_budget_months set
    reserved_audio_minutes = reserved_audio_minutes + v_minutes,
    updated_at = now()
  where period_key = v_budget_period_key;

  insert into public.usage_ledger(user_id, job_id, usage_period_id, kind, minutes)
    values (v_user_id, p_job_id, v_period.id, 'reserve', v_minutes)
    on conflict do nothing;

  update public.processing_jobs set status = 'processing', updated_at = now()
    where user_id = v_user_id and id = p_job_id;
  return jsonb_build_object(
    'state', 'reserved',
    'plan', v_period.plan,
    'billedMinutes', v_minutes,
    'remainingMinutes', v_period.quota_minutes - v_period.used_minutes - v_period.reserved_minutes - v_minutes
  );
end;
$$;

create or replace function public.mark_voicebrief_ai_started(
  p_user_id uuid,
  p_job_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.processing_jobs set ai_started = true, updated_at = now()
  where user_id = p_user_id and id = p_job_id and status = 'processing';
  if not found then raise exception 'job_not_processing'; end if;
end;
$$;

create or replace function public.complete_voicebrief_job(
  p_user_id uuid,
  p_job_id uuid,
  p_result jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := p_user_id;
  v_job public.processing_jobs%rowtype;
begin
  select * into v_job from public.processing_jobs
    where user_id = v_user_id and id = p_job_id for update;
  if not found then raise exception 'job_missing'; end if;
  if v_job.status = 'completed' then return; end if;
  if v_job.status <> 'processing' then raise exception 'job_not_processing'; end if;

  update public.usage_periods set
    reserved_minutes = greatest(0, reserved_minutes - v_job.billed_minutes),
    used_minutes = used_minutes + v_job.billed_minutes,
    updated_at = now()
  where id = v_job.usage_period_id;
  update public.service_budget_months set
    reserved_audio_minutes = greatest(0, reserved_audio_minutes - v_job.billed_minutes),
    used_audio_minutes = used_audio_minutes + v_job.billed_minutes,
    updated_at = now()
  where period_key = v_job.service_budget_period_key;
  insert into public.usage_ledger(user_id, job_id, usage_period_id, kind, minutes)
    values (v_user_id, p_job_id, v_job.usage_period_id, 'charge', v_job.billed_minutes)
    on conflict do nothing;
  update public.processing_jobs set
    status = 'completed', result = p_result, error_code = null, updated_at = now()
  where user_id = v_user_id and id = p_job_id;
end;
$$;

create or replace function public.fail_voicebrief_job(
  p_user_id uuid,
  p_job_id uuid,
  p_error_code text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := p_user_id;
  v_job public.processing_jobs%rowtype;
begin
  select * into v_job from public.processing_jobs
    where user_id = v_user_id and id = p_job_id for update;
  if not found or v_job.status in ('completed', 'failed') then return; end if;
  update public.usage_periods set
    reserved_minutes = greatest(0, reserved_minutes - v_job.billed_minutes),
    updated_at = now()
  where id = v_job.usage_period_id;
  update public.service_budget_months set
    reserved_audio_minutes = greatest(0, reserved_audio_minutes - v_job.billed_minutes),
    used_audio_minutes = used_audio_minutes + case when v_job.ai_started then v_job.billed_minutes else 0 end,
    updated_at = now()
  where period_key = v_job.service_budget_period_key;
  insert into public.usage_ledger(user_id, job_id, usage_period_id, kind, minutes)
    values (v_user_id, p_job_id, v_job.usage_period_id, 'refund', v_job.billed_minutes)
    on conflict do nothing;
  update public.processing_jobs set
    status = 'failed', error_code = left(coalesce(p_error_code, 'processing_failed'), 64),
    result = null, updated_at = now()
  where user_id = v_user_id and id = p_job_id;
end;
$$;

create or replace function public.apply_revenuecat_event(
  p_event_id text,
  p_event_type text,
  p_user_id uuid,
  p_is_pro boolean,
  p_product_id text,
  p_store text,
  p_event_at timestamptz,
  p_period_start timestamptz,
  p_period_end timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_period_key text;
begin
  insert into public.revenuecat_webhook_events(event_id, event_type, app_user_id)
    values (left(p_event_id, 200), left(p_event_type, 80), p_user_id)
    on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then return false; end if;

  insert into public.subscription_state(
    user_id, entitlement, product_id, store, expires_at, revenuecat_event_id,
    revenuecat_event_at, updated_at
  ) values (
    p_user_id, case when p_is_pro then 'pro' else 'free' end,
    left(p_product_id, 200), left(p_store, 40), p_period_end,
    left(p_event_id, 200), p_event_at, now()
  ) on conflict (user_id) do update set
    entitlement = excluded.entitlement,
    product_id = excluded.product_id,
    store = excluded.store,
    expires_at = excluded.expires_at,
    revenuecat_event_id = excluded.revenuecat_event_id,
    revenuecat_event_at = excluded.revenuecat_event_at,
    updated_at = now()
  where public.subscription_state.revenuecat_event_at is null
    or excluded.revenuecat_event_at >= public.subscription_state.revenuecat_event_at;

  if p_is_pro and p_period_end > p_period_start then
    v_period_key := 'pro-' || floor(extract(epoch from p_period_start))::bigint::text
      || '-' || floor(extract(epoch from p_period_end))::bigint::text;
    insert into public.usage_periods(
      user_id, period_key, plan, starts_at, ends_at, quota_minutes
    ) values (p_user_id, v_period_key, 'pro', p_period_start, p_period_end, 300)
    on conflict (user_id, period_key) do update set
      starts_at = excluded.starts_at,
      ends_at = excluded.ends_at,
      quota_minutes = excluded.quota_minutes,
      updated_at = now();
  end if;
  return true;
end;
$$;

revoke all on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer) from public, anon, authenticated;
revoke all on function public.mark_voicebrief_ai_started(uuid, uuid) from public, anon, authenticated;
revoke all on function public.complete_voicebrief_job(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.fail_voicebrief_job(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz) from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer) to service_role;
grant execute on function public.mark_voicebrief_ai_started(uuid, uuid) to service_role;
grant execute on function public.complete_voicebrief_job(uuid, uuid, jsonb) to service_role;
grant execute on function public.fail_voicebrief_job(uuid, uuid, text) to service_role;
grant execute on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz) to service_role;

insert into storage.buckets(id, name, public, file_size_limit, allowed_mime_types)
values (
  'audio-temp', 'audio-temp', false, 26214400,
  array['audio/flac','audio/mpeg','audio/mp4','audio/wav','audio/ogg','audio/webm']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy "audio_insert_own_folder" on storage.objects for insert to authenticated
with check (
  bucket_id = 'audio-temp'
  and (storage.foldername(name))[1] = auth.uid()::text
  and lower(storage.extension(name)) in ('flac','mp3','mp4','mpeg','mpga','m4a','ogg','wav','webm')
);
create policy "audio_read_own_folder" on storage.objects for select to authenticated
using (bucket_id = 'audio-temp' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "audio_delete_own_folder" on storage.objects for delete to authenticated
using (bucket_id = 'audio-temp' and (storage.foldername(name))[1] = auth.uid()::text);

commit;
