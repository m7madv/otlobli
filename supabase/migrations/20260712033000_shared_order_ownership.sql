-- Shared-order ownership, member visibility, delivery selection, and
-- owner-scoped product-issue responses. Forward-only; payment and wallet
-- calculations remain in create_pending_order unchanged.

alter table public.orders
  add column if not exists delivery_member_key text not null default '',
  add column if not exists delivery_owner_phone text not null default '',
  add column if not exists delivery_owner_name text not null default '';

alter table public.order_items
  add column if not exists owner_member_key text not null default '',
  add column if not exists owner_phone text not null default '',
  add column if not exists owner_name text not null default '';

update public.orders
set delivery_owner_phone = phone,
    delivery_owner_name = customer_name
where delivery_owner_phone = '' and delivery_owner_name = '';

-- Backfill only unambiguous legacy group lines. If two members added the same
-- product id, leaving ownership empty is safer than assigning it incorrectly;
-- legacy empty ownership falls back to the payer in the authorization helper.
with matches as (
  select
    oi.id as order_item_id,
    min(cgi.member_key) as member_key,
    min(cgm.phone) as phone,
    min(cgm.display_name) as display_name
  from public.order_items oi
  join public.orders o on o.id = oi.order_id and o.group_id is not null
  join public.cart_group_items cgi
    on cgi.group_id = o.group_id and cgi.payload->>'id' = oi.product_id
  join public.cart_group_members cgm
    on cgm.group_id = cgi.group_id and cgm.member_key = cgi.member_key
  where oi.owner_member_key = '' and oi.owner_phone = ''
  group by oi.id
  having count(*) = 1
)
update public.order_items oi
set owner_member_key = matches.member_key,
    owner_phone = matches.phone,
    owner_name = matches.display_name
from matches
where oi.id = matches.order_item_id;

create or replace function public.create_pending_order_v2(
  order_payload jsonb,
  currency text,
  p_session_token text,
  p_wallet_spend_usd numeric
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
  target_order_id text;
  target_group_id uuid;
  selected_delivery_key text := '';
  selected_delivery_phone text := '';
  selected_delivery_name text := '';
begin
  result := public.create_pending_order(order_payload, currency, p_session_token, p_wallet_spend_usd);
  target_order_id := result->>'orderId';

  select o.group_id into target_group_id
  from public.orders o
  where o.id = target_order_id;

  -- Never trust the client-supplied delivery phone/name. Resolve both from
  -- the selected member key in the server-side group snapshot.
  if target_group_id is not null then
    select cgm.member_key, cgm.phone, cgm.display_name
    into selected_delivery_key, selected_delivery_phone, selected_delivery_name
    from public.cart_group_members cgm
    where cgm.group_id = target_group_id
      and cgm.member_key = left(coalesce(order_payload->>'deliveryMemberKey', ''), 200)
    limit 1;
  end if;

  update public.orders o
  set delivery_member_key = coalesce(selected_delivery_key, ''),
      delivery_owner_phone = coalesce(nullif(selected_delivery_phone, ''), o.phone),
      delivery_owner_name = coalesce(nullif(selected_delivery_name, ''), o.customer_name)
  where o.id = target_order_id;

  with payload_items as (
    select
      item->>'id' as product_id,
      left(coalesce(item->>'ownerMemberKey', ''), 200) as owner_member_key,
      left(coalesce(item->>'ownerPhone', ''), 80) as owner_phone,
      left(coalesce(item->>'ownerName', ''), 200) as owner_name,
      row_number() over (partition by item->>'id' order by ordinal) as occurrence
    from jsonb_array_elements(order_payload->'items') with ordinality as source(item, ordinal)
  ), db_items as (
    select oi.id, oi.product_id,
      row_number() over (partition by oi.product_id order by oi.created_at, oi.id) as occurrence
    from public.order_items oi
    where oi.order_id = target_order_id
  ), paired as (
    select db.id, member.member_key as owner_member_key,
      member.phone as owner_phone, member.display_name as owner_name
    from db_items db
    join payload_items payload
      on payload.product_id = db.product_id and payload.occurrence = db.occurrence
    join public.cart_group_members member
      on member.group_id = target_group_id and member.member_key = payload.owner_member_key
    where target_group_id is not null
      and exists (
        select 1
        from public.cart_group_items group_item
        where group_item.group_id = target_group_id
          and group_item.member_key = member.member_key
          and group_item.payload->>'id' = db.product_id
      )
  )
  update public.order_items oi
  set owner_member_key = paired.owner_member_key,
      owner_phone = paired.owner_phone,
      owner_name = paired.owner_name
  from paired
  where oi.id = paired.id;

  return result;
end;
$$;

revoke all on function public.create_pending_order_v2(jsonb, text, text, numeric) from public;
grant execute on function public.create_pending_order_v2(jsonb, text, text, numeric) to anon, authenticated;

create or replace function public.customer_owns_order_item_row(p_order_item_id uuid, p_customer_id uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.order_items oi
    join public.orders o on o.id = oi.order_id
    left join public.cart_group_members cgm
      on cgm.group_id = o.group_id and cgm.member_key = oi.owner_member_key
    left join public.customers owner_customer
      on regexp_replace(owner_customer.phone, '\s+', '', 'g') = regexp_replace(oi.owner_phone, '\s+', '', 'g')
    where oi.id = p_order_item_id
      and (
        cgm.customer_id = p_customer_id
        or owner_customer.id = p_customer_id
        or (oi.owner_member_key = '' and oi.owner_phone = '' and o.customer_id = p_customer_id)
      )
  );
$$;

create or replace function public.customer_owns_order_item(
  p_order_id text,
  p_product_or_item_id text,
  p_customer_id uuid
)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1 from public.order_items oi
    where oi.order_id = p_order_id
      and (oi.id::text = p_product_or_item_id or oi.product_id = p_product_or_item_id)
      and public.customer_owns_order_item_row(oi.id, p_customer_id)
  );
