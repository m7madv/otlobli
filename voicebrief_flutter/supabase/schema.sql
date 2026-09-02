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
  quota_generation_key text,
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
  subscription_generation_key text,
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
  app_user_id uuid references public.profiles(user_id) on delete set null,
  handling_status text not null default 'applied' check (
    handling_status in (
      'applied',
      'ignored_missing_profile',
      'ignored_non_subscription',
      'anonymized_deleted_user'
    )
  ),
  received_at timestamptz not null default now()
);

create table public.subscription_sync_rate_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  request_count integer not null check (request_count between 1 and 6),
  updated_at timestamptz not null default now()
);

create index processing_jobs_expires_idx on public.processing_jobs(expires_at);
create index usage_periods_user_active_idx on public.usage_periods(user_id, starts_at desc);
create index usage_periods_active_subscription_generation_idx
  on public.usage_periods(
    user_id,
    subscription_generation_key,
    starts_at,
    ends_at
  )
  where plan = 'pro';
create index support_requests_status_created_idx on public.support_requests(status, created_at desc);
create index support_requests_rate_limit_idx on public.support_requests(request_key_hash, created_at desc);
create index revenuecat_webhook_events_app_user_idx
  on public.revenuecat_webhook_events(app_user_id)
  where app_user_id is not null;

alter table public.profiles enable row level security;
alter table public.subscription_state enable row level security;
alter table public.usage_periods enable row level security;
alter table public.service_budget_months enable row level security;
alter table public.processing_jobs enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.account_deletion_requests enable row level security;
alter table public.revenuecat_webhook_events enable row level security;
alter table public.subscription_sync_rate_limits enable row level security;
alter table public.support_requests enable row level security;

revoke all on table public.support_requests from anon, authenticated;
grant all on table public.support_requests to service_role;
revoke all on table public.subscription_sync_rate_limits
  from public, anon, authenticated;
grant all on table public.subscription_sync_rate_limits to service_role;

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

create or replace function public.voicebrief_subscription_window_limit(
  p_product_id text
)
returns integer
language sql
immutable
parallel safe
set search_path = public
as $$
  select case
    when split_part(coalesce(p_product_id, ''), ':', 1) =
      'voicebrief_pro_annual' then 12
    else 1
  end;
$$;

create or replace function public.voicebrief_subscription_generation_key(
  p_product_id text,
  p_period_start timestamptz
)
returns text
language sql
immutable
parallel safe
set search_path = public
as $$
  select case
    when p_period_start is null then null
    else md5(
      coalesce(p_product_id, '') || ':' ||
        floor(extract(epoch from p_period_start) * 1000)::bigint::text
    )
  end;
$$;

