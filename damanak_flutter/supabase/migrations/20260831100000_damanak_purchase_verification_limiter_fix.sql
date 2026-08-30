-- Avoid collision with PostgreSQL's CURRENT_TIME keyword in the verification
-- limiter. The previous local variable name resolved as timetz during UTC day
-- initialization and rejected every reservation before provider verification.

create or replace function public.reserve_store_purchase_verification(
  target_store_id uuid,
  target_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_time timestamptz := clock_timestamp();
  current_utc_day date := (request_time at time zone 'UTC')::date;
  limit_row private.store_purchase_verification_limits%rowtype;
  retry_after integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role = 'owner'
      and member.status = 'active'
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  insert into private.store_purchase_verification_limits(
    user_id, store_id, window_started_at, day_started_at
  ) values (
    target_user_id, target_store_id, request_time, current_utc_day
  )
  on conflict (user_id, store_id) do nothing;

  select * into limit_row
  from private.store_purchase_verification_limits limits
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id
  for update;

  if limit_row.window_started_at <= request_time - interval '15 minutes' then
    limit_row.window_started_at := request_time;
    limit_row.window_attempts := 0;
  end if;
  if limit_row.day_started_at <> current_utc_day then
    limit_row.day_started_at := current_utc_day;
    limit_row.day_attempts := 0;
  end if;

  update private.store_purchase_verification_limits limits
  set window_started_at = limit_row.window_started_at,
      window_attempts = limit_row.window_attempts,
      day_started_at = limit_row.day_started_at,
      day_attempts = limit_row.day_attempts,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  if limit_row.window_attempts >= 10 or limit_row.day_attempts >= 50 then
    retry_after := greatest(
      case when limit_row.window_attempts >= 10 then
        ceil(extract(epoch from (
          limit_row.window_started_at + interval '15 minutes' - request_time
        )))::integer
      else 0 end,
      case when limit_row.day_attempts >= 50 then
        ceil(extract(epoch from (
          ((current_utc_day + 1)::timestamp at time zone 'UTC') - request_time
        )))::integer
      else 0 end,
      1
    );
    return jsonb_build_object(
      'allowed', false,
      'retry_after_seconds', retry_after
    );
  end if;

  update private.store_purchase_verification_limits limits
  set window_attempts = window_attempts + 1,
      day_attempts = day_attempts + 1,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  return jsonb_build_object(
    'allowed', true,
    'window_remaining', 9 - limit_row.window_attempts,
    'day_remaining', 49 - limit_row.day_attempts
  );
end;
$$;

revoke all on function public.reserve_store_purchase_verification(uuid, uuid)
  from public, anon, authenticated;
grant execute on function public.reserve_store_purchase_verification(uuid, uuid)
  to service_role;
