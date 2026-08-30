-- A new store receives its trial subscription in the same transaction as the
-- store row. Defer the automatic main-branch insert until transaction end so
-- the branch entitlement trigger can see that subscription.

drop trigger if exists stores_create_default_branch on public.stores;

create constraint trigger stores_create_default_branch
after insert on public.stores
deferrable initially deferred
for each row execute function public.create_default_store_branch();

comment on trigger stores_create_default_branch on public.stores is
  'Creates the main branch after the new store trial subscription exists.';