create or replace function public.claim_voicebrief_subscription_sync(
  p_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_now timestamptz := statement_timestamp();
  v_claimed boolean := false;
begin
  perform 1
  from public.profiles
  where user_id = p_user_id
  for key share;
  if not found then return false; end if;

  insert into public.subscription_sync_rate_limits(
    user_id,
    window_started_at,
    request_count,
    updated_at
  ) values (
    p_user_id,
    v_now,
    1,
    v_now
  ) on conflict (user_id) do update set
    window_started_at = case
      when public.subscription_sync_rate_limits.window_started_at <=
        v_now - interval '1 minute' then v_now
      else public.subscription_sync_rate_limits.window_started_at
    end,
    request_count = case
      when public.subscription_sync_rate_limits.window_started_at <=
        v_now - interval '1 minute' then 1
      else public.subscription_sync_rate_limits.request_count + 1
    end,
    updated_at = v_now
  where public.subscription_sync_rate_limits.window_started_at <=
      v_now - interval '1 minute'
    or public.subscription_sync_rate_limits.request_count < 6
  returning true into v_claimed;

  return coalesce(v_claimed, false);
end;
$$;

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

create or replace function public.anonymize_revenuecat_events_on_profile_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.revenuecat_webhook_events
  set app_user_id = null,
      handling_status = 'anonymized_deleted_user'
  where app_user_id = old.user_id;
  return old;
end;
$$;

create trigger on_voicebrief_profile_deleted
before delete on public.profiles
for each row execute function public.anonymize_revenuecat_events_on_profile_delete();

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
  v_subscription public.subscription_state%rowtype;
  v_period public.usage_periods%rowtype;
  v_budget public.service_budget_months%rowtype;
  v_budget_period_key text := to_char(timezone('UTC', now()), 'YYYY-MM');
  v_minutes integer;
  v_future_generation_start timestamptz;
  v_has_active_generation_window boolean := false;
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

  -- Lock subscription_state before usage_periods, matching the webhook lock
  -- order. If a product change/transfer is committing, READ COMMITTED follows
  -- the updated row after the wait instead of reserving against a stale
  -- generation snapshot.
  select * into v_subscription
  from public.subscription_state
  where user_id = v_user_id
  for share;
  if not found then raise exception 'usage_period_missing'; end if;

  if v_subscription.entitlement = 'pro'
    and v_subscription.expires_at > now()
    and v_subscription.quota_generation_key is not null then
    select
      min(starts_at) filter (where starts_at > now()),
      coalesce(bool_or(starts_at <= now() and ends_at > now()), false)
    into v_future_generation_start, v_has_active_generation_window
    from public.usage_periods
    where user_id = v_user_id
      and plan = 'pro'
      and subscription_generation_key =
        v_subscription.quota_generation_key;
  end if;

  select up.* into v_period
  from public.usage_periods up
  where up.user_id = v_user_id
    and (
      (
        v_subscription.entitlement = 'pro'
        and v_subscription.expires_at > now()
        and v_subscription.quota_generation_key is not null
        and up.plan = 'pro'
        and up.starts_at <= now()
        and up.ends_at > now()
        and (
          up.subscription_generation_key =
            v_subscription.quota_generation_key
          or (
            not v_has_active_generation_window
            and v_future_generation_start is not null
            and up.subscription_generation_key is distinct from
              v_subscription.quota_generation_key
            and up.ends_at >= v_future_generation_start
          )
        )
      )
      or (
        (
          v_subscription.entitlement <> 'pro'
          or v_subscription.expires_at is null
          or v_subscription.expires_at <= now()
          or v_subscription.quota_generation_key is null
        )
        and up.period_key = 'free-lifetime'
      )
    )
  order by
    case
      when up.subscription_generation_key =
        v_subscription.quota_generation_key then 0
      when up.plan = 'pro' then 1
      else 2
    end,
    up.starts_at desc
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

-- Return one server-authoritative subscription/quota snapshot. The client
-- never compares billing timestamps with the device clock and cannot combine
-- subscription_state from one webhook transaction with usage_periods from
-- another.
create or replace function public.get_voicebrief_subscription_status()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_now timestamptz := statement_timestamp();
  v_subscription public.subscription_state%rowtype;
  v_period public.usage_periods%rowtype;
  v_future_generation_start timestamptz;
  v_has_active_generation_window boolean := false;
begin
  if v_user_id is null then raise exception 'invalid_user'; end if;

  select * into v_subscription
  from public.subscription_state
  where user_id = v_user_id
  for share;
  if not found then raise exception 'usage_period_missing'; end if;

  if v_subscription.entitlement = 'pro'
    and v_subscription.expires_at > v_now
    and v_subscription.quota_generation_key is not null then
    select
      min(starts_at) filter (where starts_at > v_now),
      coalesce(bool_or(starts_at <= v_now and ends_at > v_now), false)
    into v_future_generation_start, v_has_active_generation_window
    from public.usage_periods
    where user_id = v_user_id
      and plan = 'pro'
      and subscription_generation_key =
        v_subscription.quota_generation_key;
  end if;

  select up.* into v_period
  from public.usage_periods up
  where up.user_id = v_user_id
    and (
      (
        v_subscription.entitlement = 'pro'
        and v_subscription.expires_at > v_now
        and v_subscription.quota_generation_key is not null
        and up.plan = 'pro'
        and up.starts_at <= v_now
        and up.ends_at > v_now
        and (
          up.subscription_generation_key =
            v_subscription.quota_generation_key
          or (
            not v_has_active_generation_window
            and v_future_generation_start is not null
            and up.subscription_generation_key is distinct from
              v_subscription.quota_generation_key
            and up.ends_at >= v_future_generation_start
          )
        )
      )
      or (
        (
          v_subscription.entitlement <> 'pro'
          or v_subscription.expires_at is null
          or v_subscription.expires_at <= v_now
          or v_subscription.quota_generation_key is null
        )
        and up.period_key = 'free-lifetime'
        and up.starts_at <= v_now
        and (up.ends_at is null or up.ends_at > v_now)
      )
    )
  order by
    case
      when up.subscription_generation_key =
        v_subscription.quota_generation_key then 0
      when up.plan = 'pro' then 1
      else 2
    end,
    up.starts_at desc
  limit 1;

  if not found then raise exception 'usage_period_missing'; end if;
  return jsonb_build_object(
    'tier', v_period.plan,
    'quotaMinutes', v_period.quota_minutes,
    'usedMinutes', v_period.used_minutes,
    'reservedMinutes', v_period.reserved_minutes,
    'periodKey', v_period.period_key,
    'periodStartsAt', v_period.starts_at,
    'periodEndsAt', v_period.ends_at,
    'serverNow', v_now
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
  p_period_end timestamptz,
  p_access_end timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_state_applied integer;
  v_period_key text;
  v_profile_exists boolean;
  v_window_index integer;
  v_window_limit integer;
  v_window_start timestamptz;
  v_quota_window_end timestamptz;
  v_window_end timestamptz;
  v_existing_used integer;
  v_previous_event_type text;
  v_previous_product_id text;
  v_previous_generation_key text;
  v_previous_access_end timestamptz;
  v_generation_key text;
  v_generation_changed boolean;
  v_overlaps_previous_access boolean;
  v_has_legacy_overlap boolean;
  v_should_carry boolean;
  v_is_final_window boolean;
begin
  perform 1
  from public.profiles
  where user_id = p_user_id
  for key share;
  v_profile_exists := found;

  insert into public.revenuecat_webhook_events(
    event_id,
    event_type,
    app_user_id,
    handling_status
  ) values (
    left(p_event_id, 200),
    left(p_event_type, 80),
    case when v_profile_exists then p_user_id else null end,
    case
      when v_profile_exists then 'applied'
      else 'ignored_missing_profile'
    end
  ) on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then return false; end if;
  if not v_profile_exists then return true; end if;

  lock table public.subscription_state in row exclusive mode;
  select
    events.event_type,
    state.product_id,
    state.quota_generation_key,
    state.expires_at
  into
    v_previous_event_type,
    v_previous_product_id,
    v_previous_generation_key,
    v_previous_access_end
  from public.subscription_state state
  left join public.revenuecat_webhook_events events
    on events.event_id = state.revenuecat_event_id
  where state.user_id = p_user_id
  for update of state;

  if p_is_pro and (
    p_period_start is null
    or p_period_end is null
    or p_access_end is null
    or p_period_end <= p_period_start
    or p_access_end < p_period_end
    or p_access_end > p_period_start + interval '2 years'
  ) then
    raise exception 'invalid_subscription_period';
  end if;

  v_generation_key := case
    when p_is_pro then public.voicebrief_subscription_generation_key(
      p_product_id,
      p_period_start
    )
    else null
  end;
  v_generation_changed := p_is_pro and
    v_previous_generation_key is distinct from v_generation_key;
  v_overlaps_previous_access := p_is_pro and coalesce(
    v_previous_access_end > p_period_start,
    false
  );
  v_has_legacy_overlap := false;

  if v_generation_changed then
    lock table public.usage_periods in exclusive mode;
    select
      exists (
        select 1
        from public.usage_periods
        where user_id = p_user_id
          and plan = 'pro'
          and starts_at < p_access_end
          and ends_at > p_period_start
      ),
      exists (
        select 1
        from public.usage_periods
        where user_id = p_user_id
          and plan = 'pro'
          and subscription_generation_key is null
          and starts_at < p_access_end
          and ends_at > p_period_start
      )
    into v_overlaps_previous_access, v_has_legacy_overlap;
    v_overlaps_previous_access := v_overlaps_previous_access or coalesce(
      v_previous_access_end > p_period_start,
      false
    );
  end if;

  v_should_carry := v_generation_changed
    and v_overlaps_previous_access
    and (
      v_has_legacy_overlap
      or p_event_type not in (
        'INITIAL_PURCHASE',
        'RENEWAL',
        'SUBSCRIPTION_SYNC'
      )
      or v_previous_event_type in (
        'PRODUCT_CHANGE',
        'TEMPORARY_ENTITLEMENT_GRANT'
      )
      or v_previous_product_id is distinct from p_product_id
    );
  if v_should_carry and exists (
      select 1
      from public.usage_periods
      where user_id = p_user_id
        and plan = 'pro'
        and starts_at < p_access_end
        and ends_at > p_period_start
        and reserved_minutes > 0
  ) then
    raise exception 'subscription_carry_has_active_reservation';
  end if;

  insert into public.subscription_state(
    user_id, entitlement, product_id, store, expires_at, revenuecat_event_id,
    revenuecat_event_at, quota_generation_key, updated_at
  ) values (
    p_user_id, case when p_is_pro then 'pro' else 'free' end,
    left(p_product_id, 200), left(p_store, 40), p_access_end,
    left(p_event_id, 200), p_event_at, v_generation_key, now()
  ) on conflict (user_id) do update set
    entitlement = excluded.entitlement,
    product_id = excluded.product_id,
    store = excluded.store,
    expires_at = excluded.expires_at,
    revenuecat_event_id = excluded.revenuecat_event_id,
    revenuecat_event_at = excluded.revenuecat_event_at,
    quota_generation_key = excluded.quota_generation_key,
    updated_at = now()
  where public.subscription_state.revenuecat_event_at is null
    or excluded.revenuecat_event_at >= public.subscription_state.revenuecat_event_at;
  get diagnostics v_state_applied = row_count;

  if v_state_applied > 0 and p_is_pro then
    v_window_index := 0;
    v_window_limit := public.voicebrief_subscription_window_limit(p_product_id);
    loop
      v_window_start := p_period_start
        + make_interval(months => v_window_index);
      exit when v_window_start >= p_period_end;
      v_quota_window_end := least(
        p_period_end,
        p_period_start + make_interval(months => v_window_index + 1)
      );
      v_is_final_window := v_quota_window_end >= p_period_end
        or v_window_index + 1 >= v_window_limit;
      v_window_end := case
        when v_is_final_window then p_access_end
        else v_quota_window_end
      end;
      if v_window_end <= v_window_start
        or v_window_index >= v_window_limit then
        raise exception 'invalid_subscription_period';
      end if;

      v_period_key := 'pro-month-' || v_generation_key
        || '-' || v_window_index::text;
      v_existing_used := 0;
      if v_should_carry then
        select
          coalesce(max(used_minutes), 0)
        into v_existing_used
        from public.usage_periods
        where user_id = p_user_id
          and plan = 'pro'
          and period_key <> v_period_key
          and starts_at < v_window_end
          and ends_at > v_window_start
          and (
            subscription_generation_key is not null
            or (v_window_start <= now() and v_window_end > now())
          );
      end if;
      v_existing_used := least(300, v_existing_used);

      insert into public.usage_periods(
        user_id,
        period_key,
        plan,
        starts_at,
        ends_at,
        quota_minutes,
        used_minutes,
        reserved_minutes,
        subscription_generation_key
      ) values (
        p_user_id,
        v_period_key,
        'pro',
        v_window_start,
        v_window_end,
        300,
        v_existing_used,
        0,
        v_generation_key
      ) on conflict (user_id, period_key) do update set
        starts_at = excluded.starts_at,
        ends_at = greatest(public.usage_periods.ends_at, excluded.ends_at),
        quota_minutes = excluded.quota_minutes,
        subscription_generation_key = excluded.subscription_generation_key,
        used_minutes = greatest(
          public.usage_periods.used_minutes,
          excluded.used_minutes
        ),
        reserved_minutes = least(
          excluded.quota_minutes - greatest(
            public.usage_periods.used_minutes,
            excluded.used_minutes
          ),
          greatest(
            public.usage_periods.reserved_minutes,
            excluded.reserved_minutes
          )
        ),
        updated_at = now();

      v_window_index := v_window_index + 1;
      exit when v_is_final_window;
    end loop;
  end if;
  return true;
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
language sql
security definer
set search_path = public
as $$
  select public.apply_revenuecat_event(
    p_event_id,
    p_event_type,
    p_user_id,
    p_is_pro,
    p_product_id,
    p_store,
    p_event_at,
    p_period_start,
    p_period_end,
    p_period_end
  );
$$;

create or replace function public.record_ignored_revenuecat_event(
  p_event_id text,
  p_event_type text,
  p_user_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_profile_exists boolean;
begin
  v_profile_exists := false;
  if p_user_id is not null then
    perform 1
    from public.profiles
    where user_id = p_user_id
    for key share;
    v_profile_exists := found;
  end if;

  insert into public.revenuecat_webhook_events(
    event_id,
    event_type,
    app_user_id,
    handling_status
  ) values (
    left(p_event_id, 200),
    left(p_event_type, 80),
    case when v_profile_exists then p_user_id else null end,
    'ignored_non_subscription'
  ) on conflict do nothing;
  get diagnostics v_inserted = row_count;
  return v_inserted > 0;
end;
$$;

create or replace function public.apply_revenuecat_transfer(
  p_event_id text,
  p_event_type text,
  p_source_user_ids uuid[],
  p_destination_user_id uuid,
  p_is_pro boolean,
  p_product_id text,
  p_store text,
  p_event_at timestamptz,
  p_period_start timestamptz,
  p_period_end timestamptz,
  p_access_end timestamptz
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer;
  v_state_applied integer;
  v_profile_exists boolean;
  v_source_user_ids uuid[] := coalesce(p_source_user_ids, '{}'::uuid[]);
  v_window_index integer;
  v_window_limit integer;
  v_window_start timestamptz;
  v_quota_window_end timestamptz;
  v_window_end timestamptz;
  v_period_key text;
  v_source_used integer;
  v_source_reserved integer;
  v_generation_key text;
  v_is_final_window boolean;
  v_should_merge_usage boolean;
  v_has_parallel_generation_grants boolean;
begin
  perform 1
  from public.profiles
  where user_id = p_destination_user_id
  for key share;
  v_profile_exists := found;

  insert into public.revenuecat_webhook_events(
    event_id,
    event_type,
    app_user_id,
    handling_status
  ) values (
    left(p_event_id, 200),
    left(p_event_type, 80),
    case when v_profile_exists then p_destination_user_id else null end,
    case
      when v_profile_exists then 'applied'
      else 'ignored_missing_profile'
    end
  ) on conflict do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then return false; end if;
  if not v_profile_exists then return true; end if;

  lock table public.subscription_state in exclusive mode;
  lock table public.usage_periods in exclusive mode;

  if exists (
    select 1
    from public.usage_periods
    where user_id = any(
      array_append(v_source_user_ids, p_destination_user_id)
    )
      and reserved_minutes > 0
  ) then
    raise exception 'transfer_has_active_reservation';
  end if;

  if p_is_pro and (
    p_period_start is null
    or p_period_end is null
    or p_access_end is null
    or p_period_end <= p_period_start
    or p_access_end < p_period_end
    or p_access_end > p_period_start + interval '2 years'
  ) then
    raise exception 'invalid_subscription_period';
  end if;

  v_generation_key := case
    when p_is_pro then public.voicebrief_subscription_generation_key(
      p_product_id,
      p_period_start
    )
    else null
  end;

  select
    exists (
      select 1
      from public.subscription_state
      where user_id = p_destination_user_id
        and entitlement = 'pro'
        and expires_at > now()
        and quota_generation_key = v_generation_key
    ) and exists (
      select 1
      from public.subscription_state
      where user_id = any(v_source_user_ids)
        and user_id <> p_destination_user_id
        and entitlement = 'pro'
        and expires_at > now()
        and quota_generation_key = v_generation_key
    )
  into v_has_parallel_generation_grants;

  insert into public.subscription_state(
    user_id, entitlement, product_id, store, expires_at, revenuecat_event_id,
    revenuecat_event_at, quota_generation_key, updated_at
  ) values (
    p_destination_user_id, case when p_is_pro then 'pro' else 'free' end,
    left(p_product_id, 200), left(p_store, 40), p_access_end,
    left(p_event_id, 200), p_event_at, v_generation_key, now()
  ) on conflict (user_id) do update set
    entitlement = excluded.entitlement,
    product_id = excluded.product_id,
    store = excluded.store,
    expires_at = excluded.expires_at,
    revenuecat_event_id = excluded.revenuecat_event_id,
    revenuecat_event_at = excluded.revenuecat_event_at,
    quota_generation_key = excluded.quota_generation_key,
    updated_at = now()
  where public.subscription_state.revenuecat_event_at is null
    or excluded.revenuecat_event_at >= public.subscription_state.revenuecat_event_at;
  get diagnostics v_state_applied = row_count;

  v_should_merge_usage := p_is_pro and (
    v_state_applied > 0
    or exists (
      select 1
      from public.subscription_state
      where user_id = p_destination_user_id
        and entitlement = 'pro'
        and quota_generation_key = v_generation_key
    )
  );

  -- An authenticated on-demand sync can install the destination snapshot
  -- before RevenueCat delivers its older TRANSFER event. The stale event must
  -- not replace newer state, but it still has to merge the source receipt's
  -- usage high-water mark into that exact same destination generation.
  if v_should_merge_usage then
    v_window_index := 0;
    v_window_limit := public.voicebrief_subscription_window_limit(p_product_id);
    loop
      v_window_start := p_period_start
        + make_interval(months => v_window_index);
      exit when v_window_start >= p_period_end;
      v_quota_window_end := least(
        p_period_end,
        p_period_start + make_interval(months => v_window_index + 1)
      );
      v_is_final_window := v_quota_window_end >= p_period_end
        or v_window_index + 1 >= v_window_limit;
      v_window_end := case
        when v_is_final_window then p_access_end
        else v_quota_window_end
      end;
      if v_window_end <= v_window_start
        or v_window_index >= v_window_limit then
        raise exception 'invalid_subscription_period';
      end if;

      -- A normal transfer carries a cumulative high-water mark, so max keeps
      -- A -> B -> A from double-charging. If legacy state proves source and
      -- destination were simultaneously granted this exact generation, their
      -- independent consumption is summed once and capped at the quota.
      select least(
        300,
        coalesce(
          case
            when v_has_parallel_generation_grants
              then sum(per_user.used_minutes)
            else max(per_user.used_minutes)
          end,
          0
        )
      )::integer
      into v_source_used
      from (
        select distinct on (user_id) user_id, used_minutes
        from public.usage_periods
        where user_id = any(
          array_append(v_source_user_ids, p_destination_user_id)
        )
          and plan = 'pro'
          and starts_at < v_window_end
          and ends_at > v_window_start
          and (
            subscription_generation_key is not null
            or (v_window_start <= now() and v_window_end > now())
          )
        order by user_id, starts_at desc, ends_at desc
      ) per_user;
      v_source_reserved := 0;

      v_period_key := 'pro-month-' || v_generation_key
        || '-' || v_window_index::text;
      insert into public.usage_periods(
        user_id,
        period_key,
        plan,
        starts_at,
        ends_at,
        quota_minutes,
        used_minutes,
        reserved_minutes,
        subscription_generation_key
      ) values (
        p_destination_user_id,
        v_period_key,
        'pro',
        v_window_start,
        v_window_end,
        300,
        v_source_used,
        v_source_reserved,
        v_generation_key
      ) on conflict (user_id, period_key) do update set
        starts_at = excluded.starts_at,
        ends_at = greatest(public.usage_periods.ends_at, excluded.ends_at),
        quota_minutes = excluded.quota_minutes,
        subscription_generation_key = excluded.subscription_generation_key,
        used_minutes = greatest(
          public.usage_periods.used_minutes,
          excluded.used_minutes
        ),
        reserved_minutes = least(
          excluded.quota_minutes - greatest(
            public.usage_periods.used_minutes,
            excluded.used_minutes
          ),
          greatest(
            public.usage_periods.reserved_minutes,
            excluded.reserved_minutes
          )
        ),
        updated_at = now();

      v_window_index := v_window_index + 1;
      exit when v_is_final_window;
    end loop;
  end if;

  update public.subscription_state
  set entitlement = 'free',
      expires_at = least(coalesce(expires_at, p_event_at), p_event_at),
      quota_generation_key = null,
      revenuecat_event_id = left(p_event_id, 200),
      revenuecat_event_at = p_event_at,
      updated_at = now()
  where user_id = any(v_source_user_ids)
    and user_id <> p_destination_user_id
    and (
      revenuecat_event_at is null
      or p_event_at >= revenuecat_event_at
    );

  return true;
end;
$$;

revoke all on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer) from public, anon, authenticated;
revoke all on function public.mark_voicebrief_ai_started(uuid, uuid) from public, anon, authenticated;
revoke all on function public.complete_voicebrief_job(uuid, uuid, jsonb) from public, anon, authenticated;
revoke all on function public.fail_voicebrief_job(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.anonymize_revenuecat_events_on_profile_delete() from public, anon, authenticated;
revoke all on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz) from public, anon, authenticated;
revoke all on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz, timestamptz) from public, anon, authenticated;
revoke all on function public.apply_revenuecat_transfer(text, text, uuid[], uuid, boolean, text, text, timestamptz, timestamptz, timestamptz, timestamptz) from public, anon, authenticated;
revoke all on function public.record_ignored_revenuecat_event(text, text, uuid) from public, anon, authenticated;
revoke all on function public.voicebrief_subscription_window_limit(text) from public, anon, authenticated;
revoke all on function public.voicebrief_subscription_generation_key(text, timestamptz) from public, anon, authenticated;
revoke all on function public.get_voicebrief_subscription_status() from public, anon;
revoke all on function public.claim_voicebrief_subscription_sync(uuid) from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_minutes(uuid, uuid, text, integer) to service_role;
grant execute on function public.mark_voicebrief_ai_started(uuid, uuid) to service_role;
grant execute on function public.complete_voicebrief_job(uuid, uuid, jsonb) to service_role;
grant execute on function public.fail_voicebrief_job(uuid, uuid, text) to service_role;
grant execute on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz) to service_role;
grant execute on function public.apply_revenuecat_event(text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz, timestamptz) to service_role;
grant execute on function public.apply_revenuecat_transfer(text, text, uuid[], uuid, boolean, text, text, timestamptz, timestamptz, timestamptz, timestamptz) to service_role;
grant execute on function public.record_ignored_revenuecat_event(text, text, uuid) to service_role;
grant execute on function public.get_voicebrief_subscription_status() to authenticated, service_role;
grant execute on function public.claim_voicebrief_subscription_sync(uuid) to service_role;
grant execute on function public.voicebrief_subscription_generation_key(text, timestamptz) to service_role;

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

-- Post-launch security hardening. Kept here as executable canonical schema so a
-- clean environment reaches the same state as the versioned migrations.

create table public.audio_upload_reservations (
  user_id uuid not null references auth.users(id) on delete cascade,
  job_id uuid not null,
  storage_path text not null unique,
  expected_size_bytes integer not null check (expected_size_bytes > 0 and expected_size_bytes <= 26214400),
  expected_mime_type text not null,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '2 hours'),
  consumed_at timestamptz,
  cleanup_first_removed_at timestamptz,
  cleanup_claim_id uuid,
  cleanup_claimed_at timestamptz,
  cleanup_attempts bigint not null default 0 check (cleanup_attempts >= 0),
  primary key (user_id, job_id),
  check (storage_path ~ ('^' || user_id::text || '/' || job_id::text || '/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$')),
  check (expected_mime_type in ('audio/flac','audio/mpeg','audio/mp4','audio/wav','audio/ogg','audio/webm')),
  constraint audio_upload_reservations_hard_expiry_check
    check (expires_at <= created_at + interval '4 hours')
);

