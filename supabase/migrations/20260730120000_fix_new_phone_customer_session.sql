-- v86.19: new phone numbers reach ensure_customer() after a valid WhatsApp
-- OTP. The validator existed in schema.sql, but no production migration ever
-- created it, so only the new-customer branch failed at runtime.

create or replace function public.validate_customer_full_name(p_name text)
returns text
language plpgsql
immutable
set search_path = pg_catalog
as $$
declare
  normalized text := regexp_replace(trim(coalesce(p_name, '')), '\s+', ' ', 'g');
begin
  if normalized = ''
    or char_length(normalized) > 120
    or array_length(regexp_split_to_array(normalized, '\s+'), 1) < 2
  then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام كلمتين على الأقل.';
  end if;

  if normalized ~ '[0-9٠-٩۰-۹]' then
    raise exception 'يرجى إدخال الاسم الكامل بدون أرقام.';
  end if;

  if normalized !~ ('^[A-Za-zء-يآأإؤئ' || chr(39) || '\- ]+$') then
    raise exception 'يرجى إدخال الاسم الكامل باستخدام الأحرف فقط.';
  end if;

  return normalized;
end;
$$;

revoke all on function public.validate_customer_full_name(text) from public, anon, authenticated;
grant execute on function public.validate_customer_full_name(text) to service_role;
