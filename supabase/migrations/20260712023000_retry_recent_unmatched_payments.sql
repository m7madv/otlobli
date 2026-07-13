-- Allow a correctly signed notification that arrived just before its payment
-- intent committed to be reconciled for two minutes. Older unmatched events
-- remain terminal so a stale payment cannot drift into an unrelated intent.

create or replace function public.process_shamcash_payment_event(
  p_event_id text,
  p_amount numeric,
  p_currency text,
  p_notification_text text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  normalized_event_id text := trim(coalesce(p_event_id, ''));
  normalized_amount numeric := round(coalesce(p_amount, 0), 2);
  normalized_currency text := upper(trim(coalesce(p_currency, '')));
  found_event public.payment_events%rowtype;
  confirmation_result jsonb;
  merged_result jsonb;
  terminal_status text;
  resolved_matched_type text;
  resolved_matched_id text;
  effective_notification_text text;
begin
  if normalized_event_id = '' or length(normalized_event_id) > 160 then
    raise exception 'invalid payment event id';
  end if;
  if normalized_amount <= 0 or normalized_currency not in ('SYP', 'USD') then
    raise exception 'invalid parsed payment';
  end if;

  select * into found_event
  from public.payment_events
  where event_id = normalized_event_id
  for update;

  if not found then
    raise exception 'payment event not found';
  end if;
  if found_event.provider <> 'shamcash'
     or found_event.package_name <> 'com.shmacash.shamcash' then
    raise exception 'payment event source mismatch';
  end if;
  if found_event.parsed_amount is null
     or found_event.parsed_amount <> normalized_amount
     or found_event.parsed_currency is null
     or found_event.parsed_currency <> normalized_currency then
    raise exception 'payment event parse mismatch';
  end if;

  if found_event.status in ('matched', 'ambiguous', 'rejected', 'duplicate') then
    return coalesce(found_event.result, '{}'::jsonb);
  end if;
  if found_event.status = 'unmatched'
     and found_event.received_at <= now() - interval '2 minutes' then
    return coalesce(found_event.result, '{}'::jsonb);
  end if;
  if found_event.status not in ('received', 'error', 'unmatched') then
    raise exception 'invalid payment event state';
  end if;

  perform pg_advisory_xact_lock(hashtext('shamcash-payment-' || normalized_currency));

  effective_notification_text := left(
    coalesce(nullif(found_event.notification_text, ''), p_notification_text, ''),
    1200
  );
  confirmation_result := public.confirm_shamcash_payment_by_amount(
    normalized_amount,
    normalized_currency,
    effective_notification_text
  );

  if coalesce((confirmation_result->>'matched')::boolean, false) then
    terminal_status := 'matched';
    resolved_matched_type := coalesce(nullif(confirmation_result->>'type', ''), 'order_payment');
    resolved_matched_id := case resolved_matched_type
      when 'wallet_topup' then nullif(confirmation_result->>'topUpId', '')
      when 'order_issue_payment' then coalesce(
        nullif(confirmation_result->>'issuePaymentId', ''),
        nullif(confirmation_result->>'orderId', '')
      )
      else nullif(confirmation_result->>'orderId', '')
    end;
  elsif confirmation_result->>'reason' = 'ambiguous' then
    terminal_status := 'ambiguous';
    resolved_matched_type := null;
    resolved_matched_id := null;
  else
    terminal_status := 'unmatched';
    resolved_matched_type := null;
    resolved_matched_id := null;
  end if;

  merged_result := coalesce(found_event.result, '{}'::jsonb)
    || coalesce(confirmation_result, '{}'::jsonb);

  update public.payment_events
  set status = terminal_status,
      matched_type = resolved_matched_type,
      matched_id = resolved_matched_id,
      result = merged_result,
      updated_at = now()
  where id = found_event.id;

  return merged_result;
end;
$$;

revoke all on function public.process_shamcash_payment_event(text, numeric, text, text)
  from public, anon, authenticated;
grant execute on function public.process_shamcash_payment_event(text, numeric, text, text)
  to service_role;

notify pgrst, 'reload schema';
