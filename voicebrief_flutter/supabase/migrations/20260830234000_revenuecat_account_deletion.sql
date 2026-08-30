begin;

alter table public.revenuecat_webhook_events
  add column handling_status text not null default 'applied'
  check (
    handling_status in (
      'applied',
      'ignored_missing_profile',
      'anonymized_deleted_user'
    )
  );

update public.revenuecat_webhook_events as event
set app_user_id = null,
    handling_status = 'anonymized_deleted_user'
where event.app_user_id is not null
  and not exists (
    select 1
    from public.profiles as profile
    where profile.user_id = event.app_user_id
  );

alter table public.revenuecat_webhook_events
  add constraint revenuecat_webhook_events_app_user_id_fkey
  foreign key (app_user_id)
  references public.profiles(user_id)
  on delete set null;

create index revenuecat_webhook_events_app_user_idx
  on public.revenuecat_webhook_events(app_user_id)
  where app_user_id is not null;

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

drop trigger if exists on_voicebrief_profile_deleted on public.profiles;
create trigger on_voicebrief_profile_deleted
before delete on public.profiles
for each row execute function public.anonymize_revenuecat_events_on_profile_delete();

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
  v_profile_exists boolean;
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

revoke all on function public.anonymize_revenuecat_events_on_profile_delete()
  from public, anon, authenticated;
revoke all on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) from public, anon, authenticated;
grant execute on function public.apply_revenuecat_event(
  text, text, uuid, boolean, text, text, timestamptz, timestamptz, timestamptz
) to service_role;

commit;
