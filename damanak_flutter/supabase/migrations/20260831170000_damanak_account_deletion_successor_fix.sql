-- Keep the surviving store reachable when its purchasing owner deletes their
-- account. The successor must become an active owner before canceling the
-- store subscription, because that cancellation runs the member-limit trigger.

create or replace function public.delete_current_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleting_user_id uuid := auth.uid();
  owned_store_id uuid;
  owned_store public.stores%rowtype;
  successor uuid;
  terminated_entitlement_id uuid;
begin
  if deleting_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  for owned_store_id in
    select store.id
    from public.stores store
    where store.owner_id = deleting_user_id
    order by store.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        owned_store_id::text || ':store-subscription',
        0
      )
    );
    select store.*
    into owned_store
    from public.stores store
    where store.id = owned_store_id
      and store.owner_id = deleting_user_id
    for update;
    if not found then
      continue;
    end if;

    select member.user_id
    into successor
    from public.store_members member
    where member.store_id = owned_store.id
      and member.user_id <> deleting_user_id
      and member.status = 'active'
    order by case member.role when 'manager' then 0 else 1 end,
      member.joined_at,
      member.user_id
    limit 1
    for update;

    if successor is null then
      delete from public.stores where id = owned_store.id;
    else
      -- Subscription cancellation fires subscriptions_enforce_member_limit.
      -- Promote the chosen successor first so that trigger can never suspend
      -- the only account that will remain able to administer the store.
      update public.store_members
      set role = 'owner',
          status = 'active'
      where store_id = owned_store.id
        and user_id = successor;

      terminated_entitlement_id := null;
      update public.store_entitlements entitlement
      set status = 'canceled',
          auto_renews = false,
          period_end = least(
            coalesce(entitlement.period_end, pg_catalog.now()),
            pg_catalog.now()
          ),
          refresh_locked_at = null,
          next_verification_at = pg_catalog.now(),
          updated_at = pg_catalog.now()
      where entitlement.store_id = owned_store.id
        and entitlement.superseded_at is null
        and entitlement.user_id = deleting_user_id
      returning entitlement.id into terminated_entitlement_id;

      if terminated_entitlement_id is not null then
        update public.subscriptions subscription
        set status = 'canceled',
            current_period_end = least(
              coalesce(subscription.current_period_end, pg_catalog.now()),
              pg_catalog.now()
            ),
            auto_renews = false,
            updated_at = pg_catalog.now()
        where subscription.store_id = owned_store.id
          and subscription.source = 'store'
          and subscription.store_entitlement_id = terminated_entitlement_id;

        insert into public.audit_logs (
          store_id,
          user_id,
          action,
          entity_type,
          entity_id,
          metadata
        ) values (
          owned_store.id,
          deleting_user_id,
          'store_subscription_terminated_for_account_deletion',
          'store_entitlement',
          terminated_entitlement_id,
          pg_catalog.jsonb_build_object(
            'successor_user_id', successor,
            'external_billing_cancellation_required', true
          )
        );
      end if;

      update public.stores
      set owner_id = successor
      where id = owned_store.id;
    end if;
    successor := null;
    terminated_entitlement_id := null;
  end loop;
  delete from auth.users where id = deleting_user_id;
end;
$$;

revoke all on function public.delete_current_account()
  from public, anon, authenticated;
grant execute on function public.delete_current_account()
  to authenticated;

do $$
declare
  account_delete_definition text;
  promotion_position integer;
  cancellation_position integer;
begin
  select pg_catalog.pg_get_functiondef(
    pg_catalog.to_regprocedure('public.delete_current_account()')
  ) into account_delete_definition;
  promotion_position := pg_catalog.strpos(
    account_delete_definition,
    'set role = ''owner'','
  );
  cancellation_position := pg_catalog.strpos(
    account_delete_definition,
    'update public.store_entitlements entitlement'
  );
  if promotion_position = 0
     or cancellation_position = 0
     or promotion_position > cancellation_position
     or pg_catalog.strpos(
       account_delete_definition,
       'status = ''active'''
     ) = 0 then
    raise exception 'DAMANAK_ACCOUNT_SUCCESSOR_PROMOTION_ORDER_INVALID';
  end if;
end;
$$;
