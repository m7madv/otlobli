-- One shared order is exactly one host plus at most one friend. Refuse to
-- guess which historical member should survive if production already violates
-- that contract; the migration must stop for an explicit data review instead.
do $$
begin
  if exists (
    select 1
    from public.cart_group_members
    where role = 'host'
    group by group_id
    having count(*) > 1
  ) then
    raise exception 'group_order_integrity: more than one host exists in a cart group';
  end if;

  if exists (
    select 1
    from public.cart_group_members
    where role = 'member'
    group by group_id
    having count(*) > 1
  ) then
    raise exception 'group_order_integrity: more than one friend exists in a cart group';
  end if;

  if exists (
    select 1
    from public.cart_groups as g
    left join public.cart_group_members as host_member
      on host_member.group_id = g.id
      and host_member.role = 'host'
    where g.status = 'open'
      and g.expires_at > now()
    group by g.id, g.host_customer_id
    having count(host_member.group_id) <> 1
      or not coalesce(bool_and(host_member.customer_id = g.host_customer_id), false)
  ) then
    raise exception 'group_order_integrity: an active group has a missing or mismatched host';
  end if;
end;
$$;

create unique index if not exists cart_group_members_one_host_per_group_idx
on public.cart_group_members (group_id)
where role = 'host';

create unique index if not exists cart_group_members_one_friend_per_group_idx
on public.cart_group_members (group_id)
where role = 'member';

alter table public.cart_group_members
alter column member_key set default gen_random_uuid()::text;

-- The current app authenticates group mutations with require_customer_session
-- inside the Edge Function. Retire the older anonymous SECURITY DEFINER entry
-- points so a caller cannot impersonate a customer by supplying a phone number.
do $$
declare
  legacy_signature text;
  legacy_function regprocedure;
begin
  foreach legacy_signature in array array[
    'public.replace_cart_group_items(uuid,uuid,jsonb)',
    'public.cart_group_snapshot(uuid)',
    'public.create_cart_group(text,text,text,jsonb)',
    'public.join_cart_group(text,text,text,jsonb)',
    'public.sync_cart_group_items(text,uuid,jsonb)'
  ] loop
    legacy_function := to_regprocedure(legacy_signature);
    if legacy_function is not null then
      execute format(
        'revoke all on function %s from public, anon, authenticated, service_role',
        legacy_function
      );
    end if;
  end loop;
end;
$$;

-- Serialize member creation/update and item replacement with leave/cancel on
-- the group row. Every save is one transaction: a failed insert restores the
-- old cart, while a completed leave cannot be undone by an in-flight sync.
-- PostgreSQL cannot change an existing function return type with CREATE OR
-- REPLACE. The previous private helper returned text; no database object calls
-- it, so replace that exact signature without CASCADE.
drop function if exists public.save_cart_group_member_authenticated(text, uuid, text, text, text, boolean, jsonb);

create or replace function public.save_cart_group_member_authenticated(
  p_session_token text,
  p_group_id uuid,
  p_phone text,
  p_name text,
  p_role text,
  p_allow_insert boolean,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_customer_id uuid;
  target_member_key text;
  target_role text;
  target_status text;
  target_expires_at timestamptz;
  target_host_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if target_customer_id is null then
    raise exception 'invalid_session';
  end if;

  select status, expires_at, host_customer_id
  into target_status, target_expires_at, target_host_customer_id
  from public.cart_groups
  where id = p_group_id
  for update;

  if not found or target_status <> 'open' or target_expires_at <= now() then
    raise exception 'group_not_open';
  end if;

  select member_key, role
  into target_member_key, target_role
  from public.cart_group_members
  where group_id = p_group_id
    and customer_id = target_customer_id
    and role = case
      when target_host_customer_id = target_customer_id then 'host'
      else 'member'
    end
  for update;

  if not found then
    if not p_allow_insert then
      raise exception 'not_group_member';
    end if;
    if p_role not in ('host', 'member') then
      raise exception 'invalid_group_role';
    end if;
    if (p_role = 'host') <> (target_host_customer_id = target_customer_id) then
      raise exception 'invalid_group_role';
    end if;

    target_role := p_role;
    insert into public.cart_group_members (
      group_id, customer_id, phone, display_name, role
    ) values (
      p_group_id,
      target_customer_id,
      regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'),
      coalesce(nullif(trim(p_name), ''), 'عضو'),
      target_role
    )
    returning member_key into target_member_key;
  else
    update public.cart_group_members
    set phone = regexp_replace(coalesce(p_phone, ''), '\s+', '', 'g'),
        display_name = coalesce(nullif(trim(p_name), ''), display_name)
    where group_id = p_group_id
      and customer_id = target_customer_id
      and role = target_role;
  end if;

  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'invalid_group_items';
  end if;

  if jsonb_array_length(coalesce(p_items, '[]'::jsonb)) > 200 or exists (
    select 1
    from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) as item
    where jsonb_typeof(item) <> 'object'
  ) then
    raise exception 'invalid_group_items';
  end if;

  if exists (
    select 1
    from (
      select coalesce(nullif(item->>'id', ''), nullif(item->>'localItemId', '')) as item_key
      from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) as item
    ) as keyed_items
    where item_key is not null
    group by item_key
    having count(*) > 1
  ) then
    raise exception 'invalid_group_items';
  end if;

  delete from public.cart_group_items
  where group_id = p_group_id
    and member_key = target_member_key;

  insert into public.cart_group_items (
    group_id,
    customer_id,
    member_key,
    local_item_id,
    payload,
    price_usd,
    price_syp,
    quantity
  )
  select
    p_group_id,
    target_customer_id,
    target_member_key,
    coalesce(nullif(item->>'id', ''), nullif(item->>'localItemId', ''), gen_random_uuid()::text),
    item,
    greatest(coalesce(nullif(item->>'priceUsd', '')::numeric, 0), 0),
    greatest(coalesce(nullif(item->>'priceSyp', '')::integer, 0), 0),
    greatest(coalesce(nullif(item->>'quantity', '')::integer, 1), 1)
  from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) as item;

  return (
    select jsonb_build_object(
      'id', g.id,
      'code', g.code,
      'sourceStore', g.source_store,
      'status', g.status,
      'minTotalUsd', g.min_total_usd,
      'totalUsd', coalesce((
        select sum(group_item.price_usd * group_item.quantity)
        from public.cart_group_items as group_item
        where group_item.group_id = g.id
      ), 0),
      'members', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'memberKey', member.member_key,
          'phone', member.phone,
          'name', member.display_name,
          'role', member.role
        ) order by member.joined_at), '[]'::jsonb)
        from public.cart_group_members as member
        where member.group_id = g.id
      ),
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'ownerMemberKey', owner.member_key,
          'ownerPhone', owner.phone,
          'ownerName', owner.display_name,
          'item', group_item.payload
        ) order by group_item.updated_at), '[]'::jsonb)
        from public.cart_group_items as group_item
        join public.cart_group_members as owner
          on owner.group_id = group_item.group_id
          and owner.member_key = group_item.member_key
        where group_item.group_id = g.id
      )
    )
    from public.cart_groups as g
    where g.id = p_group_id
  );
