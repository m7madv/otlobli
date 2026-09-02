begin;

-- Drain writers in their runtime acquisition order before changing either
-- subscription table. Locking the webhook audit table first prevents a new
-- entitlement mutation; EXCLUSIVE on processing_jobs conflicts with its
-- SELECT FOR UPDATE paths, so reserve/complete/fail transactions already in
-- flight finish before the state/usage conversion starts.
lock table public.revenuecat_webhook_events in share row exclusive mode;
lock table public.processing_jobs in exclusive mode;
lock table public.subscription_state in share row exclusive mode;
lock table public.usage_periods in share row exclusive mode;
lock table public.usage_ledger in share row exclusive mode;

alter table public.subscription_state
  add column if not exists quota_generation_key text;
alter table public.usage_periods
  add column if not exists subscription_generation_key text;

create index if not exists usage_periods_active_subscription_generation_idx
  on public.usage_periods(
    user_id,
    subscription_generation_key,
    starts_at,
    ends_at
  )
  where plan = 'pro';

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

do $$
begin
  if exists (
    select 1
    from public.usage_periods up
    join public.subscription_state ss on ss.user_id = up.user_id
    where ss.entitlement = 'pro'
      and up.plan = 'pro'
      and up.period_key not like 'pro-month-%'
      and up.starts_at <= now()
      and up.ends_at > now()
      and up.used_minutes + up.reserved_minutes > 300
  ) then
    raise exception 'legacy_subscription_quota_exceeds_monthly_limit';
  end if;
  if exists (
    select 1
    from public.usage_periods up
    join public.subscription_state ss on ss.user_id = up.user_id
    where ss.entitlement = 'pro'
      and up.plan = 'pro'
      and up.period_key not like 'pro-month-%'
      and up.starts_at <= now()
      and up.ends_at > now()
    group by up.user_id
    having count(*) > 1
  ) then
    raise exception 'overlapping_legacy_subscription_periods';
  end if;
  if exists (
    select 1
    from public.subscription_state ss
    where ss.entitlement = 'pro'
      and ss.expires_at > now()
      and (
        select count(*)
        from public.usage_periods up
        where up.user_id = ss.user_id
          and up.plan = 'pro'
          and up.period_key not like 'pro-month-%'
          and up.ends_at = ss.expires_at
      ) <> 1
  ) then
    raise exception 'ambiguous_legacy_subscription_state_period';
  end if;
  if exists (
    select 1
    from public.usage_periods up
    join public.subscription_state ss on ss.user_id = up.user_id
    where ss.entitlement = 'pro'
      and ss.expires_at > now()
      and up.plan = 'pro'
      and up.period_key not like 'pro-month-%'
      and up.ends_at = ss.expires_at
      and up.starts_at > now()
      and up.used_minutes + up.reserved_minutes > 0
  ) then
    raise exception 'future_legacy_subscription_has_usage';
  end if;
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
  v_state_applied integer;
  v_period_key text;
  v_profile_exists boolean;
  v_window_index integer;
  v_window_limit integer;
  v_window_start timestamptz;
  v_window_end timestamptz;
  v_generation_key text;
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

  if p_is_pro and (
    p_period_start is null
    or p_period_end is null
    or p_period_end <= p_period_start
    or p_period_end > p_period_start + interval '2 years'
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

  insert into public.subscription_state(
    user_id, entitlement, product_id, store, expires_at, revenuecat_event_id,
    revenuecat_event_at, quota_generation_key, updated_at
  ) values (
    p_user_id, case when p_is_pro then 'pro' else 'free' end,
    left(p_product_id, 200), left(p_store, 40), p_period_end,
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
      v_window_end := least(
        p_period_end,
        p_period_start + make_interval(months => v_window_index + 1)
      );
      v_is_final_window := v_window_end >= p_period_end
        or v_window_index + 1 >= v_window_limit;
      if v_is_final_window then
        v_window_end := p_period_end;
      end if;
      if v_window_end <= v_window_start
        or v_window_index >= v_window_limit then
        raise exception 'invalid_subscription_period';
      end if;

      v_period_key := 'pro-month-' || v_generation_key
        || '-' || v_window_index::text;
      insert into public.usage_periods(
        user_id, period_key, plan, starts_at, ends_at, quota_minutes,
        subscription_generation_key
      ) values (
        p_user_id, v_period_key, 'pro', v_window_start, v_window_end, 300,
        v_generation_key
      ) on conflict (user_id, period_key) do update set
        starts_at = excluded.starts_at,
        ends_at = greatest(public.usage_periods.ends_at, excluded.ends_at),
        quota_minutes = excluded.quota_minutes,
        subscription_generation_key = excluded.subscription_generation_key,
        updated_at = now();

      v_window_index := v_window_index + 1;
      exit when v_is_final_window;
    end loop;
  end if;
  return true;
end;
$$;

-- Convert both the state-linked legacy period and any active predecessor. An
-- App Store renewal may already have moved subscription_state to a period that
-- starts up to 24 hours in the future; its predecessor becomes the temporary
-- bridge generation until that future period starts. Existing consumption and
-- active jobs move before each legacy row is retired.
do $$
declare
  v_legacy public.usage_periods%rowtype;
  v_window_index integer;
  v_window_limit integer;
  v_window_start timestamptz;
  v_window_end timestamptz;
  v_period_key text;
  v_new_period_id uuid;
  v_is_current boolean;
  v_is_final_window boolean;
  v_product_id text;
  v_generation_key text;
  v_state_expires_at timestamptz;
  v_is_state_period boolean;
begin
  for v_legacy in
    select up.*
    from public.usage_periods up
    join public.subscription_state ss on ss.user_id = up.user_id
    where ss.entitlement = 'pro'
      and ss.expires_at > now()
      and up.plan = 'pro'
      and up.period_key not like 'pro-month-%'
      and (
        up.ends_at = ss.expires_at
        or (up.starts_at <= now() and up.ends_at > now())
      )
    order by up.user_id, up.starts_at
  loop
    select product_id, expires_at
    into v_product_id, v_state_expires_at
    from public.subscription_state
    where user_id = v_legacy.user_id;
    v_is_state_period := v_legacy.ends_at = v_state_expires_at;
    v_generation_key := public.voicebrief_subscription_generation_key(
      v_product_id,
      v_legacy.starts_at
    );
    v_window_limit := public.voicebrief_subscription_window_limit(v_product_id);
    if v_is_state_period then
      update public.subscription_state
      set quota_generation_key = v_generation_key,
          updated_at = now()
      where user_id = v_legacy.user_id;
    end if;

    v_window_index := 0;
    loop
      v_window_start := v_legacy.starts_at
        + make_interval(months => v_window_index);
      exit when v_window_start >= v_legacy.ends_at;
      v_window_end := least(
        v_legacy.ends_at,
        v_legacy.starts_at + make_interval(months => v_window_index + 1)
      );
      v_is_final_window := v_window_end >= v_legacy.ends_at
        or v_window_index + 1 >= v_window_limit;
      if v_is_final_window then
        v_window_end := v_legacy.ends_at;
      end if;
      if v_window_end <= v_window_start
        or v_window_index >= v_window_limit then
        raise exception 'invalid_legacy_subscription_period';
      end if;
      v_is_current := v_window_start <= now() and v_window_end > now();
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
        v_legacy.user_id,
        v_period_key,
        'pro',
        v_window_start,
        v_window_end,
        300,
        case when v_is_current then v_legacy.used_minutes else 0 end,
        case when v_is_current then v_legacy.reserved_minutes else 0 end,
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
        updated_at = now()
      returning id into v_new_period_id;

      update public.usage_ledger ul
      set usage_period_id = v_new_period_id
      from public.processing_jobs pj
      where ul.usage_period_id = v_legacy.id
        and pj.user_id = ul.user_id
        and pj.id = ul.job_id
        and pj.created_at >= v_window_start
        and pj.created_at < v_window_end;

      update public.processing_jobs
      set usage_period_id = v_new_period_id
      where usage_period_id = v_legacy.id
        and created_at >= v_window_start
        and created_at < v_window_end;

      v_window_index := v_window_index + 1;
      exit when v_is_final_window;
    end loop;

    update public.usage_periods
    set ends_at = starts_at,
        used_minutes = 0,
        reserved_minutes = 0,
        updated_at = now()
    where id = v_legacy.id;
  end loop;

  if exists (
    select 1
    from public.subscription_state ss
    where ss.entitlement = 'pro'
      and ss.expires_at > now()
      and (
        ss.quota_generation_key is null
        or not exists (
          select 1
          from public.usage_periods up
          where up.user_id = ss.user_id
            and up.plan = 'pro'
            and up.subscription_generation_key = ss.quota_generation_key
        )
      )
  ) then
    raise exception 'legacy_subscription_generation_backfill_failed';
  end if;
end;
$$;

revoke all on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) to service_role;

revoke all on function public.voicebrief_subscription_window_limit(text)
  from public, anon, authenticated;
revoke all on function public.voicebrief_subscription_generation_key(
  text,
  timestamptz
) from public, anon, authenticated;
grant execute on function public.voicebrief_subscription_generation_key(
  text,
  timestamptz
) to service_role;

commit;
