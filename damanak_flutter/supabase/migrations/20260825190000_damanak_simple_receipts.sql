-- Damanak 4.2: keep tax columns for backward compatibility while the app
-- issues simple internal sales receipts rather than tax invoices.

begin;

update public.stores
set tax_rate = 0,
    prices_include_tax = true,
    tax_number = '';

update public.suppliers
set tax_number = '';

alter table public.stores alter column tax_rate set default 0;
alter table public.stores alter column prices_include_tax set default true;
alter table public.stores alter column tax_number set default '';

alter table public.stores drop constraint if exists stores_tax_rate_check;
alter table public.stores add constraint stores_tax_rate_check
  check (tax_rate = 0);

commit;