$$;

revoke all on function public.customer_owns_order_item_row(uuid, uuid) from public, anon, authenticated;
revoke all on function public.customer_owns_order_item(text, text, uuid) from public, anon, authenticated;
grant execute on function public.customer_owns_order_item_row(uuid, uuid) to service_role;
grant execute on function public.customer_owns_order_item(text, text, uuid) to service_role;

create or replace function public.customer_orders_json(target_customer_id uuid, target_phone text)
returns jsonb
language sql
security definer
set search_path = public
stable
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', o.id,
      'customer', o.customer_name,
      'phone', o.phone,
      'city', o.city,
      'address', o.address,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', oi.product_id,
          'orderItemId', oi.id,
          'title', oi.title,
          'image', oi.image,
          'color', oi.color,
          'size', oi.size,
          'quantity', oi.quantity,
          'priceSyp', oi.price_syp,
          'sourceLink', oi.source_link,
          'customText', oi.custom_text,
          'customPhotoDataUrl', oi.custom_photo,
          'customPhotoNote', oi.custom_photo_note,
          'ownerMemberKey', oi.owner_member_key,
          'ownerPhone', oi.owner_phone,
          'ownerName', oi.owner_name
        ) order by oi.created_at, oi.id), '[]'::jsonb)
        from public.order_items oi where oi.order_id = o.id
      ),
      'total', o.total_syp,
      'paymentStatus', o.payment_status,
      'statusIndex', o.status_index,
      'qadmousNumber', o.qadmous_number,
      'createdAt', o.created_at,
      'paidAt', o.paid_at,
      'rating', o.rating,
      'ratingNote', o.rating_note,
      'paymentIssue', o.payment_issue,
      'paymentIssueNote', o.payment_issue_note,
      'extraAmountUsd', o.extra_amount_usd,
      'invoice', o.invoice,
      'issues', o.issues,
      'groupId', o.group_id,
      'groupCode', o.group_code,
      'groupMembers', case when o.group_id is null then '[]'::jsonb else (
        select coalesce(jsonb_agg(jsonb_build_object(
          'memberKey', cgm.member_key,
          'phone', cgm.phone,
          'name', cgm.display_name,
          'role', cgm.role
        ) order by case when cgm.role = 'host' then 0 else 1 end, cgm.joined_at), '[]'::jsonb)
        from public.cart_group_members cgm where cgm.group_id = o.group_id
      ) end,
      'deliveryMemberKey', o.delivery_member_key,
      'deliveryOwnerPhone', o.delivery_owner_phone,
      'deliveryOwnerName', o.delivery_owner_name
    ) order by o.created_at desc, o.id desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (target_phone <> '' and o.phone = target_phone)
     or (
       o.group_id is not null and exists (
         select 1 from public.cart_group_members cgm
         where cgm.group_id = o.group_id
           and (
             (target_customer_id is not null and cgm.customer_id = target_customer_id)
             or (target_phone <> '' and regexp_replace(cgm.phone, '\s+', '', 'g') = regexp_replace(target_phone, '\s+', '', 'g'))
           )
       )
     );
$$;

revoke all on function public.customer_orders_json(uuid, text) from public, anon, authenticated;
grant execute on function public.customer_orders_json(uuid, text) to service_role;

