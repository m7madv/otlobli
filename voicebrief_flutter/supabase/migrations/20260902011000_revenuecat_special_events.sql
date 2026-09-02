begin;

create table if not exists public.subscription_sync_rate_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  request_count integer not null check (request_count between 1 and 6),
  updated_at timestamptz not null default now()
);

alter table public.subscription_sync_rate_limits enable row level security;
revoke all on table public.subscription_sync_rate_limits
  from public, anon, authenticated;
grant all on table public.subscription_sync_rate_limits to service_role;

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

alter table public.revenuecat_webhook_events
  drop constraint if exists revenuecat_webhook_events_handling_status_check;
alter table public.revenuecat_webhook_events
  add constraint revenuecat_webhook_events_handling_status_check check (
    handling_status in (
      'applied',
      'ignored_missing_profile',
      'ignored_non_subscription',
      'anonymized_deleted_user'
    )
  );

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

-- Keep the paid quota boundary separate from the effective access boundary.
-- A billing grace period extends the final quota window, but never creates a
-- second 300-minute refill. Overlapping Pro periods carry consumption forward
-- so a temporary grant followed by INITIAL_PURCHASE cannot refill the account.
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

-- Preserve the old RPC signature during the edge-function rollout.
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

  -- TRANSFER is rare and must serialize against quota reservation/completion.
  -- This makes a concurrent reserve either finish before the copy or observe
  -- the revoked source entitlement after this transaction commits.
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

-- A Pro row is selectable only when it belongs to the generation currently
-- named by subscription_state. Historical annual windows remain immutable
-- audit history and cannot be selected after a product change or transfer.
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

  select * into v_job
  from public.processing_jobs
  where user_id = v_user_id and id = p_job_id
  for update;
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
  if v_period.used_minutes + v_period.reserved_minutes + v_minutes >
      v_period.quota_minutes then
    return jsonb_build_object('state', 'quota_exhausted');
  end if;

  insert into public.service_budget_months(period_key, max_audio_minutes)
    values (v_budget_period_key, 500)
    on conflict do nothing;
  select * into v_budget
  from public.service_budget_months
  where period_key = v_budget_period_key
  for update;
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

  update public.usage_periods
  set reserved_minutes = reserved_minutes + v_minutes,
      updated_at = now()
  where id = v_period.id;

  update public.service_budget_months
  set reserved_audio_minutes = reserved_audio_minutes + v_minutes,
      updated_at = now()
  where period_key = v_budget_period_key;

  insert into public.usage_ledger(
    user_id,
    job_id,
    usage_period_id,
    kind,
    minutes
  ) values (
    v_user_id,
    p_job_id,
    v_period.id,
    'reserve',
    v_minutes
  ) on conflict do nothing;

  update public.processing_jobs
  set status = 'processing', updated_at = now()
  where user_id = v_user_id and id = p_job_id;
  return jsonb_build_object(
    'state', 'reserved',
    'plan', v_period.plan,
    'billedMinutes', v_minutes,
    'remainingMinutes',
      v_period.quota_minutes - v_period.used_minutes -
        v_period.reserved_minutes - v_minutes
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

revoke all on function public.apply_revenuecat_transfer(
  text, text, uuid[], uuid, boolean, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_transfer(
  text, text, uuid[], uuid, boolean, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz
) to service_role;

revoke all on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text,
  timestamptz, timestamptz, timestamptz, timestamptz
) to service_role;

revoke all on function public.record_ignored_revenuecat_event(
  text, text, uuid
) from public, anon, authenticated;
grant execute on function public.record_ignored_revenuecat_event(
  text, text, uuid
) to service_role;

revoke all on function public.reserve_voicebrief_minutes(
  uuid,
  uuid,
  text,
  integer
) from public, anon, authenticated;
grant execute on function public.reserve_voicebrief_minutes(
  uuid,
  uuid,
  text,
  integer
) to service_role;

revoke all on function public.get_voicebrief_subscription_status()
  from public, anon;
grant execute on function public.get_voicebrief_subscription_status()
  to authenticated, service_role;

revoke all on function public.claim_voicebrief_subscription_sync(uuid)
  from public, anon, authenticated;
grant execute on function public.claim_voicebrief_subscription_sync(uuid)
  to service_role;
grant execute on function public.voicebrief_subscription_generation_key(
  text,
  timestamptz
) to service_role;

commit;
