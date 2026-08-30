-- Store-owned warranty identity and policy. The customer portal uses one
-- accessible accent only; product text overrides the store default when set.

alter table public.stores
  add column if not exists logo_url text not null default '',
  add column if not exists brand_color text not null default '#087F5B',
  add column if not exists customer_portal_title text not null default 'بطاقة ضمان موثّقة',
  add column if not exists warranty_policy text not null default '',
  add column if not exists warranty_exclusions text not null default '';

alter table public.stores drop constraint if exists stores_logo_url_check;
alter table public.stores add constraint stores_logo_url_check check (
  logo_url = '' or (
    char_length(logo_url) <= 500 and
    logo_url ~ '^https://'
  )
);
alter table public.stores drop constraint if exists stores_brand_color_check;
alter table public.stores add constraint stores_brand_color_check check (
  brand_color in ('#087F5B', '#1D4ED8', '#6D28D9', '#9F1239', '#334155', '#7C2D12')
);
alter table public.stores drop constraint if exists stores_portal_title_check;
alter table public.stores add constraint stores_portal_title_check check (
  char_length(trim(customer_portal_title)) between 3 and 80
);
alter table public.stores drop constraint if exists stores_warranty_policy_check;
alter table public.stores add constraint stores_warranty_policy_check check (
  char_length(warranty_policy) <= 4000 and
  char_length(warranty_exclusions) <= 4000
);

alter table public.products
  add column if not exists warranty_policy text not null default '',
  add column if not exists warranty_exclusions text not null default '';

alter table public.products drop constraint if exists products_warranty_policy_check;
alter table public.products add constraint products_warranty_policy_check check (
  char_length(warranty_policy) <= 4000 and
  char_length(warranty_exclusions) <= 4000
);

comment on column public.products.warranty_policy is
  'Optional product override; an empty value inherits the store policy.';
comment on column public.products.warranty_exclusions is
  'Optional product override; an empty value inherits the store exclusions.';