create table public.audio_upload_daily_limits (
  user_id uuid not null references auth.users(id) on delete cascade,
  day_utc date not null,
  issued_count integer not null default 0 check (issued_count between 0 and 20),
  primary key (user_id, day_utc)
);

alter table public.audio_upload_reservations enable row level security;
alter table public.audio_upload_daily_limits enable row level security;

create index audio_upload_reservations_expiry_idx
  on public.audio_upload_reservations(expires_at);
create index audio_upload_reservations_cleanup_idx
  on public.audio_upload_reservations(expires_at, cleanup_claimed_at)
  where cleanup_first_removed_at is null;
create index audio_upload_reservations_cleanup_verify_idx
  on public.audio_upload_reservations(cleanup_first_removed_at, cleanup_claimed_at)
  where cleanup_first_removed_at is not null;

create or replace function public.reserve_voicebrief_upload(
  p_user_id uuid,
  p_job_id uuid,
  p_storage_path text,
  p_size_bytes integer,
  p_mime_type text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing public.audio_upload_reservations%rowtype;
  v_issued integer;
begin
  if p_user_id is null or p_job_id is null then
    raise exception 'invalid_upload_identity';
  end if;
  if p_storage_path !~ ('^' || p_user_id::text || '/' || p_job_id::text || '/input\.(flac|mp3|mp4|mpeg|mpga|m4a|ogg|wav|webm)$') then
    raise exception 'invalid_storage_path';
  end if;
  if p_size_bytes <= 0 or p_size_bytes > 26214400 then
    raise exception 'invalid_file_size';
  end if;
  if p_mime_type not in ('audio/flac','audio/mpeg','audio/mp4','audio/wav','audio/ogg','audio/webm') then
    raise exception 'unsupported_audio';
  end if;

  perform 1 from public.profiles where user_id = p_user_id for update;
  if not found then raise exception 'profile_missing'; end if;

  select * into v_existing
  from public.audio_upload_reservations
  where user_id = p_user_id and job_id = p_job_id
  for update;
  if found and v_existing.expires_at > now()
      and v_existing.created_at > now() - interval '2 hours'
      and v_existing.storage_path = p_storage_path
      and v_existing.expected_size_bytes = p_size_bytes
      and v_existing.expected_mime_type = p_mime_type then
    -- A retry may need a fresh two-hour signed URL, but the retry window closes
    -- two hours after creation and the reservation has an immutable four-hour
    -- lifetime ceiling. This keeps every issued URL discoverable without a
    -- sliding reservation that can evade cleanup forever.
    update public.audio_upload_reservations
    set expires_at = least(
          now() + interval '2 hours',
          v_existing.created_at + interval '4 hours'
        ),
        consumed_at = null
    where user_id = p_user_id and job_id = p_job_id;
    return jsonb_build_object('state', 'existing');
  elsif found and (
      v_existing.expires_at <= now()
      or v_existing.created_at <= now() - interval '2 hours'
    ) then
    -- Do not renew a path while the asynchronous cleaner may own or soon claim it.
    -- A later retry can reserve the same job after verification removes the row.
    return jsonb_build_object('state', 'cleanup_pending');
  elsif found then
    raise exception 'upload_reservation_conflict';
  end if;

  if (
    select count(*)
    from public.audio_upload_reservations
    where user_id = p_user_id
      and expires_at > now()
      and consumed_at is null
  ) >= 3 then
    return jsonb_build_object('state', 'rate_limited');
  end if;

  insert into public.audio_upload_daily_limits(user_id, day_utc, issued_count)
  values (p_user_id, timezone('UTC', now())::date, 1)
  on conflict (user_id, day_utc) do update
    set issued_count = public.audio_upload_daily_limits.issued_count + 1
    where public.audio_upload_daily_limits.issued_count < 20
  returning issued_count into v_issued;
  if v_issued is null then
    return jsonb_build_object('state', 'rate_limited');
  end if;

  insert into public.audio_upload_reservations(
    user_id, job_id, storage_path, expected_size_bytes, expected_mime_type
  ) values (
    p_user_id, p_job_id, p_storage_path, p_size_bytes, p_mime_type
  );
  return jsonb_build_object('state', 'reserved');
end;
$$;

create or replace function public.release_voicebrief_upload(
  p_user_id uuid,
  p_job_id uuid
)
returns void
language sql
security definer
set search_path = public
as $$
  -- Keep a tombstone through signed-URL expiry. A delayed upload then remains
  -- discoverable by the independent Storage cleaner.
  update public.audio_upload_reservations
  set consumed_at = now()
  where user_id = p_user_id
    and job_id = p_job_id
    and cleanup_claim_id is null;
$$;

create or replace function public.purge_expired_voicebrief_jobs()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_job record;
  v_failed integer := 0;
  v_redacted integer := 0;
begin
  for v_job in
    select user_id, id
    from public.processing_jobs
    where expires_at <= now() and status in ('reserving', 'processing')
    for update skip locked
  loop
    perform public.fail_voicebrief_job(v_job.user_id, v_job.id, 'job_expired');
    v_failed := v_failed + 1;
  end loop;

  update public.processing_jobs
  set result = null, error_code = 'result_expired', updated_at = now()
  where expires_at <= now() and status = 'completed' and result is not null;
  get diagnostics v_redacted = row_count;

  delete from public.audio_upload_daily_limits
  where day_utc < timezone('UTC', now())::date - 7;

  return jsonb_build_object(
    'failedJobs', v_failed,
    'redactedResults', v_redacted
  );
end;
$$;

drop policy if exists "jobs_read_own" on public.processing_jobs;
drop policy if exists "processing_jobs_read_own" on public.processing_jobs;
create policy "processing_jobs_read_own" on public.processing_jobs for select
  using (auth.uid() = user_id and expires_at > now());

drop policy if exists "audio_insert_own_folder" on storage.objects;

revoke all on table public.audio_upload_reservations from public, anon, authenticated;
revoke all on table public.audio_upload_daily_limits from public, anon, authenticated;
grant all on table public.audio_upload_reservations to service_role;
grant all on table public.audio_upload_daily_limits to service_role;

revoke all on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  from public, anon, authenticated;
revoke all on function public.release_voicebrief_upload(uuid, uuid)
  from public, anon, authenticated;
revoke all on function public.purge_expired_voicebrief_jobs()
  from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_upload(uuid, uuid, text, integer, text)
  to service_role;
grant execute on function public.release_voicebrief_upload(uuid, uuid)
  to service_role;
grant execute on function public.purge_expired_voicebrief_jobs()
  to service_role;

create or replace function public.submit_voicebrief_support_request(
  p_request_key_hash text,
  p_email text,
  p_category text,
  p_subject text,
  p_message text,
  p_language text
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_recent_count integer;
begin
  if p_request_key_hash !~ '^[0-9a-f]{64}$' then
    raise exception 'invalid_request_key';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(p_request_key_hash, 0));
  select count(*) into v_recent_count
  from public.support_requests
  where request_key_hash = p_request_key_hash
    and created_at >= now() - interval '24 hours';
  if v_recent_count >= 5 then return 'rate_limited'; end if;

  insert into public.support_requests(
    email, category, subject, message, language, request_key_hash
  ) values (
    p_email, p_category, p_subject, p_message, p_language, p_request_key_hash
  );
  return 'accepted';
end;
$$;

revoke all on function public.submit_voicebrief_support_request(text, text, text, text, text, text)
  from public, anon, authenticated;
grant execute on function public.submit_voicebrief_support_request(text, text, text, text, text, text)
  to service_role;

create extension if not exists pg_cron;
do $$
begin
  if not exists (select 1 from cron.job where jobname = 'voicebrief-expired-job-cleanup') then
    perform cron.schedule(
      'voicebrief-expired-job-cleanup',
      '*/15 * * * *',
      'select public.purge_expired_voicebrief_jobs()'
    );
  end if;
end;
$$;

-- Independent abandoned-audio cleanup. Storage objects are claimed in Postgres,
-- while object deletion is delegated to the Storage API Edge Function.

create or replace function public.claim_expired_voicebrief_uploads(
  p_limit integer default 100
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_claim_id uuid := gen_random_uuid();
  v_storage_paths text[];
begin
  if p_limit is null or p_limit < 1 or p_limit > 100 then
    raise exception 'invalid_cleanup_limit';
  end if;

  with candidates as (
    select user_id, job_id
    from public.audio_upload_reservations
    where (
        (
          cleanup_first_removed_at is null
          and expires_at <= now() - interval '15 minutes'
        )
        or cleanup_first_removed_at <= now() - interval '15 minutes'
      )
      and (
        cleanup_claimed_at is null
        or cleanup_claimed_at <= now() - interval '30 minutes'
      )
    order by coalesce(cleanup_first_removed_at, expires_at)
    limit p_limit
    for update skip locked
  ), claimed as (
    update public.audio_upload_reservations as reservation
    set cleanup_claim_id = v_claim_id,
        cleanup_claimed_at = now(),
        cleanup_attempts = reservation.cleanup_attempts + 1
    from candidates
    where reservation.user_id = candidates.user_id
      and reservation.job_id = candidates.job_id
    returning reservation.storage_path
  )
  select coalesce(
    array_agg(storage_path order by storage_path),
    array[]::text[]
  ) into v_storage_paths
  from claimed;

  if cardinality(v_storage_paths) = 0 then
    return jsonb_build_object(
      'claimId', null,
      'storagePaths', jsonb_build_array()
    );
  end if;
  return jsonb_build_object(
    'claimId', v_claim_id,
    'storagePaths', to_jsonb(v_storage_paths)
  );
end;
$$;

create or replace function public.complete_expired_voicebrief_upload_cleanup(
  p_claim_id uuid,
  p_storage_paths text[]
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_staged integer := 0;
  v_deleted integer := 0;
begin
  if p_claim_id is null or p_storage_paths is null
      or cardinality(p_storage_paths) < 1
      or cardinality(p_storage_paths) > 100 then
    raise exception 'invalid_cleanup_completion';
  end if;

  -- A verification claim has already survived the conservative interval after
  -- the first Storage removal. Its second removal can now retire the pointer.
  delete from public.audio_upload_reservations
  where cleanup_claim_id = p_claim_id
    and storage_path = any(p_storage_paths)
    and cleanup_first_removed_at is not null;
  get diagnostics v_deleted = row_count;

  -- The first successful Storage removal only stages a tombstone. Clearing the
  -- lease lets a later run claim it for the independent verification removal.
  update public.audio_upload_reservations
  set cleanup_first_removed_at = now(),
      cleanup_claim_id = null,
      cleanup_claimed_at = null
  where cleanup_claim_id = p_claim_id
    and storage_path = any(p_storage_paths)
    and cleanup_first_removed_at is null;
  get diagnostics v_staged = row_count;

  return jsonb_build_object('staged', v_staged, 'deleted', v_deleted);
end;
$$;

create or replace function public.release_expired_voicebrief_upload_cleanup(
  p_claim_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_released integer := 0;
begin
  if p_claim_id is null then
    raise exception 'invalid_cleanup_release';
  end if;
  update public.audio_upload_reservations
  set cleanup_claim_id = null,
      cleanup_claimed_at = null
  where cleanup_claim_id = p_claim_id;
  get diagnostics v_released = row_count;
  return v_released;
end;
$$;

revoke all on function public.claim_expired_voicebrief_uploads(integer)
  from public, anon, authenticated;
revoke all on function public.complete_expired_voicebrief_upload_cleanup(uuid, text[])
  from public, anon, authenticated;
revoke all on function public.release_expired_voicebrief_upload_cleanup(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_expired_voicebrief_uploads(integer)
  to service_role;
grant execute on function public.complete_expired_voicebrief_upload_cleanup(uuid, text[])
  to service_role;
grant execute on function public.release_expired_voicebrief_upload_cleanup(uuid)
  to service_role;

create extension if not exists supabase_vault with schema vault;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;

create or replace function public.invoke_voicebrief_expired_audio_cleanup()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  v_project_url text;
  v_secret_key text;
  v_request_id bigint;
begin
  select decrypted_secret into v_project_url
  from vault.decrypted_secrets
  where name = 'voicebrief_project_url';
  select decrypted_secret into v_secret_key
  from vault.decrypted_secrets
  where name = 'voicebrief_secret_key';

  if nullif(trim(v_project_url), '') is null
      or nullif(v_secret_key, '') is null then
    raise exception 'voicebrief_cleanup_vault_not_configured';
  end if;

  select net.http_post(
    url := rtrim(v_project_url, '/') || '/functions/v1/cleanup-expired-audio',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'apikey', v_secret_key
    ),
    body := '{}'::jsonb,
    timeout_milliseconds := 30000
  ) into v_request_id;
  return v_request_id;
end;
$$;

revoke all on function public.invoke_voicebrief_expired_audio_cleanup()
  from public, anon, authenticated, service_role;

do $$
begin
  if not exists (
    select 1 from cron.job
    where jobname = 'voicebrief-expired-audio-cleanup'
  ) then
    perform cron.schedule(
      'voicebrief-expired-audio-cleanup',
      '*/15 * * * *',
      'select public.invoke_voicebrief_expired_audio_cleanup()'
    );
  end if;
end;
$$;