create or replace function public.submit_order_option_fix(
  target_order_id text,
  p_product_id text,
  p_field text,
  p_value text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  updated_count integer;
  clean_value text := left(trim(coalesce(p_value, '')), 120);
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_value = '' or p_field not in ('size', 'color') then return false; end if;
  if p_field = 'size' then
    update public.order_items oi set size = clean_value
    where oi.order_id = target_order_id
      and (oi.id::text = p_product_id or oi.product_id = p_product_id)
      and public.customer_owns_order_item_row(oi.id, target_customer_id);
  else
    update public.order_items oi set color = clean_value
    where oi.order_id = target_order_id
      and (oi.id::text = p_product_id or oi.product_id = p_product_id)
      and public.customer_owns_order_item_row(oi.id, target_customer_id);
  end if;
  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_option_fix(text, text, text, text, text) from public;
grant execute on function public.submit_order_option_fix(text, text, text, text, text) to anon, authenticated;

create or replace function public.submit_order_custom_fix(
  target_order_id text,
  p_product_id text,
  p_custom_photo text,
  p_custom_text text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  updated_count integer;
  clean_photo text := trim(coalesce(p_custom_photo, ''));
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_photo <> '' and (
    length(clean_photo) > 4000000
    or clean_photo !~ '^data:image/(png|jpeg|jpg|webp);base64,[A-Za-z0-9+/=[:space:]]+$'
  ) then return false; end if;
  update public.order_items oi
  set custom_photo = coalesce(nullif(clean_photo, ''), oi.custom_photo),
      custom_text = coalesce(nullif(left(trim(coalesce(p_custom_text, '')), 2000), ''), oi.custom_text)
  where oi.order_id = target_order_id
    and (oi.id::text = p_product_id or oi.product_id = p_product_id)
    and public.customer_owns_order_item_row(oi.id, target_customer_id);
  get diagnostics updated_count = row_count;
  return updated_count > 0;
end;
$$;

revoke all on function public.submit_order_custom_fix(text, text, text, text, text) from public;
grant execute on function public.submit_order_custom_fix(text, text, text, text, text) to anon, authenticated;

-- Backward-compatible text-only resolver. Payment issues still cannot be
-- self-resolved, and product issues are owner-scoped.
create or replace function public.submit_order_issue_resolve(
  target_order_id text,
  p_issue_id text,
  p_resolved_value text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id and issue->>'type' = 'payment'
  ) then return false; end if;
  if not exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id
      and (
        (coalesce(issue->>'itemId', '') <> '' and public.customer_owns_order_item(o.id, issue->>'itemId', target_customer_id))
        or (coalesce(issue->>'itemId', '') = '' and o.customer_id = target_customer_id)
      )
  ) then return false; end if;
  return public.submit_order_issue_resolve(target_order_id, p_issue_id, left(coalesce(p_resolved_value, ''), 2000));
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text) to anon, authenticated;

create or replace function public.submit_order_issue_resolve(
  target_order_id text,
  p_issue_id text,
  p_resolved_value text,
  p_resolved_photo_data_url text,
  p_session_token text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  clean_photo text := trim(coalesce(p_resolved_photo_data_url, ''));
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  if clean_photo <> '' and (
    length(clean_photo) > 4000000
    or clean_photo !~ '^data:image/(png|jpeg|jpg|webp);base64,[A-Za-z0-9+/=[:space:]]+$'
  ) then return false; end if;
  if exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id and issue->>'type' = 'payment'
  ) then return false; end if;
  if not exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id
      and (
        (coalesce(issue->>'itemId', '') <> '' and public.customer_owns_order_item(o.id, issue->>'itemId', target_customer_id))
        or (coalesce(issue->>'itemId', '') = '' and o.customer_id = target_customer_id)
      )
  ) then return false; end if;
  if clean_photo <> '' and not exists (
    select 1 from public.orders o, jsonb_array_elements(o.issues) issue
    where o.id = target_order_id and issue->>'id' = p_issue_id
      and (issue->>'requestPhoto' = 'true' or issue->>'responseType' = 'image')
  ) then return false; end if;

  -- Reuse the hardened core resolver so payment_issue/note/amount are
  -- recalculated exactly like text/option responses.
  if not public.submit_order_issue_resolve(
    target_order_id,
    p_issue_id,
    left(coalesce(p_resolved_value, ''), 2000)
  ) then return false; end if;

  if clean_photo <> '' then
    update public.orders o
    set issues = (
      select jsonb_agg(
        case when issue->>'id' = p_issue_id
          then issue || jsonb_build_object('resolvedPhotoDataUrl', clean_photo)
          else issue end
      ) from jsonb_array_elements(o.issues) issue
    )
    where o.id = target_order_id and exists (
      select 1 from jsonb_array_elements(o.issues) issue
      where issue->>'id' = p_issue_id
    );
  end if;
  return true;
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text, text) to anon, authenticated;

create or replace function public.get_order_payment_status(
  target_order_id text,
  p_session_token text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  found_order public.orders%rowtype;
begin
  target_customer_id := public.require_customer_session(p_session_token, null);
  select * into found_order
  from public.orders o
  where o.id = target_order_id
    and (
      o.customer_id = target_customer_id
      or (
        o.group_id is not null and exists (
          select 1 from public.cart_group_members cgm
          where cgm.group_id = o.group_id and cgm.customer_id = target_customer_id
        )
      )
    );
  if not found then return jsonb_build_object('found', false); end if;
  return jsonb_build_object(
    'found', true,
    'paymentStatus', found_order.payment_status,
    'statusIndex', found_order.status_index,
    'paidAt', found_order.paid_at,
    'paymentAmount', found_order.payment_amount,
    'paymentCurrency', found_order.payment_currency,
    'paymentExpiresAt', found_order.payment_expires_at,
    'qadmousNumber', found_order.qadmous_number,
    'paymentIssue', found_order.payment_issue,
    'paymentIssueNote', found_order.payment_issue_note,
    'extraAmountUsd', found_order.extra_amount_usd
  );
end;
$$;

revoke all on function public.get_order_payment_status(text, text) from public;
grant execute on function public.get_order_payment_status(text, text) to anon, authenticated;
