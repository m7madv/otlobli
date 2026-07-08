-- RESET_CUSTOMER_DATA.sql
--
-- Purpose:
--   Clear customer/user operational data while keeping app configuration,
--   coupons, catalog products, drivers, and settings.
--
-- Use only from Supabase SQL Editor or a trusted admin Postgres connection.
-- Take a database backup first.
--
-- This is intentionally NOT executed automatically by Codex because deleting
-- production users/orders is destructive and requires confirmed admin access.

begin;

truncate table
  public.payment_verifications,
  public.order_events,
  public.order_items,
  public.orders,
  public.addresses,
  public.wallet_transactions,
  public.wallets,
  public.cart_group_items,
  public.cart_group_members,
  public.cart_groups,
  public.coupon_redemptions,
  public.customer_activity,
  public.blocked_users,
  public.otp_challenges,
  public.customers
restart identity cascade;

commit;

-- Optional Supabase Auth cleanup:
-- If this project has real Supabase Auth users, delete them from the Supabase
-- Auth dashboard or run the appropriate admin-only Auth cleanup separately.
-- The current app primarily identifies customers by phone/profile tables.
