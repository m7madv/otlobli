-- Resolve the authenticated profile wrapper explicitly to the legacy
-- service-only implementation. Positional arguments are ambiguous because
-- both overloads accept six text values once defaults are considered.

create or replace function public.upsert_customer_profile(
  p_phone text,
  p_name text,
  p_governorate text,
  p_session_token text,
  p_qadmous_branch text default '',
  p_city text default '',
  p_details text default ''
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  perform public.require_customer_session(p_session_token, p_phone);
  perform public.upsert_customer_profile(
    p_phone => p_phone,
    p_name => p_name,
    p_governorate => p_governorate,
    p_qadmous_branch => p_qadmous_branch,
    p_city => p_city,
    p_details => p_details
  );
  return public.get_customer_account(p_phone, p_session_token);
end;
$$;

revoke all on function public.upsert_customer_profile(text, text, text, text, text, text, text)
  from public;
grant execute on function public.upsert_customer_profile(text, text, text, text, text, text, text)
  to anon, authenticated;

notify pgrst, 'reload schema';
