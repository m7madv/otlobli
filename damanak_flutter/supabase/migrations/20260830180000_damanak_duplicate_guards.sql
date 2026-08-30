-- Flag duplicate serialized products before a second warranty is issued.

create index if not exists warranties_store_serial_normalized_idx
on public.warranties (
  store_id,
  upper(regexp_replace(trim(serial_number), '[^A-Za-z0-9]', '', 'g'))
)
where serial_number is not null
  and trim(serial_number) <> ''
  and voided_at is null;

create or replace function public.find_warranty_by_serial(
  target_store_id uuid,
  target_serial text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_serial text := upper(
    regexp_replace(trim(coalesce(target_serial, '')), '[^A-Za-z0-9]', '', 'g')
  );
  warranty_row public.warranties;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if normalized_serial = '' then
    return null;
  end if;

  select * into warranty_row
  from public.warranties warranty
  where warranty.store_id = target_store_id
    and warranty.voided_at is null
    and upper(
      regexp_replace(trim(warranty.serial_number), '[^A-Za-z0-9]', '', 'g')
    ) = normalized_serial
  order by warranty.created_at desc
  limit 1;

  if warranty_row.id is null then
    return null;
  end if;
  return to_jsonb(warranty_row);
end;
$$;

revoke all on function public.find_warranty_by_serial(uuid, text) from public;
grant execute on function public.find_warranty_by_serial(uuid, text)
to authenticated;