end;
$$;

revoke all on function public.save_cart_group_member_authenticated(text, uuid, text, text, text, boolean, jsonb) from public, anon, authenticated;
grant execute on function public.save_cart_group_member_authenticated(text, uuid, text, text, text, boolean, jsonb) to service_role;

create or replace function public.create_cart_group_authenticated(
  p_session_token text,
  p_store text,
  p_phone text,
  p_name text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_customer_id uuid;
  target_group_id uuid;
  generated_code text;
  normalized_store text := case when lower(trim(coalesce(p_store, ''))) = 'temu' then 'temu' else 'shein' end;
  attempt integer;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if target_customer_id is null then
    raise exception 'invalid_session';
  end if;

  for attempt in 1..16 loop
    generated_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 9));
    begin
      insert into public.cart_groups (code, host_customer_id, source_store)
      values (generated_code, target_customer_id, normalized_store)
      returning id into target_group_id;
      exit;
    exception when unique_violation then
      target_group_id := null;
    end;
  end loop;

  if target_group_id is null then
    raise exception 'create_failed';
  end if;

  return public.save_cart_group_member_authenticated(
    p_session_token,
    target_group_id,
    p_phone,
    p_name,
    'host',
    true,
    p_items
  );
end;
$$;

revoke all on function public.create_cart_group_authenticated(text, text, text, text, jsonb) from public, anon, authenticated;
grant execute on function public.create_cart_group_authenticated(text, text, text, text, jsonb) to service_role;

create or replace function public.leave_cart_group_authenticated(
  p_session_token text,
  p_group_id uuid
)
returns text
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  target_customer_id uuid;
  target_member_key text;
  target_role text;
  target_status text;
  target_host_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if target_customer_id is null then
    raise exception 'invalid_session';
  end if;

  select status, host_customer_id
  into target_status, target_host_customer_id
  from public.cart_groups
  where id = p_group_id
  for update;

  if not found then
    return 'absent';
  end if;

  if target_status <> 'open' then
    return 'closed:' || target_status;
  end if;

  select member_key, role
  into target_member_key, target_role
  from public.cart_group_members
  where group_id = p_group_id
    and customer_id = target_customer_id
    and role = case
      when target_host_customer_id = target_customer_id then 'host'
      else 'member'
    end
  for update;

  if not found then
    return 'absent';
  end if;

  if target_role = 'host' then
    update public.cart_groups
    set status = 'cancelled'
    where id = p_group_id
      and host_customer_id = target_customer_id
      and status = 'open';
  else
    delete from public.cart_group_items
    where group_id = p_group_id
      and member_key = target_member_key;

    delete from public.cart_group_members
    where group_id = p_group_id
      and customer_id = target_customer_id
      and role = target_role;
  end if;

  return target_role;
end;
$$;

revoke all on function public.leave_cart_group_authenticated(text, uuid) from public, anon, authenticated;
grant execute on function public.leave_cart_group_authenticated(text, uuid) to service_role;
