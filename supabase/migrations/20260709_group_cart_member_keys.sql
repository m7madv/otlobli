alter table public.cart_group_members add column if not exists member_key text not null default '';
alter table public.cart_group_items add column if not exists member_key text not null default '';

update public.cart_group_members
set member_key = coalesce(nullif(member_key, ''), customer_id::text)
where member_key = '';

update public.cart_group_items
set member_key = coalesce(nullif(member_key, ''), customer_id::text)
where member_key = '';

do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'cart_group_members_pkey'
      and conrelid = 'public.cart_group_members'::regclass
  ) then
    alter table public.cart_group_members drop constraint cart_group_members_pkey;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cart_group_members_group_id_member_key_key'
      and conrelid = 'public.cart_group_members'::regclass
  ) then
    alter table public.cart_group_members
      add constraint cart_group_members_group_id_member_key_key unique (group_id, member_key);
  end if;

  if exists (
    select 1 from pg_constraint
    where conname = 'cart_group_items_group_id_customer_id_local_item_id_key'
      and conrelid = 'public.cart_group_items'::regclass
  ) then
    alter table public.cart_group_items drop constraint cart_group_items_group_id_customer_id_local_item_id_key;
  end if;

  if not exists (
    select 1 from pg_constraint
    where conname = 'cart_group_items_group_id_member_key_local_item_id_key'
      and conrelid = 'public.cart_group_items'::regclass
  ) then
    alter table public.cart_group_items
      add constraint cart_group_items_group_id_member_key_local_item_id_key unique (group_id, member_key, local_item_id);
  end if;
end $$;
