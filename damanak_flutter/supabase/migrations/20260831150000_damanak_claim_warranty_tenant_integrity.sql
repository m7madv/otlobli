-- Keep public and service-role claim reads inside the warranty's tenant.
-- Fail closed if historical data is inconsistent; never guess ownership.

do $$
begin
  if exists (
    select 1
    from public.maintenance_requests request
    join public.warranties warranty on warranty.id = request.warranty_id
    where request.store_id <> warranty.store_id
  ) then
    raise exception
      'Cannot enforce claim tenant integrity: cross-store maintenance requests exist';
  end if;
end
$$;

create unique index if not exists warranties_id_store_id_key
  on public.warranties(id, store_id);

alter table public.maintenance_requests
  add constraint maintenance_requests_warranty_store_fk
    foreign key (warranty_id, store_id)
    references public.warranties(id, store_id)
    on update restrict
    on delete cascade;
