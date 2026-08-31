-- Enforce the tenant boundary at PostgreSQL's referential-integrity layer.
-- Existing single-column FKs keep their original delete behavior; these
-- composite FKs add the invariant that every warranty reference shares the
-- warranty's store_id and prevent a referenced row from drifting stores.

create unique index if not exists branches_id_store_id_key
  on public.branches(id, store_id);
create unique index if not exists customers_id_store_id_key
  on public.customers(id, store_id);
create unique index if not exists products_id_store_id_key
  on public.products(id, store_id);
create unique index if not exists sales_id_store_id_key
  on public.sales(id, store_id);
create unique index if not exists sale_lines_id_store_id_key
  on public.sale_lines(id, store_id);

alter table public.warranties
  add constraint warranties_customer_store_fk
    foreign key (customer_id, store_id)
    references public.customers(id, store_id)
    on update restrict
    on delete restrict,
  add constraint warranties_product_store_fk
    foreign key (product_id, store_id)
    references public.products(id, store_id)
    on update restrict
    on delete set null (product_id),
  add constraint warranties_branch_store_fk
    foreign key (branch_id, store_id)
    references public.branches(id, store_id)
    on update restrict
    on delete set null (branch_id),
  add constraint warranties_sale_store_fk
    foreign key (sale_id, store_id)
    references public.sales(id, store_id)
    on update restrict
    on delete set null (sale_id),
  add constraint warranties_sale_line_store_fk
    foreign key (sale_line_id, store_id)
    references public.sale_lines(id, store_id)
    on update restrict
    on delete set null (sale_line_id);
