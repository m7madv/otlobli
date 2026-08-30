-- Preserve normal business-object deletion audits, but do not try to append an
-- audit row while the parent store itself is being cascade-deleted.

create or replace function public.audit_business_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  row_store_id uuid;
  row_entity_id uuid;
begin
  if tg_op = 'DELETE' then
    row_store_id := old.store_id;
    row_entity_id := old.id;

    if not exists (
      select 1
      from public.stores store
      where store.id = row_store_id
    ) then
      return old;
    end if;
  else
    row_store_id := new.store_id;
    row_entity_id := new.id;
  end if;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id)
  values (
    row_store_id,
    (select auth.uid()),
    lower(tg_op),
    tg_table_name,
    row_entity_id
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

comment on function public.audit_business_change() is
  'Audits business rows while safely ignoring child cascades during full store deletion.';
