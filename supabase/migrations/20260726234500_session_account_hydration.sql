-- Otlobli v86.5: restore account state from the authenticated customer session.
--
-- The client may restart before it has a local phone/profile snapshot. The
-- session is already the stronger identity proof, so account and wallet reads
-- must resolve the customer/phone from that session rather than trusting a
-- possibly empty or stale form value.

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
        ) order by oi.created_at), '[]'::jsonb)
        from public.order_items oi
        where oi.order_id = o.id
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
        from public.cart_group_members cgm
        where cgm.group_id = o.group_id
      ) end,
      'deliveryMemberKey', o.delivery_member_key,
      'deliveryOwnerPhone', o.delivery_owner_phone,
      'deliveryOwnerName', o.delivery_owner_name
    ) order by o.created_at desc), '[]'::jsonb)
  from public.orders o
  where (target_customer_id is not null and o.customer_id = target_customer_id)
     or (
       length(regexp_replace(coalesce(target_phone, ''), '[^0-9]', '', 'g')) >= 9
       and length(regexp_replace(coalesce(o.phone, ''), '[^0-9]', '', 'g')) >= 9
       and right(regexp_replace(o.phone, '[^0-9]', '', 'g'), 9)
         = right(regexp_replace(target_phone, '[^0-9]', '', 'g'), 9)
     )
     or (
       o.group_id is not null
       and exists (
         select 1
         from public.cart_group_members cgm
         where cgm.group_id = o.group_id
           and (
             (target_customer_id is not null and cgm.customer_id = target_customer_id)
             or (
               length(regexp_replace(coalesce(target_phone, ''), '[^0-9]', '', 'g')) >= 9
               and length(regexp_replace(coalesce(cgm.phone, ''), '[^0-9]', '', 'g')) >= 9
               and right(regexp_replace(cgm.phone, '[^0-9]', '', 'g'), 9)
                 = right(regexp_replace(target_phone, '[^0-9]', '', 'g'), 9)
             )
           )
       )
     );
$$;

revoke all on function public.customer_orders_json(uuid, text) from public;
grant execute on function public.customer_orders_json(uuid, text) to anon, authenticated, service_role;

create or replace function public.get_customer_account(p_phone text, p_session_token text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  resolved_phone text;
  payload jsonb;
  available_syp integer;
begin
  -- Session is authoritative. p_phone remains in the signature for backwards
  -- compatibility with installed clients, but cannot redirect the read.
  target_customer_id := public.require_customer_session(p_session_token, null);

  select phone into resolved_phone
  from public.customers
  where id = target_customer_id;

  if coalesce(resolved_phone, '') = '' then
    raise exception 'customer account not found';
  end if;

  payload := public.get_customer_account(resolved_phone);
  available_syp := public.available_wallet_syp(target_customer_id);
  payload := payload || jsonb_build_object('walletBalanceSyp', available_syp);
  if jsonb_typeof(payload->'profile') = 'object' then
    payload := jsonb_set(
      payload,
      '{profile}',
      (payload->'profile') || jsonb_build_object('walletBalanceSyp', available_syp),
      true
    );
  end if;
  return payload;
end;
$$;

revoke all on function public.get_customer_account(text, text) from public;
grant execute on function public.get_customer_account(text, text) to anon, authenticated;

create or replace function public.get_wallet_balance_usd(p_phone text, p_session_token text)
returns numeric
language plpgsql
security definer
set search_path = public
as $$
declare
  target_customer_id uuid;
  usd_rate numeric;
begin
  -- Resolve solely from the signed session. This keeps wallet state stable
  -- even when the local delivery-phone field is not hydrated yet.
  target_customer_id := public.require_customer_session(p_session_token, null);
  select value::numeric into usd_rate from public.app_settings where key = 'usd_to_syp_rate';
  usd_rate := case when usd_rate > 0 then usd_rate else 13000 end;
  return round(public.available_wallet_syp(target_customer_id) / usd_rate, 2);
end;
$$;

revoke all on function public.get_wallet_balance_usd(text, text) from public;
grant execute on function public.get_wallet_balance_usd(text, text) to anon, authenticated;
