-- Keep the structured v63 issue list authoritative when an issue-payment is
-- confirmed by ShamCash. Without this, the legacy payment_issue fields are
-- cleared while issues[] still contains an unresolved payment issue, allowing
-- the admin save path to recreate the same charge.

create or replace function public.sync_order_issue_payment_resolution(p_order_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_issues jsonb;
begin
  if coalesce(p_order_id, '') = '' then
    return;
  end if;

  update public.orders o
  set issues = (
    select coalesce(jsonb_agg(
      case
        when elem->>'type' = 'payment'
          and coalesce(lower(elem->>'resolved'), 'false') <> 'true'
        then elem || jsonb_build_object('resolved', true, 'resolvedValue', 'payment_confirmed')
        else elem
      end
    ), '[]'::jsonb)
    from jsonb_array_elements(
      case when jsonb_typeof(o.issues) = 'array' then o.issues else '[]'::jsonb end
    ) elem
  )
  where o.id = p_order_id
  returning o.issues into normalized_issues;

  if normalized_issues is null then
    return;
  end if;

  -- Re-derive the legacy fields from unresolved structured issues. This keeps
  -- old clients and the current customer UI coherent after the payment row is
  -- settled, while excluding resolved payment amounts from future charges.
  update public.orders o
  set payment_issue = coalesce(state.has_unresolved, false),
      payment_issue_note = case
        when coalesce(state.has_unresolved, false) then coalesce(o.payment_issue_note, '')
        else ''
      end,
      extra_amount_usd = coalesce(state.payment_total, 0)
  from (
    select
      coalesce(bool_or(coalesce(lower(elem->>'resolved'), 'false') <> 'true'), false) as has_unresolved,
      coalesce(sum(
        case
          when elem->>'type' = 'payment'
            and coalesce(lower(elem->>'resolved'), 'false') <> 'true'
          then greatest(coalesce((elem->>'amountUsd')::numeric, 0), 0)
          else 0
        end
      ), 0) as payment_total
    from jsonb_array_elements(normalized_issues) elem
  ) state
  where o.id = p_order_id;
end;
$$;

revoke all on function public.sync_order_issue_payment_resolution(text) from public, anon, authenticated;
grant execute on function public.sync_order_issue_payment_resolution(text) to service_role;

create or replace function public.sync_order_issue_payment_resolution_trigger()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = U&'\0645\062f\0641\0648\0639'
     and old.status is distinct from new.status then
    perform public.sync_order_issue_payment_resolution(new.order_id);
  end if;
  return new;
end;
$$;

revoke all on function public.sync_order_issue_payment_resolution_trigger() from public, anon, authenticated;
grant execute on function public.sync_order_issue_payment_resolution_trigger() to service_role;

drop trigger if exists order_issue_payment_resolution_sync on public.order_issue_payments;
create constraint trigger order_issue_payment_resolution_sync
after update of status on public.order_issue_payments
deferrable initially deferred
for each row
execute function public.sync_order_issue_payment_resolution_trigger();

-- Repair any issue-payment rows that were already marked paid before this
-- trigger existed.
do $$
declare
  payment_order record;
begin
  for payment_order in
    select distinct order_id
    from public.order_issue_payments
    where status = U&'\0645\062f\0641\0648\0639'
  loop
    perform public.sync_order_issue_payment_resolution(payment_order.order_id);
  end loop;
end;
$$;

-- A customer may resolve option/size/custom issues, but a payment issue must
-- be resolved only by a confirmed payment (or an explicit service-role action).
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
  if not exists (
    select 1
    from public.orders
    where id = target_order_id and customer_id = target_customer_id
  ) then
    return false;
  end if;

  if exists (
    select 1
    from public.orders o,
         jsonb_array_elements(case when jsonb_typeof(o.issues) = 'array' then o.issues else '[]'::jsonb end) elem
    where o.id = target_order_id
      and elem->>'id' = p_issue_id
      and elem->>'type' = 'payment'
  ) then
    return false;
  end if;

  return public.submit_order_issue_resolve(target_order_id, p_issue_id, p_resolved_value);
end;
$$;

revoke all on function public.submit_order_issue_resolve(text, text, text, text) from public;
grant execute on function public.submit_order_issue_resolve(text, text, text, text) to anon, authenticated;
