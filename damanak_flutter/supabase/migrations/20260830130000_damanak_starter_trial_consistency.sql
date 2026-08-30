-- New stores trial the Starter entitlement, not Growth. Existing trial stores
-- are moved only when the downgrade cannot strand more than two active members
-- or more than the Starter monthly warranty allowance.

do $$
begin
  if not exists (
    select 1
    from public.plans
    where id = 'starter'
      and is_active
  ) then
    raise exception 'DAMANAK_STARTER_PLAN_MISSING';
  end if;
end;
$$;

update public.subscriptions subscription
set plan_id = 'starter'
where subscription.status = 'trialing'
  and subscription.source = 'trial'
  and subscription.plan_id <> 'starter'
  and (
    select count(*)
    from public.store_members member
    where member.store_id = subscription.store_id
      and member.status = 'active'
  ) <= 2
  and (
    select count(*)
    from public.warranties warranty
    where warranty.store_id = subscription.store_id
      and warranty.created_at >= date_trunc('month', now())
      and warranty.voided_at is null
  ) <= 100;

create or replace function public.create_store_with_trial(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  created_store_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(trim(store_name)) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if store_country_code not in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM') then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    trim(store_name),
    trim(coalesce(store_phone, '')),
    trim(coalesce(store_city, '')),
    store_country_code,
    (select auth.uid())
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, (select auth.uid()), 'owner');

  insert into public.subscriptions(
    store_id,
    plan_id,
    status,
    trial_ends_at,
    source
  ) values (
    created_store_id,
    'starter',
    'trialing',
    now() + interval '14 days',
    'trial'
  );

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (
    created_store_id,
    (select auth.uid()),
    'store_created',
    'store',
    created_store_id
  );

  return created_store_id;
end;
$$;

comment on function public.create_store_with_trial(text, text, text, text) is
  'Creates a Gulf store with a 14-day Starter trial (100 warranties, 2 team accounts).';
