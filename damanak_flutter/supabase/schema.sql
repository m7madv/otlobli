--
-- PostgreSQL database dump
--

\restrict Hf0IjshAfeh5GTy3LjzAS2aaH6ZZZufnvvVxcH9euoLoR7u4PKBkMAdTtscm94o

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.6

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: private; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "private";


ALTER SCHEMA "private" OWNER TO "postgres";

--
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";

--
-- Name: SCHEMA "public"; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA "public" IS 'standard public schema';


--
-- Name: claim_store_sandbox_access("uuid", "uuid", "text", "text", boolean); Type: FUNCTION; Schema: private; Owner: postgres
--

CREATE FUNCTION "private"."claim_store_sandbox_access"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "external_original_transaction_id" "text", "allow_new_grant" boolean) RETURNS timestamp with time zone
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  explicit_expiry timestamptz;
  review_window private.store_sandbox_review_windows%rowtype;
  existing_grant private.store_sandbox_review_grants%rowtype;
  granted_expiry timestamptz;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  select tester.expires_at
  into explicit_expiry
  from private.store_sandbox_testers tester
  where tester.store_id = target_store_id
    and tester.user_id = target_user_id
    and tester.platform = billing_platform
    and tester.expires_at > pg_catalog.now()
  for share;
  if explicit_expiry is not null then
    return explicit_expiry;
  end if;

  select grant_row.*
  into existing_grant
  from private.store_sandbox_review_grants grant_row
  join private.store_sandbox_review_windows review
    on review.id = grant_row.window_id
  where grant_row.store_id = target_store_id
    and grant_row.user_id = target_user_id
    and grant_row.platform = billing_platform
    and review.revoked_at is null
    and review.opens_at <= pg_catalog.now()
    and review.closes_at > pg_catalog.now()
  order by review.closes_at, review.created_at
  for update of grant_row
  limit 1;
  if found then
    if existing_grant.original_transaction_id <>
      external_original_transaction_id then
      raise exception 'SANDBOX_REVIEW_GRANT_CONFLICT';
    end if;
    if existing_grant.expires_at <= pg_catalog.now() then
      raise exception 'SANDBOX_REVIEW_GRANT_EXPIRED';
    end if;
    return existing_grant.expires_at;
  end if;

  -- A terminal provider response may reuse an existing bounded review grant,
  -- but it must never create a fresh grant. Only a newly verified active or
  -- grace entitlement may consume a review-window seat.
  if not coalesce(allow_new_grant, false) then
    raise exception 'SANDBOX_REVIEW_GRANT_REQUIRED';
  end if;

  select review.*
  into review_window
  from private.store_sandbox_review_windows review
  where review.platform = billing_platform
    and review.revoked_at is null
    and review.opens_at <= pg_catalog.now()
    and review.closes_at > pg_catalog.now()
    and review.grants_used < review.max_grants
  order by review.closes_at, review.created_at
  for update
  limit 1;
  if not found then
    raise exception 'SANDBOX_REVIEW_WINDOW_CLOSED';
  end if;

  granted_expiry := least(
    review_window.closes_at,
    pg_catalog.now() +
      pg_catalog.make_interval(secs => review_window.grant_ttl_seconds)
  );
  insert into private.store_sandbox_review_grants (
    window_id,
    store_id,
    user_id,
    platform,
    original_transaction_id,
    expires_at
  ) values (
    review_window.id,
    target_store_id,
    target_user_id,
    billing_platform,
    external_original_transaction_id,
    granted_expiry
  );
  update private.store_sandbox_review_windows
  set grants_used = grants_used + 1
  where id = review_window.id;

  insert into public.audit_logs (
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    target_store_id,
    target_user_id,
    'sandbox_review_access_granted',
    'sandbox_review_window',
    review_window.id,
    pg_catalog.jsonb_build_object(
      'platform', billing_platform,
      'release_version', review_window.release_version,
      'submission_id', review_window.submission_id,
      'expires_at', granted_expiry
    )
  );
  return granted_expiry;
end;
$$;


ALTER FUNCTION "private"."claim_store_sandbox_access"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "external_original_transaction_id" "text", "allow_new_grant" boolean) OWNER TO "postgres";

--
-- Name: create_sale_unlocked("uuid", "uuid", "uuid", "text", "text", "jsonb", "jsonb", numeric, "text"); Type: FUNCTION; Schema: private; Owner: postgres
--

CREATE FUNCTION "private"."create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
declare
  store_row public.stores%rowtype;
  branch_row public.branches%rowtype;
  product_row public.products%rowtype;
  inventory_row public.inventory_levels%rowtype;
  created_sale public.sales%rowtype;
  created_line public.sale_lines%rowtype;
  input_line jsonb;
  input_payment jsonb;
  serials text[];
  quantity numeric;
  unit_price numeric;
  line_discount numeric;
  gross numeric;
  discounted numeric;
  line_tax numeric;
  line_total numeric;
  subtotal_value numeric := 0;
  line_discounts numeric := 0;
  tax_value numeric := 0;
  total_value numeric := 0;
  payment_value numeric := 0;
  unit_number integer;
  invoice_value text;
  resolved_customer_id uuid := target_customer_id;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if jsonb_array_length(coalesce(sale_lines_input, '[]'::jsonb)) = 0 then
    raise exception 'EMPTY_SALE';
  end if;
  select * into store_row from public.stores where id = target_store_id;
  select * into branch_row from public.branches
  where id = target_branch_id and store_id = target_store_id and is_active
    and accepts_sales;
  if not found then raise exception 'BRANCH_SALES_DISABLED'; end if;

  if resolved_customer_id is not null and not exists (
    select 1 from public.customers
    where id = resolved_customer_id and store_id = target_store_id
  ) then
    raise exception 'CUSTOMER_SCOPE_INVALID';
  end if;
  if resolved_customer_id is null and length(trim(coalesce(target_customer_phone, ''))) >= 7 then
    insert into public.customers(store_id, name, phone, created_by)
    values (
      target_store_id,
      coalesce(nullif(trim(target_customer_name), ''), 'عميل المتجر'),
      trim(target_customer_phone), auth.uid()
    )
    on conflict (store_id, phone) do update set
      name = excluded.name, updated_at = now()
    returning id into resolved_customer_id;
  end if;

  for input_line in select * from jsonb_array_elements(sale_lines_input)
  loop
    quantity := (input_line->>'quantity')::numeric;
    unit_price := (input_line->>'unit_price')::numeric;
    line_discount := coalesce((input_line->>'discount_amount')::numeric, 0);
    if quantity <= 0 or unit_price < 0 or line_discount < 0
       or line_discount > quantity * unit_price then
      raise exception 'INVALID_SALE_LINE';
    end if;
    select * into product_row from public.products
    where id = (input_line->>'product_id')::uuid
      and store_id = target_store_id and is_active;
    if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;
    serials := coalesce(array(
      select jsonb_array_elements_text(coalesce(input_line->'serial_numbers', '[]'::jsonb))
    ), array[]::text[]);
    if product_row.is_serialized and
       (quantity <> trunc(quantity) or cardinality(serials) <> quantity::integer) then
      raise exception 'SERIAL_NUMBERS_REQUIRED';
    end if;
    if product_row.track_inventory then
      select * into inventory_row from public.inventory_levels
      where branch_id = target_branch_id and product_id = product_row.id
      for update;
      if not found or inventory_row.on_hand - inventory_row.reserved < quantity then
        raise exception 'INSUFFICIENT_STOCK';
      end if;
    end if;
    subtotal_value := subtotal_value + quantity * unit_price;
    line_discounts := line_discounts + line_discount;
  end loop;

  if order_discount < 0 or order_discount > subtotal_value - line_discounts then
    raise exception 'INVALID_DISCOUNT';
  end if;
  discounted := subtotal_value - line_discounts - order_discount;
  if store_row.prices_include_tax then
    tax_value := round(discounted * store_row.tax_rate / (100 + store_row.tax_rate), 3);
    total_value := round(discounted, 3);
  else
    tax_value := round(discounted * store_row.tax_rate / 100, 3);
    total_value := round(discounted + tax_value, 3);
  end if;

  for input_payment in select * from jsonb_array_elements(coalesce(sale_payments_input, '[]'::jsonb))
  loop
    if (input_payment->>'amount')::numeric <= 0 then
      raise exception 'INVALID_PAYMENT';
    end if;
    payment_value := payment_value + (input_payment->>'amount')::numeric;
  end loop;
  if abs(payment_value - total_value) > 0.01 then
    raise exception 'PAYMENT_TOTAL_MISMATCH';
  end if;

  insert into public.sales(
    store_id, branch_id, customer_id, customer_name, customer_phone,
    invoice_number, subtotal, discount_amount, tax_amount, total,
    currency_code, tax_rate, prices_include_tax, notes, cashier_id
  ) values (
    target_store_id, target_branch_id, resolved_customer_id,
    coalesce(nullif(trim(target_customer_name), ''), 'عميل نقدي'),
    coalesce(trim(target_customer_phone), ''), 'PENDING', subtotal_value,
    line_discounts + order_discount, tax_value, total_value,
    store_row.currency_code, store_row.tax_rate, store_row.prices_include_tax,
    coalesce(target_notes, ''), auth.uid()
  ) returning * into created_sale;
  invoice_value := branch_row.receipt_prefix || '-' ||
    to_char(now(), 'YYMM') || '-' || lpad(created_sale.sequence_number::text, 6, '0');
  update public.sales set invoice_number = invoice_value where id = created_sale.id;

  for input_line in select * from jsonb_array_elements(sale_lines_input)
  loop
    quantity := (input_line->>'quantity')::numeric;
    unit_price := (input_line->>'unit_price')::numeric;
    line_discount := coalesce((input_line->>'discount_amount')::numeric, 0);
    select * into product_row from public.products
    where id = (input_line->>'product_id')::uuid;
    serials := coalesce(array(
      select jsonb_array_elements_text(coalesce(input_line->'serial_numbers', '[]'::jsonb))
    ), array[]::text[]);
    gross := quantity * unit_price;
    line_discount := line_discount + case when subtotal_value - line_discounts = 0 then 0
      else order_discount * (gross - line_discount) / (subtotal_value - line_discounts) end;
    discounted := gross - line_discount;
    if store_row.prices_include_tax then
      line_tax := round(discounted * store_row.tax_rate / (100 + store_row.tax_rate), 3);
      line_total := round(discounted, 3);
    else
      line_tax := round(discounted * store_row.tax_rate / 100, 3);
      line_total := round(discounted + line_tax, 3);
    end if;
    select * into inventory_row from public.inventory_levels
      where branch_id = target_branch_id and product_id = product_row.id;

    insert into public.sale_lines(
      sale_id, store_id, product_id, product_name, sku, barcode, quantity,
      unit_price, unit_cost, discount_amount, tax_amount, line_total,
      warranty_months, serial_numbers
    ) values (
      created_sale.id, target_store_id, product_row.id, product_row.name,
      coalesce(product_row.sku, ''), coalesce(product_row.barcode, ''), quantity,
      unit_price, coalesce(inventory_row.average_cost, product_row.cost_price, 0),
      round(line_discount, 3), line_tax, line_total,
      product_row.warranty_months, serials
    ) returning * into created_line;

    if product_row.track_inventory then
      update public.inventory_levels
      set on_hand = on_hand - quantity, updated_at = now()
      where branch_id = target_branch_id and product_id = product_row.id;
      insert into public.stock_movements(
        store_id, branch_id, product_id, movement_type, quantity, unit_cost,
        reference_type, reference_id, note, created_by
      ) values (
        target_store_id, target_branch_id, product_row.id, 'sale', -quantity,
        coalesce(inventory_row.average_cost, 0), 'sale', created_sale.id,
        invoice_value, auth.uid()
      );
    end if;

    if product_row.warranty_months > 0 and resolved_customer_id is not null then
      for unit_number in 1..quantity::integer loop
        insert into public.warranties(
          warranty_number, store_id, product_id, customer_id, branch_id,
          customer_name, customer_phone, product_name, barcode, serial_number,
          purchase_date, expiry_date, notes, created_by, invoice_number,
          sale_subtotal, discount_amount, tax_amount, sale_total, tax_rate,
          currency_code, payment_method, sale_id, sale_line_id
        ) values (
          '', target_store_id, product_row.id, resolved_customer_id, target_branch_id,
          coalesce(nullif(trim(target_customer_name), ''), 'عميل المتجر'),
          trim(target_customer_phone), product_row.name, product_row.barcode,
          coalesce(serials[unit_number], ''), current_date,
          (current_date + make_interval(months => product_row.warranty_months))::date,
          coalesce(target_notes, ''), auth.uid(), invoice_value,
          unit_price, line_discount / quantity, line_tax / quantity,
          line_total / quantity, store_row.tax_rate, store_row.currency_code,
          coalesce(sale_payments_input->0->>'payment_method', 'cash'),
          created_sale.id, created_line.id
        );
      end loop;
    end if;
  end loop;

  for input_payment in select * from jsonb_array_elements(sale_payments_input)
  loop
    insert into public.sale_payments(
      sale_id, store_id, payment_method, amount, reference
    ) values (
      created_sale.id, target_store_id, input_payment->>'payment_method',
      (input_payment->>'amount')::numeric,
      coalesce(input_payment->>'reference', '')
    );
  end loop;
  return created_sale.id;
end;
$$;


ALTER FUNCTION "private"."create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") OWNER TO "postgres";

--
-- Name: FUNCTION "create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text"); Type: COMMENT; Schema: private; Owner: postgres
--

COMMENT ON FUNCTION "private"."create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") IS 'Internal Damanak sale implementation; call public.create_sale so inventory rows are pre-locked deterministically.';


--
-- Name: lock_sale_inventory("uuid", "uuid", "jsonb"); Type: FUNCTION; Schema: private; Owner: postgres
--

CREATE FUNCTION "private"."lock_sale_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "sale_lines_input" "jsonb") RETURNS "void"
    LANGUAGE "plpgsql"
    SET "search_path" TO ''
    AS $$
begin
  perform inventory.id
  from public.inventory_levels as inventory
  join (
    select distinct (input.line ->> 'product_id')::uuid as product_id
    from pg_catalog.jsonb_array_elements(
      coalesce(sale_lines_input, '[]'::jsonb)
    ) as input(line)
  ) as requested on requested.product_id = inventory.product_id
  join public.products as product
    on product.id = requested.product_id
   and product.store_id = target_store_id
   and product.is_active
  where inventory.store_id = target_store_id
    and inventory.branch_id = target_branch_id
    and product.track_inventory
  order by inventory.product_id
  for update of inventory;
end;
$$;


ALTER FUNCTION "private"."lock_sale_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "sale_lines_input" "jsonb") OWNER TO "postgres";

--
-- Name: adjust_inventory("uuid", "uuid", "uuid", numeric, numeric, "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  level public.inventory_levels%rowtype;
  old_quantity numeric;
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if new_quantity < 0 or target_unit_cost < 0 then
    raise exception 'INVALID_INVENTORY_VALUE';
  end if;
  if not exists (
    select 1 from public.branches
    where id = target_branch_id and store_id = target_store_id and is_active
  ) or not exists (
    select 1 from public.products
    where id = target_product_id and store_id = target_store_id and is_active
  ) then
    raise exception 'INVENTORY_SCOPE_INVALID';
  end if;

  insert into public.inventory_levels(
    store_id, branch_id, product_id, on_hand, average_cost, reorder_point
  )
  select target_store_id, target_branch_id, target_product_id, 0,
         target_unit_cost, reorder_point
  from public.products where id = target_product_id
  on conflict (branch_id, product_id) do nothing;

  select * into level from public.inventory_levels
  where branch_id = target_branch_id and product_id = target_product_id
  for update;
  old_quantity := level.on_hand;

  update public.inventory_levels
  set on_hand = new_quantity,
      average_cost = target_unit_cost,
      updated_at = now()
  where id = level.id
  returning * into level;

  if new_quantity <> old_quantity then
    insert into public.stock_movements(
      store_id, branch_id, product_id, movement_type, quantity,
      unit_cost, reference_type, note, created_by
    ) values (
      target_store_id, target_branch_id, target_product_id, 'adjustment',
      new_quantity - old_quantity, target_unit_cost, 'manual_adjustment',
      coalesce(target_note, ''), auth.uid()
    );
  end if;
  return to_jsonb(level);
end;
$$;


ALTER FUNCTION "public"."adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."subscriptions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "plan_id" "text" NOT NULL,
    "status" "text" NOT NULL,
    "trial_ends_at" timestamp with time zone,
    "current_period_start" timestamp with time zone,
    "current_period_end" timestamp with time zone,
    "source" "text" DEFAULT 'manual'::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "billing_provider" "text",
    "store_product_id" "text",
    "billing_cycle" "text",
    "original_transaction_id" "text",
    "auto_renews" boolean DEFAULT false NOT NULL,
    "last_store_verified_at" timestamp with time zone,
    "store_environment" "text",
    "store_entitlement_id" "uuid",
    CONSTRAINT "subscriptions_billing_cycle_check" CHECK ((("billing_cycle" IS NULL) OR ("billing_cycle" = ANY (ARRAY['monthly'::"text", 'yearly'::"text"])))),
    CONSTRAINT "subscriptions_billing_provider_check" CHECK ((("billing_provider" IS NULL) OR ("billing_provider" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"])))),
    CONSTRAINT "subscriptions_current_store_entitlement_check" CHECK (((("source" = 'store'::"text") AND ("store_entitlement_id" IS NOT NULL)) OR (("source" <> 'store'::"text") AND ("store_entitlement_id" IS NULL)))),
    CONSTRAINT "subscriptions_source_check" CHECK (("source" = ANY (ARRAY['trial'::"text", 'activation_code'::"text", 'manual'::"text", 'store'::"text"]))),
    CONSTRAINT "subscriptions_status_check" CHECK (("status" = ANY (ARRAY['trialing'::"text", 'active'::"text", 'past_due'::"text", 'canceled'::"text"]))),
    CONSTRAINT "subscriptions_store_environment_check" CHECK ((("store_environment" IS NULL) OR ("store_environment" = ANY (ARRAY['sandbox'::"text", 'production'::"text"])))),
    CONSTRAINT "subscriptions_store_receipt_complete_check" CHECK ((("source" <> 'store'::"text") OR (("billing_provider" IS NOT NULL) AND ("original_transaction_id" IS NOT NULL) AND ("store_environment" IS NOT NULL) AND ("current_period_end" IS NOT NULL))))
);


ALTER TABLE "public"."subscriptions" OWNER TO "postgres";

--
-- Name: apply_verified_store_entitlement("uuid", "uuid", "text", "text", "text", "text", "text", "text", "text", timestamp with time zone, timestamp with time zone, boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."apply_verified_store_entitlement"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean) RETURNS "public"."subscriptions"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  catalog_row public.store_product_catalog%rowtype;
  linked_entitlement public.store_entitlements%rowtype;
  transaction_entitlement public.store_entitlements%rowtype;
  current_entitlement public.store_entitlements%rowtype;
  subscription_row public.subscriptions%rowtype;
  verified_environment text := store_environment;
  effective_entitlement_status text := entitlement_status;
  sandbox_expires_at timestamptz;
  effective_period_end timestamptz := entitlement_period_end;
  candidate_id uuid := gen_random_uuid();
  written_store_id uuid;
  normalized_status text;
  current_blocks_replacement boolean := false;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if billing_platform not in ('app_store', 'google_play')
     or entitlement_status not in (
       'active', 'grace', 'past_due', 'canceled', 'expired', 'revoked'
     )
     or verified_environment not in ('sandbox', 'production')
     or nullif(pg_catalog.btrim(external_transaction_id), '') is null
     or nullif(
       pg_catalog.btrim(external_original_transaction_id), ''
     ) is null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;
  -- Every mutation of one store follows this lock order: store, receipt, row.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_store_id::text || ':store-subscription',
      0
    )
  );

  -- Recheck authorization after the store lock. Account deletion and purchase
  -- verification use the same lock, so a stale pre-lock membership decision
  -- can never write after ownership has moved.
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role = 'owner'
      and member.status = 'active'
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      billing_platform || ':' || external_original_transaction_id,
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      billing_platform || ':transaction:' || external_transaction_id,
      0
    )
  );

  select *
  into subscription_row
  from public.subscriptions subscription
  where subscription.store_id = target_store_id
  for update;
  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  select *
  into linked_entitlement
  from public.store_entitlements entitlement
  where entitlement.platform = billing_platform
    and entitlement.original_transaction_id =
      external_original_transaction_id
  for update;
  if found then
    candidate_id := linked_entitlement.id;
    if linked_entitlement.store_id <> target_store_id
       or linked_entitlement.user_id is distinct from target_user_id then
      raise exception 'STORE_PURCHASE_ALREADY_LINKED';
    end if;
    if linked_entitlement.environment = 'production'
       and verified_environment = 'sandbox' then
      raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
    end if;
  end if;

  select *
  into transaction_entitlement
  from public.store_entitlements entitlement
  where entitlement.platform = billing_platform
    and entitlement.transaction_id = external_transaction_id
  for update;
  if found and (
    transaction_entitlement.store_id <> target_store_id
    or transaction_entitlement.user_id is distinct from target_user_id
    or transaction_entitlement.original_transaction_id <>
      external_original_transaction_id
  ) then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  if subscription_row.store_entitlement_id is not null then
    select *
    into current_entitlement
    from public.store_entitlements entitlement
    where entitlement.id = subscription_row.store_entitlement_id
    for update;
    if found then
      current_blocks_replacement :=
        current_entitlement.status in ('active', 'grace', 'past_due')
        and current_entitlement.period_end > pg_catalog.now();
      if current_entitlement.environment = 'production'
         and verified_environment = 'sandbox' then
        raise exception 'SANDBOX_CANNOT_REPLACE_PRODUCTION';
      end if;
      if current_entitlement.id <> candidate_id
         and current_blocks_replacement
         and not (
           current_entitlement.environment = 'sandbox'
           and verified_environment = 'production'
         ) then
        if current_entitlement.platform <> billing_platform then
          raise exception 'ACTIVE_STORE_PROVIDER_CHANGE_BLOCKED';
        end if;
        raise exception 'ACTIVE_STORE_SUBSCRIPTION_REPLACEMENT_BLOCKED';
      end if;
    end if;
  end if;

  if verified_environment = 'sandbox'
     and entitlement_status <> 'revoked' then
    sandbox_expires_at := private.claim_store_sandbox_access(
      target_store_id,
      target_user_id,
      billing_platform,
      external_original_transaction_id,
      entitlement_status in ('active', 'grace')
    );
    -- Sandbox subscription periods are deliberately accelerated. Once an
    -- active/grace receipt has consumed a bounded grant, provider expiry alone
    -- must not eject App Review before that grant ends. Revocation never takes
    -- this path, and an expired grant can never be renewed implicitly.
    effective_period_end := sandbox_expires_at;
    if entitlement_status not in ('active', 'grace') then
      effective_entitlement_status := 'active';
    end if;
  end if;

  if effective_entitlement_status in ('active', 'grace') and (
    effective_period_end is null
    or effective_period_end <= pg_catalog.now()
  ) then
    raise exception 'STORE_ACTIVE_PERIOD_INVALID';
  end if;

  select *
  into catalog_row
  from public.store_product_catalog catalog
  where catalog.platform = billing_platform
    and catalog.product_id = billed_product_id
    and catalog.base_plan_id = coalesce(billed_base_plan_id, '')
    and catalog.is_active
  for share;
  if not found then
    raise exception 'STORE_PRODUCT_UNMAPPED';
  end if;

  insert into public.store_entitlements as existing (
    id,
    store_id,
    user_id,
    platform,
    product_id,
    base_plan_id,
    plan_id,
    billing_cycle,
    transaction_id,
    original_transaction_id,
    status,
    environment,
    period_start,
    period_end,
    auto_renews,
    verified_at,
    superseded_at,
    superseded_by
  ) values (
    candidate_id,
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    coalesce(billed_base_plan_id, ''),
    catalog_row.plan_id,
    catalog_row.billing_cycle,
    external_transaction_id,
    external_original_transaction_id,
    effective_entitlement_status,
    verified_environment,
    entitlement_period_start,
    effective_period_end,
    entitlement_auto_renews,
    pg_catalog.now(),
    pg_catalog.now(),
    null
  )
  on conflict (platform, original_transaction_id) do update set
    user_id = excluded.user_id,
    product_id = excluded.product_id,
    base_plan_id = excluded.base_plan_id,
    plan_id = excluded.plan_id,
    billing_cycle = excluded.billing_cycle,
    transaction_id = excluded.transaction_id,
    status = excluded.status,
    environment = excluded.environment,
    period_start = excluded.period_start,
    period_end = excluded.period_end,
    auto_renews = excluded.auto_renews,
    verified_at = pg_catalog.now(),
    updated_at = pg_catalog.now(),
    superseded_at = pg_catalog.now(),
    superseded_by = null
  where existing.store_id = excluded.store_id
    and existing.user_id is not distinct from excluded.user_id
    and not (
      existing.environment = 'production'
      and excluded.environment = 'sandbox'
    )
  returning store_id, id into written_store_id, candidate_id;
  if written_store_id is null then
    raise exception 'STORE_PURCHASE_ALREADY_LINKED';
  end if;

  update public.store_entitlements entitlement
  set superseded_at = pg_catalog.now(),
      superseded_by = candidate_id,
      refresh_locked_at = null
  where entitlement.store_id = target_store_id
    and entitlement.id <> candidate_id
    and entitlement.superseded_at is null;

  update public.store_entitlements entitlement
  set superseded_at = null,
      superseded_by = null
  where entitlement.id = candidate_id;

  normalized_status := case
    when effective_entitlement_status in ('active', 'grace') then 'active'
    when effective_entitlement_status = 'past_due' then 'past_due'
    else 'canceled'
  end;

  update public.subscriptions
  set plan_id = catalog_row.plan_id,
      status = normalized_status,
      trial_ends_at = null,
      current_period_start = entitlement_period_start,
      current_period_end = effective_period_end,
      source = 'store',
      billing_provider = billing_platform,
      store_product_id = billed_product_id,
      billing_cycle = catalog_row.billing_cycle,
      original_transaction_id = external_original_transaction_id,
      store_environment = verified_environment,
      store_entitlement_id = candidate_id,
      auto_renews = entitlement_auto_renews,
      last_store_verified_at = pg_catalog.now(),
      updated_at = pg_catalog.now()
  where store_id = target_store_id
  returning * into subscription_row;

  insert into public.audit_logs (
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    target_store_id,
    target_user_id,
    'store_subscription_verified',
    'subscription',
    subscription_row.id,
    pg_catalog.jsonb_build_object(
      'platform', billing_platform,
      'product_id', billed_product_id,
      'billing_cycle', catalog_row.billing_cycle,
      'status', effective_entitlement_status,
      'provider_status', entitlement_status,
      'environment', verified_environment,
      'effective_period_end', effective_period_end,
      'store_entitlement_id', candidate_id
    )
  );
  return subscription_row;
end;
$$;


ALTER FUNCTION "public"."apply_verified_store_entitlement"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean) OWNER TO "postgres";

--
-- Name: apply_verified_store_entitlement_with_receipt(uuid, uuid, text, text, text, text, text, text, text, timestamptz, timestamptz, boolean, text, text, text, text, boolean, uuid, uuid); Type: FUNCTION; Schema: public; Owner: postgres
--

create function public.apply_verified_store_entitlement_with_receipt(
  target_store_id uuid,
  target_user_id uuid,
  billing_platform text,
  billed_product_id text,
  billed_base_plan_id text,
  external_transaction_id text,
  external_original_transaction_id text,
  entitlement_status text,
  store_environment text,
  entitlement_period_start timestamptz,
  entitlement_period_end timestamptz,
  entitlement_auto_renews boolean,
  raw_purchase_token text,
  purchase_token_hash text,
  linked_purchase_token_hash text,
  expected_current_purchase_token_hash text,
  allow_orphan_lineage_recovery boolean default false,
  orphan_old_account_id uuid default null,
  orphan_old_store_id uuid default null
)
returns public.subscriptions
language plpgsql
security definer
set search_path = ''
as $$
declare
  subscription_row public.subscriptions%rowtype;
  current_link private.google_purchase_token_links%rowtype;
  previous_link private.google_purchase_token_links%rowtype;
  current_receipt_token text;
  resolved_original_transaction_id text :=
    external_original_transaction_id;
  written_hash text;
  current_token_is_known boolean := false;
  previous_token_is_known boolean := false;
  orphan_recovery boolean :=
    coalesce(allow_orphan_lineage_recovery, false);
  current_subscription_id uuid;
  first_token_lock text;
  second_token_lock text;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      target_store_id::text || ':store-subscription',
      0
    )
  );

  if billing_platform = 'google_play' then
    if char_length(coalesce(raw_purchase_token, '')) < 20
       or purchase_token_hash !~ '^[0-9a-f]{64}$'
       or purchase_token_hash <>
         pg_catalog.encode(
           extensions.digest(raw_purchase_token, 'sha256'),
           'hex'
         )
       or (
         linked_purchase_token_hash is not null
         and linked_purchase_token_hash !~ '^[0-9a-f]{64}$'
       )
       or linked_purchase_token_hash = purchase_token_hash then
      raise exception 'GOOGLE_PURCHASE_TOKEN_REQUIRED';
    end if;

    first_token_lock := least(
      purchase_token_hash,
      coalesce(linked_purchase_token_hash, purchase_token_hash)
    );
    second_token_lock := greatest(
      purchase_token_hash,
      coalesce(linked_purchase_token_hash, purchase_token_hash)
    );
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        'google-purchase-token:' || first_token_lock,
        0
      )
    );
    if second_token_lock <> first_token_lock then
      perform pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(
          'google-purchase-token:' || second_token_lock,
          0
        )
      );
    end if;
  elsif purchase_token_hash is not null
        or linked_purchase_token_hash is not null
        or raw_purchase_token is not null
        or expected_current_purchase_token_hash is not null
        or orphan_recovery
        or orphan_old_account_id is not null
        or orphan_old_store_id is not null then
    raise exception 'INVALID_STORE_ENTITLEMENT';
  end if;

  if expected_current_purchase_token_hash is not null then
    if expected_current_purchase_token_hash !~ '^[0-9a-f]{64}$'
       or nullif(
         pg_catalog.btrim(external_original_transaction_id),
         ''
       ) is null then
      raise exception 'STORE_RECEIPT_STALE';
    end if;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        billing_platform || ':' || external_original_transaction_id,
        0
      )
    );
    select receipt.purchase_token
    into current_receipt_token
    from private.store_receipt_secrets receipt
    where receipt.platform = billing_platform
      and receipt.original_transaction_id = external_original_transaction_id
    for update;
    if current_receipt_token is null
       or pg_catalog.encode(
         extensions.digest(current_receipt_token, 'sha256'),
         'hex'
       ) <> expected_current_purchase_token_hash then
      raise exception 'STORE_RECEIPT_STALE';
    end if;
  end if;

  if billing_platform = 'google_play' then
    select *
    into current_link
    from private.google_purchase_token_links token_link
    where token_link.token_hash = purchase_token_hash
    for update;
    current_token_is_known := found;

    if linked_purchase_token_hash is not null then
      select *
      into previous_link
      from private.google_purchase_token_links token_link
      where token_link.token_hash = linked_purchase_token_hash
      for update;
      previous_token_is_known := found;
    end if;

    if orphan_recovery then
      if expected_current_purchase_token_hash is not null
         or orphan_old_account_id is null
         or orphan_old_account_id = target_user_id
         or orphan_old_store_id = target_store_id
         or current_token_is_known
         or previous_token_is_known
         or external_original_transaction_id <>
           'token_' || purchase_token_hash
         or exists (
           select 1
           from auth.users old_user
           where old_user.id = orphan_old_account_id
         )
         or exists (
           select 1
           from public.stores old_store
           where old_store.owner_id = orphan_old_account_id
              or (
                orphan_old_store_id is not null
                and old_store.id = orphan_old_store_id
              )
         )
         or not exists (
           select 1
           from public.stores target_store
           where target_store.id = target_store_id
             and target_store.owner_id = target_user_id
         )
         or (
           select pg_catalog.count(*)
           from public.stores owned_store
           where owned_store.owner_id = target_user_id
         ) <> 1
         or exists (
           select 1
           from public.store_entitlements target_entitlement
           where target_entitlement.store_id = target_store_id
         )
         or exists (
           select 1
           from public.store_entitlements bound_entitlement
           where bound_entitlement.platform = 'google_play'
             and bound_entitlement.original_transaction_id in (
               'token_' || purchase_token_hash,
               'token_' || linked_purchase_token_hash
             )
         ) then
        raise exception 'STORE_PURCHASE_RECOVERY_NOT_ALLOWED';
      end if;
      if linked_purchase_token_hash is not null then
        resolved_original_transaction_id :=
          'token_' || linked_purchase_token_hash;
      end if;
    elsif orphan_old_account_id is not null
          or orphan_old_store_id is not null then
      raise exception 'INVALID_STORE_ENTITLEMENT';
    end if;

    if current_token_is_known and (
      current_link.store_id <> target_store_id
      or current_link.user_id is distinct from target_user_id
    ) then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;

    -- A known token is idempotent only while it remains the saved receipt for
    -- the same current store entitlement.
    if current_token_is_known then
      select subscription.id
      into current_subscription_id
      from public.subscriptions subscription
      join public.store_entitlements entitlement
        on entitlement.id = subscription.store_entitlement_id
       and entitlement.store_id = subscription.store_id
      where subscription.store_id = target_store_id
        and subscription.source = 'store'
        and subscription.billing_provider = billing_platform
        and subscription.original_transaction_id =
          current_link.original_transaction_id
        and entitlement.platform = billing_platform
        and entitlement.original_transaction_id =
          current_link.original_transaction_id
        and entitlement.superseded_at is null
      for update of subscription, entitlement;
      if current_subscription_id is null then
        raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
      end if;

      perform pg_catalog.pg_advisory_xact_lock(
        pg_catalog.hashtextextended(
          billing_platform || ':' ||
            current_link.original_transaction_id,
          0
        )
      );
      select receipt.purchase_token
      into current_receipt_token
      from private.store_receipt_secrets receipt
      where receipt.platform = billing_platform
        and receipt.original_transaction_id =
          current_link.original_transaction_id
      for update;
      if current_receipt_token is null
         or pg_catalog.encode(
           extensions.digest(current_receipt_token, 'sha256'),
           'hex'
         ) <> purchase_token_hash then
        raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
      end if;
    end if;

    if exists (
      select 1
      from private.google_purchase_token_links successor
      where successor.linked_token_hash = purchase_token_hash
        and successor.token_hash <> purchase_token_hash
    ) then
      raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
    end if;

    if linked_purchase_token_hash is not null then
      if orphan_recovery then
        -- Both absent rows are inserted only after the entitlement mutation.
        null;
      else
        if not previous_token_is_known then
          if not current_token_is_known then
            raise exception 'GOOGLE_LINKED_PURCHASE_UNRESOLVED';
          end if;

          written_hash := null;
          insert into private.google_purchase_token_links as existing (
            token_hash,
            store_id,
            user_id,
            original_transaction_id
          ) values (
            linked_purchase_token_hash,
            current_link.store_id,
            current_link.user_id,
            current_link.original_transaction_id
          )
          on conflict (token_hash) do update set
            last_seen_at = pg_catalog.now()
          where existing.store_id = excluded.store_id
            and existing.user_id is not distinct from excluded.user_id
            and existing.original_transaction_id =
              excluded.original_transaction_id
          returning token_hash into written_hash;
          if written_hash is null then
            raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
          end if;

          select *
          into previous_link
          from private.google_purchase_token_links token_link
          where token_link.token_hash = linked_purchase_token_hash
          for update;
          previous_token_is_known := found;
        end if;
        if previous_link.store_id <> target_store_id
           or previous_link.user_id is distinct from target_user_id then
          raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
        end if;

        if not current_token_is_known then
          perform pg_catalog.pg_advisory_xact_lock(
            pg_catalog.hashtextextended(
              billing_platform || ':' ||
                previous_link.original_transaction_id,
              0
            )
          );
          select receipt.purchase_token
          into current_receipt_token
          from private.store_receipt_secrets receipt
          where receipt.platform = billing_platform
            and receipt.original_transaction_id =
              previous_link.original_transaction_id
          for update;
          if current_receipt_token is null
             or pg_catalog.encode(
               extensions.digest(current_receipt_token, 'sha256'),
               'hex'
             ) <> linked_purchase_token_hash then
            raise exception 'GOOGLE_PURCHASE_TOKEN_SUPERSEDED';
          end if;
        end if;

        resolved_original_transaction_id :=
          previous_link.original_transaction_id;
        if current_token_is_known
           and current_link.original_transaction_id <>
             resolved_original_transaction_id then
          raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
        end if;
      end if;
    elsif current_token_is_known then
      resolved_original_transaction_id :=
        current_link.original_transaction_id;
    elsif external_original_transaction_id <>
      'token_' || purchase_token_hash then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;
  end if;

  subscription_row := public.apply_verified_store_entitlement(
    target_store_id,
    target_user_id,
    billing_platform,
    billed_product_id,
    billed_base_plan_id,
    external_transaction_id,
    resolved_original_transaction_id,
    entitlement_status,
    store_environment,
    entitlement_period_start,
    entitlement_period_end,
    entitlement_auto_renews
  );

  if billing_platform = 'google_play' then
    if orphan_recovery and linked_purchase_token_hash is not null then
      written_hash := null;
      insert into private.google_purchase_token_links as existing (
        token_hash,
        linked_token_hash,
        store_id,
        user_id,
        original_transaction_id
      ) values (
        linked_purchase_token_hash,
        null,
        target_store_id,
        target_user_id,
        resolved_original_transaction_id
      )
      on conflict (token_hash) do nothing
      returning token_hash into written_hash;
      if written_hash is null then
        raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
      end if;
    end if;

    written_hash := null;
    insert into private.google_purchase_token_links as existing (
      token_hash,
      linked_token_hash,
      store_id,
      user_id,
      original_transaction_id
    ) values (
      purchase_token_hash,
      linked_purchase_token_hash,
      target_store_id,
      target_user_id,
      resolved_original_transaction_id
    )
    on conflict (token_hash) do update set
      linked_token_hash = coalesce(
        excluded.linked_token_hash,
        existing.linked_token_hash
      ),
      last_seen_at = pg_catalog.now()
    where existing.store_id = excluded.store_id
      and existing.user_id is not distinct from excluded.user_id
      and existing.original_transaction_id =
        excluded.original_transaction_id
      and (
        existing.linked_token_hash is null
        or excluded.linked_token_hash is null
        or existing.linked_token_hash = excluded.linked_token_hash
      )
    returning token_hash into written_hash;
    if written_hash is null then
      raise exception 'GOOGLE_PURCHASE_LINEAGE_CONFLICT';
    end if;

    insert into private.store_receipt_secrets (
      platform,
      original_transaction_id,
      purchase_token,
      updated_at
    ) values (
      billing_platform,
      resolved_original_transaction_id,
      raw_purchase_token,
      pg_catalog.now()
    )
    on conflict (platform, original_transaction_id) do update set
      purchase_token = excluded.purchase_token,
      updated_at = pg_catalog.now();
  end if;
  return subscription_row;
end;
$$;

alter function public.apply_verified_store_entitlement_with_receipt(
  uuid, uuid, text, text, text, text, text, text, text,
  timestamptz, timestamptz, boolean, text, text, text, text,
  boolean, uuid, uuid
) owner to postgres;
--
-- Name: audit_business_change(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."audit_business_change"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "public"."audit_business_change"() OWNER TO "postgres";

--
-- Name: FUNCTION "audit_business_change"(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION "public"."audit_business_change"() IS 'Trigger-only audit routine; direct execution is denied to API roles.';


--
-- Name: authenticate_store_api_key("text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."authenticate_store_api_key"("presented_key" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
declare
  matched_key public.store_api_keys;
begin
  if presented_key !~ '^dmn_live_[0-9a-f]{64}$' then return null; end if;
  select * into matched_key from public.store_api_keys
  where key_hash = extensions.digest(presented_key, 'sha256')
    and revoked_at is null;
  if matched_key.id is null or not public.store_plan_allows(matched_key.store_id, 'api') then
    return null;
  end if;
  update public.store_api_keys set last_used_at = now() where id = matched_key.id;
  return jsonb_build_object(
    'keyId', matched_key.id,
    'storeId', matched_key.store_id,
    'scopes', matched_key.scopes
  );
end;
$_$;


ALTER FUNCTION "public"."authenticate_store_api_key"("presented_key" "text") OWNER TO "postgres";

--
-- Name: claim_ai_claim_review_job("uuid", "uuid", "uuid", "text", boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."claim_ai_claim_review_job"("target_store_id" "uuid", "target_request_id" "uuid", "target_user_id" "uuid", "target_model" "text", "target_include_attachments" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  monthly_limit integer;
  monthly_used integer;
  recent_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_members
    where store_id = target_store_id
      and user_id = target_user_id
      and role in ('owner', 'manager')
      and status = 'active'
  ) or not exists (
    select 1 from public.maintenance_requests
    where id = target_request_id and store_id = target_store_id
  ) then
    raise exception 'CLAIM_REVIEW_ACCESS_DENIED';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':claim-ai', 0)
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_request_id::text || ':claim-ai', 0)
  );
  select plan.monthly_ai_claim_reviews into monthly_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
    and (
      (subscription.status = 'trialing' and subscription.trial_ends_at > now())
      or
      (subscription.status = 'active' and (
        subscription.current_period_end is null
        or subscription.current_period_end > now()
      ))
    );
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'CLAIM_AI_NOT_INCLUDED';
  end if;

  select count(*) into monthly_used
  from public.ai_claim_reviews
  where store_id = target_store_id
    and created_at >= pg_catalog.date_trunc('month', now());
  select count(*) into recent_used
  from public.ai_claim_reviews
  where request_id = target_request_id
    and created_at >= now() - interval '10 minutes';
  if monthly_used >= monthly_limit then
    raise exception 'CLAIM_AI_MONTHLY_LIMIT';
  end if;
  if recent_used >= 1 then
    raise exception 'CLAIM_AI_COOLDOWN';
  end if;

  insert into public.ai_claim_reviews(
    store_id, request_id, user_id, status, provider, model,
    included_attachments
  ) values (
    target_store_id, target_request_id, target_user_id, 'started',
    'openai', target_model, target_include_attachments
  ) returning id into created_id;

  return jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;


ALTER FUNCTION "public"."claim_ai_claim_review_job"("target_store_id" "uuid", "target_request_id" "uuid", "target_user_id" "uuid", "target_model" "text", "target_include_attachments" boolean) OWNER TO "postgres";

--
-- Name: claim_ai_import_job("uuid", "uuid", "text", "text", bigint, "text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."claim_ai_import_job"("target_store_id" "uuid", "target_user_id" "uuid", "target_filename" "text", "target_mime_type" "text", "target_size_bytes" bigint, "target_provider" "text", "target_pricing_tier" "text", "target_model" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  monthly_limit integer;
  monthly_used integer;
  daily_used integer;
  created_id uuid;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_members
    where store_id = target_store_id
      and user_id = target_user_id
      and role in ('owner', 'manager')
      and status = 'active'
  ) then
    raise exception 'IMPORT_MANAGER_REQUIRED';
  end if;
  if target_provider not in ('gemini', 'openai')
     or target_pricing_tier not in ('free', 'paid') then
    raise exception 'AI_PROVIDER_INVALID';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':ai-import', 0)
  );
  select plan.monthly_ai_imports into monthly_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id
    and (
      (subscription.status = 'trialing' and subscription.trial_ends_at > now())
      or
      (subscription.status = 'active' and (
        subscription.current_period_end is null
        or subscription.current_period_end > now()
      ))
    );
  if coalesce(monthly_limit, 0) < 1 then
    raise exception 'AI_IMPORT_NOT_INCLUDED';
  end if;

  select count(*) into monthly_used
  from public.ai_import_jobs
  where store_id = target_store_id
    and created_at >= pg_catalog.date_trunc('month', now());
  select count(*) into daily_used
  from public.ai_import_jobs
  where store_id = target_store_id
    and created_at >= now() - interval '24 hours';
  if monthly_used >= monthly_limit then
    raise exception 'AI_IMPORT_MONTHLY_LIMIT';
  end if;
  if daily_used >= 25 then
    raise exception 'AI_IMPORT_DAILY_SAFETY_LIMIT';
  end if;

  insert into public.ai_import_jobs(
    store_id, user_id, status, filename, mime_type, size_bytes,
    provider, pricing_tier, model
  ) values (
    target_store_id, target_user_id, 'started', target_filename,
    target_mime_type, target_size_bytes, target_provider,
    target_pricing_tier, target_model
  ) returning id into created_id;

  return jsonb_build_object(
    'jobId', created_id,
    'monthlyLimit', monthly_limit,
    'monthlyUsed', monthly_used + 1
  );
end;
$$;


ALTER FUNCTION "public"."claim_ai_import_job"("target_store_id" "uuid", "target_user_id" "uuid", "target_filename" "text", "target_mime_type" "text", "target_size_bytes" bigint, "target_provider" "text", "target_pricing_tier" "text", "target_model" "text") OWNER TO "postgres";

--
-- Name: claim_store_entitlement_refreshes(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."claim_store_entitlement_refreshes"("requested_limit" integer DEFAULT 10) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  result jsonb;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements entitlement
  set refresh_locked_at = null
  where entitlement.superseded_at is null
    and entitlement.refresh_locked_at <
      pg_catalog.now() - interval '15 minutes';

  with selected as (
    select entitlement.id
    from public.store_entitlements entitlement
    join public.subscriptions subscription
      on subscription.store_entitlement_id = entitlement.id
     and subscription.store_id = entitlement.store_id
     and subscription.source = 'store'
    where entitlement.superseded_at is null
      and entitlement.next_verification_at <= pg_catalog.now()
      and entitlement.refresh_locked_at is null
      and entitlement.status in ('active', 'grace', 'past_due')
    order by entitlement.next_verification_at, entitlement.verified_at
    for update of entitlement skip locked
    limit greatest(1, least(requested_limit, 100))
  ), claimed as (
    update public.store_entitlements entitlement
    set refresh_locked_at = pg_catalog.now()
    from selected
    where entitlement.id = selected.id
    returning entitlement.*
  )
  select coalesce(pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
    'id', claimed.id,
    'storeId', claimed.store_id,
    'userId', claimed.user_id,
    'platform', claimed.platform,
    'originalTransactionId', claimed.original_transaction_id,
    'purchaseToken', receipt.purchase_token
  ) order by claimed.next_verification_at), '[]'::jsonb)
  into result
  from claimed
  left join private.store_receipt_secrets receipt
    on receipt.platform = claimed.platform
   and receipt.original_transaction_id = claimed.original_transaction_id;
  return result;
end;
$$;


ALTER FUNCTION "public"."claim_store_entitlement_refreshes"("requested_limit" integer) OWNER TO "postgres";

--
-- Name: claim_webhook_deliveries(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."claim_webhook_deliveries"("requested_limit" integer DEFAULT 25) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare result jsonb;
begin
  -- Recover work if a dispatcher stopped after reserving it.
  update public.webhook_deliveries
  set status = 'pending', locked_at = null
  where status = 'processing' and locked_at < now() - interval '15 minutes';

  with selected as (
    select delivery.id
    from public.webhook_deliveries delivery
    where delivery.status = 'pending' and delivery.next_attempt_at <= now()
    order by delivery.created_at
    for update skip locked
    limit greatest(1, least(requested_limit, 100))
  ), claimed as (
    update public.webhook_deliveries delivery
    set status = 'processing', locked_at = now()
    from selected
    where delivery.id = selected.id
    returning delivery.*
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', claimed.id,
    'event_name', claimed.event_name,
    'payload', claimed.payload,
    'attempts', claimed.attempts,
    'endpoint_url', hook.endpoint_url,
    'signing_secret', hook.signing_secret,
    'is_active', hook.is_active
  ) order by claimed.created_at), '[]'::jsonb)
  into result
  from claimed
  join public.store_webhooks hook on hook.id = claimed.webhook_id;

  return result;
end;
$$;


ALTER FUNCTION "public"."claim_webhook_deliveries"("requested_limit" integer) OWNER TO "postgres";

--
-- Name: close_register("uuid", numeric, "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare session_row public.register_sessions%rowtype;
begin
  select * into session_row from public.register_sessions
  where id = target_session_id and status = 'open' for update;
  if not found or not public.is_store_member(session_row.store_id) then
    raise exception 'REGISTER_NOT_FOUND';
  end if;
  if target_closing_cash < 0 then raise exception 'INVALID_CLOSING_CASH'; end if;
  select coalesce(sum(payments.amount), 0) into session_row.cash_sales
  from public.sale_payments payments
  join public.sales sales on sales.id = payments.sale_id
  where sales.branch_id = session_row.branch_id
    and sales.created_at >= session_row.opened_at
    and payments.payment_method = 'cash';
  select coalesce(sum(returns.refund_amount), 0) into session_row.cash_refunds
  from public.sale_returns returns
  join public.sales sales on sales.id = returns.sale_id
  where sales.branch_id = session_row.branch_id
    and returns.created_at >= session_row.opened_at
    and returns.refund_method = 'cash';
  update public.register_sessions
  set closed_by = auth.uid(), closing_cash = target_closing_cash,
      cash_sales = session_row.cash_sales, cash_refunds = session_row.cash_refunds,
      status = 'closed', closed_at = now(),
      notes = case when trim(coalesce(target_notes, '')) = '' then notes else target_notes end
  where id = target_session_id returning * into session_row;
  return to_jsonb(session_row);
end;
$$;


ALTER FUNCTION "public"."close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text") OWNER TO "postgres";

--
-- Name: create_claim_notifications(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_claim_notifications"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  member_row record;
  claim_reference text;
begin
  claim_reference := 'CLM-' || lpad(coalesce(new.claim_number, 0)::text, 6, '0');

  if tg_op = 'INSERT' then
    for member_row in
      select member.user_id
      from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.status = 'active'
        and member.role in ('owner', 'manager')
        and coalesce(preference.claim_created, true)
    loop
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, member_row.user_id, 'claim_created',
        'مطالبة جديدة ' || claim_reference,
        left(new.issue, 500), new.id, 'claim-created:' || new.id::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end loop;
    return new;
  end if;

  if new.assigned_to is distinct from old.assigned_to and new.assigned_to is not null then
    if exists (
      select 1 from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.user_id = new.assigned_to
        and member.status = 'active'
        and coalesce(preference.claim_assigned, true)
    ) then
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, new.assigned_to, 'claim_assigned',
        'أُسندت إليك ' || claim_reference,
        left(new.issue, 500), new.id,
        'claim-assigned:' || new.id::text || ':' || new.assigned_to::text || ':' || new.version::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end if;
  end if;

  if new.status = 'ready_for_pickup' and old.status is distinct from new.status then
    for member_row in
      select member.user_id
      from public.store_members member
      left join public.notification_preferences preference
        on preference.store_id = member.store_id
       and preference.user_id = member.user_id
      where member.store_id = new.store_id
        and member.status = 'active'
        and (member.role in ('owner', 'manager') or member.user_id = new.assigned_to)
        and coalesce(preference.ready_for_pickup, true)
    loop
      insert into public.notifications(
        store_id, user_id, event_type, title, body, request_id, dedupe_key
      ) values (
        new.store_id, member_row.user_id, 'ready_for_pickup',
        'جاهزة للاستلام ' || claim_reference,
        'تواصل مع العميل لتنسيق الاستلام.', new.id,
        'claim-ready:' || new.id::text || ':' || new.version::text
      ) on conflict (user_id, dedupe_key) do nothing;
    end loop;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."create_claim_notifications"() OWNER TO "postgres";

--
-- Name: create_default_store_branch(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_default_store_branch"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.branches(store_id, name, code, city, address, phone, is_main)
  values (new.id, 'الفرع الرئيسي', 'MAIN', new.city, new.address, new.phone, true)
  on conflict (store_id, code) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."create_default_store_branch"() OWNER TO "postgres";

--
-- Name: create_maintenance_request("uuid", "uuid", "text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text" DEFAULT 'other'::"text", "claim_priority" "text" DEFAULT 'normal'::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  created_request public.maintenance_requests;
  normalized_issue text := trim(coalesce(claim_issue, ''));
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_MEMBER_REQUIRED';
  end if;
  if char_length(normalized_issue) not between 3 and 2000
     or claim_category not in (
       'malfunction', 'battery', 'software', 'physical_damage',
       'missing_parts', 'other'
     )
     or claim_priority not in ('low', 'normal', 'high', 'urgent') then
    raise exception 'CLAIM_INPUT_INVALID';
  end if;
  if not exists (
    select 1
    from public.warranties warranty
    where warranty.id = target_warranty_id
      and warranty.store_id = target_store_id
      and warranty.voided_at is null
  ) then
    raise exception 'WARRANTY_NOT_FOUND';
  end if;

  insert into public.maintenance_requests(
    store_id,
    warranty_id,
    issue,
    category,
    priority,
    created_by,
    updated_by
  ) values (
    target_store_id,
    target_warranty_id,
    normalized_issue,
    claim_category,
    claim_priority,
    (select auth.uid()),
    (select auth.uid())
  )
  returning * into created_request;
  return to_jsonb(created_request);
end;
$$;


ALTER FUNCTION "public"."create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_priority" "text") OWNER TO "postgres";

--
-- Name: create_purchase_order("uuid", "uuid", "uuid", timestamp with time zone, "text", "jsonb"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare order_row public.purchase_orders%rowtype;
  product_row public.products%rowtype;
  item jsonb;
  total_value numeric := 0;
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if not exists (select 1 from public.branches where id = target_branch_id and store_id = target_store_id)
     or not exists (select 1 from public.suppliers where id = target_supplier_id and store_id = target_store_id and is_active)
     or jsonb_array_length(coalesce(purchase_lines_input, '[]'::jsonb)) = 0 then
    raise exception 'INVALID_PURCHASE_ORDER';
  end if;
  for item in select * from jsonb_array_elements(purchase_lines_input)
  loop
    if (item->>'quantity')::numeric <= 0 or (item->>'unit_cost')::numeric < 0 then
      raise exception 'INVALID_PURCHASE_LINE';
    end if;
    total_value := total_value +
      (item->>'quantity')::numeric * (item->>'unit_cost')::numeric;
  end loop;
  insert into public.purchase_orders(
    store_id, branch_id, supplier_id, order_number, status, expected_at,
    notes, total_cost, created_by
  ) values (
    target_store_id, target_branch_id, target_supplier_id, 'PENDING', 'ordered',
    target_expected_at, coalesce(target_notes, ''), total_value, auth.uid()
  ) returning * into order_row;
  update public.purchase_orders
  set order_number = 'PO-' || to_char(now(), 'YYMM') || '-' ||
    lpad(order_row.sequence_number::text, 6, '0')
  where id = order_row.id;
  for item in select * from jsonb_array_elements(purchase_lines_input)
  loop
    select * into product_row from public.products
    where id = (item->>'product_id')::uuid and store_id = target_store_id and is_active;
    if not found then raise exception 'PRODUCT_NOT_FOUND'; end if;
    insert into public.purchase_order_lines(
      purchase_order_id, store_id, product_id, product_name, quantity, unit_cost
    ) values (
      order_row.id, target_store_id, product_row.id, product_row.name,
      (item->>'quantity')::numeric, (item->>'unit_cost')::numeric
    );
  end loop;
  return order_row.id;
end;
$$;


ALTER FUNCTION "public"."create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb") OWNER TO "postgres";

--
-- Name: create_sale("uuid", "uuid", "uuid", "text", "text", "jsonb", "jsonb", numeric, "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;

  if pg_catalog.jsonb_array_length(
       coalesce(sale_lines_input, '[]'::jsonb)
     ) = 0 then
    raise exception 'EMPTY_SALE';
  end if;

  if not exists (
    select 1
    from public.branches as branch
    where branch.id = target_branch_id
      and branch.store_id = target_store_id
      and branch.is_active
      and branch.accepts_sales
  ) then
    raise exception 'BRANCH_SALES_DISABLED';
  end if;

  perform private.lock_sale_inventory(
    target_store_id,
    target_branch_id,
    sale_lines_input
  );

  -- The original implementation validates each line independently. Once the
  -- canonical locks are held, aggregate duplicate product lines so two valid
  -- individual lines cannot jointly exceed the available stock.
  if exists (
    with requested_inventory as (
      select
        (input.line ->> 'product_id')::uuid as product_id,
        pg_catalog.sum((input.line ->> 'quantity')::numeric)
          as requested_quantity
      from pg_catalog.jsonb_array_elements(sale_lines_input) as input(line)
      group by (input.line ->> 'product_id')::uuid
    )
    select 1
    from requested_inventory as requested
    join public.products as product
      on product.id = requested.product_id
     and product.store_id = target_store_id
     and product.is_active
     and product.track_inventory
    left join public.inventory_levels as inventory
      on inventory.store_id = target_store_id
     and inventory.branch_id = target_branch_id
     and inventory.product_id = requested.product_id
    where inventory.id is null
       or inventory.on_hand - inventory.reserved
          < requested.requested_quantity
  ) then
    raise exception 'INSUFFICIENT_STOCK';
  end if;

  return private.create_sale_unlocked(
    target_store_id,
    target_branch_id,
    target_customer_id,
    target_customer_name,
    target_customer_phone,
    sale_lines_input,
    sale_payments_input,
    order_discount,
    target_notes
  );
end;
$$;


ALTER FUNCTION "public"."create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") OWNER TO "postgres";

--
-- Name: create_store_api_key("uuid", "text", "text"[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[] DEFAULT ARRAY['warranties:read'::"text"]) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  plain_key text;
  created_key public.store_api_keys;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if not public.store_plan_allows(target_store_id, 'api') then
    raise exception 'PLAN_API_REQUIRED';
  end if;
  if char_length(trim(key_name)) not between 2 and 80 or
     cardinality(requested_scopes) not between 1 and 3 or
     not (requested_scopes <@ array['warranties:read', 'claims:read', 'claims:write']::text[]) then
    raise exception 'API_KEY_INPUT_INVALID';
  end if;
  if (select count(*) from public.store_api_keys
      where store_id = target_store_id and revoked_at is null) >= 5 then
    raise exception 'API_KEY_LIMIT_REACHED';
  end if;

  plain_key := 'dmn_live_' || encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.store_api_keys(
    store_id, name, key_prefix, key_hash, scopes, created_by
  ) values (
    target_store_id, trim(key_name), left(plain_key, 17),
    extensions.digest(plain_key, 'sha256'), requested_scopes, auth.uid()
  ) returning * into created_key;

  return jsonb_build_object(
    'id', created_key.id,
    'name', created_key.name,
    'keyPrefix', created_key.key_prefix,
    'scopes', created_key.scopes,
    'createdAt', created_key.created_at,
    'secret', plain_key
  );
end;
$$;


ALTER FUNCTION "public"."create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[]) OWNER TO "postgres";

--
-- Name: create_store_invite("uuid", "text", integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer DEFAULT 1) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  raw_code text;
  expiry timestamptz := now() + interval '48 hours';
begin
  if not public.has_store_role(
    target_store_id, array['owner', 'manager']
  ) then
    raise exception 'ROLE_REQUIRED';
  end if;
  if target_role not in ('manager', 'staff') then
    raise exception 'INVALID_ROLE';
  end if;
  if public.has_store_role(target_store_id, array['manager'])
     and target_role = 'manager' then
    raise exception 'OWNER_REQUIRED';
  end if;
  if allowed_uses not between 1 and 10 then
    raise exception 'INVALID_USE_LIMIT';
  end if;

  raw_code := 'DMN-' || upper(
    pg_catalog.encode(extensions.gen_random_bytes(16), 'hex')
  );
  insert into public.invite_codes(
    store_id,
    code_hash,
    role,
    max_uses,
    expires_at,
    created_by
  ) values (
    target_store_id,
    extensions.digest(raw_code, 'sha256'),
    target_role,
    allowed_uses,
    expiry,
    (select auth.uid())
  );

  return jsonb_build_object(
    'code', raw_code,
    'role', target_role,
    'max_uses', allowed_uses,
    'expires_at', expiry
  );
end;
$$;


ALTER FUNCTION "public"."create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer) OWNER TO "postgres";

--
-- Name: create_store_webhook("uuid", "text", "text"[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare secret text; created_hook public.store_webhooks;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if not public.store_plan_allows(target_store_id, 'webhook') then
    raise exception 'PLAN_WEBHOOK_REQUIRED';
  end if;
  if target_url !~ '^https://' or char_length(target_url) > 500 or
     cardinality(target_events) not between 1 and 2 or
     not (target_events <@ array['claim.created', 'claim.updated']::text[]) then
    raise exception 'WEBHOOK_INPUT_INVALID';
  end if;
  if (select count(*) from public.store_webhooks
      where store_id = target_store_id and is_active) >= 5 then
    raise exception 'WEBHOOK_LIMIT_REACHED';
  end if;
  secret := 'whsec_' || encode(extensions.gen_random_bytes(32), 'hex');
  insert into public.store_webhooks(
    store_id, endpoint_url, events, signing_secret, created_by
  ) values (target_store_id, target_url, target_events, secret, auth.uid())
  returning * into created_hook;
  return jsonb_build_object(
    'id', created_hook.id, 'endpointUrl', created_hook.endpoint_url,
    'events', created_hook.events, 'isActive', true,
    'createdAt', created_hook.created_at, 'secret', secret
  );
end;
$$;


ALTER FUNCTION "public"."create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]) OWNER TO "postgres";

--
-- Name: create_store_with_trial("text", "text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  raise exception 'APP_UPDATE_REQUIRED_FOR_TRIAL';
end;
$$;


ALTER FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") OWNER TO "postgres";

--
-- Name: FUNCTION "create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text"); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") IS 'Creates a Gulf store with a 14-day Starter trial (100 warranties, 2 team accounts).';


--
-- Name: create_store_with_trial("text", "text", "text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'private', 'extensions'
    AS $_$
declare
  created_store_id uuid;
  inserted_rows integer;
  account_claim_hash bytea;
  device_claim_hash bytea;
  normalized_claim text := lower(trim(coalesce(device_claim, '')));
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(trim(store_name)) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if store_country_code not in ('SA', 'AE', 'KW', 'QA', 'BH', 'OM') then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;

  account_claim_hash := extensions.digest(
    'damanak:trial-account:v1:' || auth.uid()::text,
    'sha256'
  );
  device_claim_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  insert into private.trial_account_claims(account_hash)
  values (account_claim_hash)
  on conflict (account_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then
    raise exception 'TRIAL_ALREADY_USED_BY_ACCOUNT';
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (device_claim_hash, account_claim_hash)
  on conflict (device_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 0 then
    raise exception 'TRIAL_ALREADY_USED_ON_DEVICE';
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    trim(store_name),
    trim(coalesce(store_phone, '')),
    trim(coalesce(store_city, '')),
    store_country_code,
    auth.uid()
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, auth.uid(), 'owner');

  insert into public.subscriptions(
    store_id, plan_id, status, trial_ends_at, source
  ) values (
    created_store_id, 'starter', 'trialing',
    now() + interval '14 days', 'trial'
  );

  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id,
    metadata
  ) values (
    created_store_id, auth.uid(), 'store_created', 'store',
    created_store_id,
    jsonb_build_object('trial_guard', 'account_and_device_v1')
  );

  return created_store_id;
end;
$_$;


ALTER FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") OWNER TO "postgres";

--
-- Name: FUNCTION "create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text"); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") IS 'Creates one 14-day Starter trial per authenticated account and protected app installation.';


--
-- Name: current_warranty_usage("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."current_warranty_usage"("target_store_id" "uuid") RETURNS bigint
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  month_start timestamptz := pg_catalog.date_trunc(
    'month',
    pg_catalog.now()
  );
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  return (
    select pg_catalog.count(*)
    from public.warranties warranty
    where warranty.store_id = target_store_id
      and warranty.created_at >= month_start
      and warranty.created_at < month_start + interval '1 month'
  );
end;
$$;


ALTER FUNCTION "public"."current_warranty_usage"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: delete_current_account(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."delete_current_account"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "public"."delete_current_account"() OWNER TO "postgres";

--
-- Name: enforce_authenticated_claim_write(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_authenticated_claim_write"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  actor uuid := (select auth.uid());
begin
  if actor is null then
    return new;
  end if;

  if tg_op = 'INSERT' then
    if not public.is_store_member(new.store_id) then
      raise exception 'CLAIM_STORE_ACCESS_DENIED';
    end if;
    if not exists (
      select 1
      from public.warranties warranty
      where warranty.id = new.warranty_id
        and warranty.store_id = new.store_id
        and warranty.voided_at is null
    ) then
      raise exception 'WARRANTY_NOT_FOUND';
    end if;
    new.claim_number := nextval('public.maintenance_claim_number_seq');
    new.status := 'new';
    new.channel := 'staff';
    new.resolution := 'none';
    new.assigned_to := null;
    new.service_branch_id := null;
    new.customer_notes := '';
    new.internal_notes := '';
    new.diagnosis := '';
    new.resolution_notes := '';
    new.decision_reason := '';
    new.sla_due_at := null;
    new.approved_at := null;
    new.completed_at := null;
    new.created_by := actor;
    new.updated_by := actor;
    new.created_at := now();
    new.updated_at := now();
    new.version := 1;
    new.public_submission_id := null;
    return new;
  end if;

  if new.id is distinct from old.id
     or new.store_id is distinct from old.store_id
     or new.warranty_id is distinct from old.warranty_id
     or new.claim_number is distinct from old.claim_number
     or new.channel is distinct from old.channel
     or new.public_submission_id is distinct from old.public_submission_id
     or new.created_by is distinct from old.created_by
     or new.created_at is distinct from old.created_at then
    raise exception 'CLAIM_IMMUTABLE_FIELDS';
  end if;
  new.updated_by := actor;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_authenticated_claim_write"() OWNER TO "postgres";

--
-- Name: enforce_branch_entitlement(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_branch_entitlement"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  branch_limit integer;
  current_count integer;
begin
  if not new.is_active then
    return new;
  end if;
  if tg_op = 'UPDATE'
     and old.is_active
     and new.store_id = old.store_id then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  select plan.max_branches
  into branch_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id
    and public.subscription_is_usable(new.store_id);
  if branch_limit is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select count(*)
  into current_count
  from public.branches branch
  where branch.store_id = new.store_id
    and branch.is_active
    and branch.id <> new.id;
  if current_count >= branch_limit then
    raise exception 'BRANCH_LIMIT_REACHED';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_branch_entitlement"() OWNER TO "postgres";

--
-- Name: enforce_product_branding_entitlement(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_product_branding_entitlement"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  policy_requested boolean :=
    pg_catalog.btrim(coalesce(new.warranty_policy, '')) <> ''
    or pg_catalog.btrim(coalesce(new.warranty_exclusions, '')) <> '';
  policy_changed boolean := tg_op = 'INSERT' or (
    new.warranty_policy is distinct from old.warranty_policy
    or new.warranty_exclusions is distinct from old.warranty_exclusions
  );
begin
  if policy_requested
     and policy_changed
     and not public.store_plan_allows(new.store_id, 'branding') then
    raise exception 'PLAN_BRANDING_REQUIRED';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_product_branding_entitlement"() OWNER TO "postgres";

--
-- Name: enforce_store_api_key_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_store_api_key_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':api-keys', 0)
  );
  if (
    select count(*) from public.store_api_keys
    where store_id = new.store_id and revoked_at is null
  ) >= 5 then
    raise exception 'API_KEY_LIMIT_REACHED';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_store_api_key_limit"() OWNER TO "postgres";

--
-- Name: enforce_store_branding_entitlement(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_store_branding_entitlement"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  branding_changed boolean;
  clearing_branding boolean;
begin
  branding_changed :=
    new.logo_url is distinct from old.logo_url
    or new.brand_color is distinct from old.brand_color
    or new.customer_portal_title is distinct from old.customer_portal_title
    or new.warranty_policy is distinct from old.warranty_policy
    or new.warranty_exclusions is distinct from old.warranty_exclusions;
  clearing_branding :=
    new.logo_url = ''
    and new.brand_color = '#087F5B'
    and new.customer_portal_title = 'بطاقة ضمان موثّقة'
    and new.warranty_policy = ''
    and new.warranty_exclusions = '';
  if branding_changed
     and not clearing_branding
     and not public.store_plan_allows(new.id, 'branding') then
    raise exception 'PLAN_BRANDING_REQUIRED';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_store_branding_entitlement"() OWNER TO "postgres";

--
-- Name: enforce_store_webhook_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_store_webhook_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if new.is_active and (tg_op = 'INSERT' or not old.is_active) then
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(new.store_id::text || ':webhooks', 0)
    );
    if (
      select count(*) from public.store_webhooks
      where store_id = new.store_id and is_active
        and (tg_op = 'INSERT' or id <> new.id)
    ) >= 5 then
      raise exception 'WEBHOOK_LIMIT_REACHED';
    end if;
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_store_webhook_limit"() OWNER TO "postgres";

--
-- Name: enforce_subscription_member_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_subscription_member_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  allowed_members integer := 1;
  active_owners integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':members', 0)
  );
  if public.subscription_is_usable(new.store_id) then
    select plan.max_members into allowed_members
    from public.plans plan
    where plan.id = new.plan_id;
  end if;
  allowed_members := greatest(coalesce(allowed_members, 1), 1);
  select count(*) into active_owners
  from public.store_members member
  where member.store_id = new.store_id
    and member.status = 'active'
    and member.role = 'owner';

  with ranked as (
    select
      member.user_id,
      row_number() over (
        order by member.joined_at, member.user_id
      ) as position
    from public.store_members member
    where member.store_id = new.store_id
      and member.status = 'active'
      and member.role <> 'owner'
  ), suspended as (
    update public.store_members member
    set status = 'suspended', updated_at = now()
    from ranked
    where member.store_id = new.store_id
      and member.user_id = ranked.user_id
      and ranked.position > greatest(allowed_members - active_owners, 0)
    returning member.user_id
  )
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  )
  select
    new.store_id,
    (select auth.uid()),
    'member_suspended_for_plan_limit',
    'member',
    suspended.user_id,
    jsonb_build_object('max_members', allowed_members)
  from suspended;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_subscription_member_limit"() OWNER TO "postgres";

--
-- Name: enforce_usable_subscription_for_core_write(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_usable_subscription_for_core_write"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  target_store_id uuid;
  actor_role text := coalesce((select auth.role()), '');
begin
  if actor_role in ('', 'service_role') then
    return new;
  end if;
  if actor_role <> 'authenticated' then
    raise exception 'AUTH_REQUIRED';
  end if;
  if current_setting('damanak.write_context', true) = 'return_sale' then
    return new;
  end if;
  if tg_table_name = 'register_sessions' and tg_op = 'UPDATE'
     and to_jsonb(old)->>'status' = 'open'
     and to_jsonb(new)->>'status' = 'closed'
     and to_jsonb(new)->>'id' = to_jsonb(old)->>'id'
     and to_jsonb(new)->>'store_id' = to_jsonb(old)->>'store_id'
     and to_jsonb(new)->>'branch_id' = to_jsonb(old)->>'branch_id'
     and to_jsonb(new)->>'opened_by' = to_jsonb(old)->>'opened_by'
     and to_jsonb(new)->>'opened_at' = to_jsonb(old)->>'opened_at' then
    return new;
  end if;
  target_store_id := nullif(to_jsonb(new)->>'store_id', '')::uuid;
  if target_store_id is null then
    raise exception 'STORE_REQUIRED';
  end if;
  if not public.subscription_is_usable(target_store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_usable_subscription_for_core_write"() OWNER TO "postgres";

--
-- Name: enforce_warranty_entitlement(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enforce_warranty_entitlement"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  included_limit integer;
  effective_limit integer;
  used_count bigint;
  actor uuid := (select auth.uid());
begin
  if (select auth.role()) = 'authenticated' then
    if actor is null then
      raise exception 'AUTH_REQUIRED';
    end if;
    new.created_by := actor;
    new.created_at := pg_catalog.now();
    new.updated_at := pg_catalog.now();
    new.voided_at := null;
  end if;

  if not public.subscription_is_usable(new.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':warranties', 0)
  );

  select plan.monthly_warranties
  into included_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = new.store_id;
  if included_limit is null then
    raise exception 'SUBSCRIPTION_PLAN_NOT_FOUND';
  end if;

  effective_limit := included_limit
    + pg_catalog.ceil(included_limit::numeric * 0.10)::integer;

  select pg_catalog.count(*)
  into used_count
  from public.warranties warranty
  where warranty.store_id = new.store_id
    and warranty.created_at >= pg_catalog.date_trunc(
      'month', pg_catalog.now()
    )
    and warranty.created_at < pg_catalog.date_trunc(
      'month', pg_catalog.now()
    ) + interval '1 month';

  if used_count >= effective_limit then
    raise exception 'WARRANTY_LIMIT_REACHED';
  end if;

  if new.warranty_number is null or new.warranty_number = '' then
    new.warranty_number :=
      'DMN-' || pg_catalog.to_char(pg_catalog.now(), 'YYMM') || '-S' ||
      pg_catalog.upper(
        pg_catalog.lpad(
          pg_catalog.to_hex(
            pg_catalog.nextval(
              'public.warranty_number_seq'::pg_catalog.regclass
            )
          ),
          12,
          '0'
        )
      );
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."enforce_warranty_entitlement"() OWNER TO "postgres";

--
-- Name: enqueue_overdue_claim_notifications("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."enqueue_overdue_claim_notifications"("target_store_id" "uuid") RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  inserted_count integer := 0;
begin
  if not exists (
    select 1 from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = auth.uid()
      and member.status = 'active'
  ) then
    raise exception 'STORE_MEMBER_REQUIRED';
  end if;

  insert into public.notifications(
    store_id, user_id, event_type, title, body, request_id, dedupe_key
  )
  select
    request.store_id,
    member.user_id,
    'claim_overdue',
    'مطالبة متأخرة CLM-' || lpad(request.claim_number::text, 6, '0'),
    'تجاوزت موعد المتابعة المحدد. افتحها وحدّث الخطوة التالية.',
    request.id,
    'claim-overdue:' || request.id::text || ':' || current_date::text
  from public.maintenance_requests request
  join public.store_members member
    on member.store_id = request.store_id
   and member.status = 'active'
   and (member.role in ('owner', 'manager') or member.user_id = request.assigned_to)
  left join public.notification_preferences preference
    on preference.store_id = member.store_id
   and preference.user_id = member.user_id
  where request.store_id = target_store_id
    and request.sla_due_at < now()
    and request.status not in ('completed', 'rejected', 'cancelled')
    and coalesce(preference.claim_overdue, true)
  on conflict (user_id, dedupe_key) do nothing;

  get diagnostics inserted_count = row_count;
  return inserted_count;
end;
$$;


ALTER FUNCTION "public"."enqueue_overdue_claim_notifications"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: find_warranty_by_serial("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
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


ALTER FUNCTION "public"."find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text") OWNER TO "postgres";

--
-- Name: finish_api_request(bigint, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."finish_api_request"("target_log_id" bigint, "target_status" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if target_status not between 100 and 599 then
    raise exception 'API_STATUS_INVALID';
  end if;
  update public.api_request_logs
  set response_status = target_status
  where id = target_log_id;
end;
$$;


ALTER FUNCTION "public"."finish_api_request"("target_log_id" bigint, "target_status" integer) OWNER TO "postgres";

--
-- Name: get_store_receipt_secret("text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."get_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text") RETURNS "text"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'private'
    AS $$
declare
  receipt_secret text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  select purchase_token into receipt_secret
  from private.store_receipt_secrets
  where platform = billing_platform
    and original_transaction_id = external_original_transaction_id;
  return receipt_secret;
end;
$$;


ALTER FUNCTION "public"."get_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text") OWNER TO "postgres";

--
-- Name: guard_maintenance_attachment(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."guard_maintenance_attachment"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  request_store_id uuid;
begin
  select store_id into request_store_id
  from public.maintenance_requests
  where id = new.request_id;
  if request_store_id is null or request_store_id <> new.store_id then
    raise exception 'CLAIM_ATTACHMENT_STORE_MISMATCH';
  end if;
  new.original_name = trim(new.original_name);
  return new;
end;
$$;


ALTER FUNCTION "public"."guard_maintenance_attachment"() OWNER TO "postgres";

--
-- Name: guard_maintenance_request(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."guard_maintenance_request"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  warranty_store_id uuid;
  branch_store_id uuid;
  actor_role text;
  allowed_transition boolean;
begin
  select store_id into warranty_store_id
  from public.warranties
  where id = new.warranty_id;

  if warranty_store_id is null or warranty_store_id <> new.store_id then
    raise exception 'CLAIM_WARRANTY_STORE_MISMATCH';
  end if;

  if new.service_branch_id is not null then
    select store_id into branch_store_id
    from public.branches
    where id = new.service_branch_id;
    if branch_store_id is null or branch_store_id <> new.store_id then
      raise exception 'CLAIM_BRANCH_STORE_MISMATCH';
    end if;
  end if;

  if new.assigned_to is not null and not exists (
    select 1
    from public.store_members member
    where member.store_id = new.store_id
      and member.user_id = new.assigned_to
      and member.status = 'active'
  ) then
    raise exception 'CLAIM_ASSIGNEE_INVALID';
  end if;

  new.customer_notes = trim(coalesce(new.customer_notes, ''));
  new.internal_notes = trim(coalesce(new.internal_notes, ''));
  new.diagnosis = trim(coalesce(new.diagnosis, ''));
  new.resolution_notes = trim(coalesce(new.resolution_notes, ''));
  new.decision_reason = trim(coalesce(new.decision_reason, ''));

  if tg_op = 'INSERT' then
    new.version = 1;
    new.updated_by = coalesce(new.updated_by, new.created_by);
    new.sla_due_at = coalesce(
      new.sla_due_at,
      now() + case new.priority
        when 'urgent' then interval '4 hours'
        when 'high' then interval '24 hours'
        when 'low' then interval '72 hours'
        else interval '48 hours'
      end
    );
    return new;
  end if;

  allowed_transition := new.status = old.status or case old.status
    when 'new' then new.status in ('needs_review', 'approved', 'in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'needs_review' then new.status in ('approved', 'in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'approved' then new.status in ('in_progress', 'waiting_for_customer', 'rejected', 'cancelled')
    when 'in_progress' then new.status in ('waiting_for_customer', 'ready_for_pickup', 'completed', 'rejected', 'cancelled')
    when 'waiting_for_customer' then new.status in ('needs_review', 'approved', 'in_progress', 'cancelled')
    when 'ready_for_pickup' then new.status in ('in_progress', 'completed', 'cancelled')
    when 'completed' then new.status in ('in_progress')
    when 'rejected' then new.status in ('needs_review')
    when 'cancelled' then new.status in ('needs_review')
    else false
  end;

  if not allowed_transition then
    raise exception 'CLAIM_STATUS_TRANSITION_INVALID';
  end if;

  if (select auth.uid()) is not null then
    select member.role into actor_role
    from public.store_members member
    where member.store_id = new.store_id
      and member.user_id = (select auth.uid())
      and member.status = 'active';

    if actor_role is null then
      raise exception 'CLAIM_STORE_ACCESS_DENIED';
    end if;

    if (
      (new.status in ('approved', 'rejected') and new.status <> old.status)
      or (new.resolution in ('refund', 'rejected') and new.resolution <> old.resolution)
      or (old.status in ('completed', 'rejected', 'cancelled') and new.status <> old.status)
    ) and actor_role not in ('owner', 'manager') then
      raise exception 'CLAIM_MANAGER_REQUIRED';
    end if;
  end if;

  if new.status = 'rejected' and new.decision_reason = '' then
    raise exception 'CLAIM_DECISION_REASON_REQUIRED';
  end if;

  if new.status = 'approved' and old.status <> 'approved' then
    new.approved_at = now();
  end if;
  if new.status = 'completed' and old.status <> 'completed' then
    new.completed_at = now();
  elsif new.status <> 'completed' then
    new.completed_at = null;
  end if;

  new.version = old.version + 1;
  new.updated_by = coalesce(new.updated_by, (select auth.uid()));
  return new;
end;
$$;


ALTER FUNCTION "public"."guard_maintenance_request"() OWNER TO "postgres";

--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.profiles(id, email, full_name)
  values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = case
      when public.profiles.full_name = '' then excluded.full_name
      else public.profiles.full_name
    end;
  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

--
-- Name: has_store_role("uuid", "text"[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.store_members
    where store_id = target_store_id
      and user_id = (select auth.uid())
      and status = 'active'
      and role = any(allowed_roles)
  );
$$;


ALTER FUNCTION "public"."has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]) OWNER TO "postgres";

--
-- Name: is_store_member("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."is_store_member"("target_store_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.store_members
    where store_id = target_store_id
      and user_id = (select auth.uid())
      and status = 'active'
  );
$$;


ALTER FUNCTION "public"."is_store_member"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: join_store_by_code("text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."join_store_by_code"("invitation_code" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $_$
declare
  actor uuid := (select auth.uid());
  normalized_code text := upper(trim(coalesce(invitation_code, '')));
  invite public.invite_codes%rowtype;
  allowed_members integer;
  active_members integer;
  existing_status text;
  attempt private.invite_join_attempts%rowtype;
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  select * into attempt
  from private.invite_join_attempts attempts
  where attempts.user_id = actor
  for update;
  if attempt.blocked_until is not null
     and attempt.blocked_until > now() then
    return jsonb_build_object(
      'error', 'INVITE_RATE_LIMITED',
      'retry_after_seconds', greatest(
        1,
        ceil(extract(epoch from attempt.blocked_until - now()))::integer
      )
    );
  elsif attempt.blocked_until is not null then
    delete from private.invite_join_attempts where user_id = actor;
  end if;

  if normalized_code ~ '^DMN-([A-F0-9]{10}|[A-F0-9]{16}|[A-F0-9]{32})$' then
    select * into invite
    from public.invite_codes
    where code_hash = extensions.digest(normalized_code, 'sha256')
      and is_active
      and expires_at > now()
      and used_count < max_uses
    for update;
  end if;

  if invite.id is null then
    insert into private.invite_join_attempts as attempts(
      user_id, window_started_at, failed_attempts, blocked_until, updated_at
    ) values (
      actor, now(), 1, null, now()
    )
    on conflict (user_id) do update set
      window_started_at = case
        when attempts.window_started_at <= now() - interval '15 minutes'
          then now()
        else attempts.window_started_at
      end,
      failed_attempts = case
        when attempts.window_started_at <= now() - interval '15 minutes'
          then 1
        else least(attempts.failed_attempts + 1, 1000)
      end,
      blocked_until = case
        when (
          case
            when attempts.window_started_at <= now() - interval '15 minutes'
              then 1
            else attempts.failed_attempts + 1
          end
        ) >= 10 then now() + interval '15 minutes'
        else null
      end,
      updated_at = now()
    returning * into attempt;

    return jsonb_build_object(
      'error', case
        when attempt.blocked_until is null
          then 'INVITE_INVALID'
        else 'INVITE_RATE_LIMITED'
      end,
      'retry_after_seconds', case
        when attempt.blocked_until is null then null
        else greatest(
          1,
          ceil(extract(epoch from attempt.blocked_until - now()))::integer
        )
      end
    );
  end if;

  delete from private.invite_join_attempts where user_id = actor;
  if not public.subscription_is_usable(invite.store_id) then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(invite.store_id::text || ':members', 0)
  );
  select plan.max_members into allowed_members
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = invite.store_id;
  if allowed_members is null then
    raise exception 'SUBSCRIPTION_INACTIVE';
  end if;

  select count(*) into active_members
  from public.store_members member
  where member.store_id = invite.store_id and member.status = 'active';
  select member.status into existing_status
  from public.store_members member
  where member.store_id = invite.store_id and member.user_id = actor;
  if active_members >= allowed_members
     and coalesce(existing_status, '') <> 'active' then
    raise exception 'SEAT_LIMIT_REACHED';
  end if;

  insert into public.store_members(store_id, user_id, role, status)
  values (invite.store_id, actor, invite.role, 'active')
  on conflict (store_id, user_id) do update set
    role = excluded.role,
    status = 'active',
    updated_at = now();
  update public.invite_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = invite.id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id
  ) values (
    invite.store_id, actor, 'member_joined', 'member', actor
  );

  return jsonb_build_object(
    'store_id', invite.store_id,
    'user_id', actor,
    'role', invite.role,
    'status', 'active'
  );
end;
$_$;


ALTER FUNCTION "public"."join_store_by_code"("invitation_code" "text") OWNER TO "postgres";

--
-- Name: list_store_api_keys("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."list_store_api_keys"("target_store_id" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select case when public.has_store_role(target_store_id, array['owner']) then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', key.id, 'name', key.name, 'keyPrefix', key.key_prefix,
      'scopes', key.scopes, 'createdAt', key.created_at,
      'lastUsedAt', key.last_used_at, 'revokedAt', key.revoked_at
    ) order by key.created_at desc), '[]'::jsonb)
  else '[]'::jsonb end
  from public.store_api_keys key where key.store_id = target_store_id
$$;


ALTER FUNCTION "public"."list_store_api_keys"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: list_store_webhooks("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."list_store_webhooks"("target_store_id" "uuid") RETURNS "jsonb"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select case when public.has_store_role(target_store_id, array['owner']) then
    coalesce(jsonb_agg(jsonb_build_object(
      'id', hook.id, 'endpointUrl', hook.endpoint_url,
      'events', hook.events, 'isActive', hook.is_active,
      'createdAt', hook.created_at
    ) order by hook.created_at desc), '[]'::jsonb)
  else '[]'::jsonb end
  from public.store_webhooks hook where hook.store_id = target_store_id
$$;


ALTER FUNCTION "public"."list_store_webhooks"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: open_register("uuid", "uuid", numeric, "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare session_row public.register_sessions%rowtype;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if target_opening_cash < 0 or not exists (
    select 1 from public.branches where id = target_branch_id
      and store_id = target_store_id and accepts_sales and is_active
  ) then raise exception 'INVALID_REGISTER'; end if;
  insert into public.register_sessions(
    store_id, branch_id, opened_by, opening_cash, notes
  ) values (
    target_store_id, target_branch_id, auth.uid(), target_opening_cash,
    coalesce(target_notes, '')
  ) returning * into session_row;
  return to_jsonb(session_row);
exception when unique_violation then
  raise exception 'REGISTER_ALREADY_OPEN';
end;
$$;


ALTER FUNCTION "public"."open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text") OWNER TO "postgres";

--
-- Name: queue_claim_webhooks(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."queue_claim_webhooks"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare event_name text;
begin
  event_name := case when tg_op = 'INSERT' then 'claim.created' else 'claim.updated' end;
  insert into public.webhook_deliveries(webhook_id, store_id, event_name, payload)
  select hook.id, new.store_id, event_name, jsonb_build_object(
    'event', event_name,
    'createdAt', now(),
    'data', jsonb_build_object(
      'id', new.id, 'claimNumber', new.claim_number, 'status', new.status,
      'category', new.category, 'priority', new.priority,
      'warrantyId', new.warranty_id, 'updatedAt', new.updated_at
    )
  )
  from public.store_webhooks hook
  where hook.store_id = new.store_id and hook.is_active
    and public.store_plan_allows(new.store_id, 'webhook')
    and event_name = any(hook.events);
  return new;
end;
$$;


ALTER FUNCTION "public"."queue_claim_webhooks"() OWNER TO "postgres";

--
-- Name: receive_purchase_order("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."receive_purchase_order"("target_purchase_order_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare order_row public.purchase_orders%rowtype;
  line_row public.purchase_order_lines%rowtype;
  level_row public.inventory_levels%rowtype;
  received numeric;
  new_cost numeric;
begin
  select * into order_row from public.purchase_orders
  where id = target_purchase_order_id and status in ('ordered', 'partially_received')
  for update;
  if not found or not public.has_store_role(order_row.store_id, array['owner', 'manager']) then
    raise exception 'PURCHASE_ORDER_NOT_RECEIVABLE';
  end if;
  for line_row in select * from public.purchase_order_lines
    where purchase_order_id = target_purchase_order_id for update
  loop
    received := line_row.quantity - line_row.received_quantity;
    if received > 0 then
      insert into public.inventory_levels(
        store_id, branch_id, product_id, on_hand, reorder_point, average_cost
      ) select order_row.store_id, order_row.branch_id, line_row.product_id,
          0, products.reorder_point, 0 from public.products
          where id = line_row.product_id
      on conflict (branch_id, product_id) do nothing;
      select * into level_row from public.inventory_levels
      where branch_id = order_row.branch_id and product_id = line_row.product_id
      for update;
      new_cost := case when level_row.on_hand + received = 0 then line_row.unit_cost
        else ((level_row.on_hand * level_row.average_cost) +
          (received * line_row.unit_cost)) / (level_row.on_hand + received) end;
      update public.inventory_levels
      set on_hand = on_hand + received, average_cost = round(new_cost, 3),
          updated_at = now()
      where id = level_row.id;
      update public.purchase_order_lines
      set received_quantity = quantity where id = line_row.id;
      insert into public.stock_movements(
        store_id, branch_id, product_id, movement_type, quantity, unit_cost,
        reference_type, reference_id, note, created_by
      ) values (
        order_row.store_id, order_row.branch_id, line_row.product_id, 'purchase',
        received, line_row.unit_cost, 'purchase_order', order_row.id,
        order_row.order_number, auth.uid()
      );
    end if;
  end loop;
  update public.purchase_orders set status = 'received', updated_at = now()
  where id = order_row.id;
end;
$$;


ALTER FUNCTION "public"."receive_purchase_order"("target_purchase_order_id" "uuid") OWNER TO "postgres";

--
-- Name: record_maintenance_request_event(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."record_maintenance_request_event"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  event_name text;
  event_title text;
  customer_visible boolean := false;
begin
  if tg_op = 'INSERT' then
    event_name := 'created';
    event_title := 'تم تسجيل المطالبة';
    customer_visible := true;
  elsif new.status is distinct from old.status then
    event_name := 'status_changed';
    event_title := 'تم تحديث حالة المطالبة';
    customer_visible := true;
  elsif new.assigned_to is distinct from old.assigned_to then
    event_name := 'assigned';
    event_title := 'تم تعيين مسؤول المطالبة';
  else
    event_name := 'details_updated';
    event_title := 'تم تحديث تفاصيل المطالبة';
  end if;

  insert into public.maintenance_request_events (
    request_id,
    store_id,
    event_type,
    old_status,
    new_status,
    title,
    is_customer_visible,
    created_by
  ) values (
    new.id,
    new.store_id,
    event_name,
    case when tg_op = 'UPDATE' then old.status else null end,
    new.status,
    event_title,
    customer_visible,
    coalesce(new.updated_by, new.created_by)
  );
  return new;
end;
$$;


ALTER FUNCTION "public"."record_maintenance_request_event"() OWNER TO "postgres";

--
-- Name: redeem_subscription_code("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."redeem_subscription_code"("target_store_id" "uuid", "activation_code" "text") RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'extensions'
    AS $$
declare
  license public.activation_codes%rowtype;
  updated_subscription_id uuid;
begin
  if not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'OWNER_REQUIRED';
  end if;

  select * into license
  from public.activation_codes
  where code_hash = digest(upper(trim(activation_code)), 'sha256')
    and is_active
    and expires_at > now()
    and used_count < max_uses
  for update;

  if license.id is null then
    raise exception 'ACTIVATION_CODE_INVALID';
  end if;

  update public.subscriptions
  set plan_id = license.plan_id,
      status = 'active',
      trial_ends_at = null,
      current_period_start = now(),
      current_period_end = greatest(coalesce(current_period_end, now()), now()) +
        make_interval(days => license.duration_days),
      source = 'activation_code'
  where store_id = target_store_id
  returning id into updated_subscription_id;

  update public.activation_codes
  set used_count = used_count + 1,
      is_active = used_count + 1 < max_uses
  where id = license.id;

  insert into public.audit_logs(store_id, user_id, action, entity_type, entity_id, metadata)
  values (
    target_store_id,
    (select auth.uid()),
    'subscription_activated',
    'subscription',
    updated_subscription_id,
    jsonb_build_object('plan_id', license.plan_id, 'duration_days', license.duration_days)
  );

  return updated_subscription_id;
end;
$$;


ALTER FUNCTION "public"."redeem_subscription_code"("target_store_id" "uuid", "activation_code" "text") OWNER TO "postgres";

--
-- Name: register_trial_device("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."register_trial_device"("target_store_id" "uuid", "device_claim" "text") RETURNS boolean
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'private', 'extensions'
    AS $_$
declare
  current_account_hash bytea;
  current_device_hash bytea;
  linked_account_hash bytea;
  registered_devices integer;
  normalized_claim text := lower(trim(coalesce(device_claim, '')));
begin
  if auth.uid() is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;
  if not exists (
    select 1
    from public.store_members member
    join public.stores store on store.id = member.store_id
    where member.store_id = target_store_id
      and member.user_id = auth.uid()
      and member.role = 'owner'
      and member.status = 'active'
      and store.owner_id = auth.uid()
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  current_account_hash := extensions.digest(
    'damanak:trial-account:v1:' || auth.uid()::text,
    'sha256'
  );
  current_device_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(encode(current_account_hash, 'hex'), 0)
  );

  insert into private.trial_account_claims(account_hash)
  values (current_account_hash)
  on conflict (account_hash) do update set last_seen_at = now();

  select account_hash into linked_account_hash
  from private.trial_device_claims
  where device_hash = current_device_hash;
  if found then
    if linked_account_hash = current_account_hash then
      update private.trial_device_claims
      set last_seen_at = now()
      where device_hash = current_device_hash;
      return true;
    end if;
    return false;
  end if;

  select count(*) into registered_devices
  from private.trial_device_claims
  where account_hash = current_account_hash;
  if registered_devices >= 5 then
    return false;
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (current_device_hash, current_account_hash);
  return true;
end;
$_$;


ALTER FUNCTION "public"."register_trial_device"("target_store_id" "uuid", "device_claim" "text") OWNER TO "postgres";

--
-- Name: release_store_entitlement_refresh("uuid", boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."release_store_entitlement_refresh"("target_entitlement_id" "uuid", "refresh_succeeded" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  update public.store_entitlements entitlement
  set refresh_locked_at = null,
      refresh_failures = case
        when refresh_succeeded then 0
        else least(coalesce(entitlement.refresh_failures, 0) + 1, 1000)
      end,
      next_verification_at = case
        when not refresh_succeeded then
          pg_catalog.now() + least(
            interval '6 hours',
            interval '5 minutes' * pg_catalog.power(
              2::double precision,
              least(coalesce(entitlement.refresh_failures, 0), 7)::double precision
            )
          )
        when entitlement.environment = 'sandbox' then
          least(
            pg_catalog.now() + interval '5 minutes',
            greatest(
              pg_catalog.now() + interval '1 minute',
              coalesce(
                entitlement.period_end - interval '1 minute',
                pg_catalog.now() + interval '5 minutes'
              )
            )
          )
        when entitlement.status in ('active', 'grace') then
          least(
            pg_catalog.now() + interval '6 hours',
            greatest(
              pg_catalog.now() + interval '5 minutes',
              coalesce(
                entitlement.period_end - interval '1 hour',
                pg_catalog.now() + interval '6 hours'
              )
            )
          )
        when entitlement.status = 'past_due' then
          pg_catalog.now() + interval '30 minutes'
        else pg_catalog.now() + interval '24 hours'
      end
  where entitlement.id = target_entitlement_id;
end;
$$;


ALTER FUNCTION "public"."release_store_entitlement_refresh"("target_entitlement_id" "uuid", "refresh_succeeded" boolean) OWNER TO "postgres";

--
-- Name: reserve_api_request("uuid", "uuid", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."reserve_api_request"("target_key_id" "uuid", "target_store_id" "uuid", "target_method" "text", "target_path" "text") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  recent_count integer;
  request_log_id bigint;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1 from public.store_api_keys
    where id = target_key_id and store_id = target_store_id
      and revoked_at is null
  ) then
    raise exception 'API_KEY_INVALID';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_key_id::text || ':api-hour', 0)
  );
  select count(*) into recent_count
  from public.api_request_logs
  where key_id = target_key_id
    and created_at >= now() - interval '1 hour';
  if recent_count >= 300 then
    return null;
  end if;
  insert into public.api_request_logs(
    key_id, store_id, method, path, response_status
  ) values (
    target_key_id, target_store_id, left(target_method, 16),
    left(target_path, 200), 0
  ) returning id into request_log_id;
  return request_log_id;
end;
$$;


ALTER FUNCTION "public"."reserve_api_request"("target_key_id" "uuid", "target_store_id" "uuid", "target_method" "text", "target_path" "text") OWNER TO "postgres";

--
-- Name: reserve_store_purchase_verification("uuid", "uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."reserve_store_purchase_verification"("target_store_id" "uuid", "target_user_id" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  request_time timestamptz := clock_timestamp();
  current_utc_day date := (request_time at time zone 'UTC')::date;
  limit_row private.store_purchase_verification_limits%rowtype;
  retry_after integer;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if not exists (
    select 1
    from public.store_members member
    where member.store_id = target_store_id
      and member.user_id = target_user_id
      and member.role = 'owner'
      and member.status = 'active'
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  insert into private.store_purchase_verification_limits(
    user_id, store_id, window_started_at, day_started_at
  ) values (
    target_user_id, target_store_id, request_time, current_utc_day
  )
  on conflict (user_id, store_id) do nothing;

  select * into limit_row
  from private.store_purchase_verification_limits limits
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id
  for update;

  if limit_row.window_started_at <= request_time - interval '15 minutes' then
    limit_row.window_started_at := request_time;
    limit_row.window_attempts := 0;
  end if;
  if limit_row.day_started_at <> current_utc_day then
    limit_row.day_started_at := current_utc_day;
    limit_row.day_attempts := 0;
  end if;

  update private.store_purchase_verification_limits limits
  set window_started_at = limit_row.window_started_at,
      window_attempts = limit_row.window_attempts,
      day_started_at = limit_row.day_started_at,
      day_attempts = limit_row.day_attempts,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  if limit_row.window_attempts >= 10 or limit_row.day_attempts >= 50 then
    retry_after := greatest(
      case when limit_row.window_attempts >= 10 then
        ceil(extract(epoch from (
          limit_row.window_started_at + interval '15 minutes' - request_time
        )))::integer
      else 0 end,
      case when limit_row.day_attempts >= 50 then
        ceil(extract(epoch from (
          ((current_utc_day + 1)::timestamp at time zone 'UTC') - request_time
        )))::integer
      else 0 end,
      1
    );
    return jsonb_build_object(
      'allowed', false,
      'retry_after_seconds', retry_after
    );
  end if;

  update private.store_purchase_verification_limits limits
  set window_attempts = window_attempts + 1,
      day_attempts = day_attempts + 1,
      updated_at = request_time
  where limits.user_id = target_user_id
    and limits.store_id = target_store_id;

  return jsonb_build_object(
    'allowed', true,
    'window_remaining', 9 - limit_row.window_attempts,
    'day_remaining', 49 - limit_row.day_attempts
  );
end;
$$;


ALTER FUNCTION "public"."reserve_store_purchase_verification"("target_store_id" "uuid", "target_user_id" "uuid") OWNER TO "postgres";

--
-- Name: resolve_google_purchase_token_binding("text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."resolve_google_purchase_token_binding"("raw_purchase_token" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  token_binding jsonb;
begin
  if (select auth.role()) <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if char_length(coalesce(raw_purchase_token, '')) < 20 then
    return null;
  end if;

  select pg_catalog.jsonb_build_object(
    'store_id', token_link.store_id,
    'user_id', token_link.user_id,
    'original_transaction_id', token_link.original_transaction_id
  )
  into token_binding
  from private.google_purchase_token_links token_link
  where token_link.token_hash = pg_catalog.encode(
    extensions.digest(raw_purchase_token, 'sha256'),
    'hex'
  );

  return token_binding;
end;
$$;


ALTER FUNCTION "public"."resolve_google_purchase_token_binding"("raw_purchase_token" "text") OWNER TO "postgres";

--
-- Name: return_sale("uuid", "uuid", "jsonb", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  sale_row public.sales%rowtype;
  line_row public.sale_lines%rowtype;
  return_id uuid;
  item jsonb;
  return_quantity numeric;
  refund_value numeric := 0;
  line_refund numeric;
  everything_returned boolean;
begin
  if not public.is_store_member(target_store_id) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if refund_method not in (
    'cash', 'card', 'bank_transfer', 'digital_wallet', 'other'
  ) then
    raise exception 'INVALID_REFUND_METHOD';
  end if;
  select * into sale_row from public.sales
  where id = target_sale_id and store_id = target_store_id
    and status not in ('returned', 'voided') for update;
  if not found then raise exception 'SALE_NOT_RETURNABLE'; end if;

  -- This setting is transaction-local and is set only after membership and
  -- sale validation. It lets the refund update inventory and sale totals even
  -- if the subscription expired after the original sale.
  perform set_config('damanak.write_context', 'return_sale', true);

  insert into public.sale_returns(
    sale_id, store_id, refund_method, refund_amount, reason, created_by
  ) values (
    target_sale_id, target_store_id, refund_method, 0,
    coalesce(nullif(trim(return_reason), ''), 'مرتجع عميل'), auth.uid()
  ) returning id into return_id;

  for item in select *
    from jsonb_array_elements(coalesce(returned_lines, '[]'::jsonb))
  loop
    return_quantity := (item->>'quantity')::numeric;
    select * into line_row from public.sale_lines
    where id = (item->>'sale_line_id')::uuid and sale_id = target_sale_id
    for update;
    if not found or return_quantity <= 0
       or line_row.returned_quantity + return_quantity > line_row.quantity then
      raise exception 'INVALID_RETURN_QUANTITY';
    end if;
    line_refund := round(
      line_row.line_total / line_row.quantity * return_quantity,
      3
    );
    refund_value := refund_value + line_refund;
    update public.sale_lines
    set returned_quantity = returned_quantity + return_quantity
    where id = line_row.id;
    update public.inventory_levels
    set on_hand = on_hand + return_quantity, updated_at = now()
    where branch_id = sale_row.branch_id and product_id = line_row.product_id;
    insert into public.stock_movements(
      store_id, branch_id, product_id, movement_type, quantity, unit_cost,
      reference_type, reference_id, note, created_by
    ) values (
      target_store_id, sale_row.branch_id, line_row.product_id, 'return_in',
      return_quantity, line_row.unit_cost, 'sale_return', return_id,
      coalesce(return_reason, ''), auth.uid()
    );
    insert into public.sale_return_lines(
      return_id, sale_line_id, quantity, refund_amount
    ) values (return_id, line_row.id, return_quantity, line_refund);

    if line_row.returned_quantity + return_quantity >= line_row.quantity then
      update public.warranties set voided_at = now()
      where sale_line_id = line_row.id and voided_at is null;
    end if;
  end loop;
  if refund_value <= 0 then raise exception 'EMPTY_RETURN'; end if;

  update public.sale_returns
  set refund_amount = refund_value
  where id = return_id;
  select bool_and(returned_quantity >= quantity) into everything_returned
  from public.sale_lines where sale_id = target_sale_id;
  update public.sales
  set refunded_amount = refunded_amount + refund_value,
      status = case
        when everything_returned then 'returned'
        else 'partially_returned'
      end,
      updated_at = now()
  where id = target_sale_id;
end;
$$;


ALTER FUNCTION "public"."return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text") OWNER TO "postgres";

--
-- Name: revoke_store_api_key("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."revoke_store_api_key"("target_key_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare target_store_id uuid;
begin
  select store_id into target_store_id from public.store_api_keys where id = target_key_id;
  if target_store_id is null or not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  update public.store_api_keys set revoked_at = coalesce(revoked_at, now())
  where id = target_key_id;
end;
$$;


ALTER FUNCTION "public"."revoke_store_api_key"("target_key_id" "uuid") OWNER TO "postgres";

--
-- Name: save_store_receipt_secret("text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."save_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text", "raw_purchase_token" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'private'
    AS $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if billing_platform <> 'google_play'
     or char_length(raw_purchase_token) < 20
     or not exists (
       select 1 from public.store_entitlements
       where platform = billing_platform
         and original_transaction_id = external_original_transaction_id
     ) then
    raise exception 'INVALID_STORE_RECEIPT_SECRET';
  end if;

  insert into private.store_receipt_secrets(
    platform, original_transaction_id, purchase_token, updated_at
  ) values (
    billing_platform, external_original_transaction_id,
    raw_purchase_token, now()
  )
  on conflict (platform, original_transaction_id) do update set
    purchase_token = excluded.purchase_token,
    updated_at = now();
end;
$$;


ALTER FUNCTION "public"."save_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text", "raw_purchase_token" "text") OWNER TO "postgres";

--
-- Name: seed_inventory_for_branch(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."seed_inventory_for_branch"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.inventory_levels(
    store_id, branch_id, product_id, reorder_point, average_cost
  )
  select new.store_id, new.id, products.id, products.reorder_point,
         coalesce(products.cost_price, 0)
  from public.products
  where products.store_id = new.store_id and products.is_active
  on conflict (branch_id, product_id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."seed_inventory_for_branch"() OWNER TO "postgres";

--
-- Name: seed_inventory_for_product(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."seed_inventory_for_product"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  insert into public.inventory_levels(
    store_id, branch_id, product_id, reorder_point, average_cost
  )
  select new.store_id, branches.id, new.id, new.reorder_point,
         coalesce(new.cost_price, 0)
  from public.branches
  where branches.store_id = new.store_id and branches.is_active
  on conflict (branch_id, product_id) do nothing;
  return new;
end;
$$;


ALTER FUNCTION "public"."seed_inventory_for_product"() OWNER TO "postgres";

--
-- Name: set_store_financial_defaults(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_store_financial_defaults"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  if new.currency_code is null or new.currency_code = '' or
      (tg_op = 'INSERT' and new.currency_code = 'SAR' and new.country_code <> 'SA') then
    new.currency_code := case new.country_code
      when 'AE' then 'AED'
      when 'KW' then 'KWD'
      when 'QA' then 'QAR'
      when 'BH' then 'BHD'
      when 'OM' then 'OMR'
      when 'SY' then 'SYP'
      else 'SAR'
    end;
  end if;
  new.invoice_prefix := upper(trim(coalesce(new.invoice_prefix, 'INV')));
  return new;
end;
$$;


ALTER FUNCTION "public"."set_store_financial_defaults"() OWNER TO "postgres";

--
-- Name: set_store_webhook_active("uuid", boolean); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare target_store_id uuid;
begin
  select store_id into target_store_id from public.store_webhooks where id = target_webhook_id;
  if target_store_id is null or not public.has_store_role(target_store_id, array['owner']) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;
  if target_active and not public.store_plan_allows(target_store_id, 'webhook') then
    raise exception 'PLAN_WEBHOOK_REQUIRED';
  end if;
  update public.store_webhooks set is_active = target_active, updated_at = now()
  where id = target_webhook_id;
end;
$$;


ALTER FUNCTION "public"."set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean) OWNER TO "postgres";

--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";

--
-- Name: set_warranty_invoice_number(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."set_warranty_invoice_number"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  prefix text;
begin
  if new.invoice_number is null or trim(new.invoice_number) = '' then
    select invoice_prefix into prefix from public.stores where id = new.store_id;
    new.invoice_number := coalesce(nullif(prefix, ''), 'INV') || '-' ||
      to_char(now(), 'YYMMDD') || '-' ||
      upper(substr(replace(new.id::text, '-', ''), 1, 6));
  else
    new.invoice_number := upper(trim(new.invoice_number));
  end if;
  return new;
end;
$$;


ALTER FUNCTION "public"."set_warranty_invoice_number"() OWNER TO "postgres";

--
-- Name: shares_store("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."shares_store"("target_user_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.store_members mine
    join public.store_members theirs on theirs.store_id = mine.store_id
    where mine.user_id = (select auth.uid())
      and mine.status = 'active'
      and theirs.user_id = target_user_id
  );
$$;


ALTER FUNCTION "public"."shares_store"("target_user_id" "uuid") OWNER TO "postgres";

--
-- Name: store_plan_allows("uuid", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."store_plan_allows"("target_store_id" "uuid", "entitlement_name" "text") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select coalesce((
    select case entitlement_name
      when 'api' then plan.api_access
      when 'webhook' then plan.webhook_access
      when 'branding' then plan.custom_branding
      else false
    end
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id
      and public.subscription_is_usable(target_store_id)
    limit 1
  ), false)
$$;


ALTER FUNCTION "public"."store_plan_allows"("target_store_id" "uuid", "entitlement_name" "text") OWNER TO "postgres";

--
-- Name: submit_public_warranty_claim("uuid", "uuid", "text", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."submit_public_warranty_claim"("target_warranty_id" "uuid", "submission_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_customer_notes" "text" DEFAULT ''::"text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  warranty_row public.warranties;
  existing_request public.maintenance_requests;
  created_request public.maintenance_requests;
  normalized_issue text := trim(claim_issue);
  normalized_notes text := trim(coalesce(claim_customer_notes, ''));
begin
  if submission_id is null then
    raise exception 'CLAIM_SUBMISSION_ID_REQUIRED';
  end if;
  if char_length(normalized_issue) not between 3 and 2000 then
    raise exception 'CLAIM_ISSUE_INVALID';
  end if;
  if char_length(normalized_notes) > 2000 then
    raise exception 'CLAIM_CUSTOMER_NOTES_INVALID';
  end if;
  if claim_category not in (
    'malfunction', 'battery', 'software', 'physical_damage',
    'missing_parts', 'other'
  ) then
    raise exception 'CLAIM_CATEGORY_INVALID';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(target_warranty_id::text, 0));

  select * into warranty_row
  from public.warranties
  where id = target_warranty_id
    and voided_at is null;
  if warranty_row.id is null then
    raise exception 'WARRANTY_NOT_FOUND';
  end if;
  if warranty_row.expiry_date < current_date then
    raise exception 'WARRANTY_EXPIRED';
  end if;

  select * into existing_request
  from public.maintenance_requests
  where public_submission_id = submission_id;
  if existing_request.id is not null then
    return jsonb_build_object(
      'requestId', existing_request.id,
      'storeId', existing_request.store_id,
      'claimNumber', existing_request.claim_number,
      'status', existing_request.status,
      'duplicate', true
    );
  end if;

  if (
    select count(*)
    from public.maintenance_requests request
    where request.warranty_id = target_warranty_id
      and request.channel = 'customer_portal'
      and request.created_at >= now() - interval '24 hours'
  ) >= 3 then
    raise exception 'CLAIM_RATE_LIMITED';
  end if;

  select * into existing_request
  from public.maintenance_requests request
  where request.warranty_id = target_warranty_id
    and request.channel = 'customer_portal'
    and request.status not in ('completed', 'rejected', 'cancelled')
    and lower(trim(request.issue)) = lower(normalized_issue)
    and request.created_at >= now() - interval '10 minutes'
  order by request.created_at desc
  limit 1;

  if existing_request.id is not null then
    return jsonb_build_object(
      'requestId', existing_request.id,
      'storeId', existing_request.store_id,
      'claimNumber', existing_request.claim_number,
      'status', existing_request.status,
      'duplicate', true
    );
  end if;

  insert into public.maintenance_requests (
    store_id,
    warranty_id,
    issue,
    status,
    category,
    priority,
    channel,
    customer_notes,
    public_submission_id,
    created_by
  ) values (
    warranty_row.store_id,
    warranty_row.id,
    normalized_issue,
    'new',
    claim_category,
    'normal',
    'customer_portal',
    normalized_notes,
    submission_id,
    null
  )
  returning * into created_request;

  return jsonb_build_object(
    'requestId', created_request.id,
    'storeId', created_request.store_id,
    'claimNumber', created_request.claim_number,
    'status', created_request.status,
    'duplicate', false
  );
end;
$$;


ALTER FUNCTION "public"."submit_public_warranty_claim"("target_warranty_id" "uuid", "submission_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_customer_notes" "text") OWNER TO "postgres";

--
-- Name: subscription_is_usable("uuid"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."subscription_is_usable"("target_store_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
  select exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = target_store_id
      and (
        (
          subscription.status = 'trialing'
          and subscription.trial_ends_at > pg_catalog.now()
        )
        or
        (
          subscription.status = 'active'
          and (
            (
              subscription.source = 'store'
              and subscription.current_period_end > pg_catalog.now()
            )
            or
            (
              subscription.source <> 'store'
              and (
                subscription.current_period_end is null
                or subscription.current_period_end > pg_catalog.now()
              )
            )
          )
        )
      )
  )
$$;


ALTER FUNCTION "public"."subscription_is_usable"("target_store_id" "uuid") OWNER TO "postgres";

--
-- Name: transfer_inventory("uuid", "uuid", "uuid", "uuid", numeric, "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  source_level public.inventory_levels%rowtype;
  transfer_id uuid := gen_random_uuid();
begin
  if not public.has_store_role(target_store_id, array['owner', 'manager']) then
    raise exception 'STORE_ACCESS_DENIED';
  end if;
  if target_quantity <= 0 or source_branch_id = destination_branch_id then
    raise exception 'INVALID_TRANSFER';
  end if;
  if (select count(*) from public.branches where store_id = target_store_id
      and id in (source_branch_id, destination_branch_id) and is_active) <> 2 then
    raise exception 'BRANCH_SCOPE_INVALID';
  end if;

  select * into source_level from public.inventory_levels
  where branch_id = source_branch_id and product_id = target_product_id
  for update;
  if not found or source_level.on_hand - source_level.reserved < target_quantity then
    raise exception 'INSUFFICIENT_STOCK';
  end if;

  update public.inventory_levels
  set on_hand = on_hand - target_quantity, updated_at = now()
  where id = source_level.id;
  insert into public.inventory_levels(
    store_id, branch_id, product_id, on_hand, reorder_point, average_cost
  ) values (
    target_store_id, destination_branch_id, target_product_id, target_quantity,
    source_level.reorder_point, source_level.average_cost
  )
  on conflict (branch_id, product_id) do update
  set on_hand = public.inventory_levels.on_hand + excluded.on_hand,
      average_cost = excluded.average_cost,
      updated_at = now();

  insert into public.stock_movements(
    store_id, branch_id, product_id, movement_type, quantity, unit_cost,
    reference_type, reference_id, note, created_by
  ) values
    (target_store_id, source_branch_id, target_product_id, 'transfer_out',
     -target_quantity, source_level.average_cost, 'stock_transfer', transfer_id,
     coalesce(target_note, ''), auth.uid()),
    (target_store_id, destination_branch_id, target_product_id, 'transfer_in',
     target_quantity, source_level.average_cost, 'stock_transfer', transfer_id,
     coalesce(target_note, ''), auth.uid());
end;
$$;


ALTER FUNCTION "public"."transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text") OWNER TO "postgres";

--
-- Name: trim_branches_to_subscription_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."trim_branches_to_subscription_limit"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  branch_limit integer;
begin
  if not public.subscription_is_usable(new.store_id) then
    return new;
  end if;
  select plan.max_branches
  into branch_limit
  from public.plans plan
  where plan.id = new.plan_id;
  if branch_limit is null then
    return new;
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(new.store_id::text || ':branches', 0)
  );
  with ranked as (
    select
      branch.id,
      pg_catalog.row_number() over (
        order by branch.is_main desc, branch.created_at, branch.id
      ) as position
    from public.branches branch
    where branch.store_id = new.store_id
      and branch.is_active
  )
  update public.branches branch
  set is_active = false,
      updated_at = pg_catalog.now()
  from ranked
  where branch.id = ranked.id
    and ranked.position > branch_limit;
  return new;
end;
$$;


ALTER FUNCTION "public"."trim_branches_to_subscription_limit"() OWNER TO "postgres";

--
-- Name: update_maintenance_request("uuid", integer, "jsonb"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  current_request public.maintenance_requests;
  updated_request public.maintenance_requests;
  unknown_keys text[];
begin
  select * into current_request
  from public.maintenance_requests
  where id = target_request_id
  for update;

  if current_request.id is null then
    raise exception 'CLAIM_NOT_FOUND';
  end if;
  if not public.is_store_member(current_request.store_id) then
    raise exception 'CLAIM_STORE_ACCESS_DENIED';
  end if;
  if current_request.version <> expected_version then
    raise exception 'CLAIM_VERSION_CONFLICT';
  end if;

  select array_agg(keys.key) into unknown_keys
  from jsonb_object_keys(coalesce(patch, '{}'::jsonb)) as keys(key)
  where key not in (
    'status', 'category', 'priority', 'resolution', 'customer_notes',
    'internal_notes', 'diagnosis', 'resolution_notes', 'decision_reason',
    'assigned_to', 'service_branch_id', 'sla_due_at'
  );
  if unknown_keys is not null then
    raise exception 'CLAIM_PATCH_INVALID';
  end if;

  update public.maintenance_requests
  set
    status = coalesce(patch->>'status', status),
    category = coalesce(patch->>'category', category),
    priority = coalesce(patch->>'priority', priority),
    resolution = coalesce(patch->>'resolution', resolution),
    customer_notes = case when patch ? 'customer_notes' then coalesce(patch->>'customer_notes', '') else customer_notes end,
    internal_notes = case when patch ? 'internal_notes' then coalesce(patch->>'internal_notes', '') else internal_notes end,
    diagnosis = case when patch ? 'diagnosis' then coalesce(patch->>'diagnosis', '') else diagnosis end,
    resolution_notes = case when patch ? 'resolution_notes' then coalesce(patch->>'resolution_notes', '') else resolution_notes end,
    decision_reason = case when patch ? 'decision_reason' then coalesce(patch->>'decision_reason', '') else decision_reason end,
    assigned_to = case when patch ? 'assigned_to' then nullif(patch->>'assigned_to', '')::uuid else assigned_to end,
    service_branch_id = case when patch ? 'service_branch_id' then nullif(patch->>'service_branch_id', '')::uuid else service_branch_id end,
    sla_due_at = case when patch ? 'sla_due_at' then nullif(patch->>'sla_due_at', '')::timestamptz else sla_due_at end,
    updated_by = (select auth.uid()),
    updated_at = now()
  where id = target_request_id
  returning * into updated_request;

  return to_jsonb(updated_request);
end;
$$;


ALTER FUNCTION "public"."update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb") OWNER TO "postgres";

--
-- Name: update_store_member("uuid", "uuid", "text", "text"); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION "public"."update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO ''
    AS $$
declare
  caller_role text;
  existing_role text;
  existing_status text;
  allowed_members integer;
  active_members integer;
begin
  select member.role into caller_role
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = (select auth.uid())
    and member.status = 'active';
  select member.role, member.status into existing_role, existing_status
  from public.store_members member
  where member.store_id = target_store_id
    and member.user_id = target_user_id;

  if caller_role not in ('owner', 'manager') then
    raise exception 'ROLE_REQUIRED';
  end if;
  if existing_role is null then
    raise exception 'MEMBER_NOT_FOUND';
  end if;
  if target_user_id = (select auth.uid()) or existing_role = 'owner' then
    raise exception 'OWNER_PROTECTED';
  end if;
  if target_role not in ('manager', 'staff')
     or target_status not in ('active', 'suspended') then
    raise exception 'INVALID_MEMBER_UPDATE';
  end if;
  if caller_role = 'manager'
     and (existing_role = 'manager' or target_role = 'manager') then
    raise exception 'OWNER_REQUIRED';
  end if;

  if target_status = 'active' and existing_status <> 'active' then
    if not public.subscription_is_usable(target_store_id) then
      raise exception 'SUBSCRIPTION_INACTIVE';
    end if;
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(target_store_id::text || ':members', 0)
    );
    select plan.max_members into allowed_members
    from public.subscriptions subscription
    join public.plans plan on plan.id = subscription.plan_id
    where subscription.store_id = target_store_id;
    select count(*) into active_members
    from public.store_members member
    where member.store_id = target_store_id and member.status = 'active';
    if allowed_members is null or active_members >= allowed_members then
      raise exception 'SEAT_LIMIT_REACHED';
    end if;
  end if;

  update public.store_members
  set role = target_role, status = target_status, updated_at = now()
  where store_id = target_store_id and user_id = target_user_id;
  insert into public.audit_logs(
    store_id, user_id, action, entity_type, entity_id, metadata
  ) values (
    target_store_id,
    (select auth.uid()),
    'member_updated',
    'member',
    target_user_id,
    jsonb_build_object('role', target_role, 'status', target_status)
  );
end;
$$;


ALTER FUNCTION "public"."update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text") OWNER TO "postgres";

--
-- Name: google_purchase_token_links; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."google_purchase_token_links" (
    "token_hash" "text" NOT NULL,
    "linked_token_hash" "text",
    "platform" "text" DEFAULT 'google_play'::"text" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "original_transaction_id" "text" NOT NULL,
    "first_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "google_purchase_token_links_linked_token_hash_check" CHECK ((("linked_token_hash" IS NULL) OR ("linked_token_hash" ~ '^[0-9a-f]{64}$'::"text"))),
    CONSTRAINT "google_purchase_token_links_platform_check" CHECK (("platform" = 'google_play'::"text")),
    CONSTRAINT "google_purchase_token_links_token_hash_check" CHECK (("token_hash" ~ '^[0-9a-f]{64}$'::"text"))
);


ALTER TABLE "private"."google_purchase_token_links" OWNER TO "postgres";

--
-- Name: invite_join_attempts; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."invite_join_attempts" (
    "user_id" "uuid" NOT NULL,
    "window_started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "failed_attempts" integer DEFAULT 0 NOT NULL,
    "blocked_until" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "invite_join_attempts_failed_attempts_check" CHECK ((("failed_attempts" >= 0) AND ("failed_attempts" <= 1000)))
);


ALTER TABLE "private"."invite_join_attempts" OWNER TO "postgres";

--
-- Name: store_purchase_verification_limits; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."store_purchase_verification_limits" (
    "user_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "window_started_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "window_attempts" integer DEFAULT 0 NOT NULL,
    "day_started_at" "date" DEFAULT (("now"() AT TIME ZONE 'UTC'::"text"))::"date" NOT NULL,
    "day_attempts" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_purchase_verification_limits_day_attempts_check" CHECK ((("day_attempts" >= 0) AND ("day_attempts" <= 50))),
    CONSTRAINT "store_purchase_verification_limits_window_attempts_check" CHECK ((("window_attempts" >= 0) AND ("window_attempts" <= 10)))
);


ALTER TABLE "private"."store_purchase_verification_limits" OWNER TO "postgres";

--
-- Name: store_receipt_secrets; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."store_receipt_secrets" (
    "platform" "text" NOT NULL,
    "original_transaction_id" "text" NOT NULL,
    "purchase_token" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_receipt_secrets_platform_check" CHECK (("platform" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"])))
);


ALTER TABLE "private"."store_receipt_secrets" OWNER TO "postgres";

--
-- Name: store_sandbox_review_grants; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."store_sandbox_review_grants" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "window_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "platform" "text" NOT NULL,
    "original_transaction_id" "text" NOT NULL,
    "granted_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    CONSTRAINT "store_sandbox_review_grants_check" CHECK (("expires_at" > "granted_at")),
    CONSTRAINT "store_sandbox_review_grants_check1" CHECK (("expires_at" <= ("granted_at" + '24:00:00'::interval))),
    CONSTRAINT "store_sandbox_review_grants_platform_check" CHECK (("platform" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"])))
);


ALTER TABLE "private"."store_sandbox_review_grants" OWNER TO "postgres";

--
-- Name: store_sandbox_review_windows; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."store_sandbox_review_windows" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "platform" "text" NOT NULL,
    "opens_at" timestamp with time zone NOT NULL,
    "closes_at" timestamp with time zone NOT NULL,
    "grant_ttl_seconds" integer DEFAULT 86400 NOT NULL,
    "max_grants" integer DEFAULT 8 NOT NULL,
    "grants_used" integer DEFAULT 0 NOT NULL,
    "release_version" "text" NOT NULL,
    "submission_id" "text" NOT NULL,
    "created_by" "text" NOT NULL,
    "note" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "revoked_at" timestamp with time zone,
    CONSTRAINT "store_sandbox_review_windows_check" CHECK (("closes_at" > "opens_at")),
    CONSTRAINT "store_sandbox_review_windows_check1" CHECK (("closes_at" <= ("opens_at" + '72:00:00'::interval))),
    CONSTRAINT "store_sandbox_review_windows_check2" CHECK (("grants_used" <= "max_grants")),
    CONSTRAINT "store_sandbox_review_windows_created_by_check" CHECK ((("char_length"("btrim"("created_by")) >= 3) AND ("char_length"("btrim"("created_by")) <= 200))),
    CONSTRAINT "store_sandbox_review_windows_grant_ttl_seconds_check" CHECK ((("grant_ttl_seconds" >= 300) AND ("grant_ttl_seconds" <= 86400))),
    CONSTRAINT "store_sandbox_review_windows_grants_used_check" CHECK (("grants_used" >= 0)),
    CONSTRAINT "store_sandbox_review_windows_max_grants_check" CHECK ((("max_grants" >= 1) AND ("max_grants" <= 20))),
    CONSTRAINT "store_sandbox_review_windows_platform_check" CHECK (("platform" = 'app_store'::"text")),
    CONSTRAINT "store_sandbox_review_windows_release_version_check" CHECK ((("char_length"("btrim"("release_version")) >= 1) AND ("char_length"("btrim"("release_version")) <= 50))),
    CONSTRAINT "store_sandbox_review_windows_submission_id_check" CHECK ((("char_length"("btrim"("submission_id")) >= 8) AND ("char_length"("btrim"("submission_id")) <= 100)))
);


ALTER TABLE "private"."store_sandbox_review_windows" OWNER TO "postgres";

--
-- Name: store_sandbox_testers; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."store_sandbox_testers" (
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "platform" "text" NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "note" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "store_sandbox_testers_check" CHECK ((("expires_at" > "created_at") AND ("expires_at" <= ("created_at" + '24:00:00'::interval)))),
    CONSTRAINT "store_sandbox_testers_platform_check" CHECK (("platform" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"])))
);


ALTER TABLE "private"."store_sandbox_testers" OWNER TO "postgres";

--
-- Name: trial_account_claims; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."trial_account_claims" (
    "account_hash" "bytea" NOT NULL,
    "first_claimed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "trial_account_claims_account_hash_check" CHECK (("octet_length"("account_hash") = 32))
);


ALTER TABLE "private"."trial_account_claims" OWNER TO "postgres";

--
-- Name: trial_device_claims; Type: TABLE; Schema: private; Owner: postgres
--

CREATE TABLE "private"."trial_device_claims" (
    "device_hash" "bytea" NOT NULL,
    "account_hash" "bytea" NOT NULL,
    "first_claimed_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "trial_device_claims_account_hash_check" CHECK (("octet_length"("account_hash") = 32)),
    CONSTRAINT "trial_device_claims_device_hash_check" CHECK (("octet_length"("device_hash") = 32))
);


ALTER TABLE "private"."trial_device_claims" OWNER TO "postgres";

--
-- Name: activation_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."activation_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code_hash" "bytea" NOT NULL,
    "plan_id" "text" NOT NULL,
    "duration_days" integer NOT NULL,
    "max_uses" integer DEFAULT 1 NOT NULL,
    "used_count" integer DEFAULT 0 NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "activation_codes_duration_days_check" CHECK ((("duration_days" >= 1) AND ("duration_days" <= 730))),
    CONSTRAINT "activation_codes_max_uses_check" CHECK ((("max_uses" >= 1) AND ("max_uses" <= 1000))),
    CONSTRAINT "activation_codes_used_count_check" CHECK (("used_count" >= 0))
);


ALTER TABLE "public"."activation_codes" OWNER TO "postgres";

--
-- Name: ai_claim_reviews; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."ai_claim_reviews" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "request_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "status" "text" NOT NULL,
    "provider" "text" DEFAULT 'openai'::"text" NOT NULL,
    "model" "text" NOT NULL,
    "included_attachments" boolean DEFAULT false NOT NULL,
    "input_tokens" integer,
    "output_tokens" integer,
    "estimated_cost_usd" numeric(12,6),
    "result" "jsonb",
    "error_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    CONSTRAINT "ai_claim_reviews_estimated_cost_usd_check" CHECK ((("estimated_cost_usd" IS NULL) OR ("estimated_cost_usd" >= (0)::numeric))),
    CONSTRAINT "ai_claim_reviews_input_tokens_check" CHECK ((("input_tokens" IS NULL) OR ("input_tokens" >= 0))),
    CONSTRAINT "ai_claim_reviews_output_tokens_check" CHECK ((("output_tokens" IS NULL) OR ("output_tokens" >= 0))),
    CONSTRAINT "ai_claim_reviews_provider_check" CHECK (("provider" = 'openai'::"text")),
    CONSTRAINT "ai_claim_reviews_status_check" CHECK (("status" = ANY (ARRAY['started'::"text", 'completed'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."ai_claim_reviews" OWNER TO "postgres";

--
-- Name: TABLE "ai_claim_reviews"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE "public"."ai_claim_reviews" IS 'Manager-triggered review aids. Never grants automated claim decisions.';


--
-- Name: ai_import_jobs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."ai_import_jobs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "status" "text" NOT NULL,
    "filename" "text" NOT NULL,
    "mime_type" "text" NOT NULL,
    "size_bytes" bigint NOT NULL,
    "model" "text" NOT NULL,
    "input_tokens" integer,
    "output_tokens" integer,
    "estimated_cost_usd" numeric(12,6),
    "product_count" integer DEFAULT 0 NOT NULL,
    "error_code" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "completed_at" timestamp with time zone,
    "provider" "text" DEFAULT 'openai'::"text" NOT NULL,
    "pricing_tier" "text" DEFAULT 'paid'::"text" NOT NULL,
    "fallback_used" boolean DEFAULT false NOT NULL,
    "provider_attempts" integer DEFAULT 1 NOT NULL,
    CONSTRAINT "ai_import_jobs_estimated_cost_usd_check" CHECK ((("estimated_cost_usd" IS NULL) OR ("estimated_cost_usd" >= (0)::numeric))),
    CONSTRAINT "ai_import_jobs_filename_check" CHECK ((("char_length"("filename") >= 1) AND ("char_length"("filename") <= 180))),
    CONSTRAINT "ai_import_jobs_input_tokens_check" CHECK ((("input_tokens" IS NULL) OR ("input_tokens" >= 0))),
    CONSTRAINT "ai_import_jobs_mime_type_check" CHECK (("mime_type" = ANY (ARRAY['application/pdf'::"text", 'image/jpeg'::"text", 'image/png'::"text", 'image/webp'::"text"]))),
    CONSTRAINT "ai_import_jobs_output_tokens_check" CHECK ((("output_tokens" IS NULL) OR ("output_tokens" >= 0))),
    CONSTRAINT "ai_import_jobs_pricing_tier_check" CHECK (("pricing_tier" = ANY (ARRAY['free'::"text", 'paid'::"text"]))),
    CONSTRAINT "ai_import_jobs_product_count_check" CHECK ((("product_count" >= 0) AND ("product_count" <= 100))),
    CONSTRAINT "ai_import_jobs_provider_attempts_check" CHECK ((("provider_attempts" >= 1) AND ("provider_attempts" <= 2))),
    CONSTRAINT "ai_import_jobs_provider_check" CHECK (("provider" = ANY (ARRAY['gemini'::"text", 'openai'::"text"]))),
    CONSTRAINT "ai_import_jobs_size_bytes_check" CHECK ((("size_bytes" >= 1) AND ("size_bytes" <= 8388608))),
    CONSTRAINT "ai_import_jobs_status_check" CHECK (("status" = ANY (ARRAY['started'::"text", 'completed'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."ai_import_jobs" OWNER TO "postgres";

--
-- Name: COLUMN "ai_import_jobs"."provider"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN "public"."ai_import_jobs"."provider" IS 'Final provider that produced the review-only extraction; document contents are never logged.';


--
-- Name: api_request_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."api_request_logs" (
    "id" bigint NOT NULL,
    "key_id" "uuid",
    "store_id" "uuid" NOT NULL,
    "method" "text" NOT NULL,
    "path" "text" NOT NULL,
    "response_status" integer NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."api_request_logs" OWNER TO "postgres";

--
-- Name: api_request_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."api_request_logs" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."api_request_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."audit_logs" (
    "id" bigint NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "action" "text" NOT NULL,
    "entity_type" "text" NOT NULL,
    "entity_id" "uuid",
    "metadata" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."audit_logs" OWNER TO "postgres";

--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."audit_logs" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."audit_logs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: branches; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."branches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "code" "text" NOT NULL,
    "city" "text" DEFAULT ''::"text" NOT NULL,
    "address" "text" DEFAULT ''::"text" NOT NULL,
    "phone" "text" DEFAULT ''::"text" NOT NULL,
    "is_main" boolean DEFAULT false NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "email" "text",
    "manager_name" "text" DEFAULT ''::"text" NOT NULL,
    "receipt_prefix" "text" DEFAULT 'POS'::"text" NOT NULL,
    "timezone" "text" DEFAULT 'Asia/Riyadh'::"text" NOT NULL,
    "opens_at" time without time zone DEFAULT '09:00:00'::time without time zone NOT NULL,
    "closes_at" time without time zone DEFAULT '23:00:00'::time without time zone NOT NULL,
    "branch_type" "text" DEFAULT 'retail'::"text" NOT NULL,
    "accepts_sales" boolean DEFAULT true NOT NULL,
    "handles_service" boolean DEFAULT true NOT NULL,
    CONSTRAINT "branches_code_check" CHECK (("code" ~ '^[A-Z0-9-]{2,12}$'::"text")),
    CONSTRAINT "branches_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 120)))
);


ALTER TABLE "public"."branches" OWNER TO "postgres";

--
-- Name: customers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."customers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text" NOT NULL,
    "email" "text",
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "customers_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 160))),
    CONSTRAINT "customers_phone_check" CHECK ((("char_length"(TRIM(BOTH FROM "phone")) >= 7) AND ("char_length"(TRIM(BOTH FROM "phone")) <= 30)))
);


ALTER TABLE "public"."customers" OWNER TO "postgres";

--
-- Name: inventory_levels; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."inventory_levels" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "on_hand" numeric(14,3) DEFAULT 0 NOT NULL,
    "reserved" numeric(14,3) DEFAULT 0 NOT NULL,
    "reorder_point" numeric(14,3) DEFAULT 0 NOT NULL,
    "average_cost" numeric(14,3) DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "inventory_levels_average_cost_check" CHECK (("average_cost" >= (0)::numeric)),
    CONSTRAINT "inventory_levels_check" CHECK ((("reserved" >= (0)::numeric) AND ("reserved" <= "on_hand"))),
    CONSTRAINT "inventory_levels_on_hand_check" CHECK (("on_hand" >= (0)::numeric)),
    CONSTRAINT "inventory_levels_reorder_point_check" CHECK (("reorder_point" >= (0)::numeric))
);


ALTER TABLE "public"."inventory_levels" OWNER TO "postgres";

--
-- Name: invite_codes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."invite_codes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "code_hash" "bytea" NOT NULL,
    "role" "text" NOT NULL,
    "max_uses" integer DEFAULT 1 NOT NULL,
    "used_count" integer DEFAULT 0 NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "invite_codes_max_uses_check" CHECK ((("max_uses" >= 1) AND ("max_uses" <= 10))),
    CONSTRAINT "invite_codes_role_check" CHECK (("role" = ANY (ARRAY['manager'::"text", 'staff'::"text"]))),
    CONSTRAINT "invite_codes_used_count_check" CHECK (("used_count" >= 0))
);


ALTER TABLE "public"."invite_codes" OWNER TO "postgres";

--
-- Name: maintenance_claim_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "public"."maintenance_claim_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."maintenance_claim_number_seq" OWNER TO "postgres";

--
-- Name: maintenance_request_attachments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."maintenance_request_attachments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "request_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "storage_path" "text" NOT NULL,
    "original_name" "text" NOT NULL,
    "mime_type" "text" NOT NULL,
    "size_bytes" bigint NOT NULL,
    "uploaded_by_type" "text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "maintenance_request_attachments_mime_type_check" CHECK (("mime_type" = ANY (ARRAY['image/jpeg'::"text", 'image/png'::"text", 'image/webp'::"text", 'application/pdf'::"text"]))),
    CONSTRAINT "maintenance_request_attachments_original_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "original_name")) >= 1) AND ("char_length"(TRIM(BOTH FROM "original_name")) <= 180))),
    CONSTRAINT "maintenance_request_attachments_size_bytes_check" CHECK ((("size_bytes" >= 1) AND ("size_bytes" <= 5242880))),
    CONSTRAINT "maintenance_request_attachments_storage_path_check" CHECK ((("char_length"("storage_path") >= 10) AND ("char_length"("storage_path") <= 500))),
    CONSTRAINT "maintenance_request_attachments_uploaded_by_type_check" CHECK (("uploaded_by_type" = ANY (ARRAY['customer'::"text", 'staff'::"text"])))
);


ALTER TABLE "public"."maintenance_request_attachments" OWNER TO "postgres";

--
-- Name: maintenance_request_events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."maintenance_request_events" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "request_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "old_status" "text",
    "new_status" "text",
    "title" "text" NOT NULL,
    "details" "jsonb" DEFAULT '{}'::"jsonb" NOT NULL,
    "is_customer_visible" boolean DEFAULT false NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "maintenance_request_events_event_type_check" CHECK (("event_type" = ANY (ARRAY['created'::"text", 'status_changed'::"text", 'assigned'::"text", 'details_updated'::"text", 'customer_message'::"text", 'staff_message'::"text", 'attachment_added'::"text"]))),
    CONSTRAINT "maintenance_request_events_title_check" CHECK ((("char_length"(TRIM(BOTH FROM "title")) >= 2) AND ("char_length"(TRIM(BOTH FROM "title")) <= 160)))
);


ALTER TABLE "public"."maintenance_request_events" OWNER TO "postgres";

--
-- Name: maintenance_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."maintenance_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "warranty_id" "uuid" NOT NULL,
    "issue" "text" NOT NULL,
    "status" "text" DEFAULT 'new'::"text" NOT NULL,
    "assigned_to" "uuid",
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "claim_number" bigint DEFAULT "nextval"('"public"."maintenance_claim_number_seq"'::"regclass") NOT NULL,
    "category" "text" DEFAULT 'other'::"text" NOT NULL,
    "priority" "text" DEFAULT 'normal'::"text" NOT NULL,
    "channel" "text" DEFAULT 'staff'::"text" NOT NULL,
    "resolution" "text" DEFAULT 'none'::"text" NOT NULL,
    "customer_notes" "text" DEFAULT ''::"text" NOT NULL,
    "internal_notes" "text" DEFAULT ''::"text" NOT NULL,
    "diagnosis" "text" DEFAULT ''::"text" NOT NULL,
    "resolution_notes" "text" DEFAULT ''::"text" NOT NULL,
    "decision_reason" "text" DEFAULT ''::"text" NOT NULL,
    "service_branch_id" "uuid",
    "sla_due_at" timestamp with time zone,
    "approved_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "updated_by" "uuid",
    "version" integer DEFAULT 1 NOT NULL,
    "public_submission_id" "uuid",
    CONSTRAINT "maintenance_requests_category_check" CHECK (("category" = ANY (ARRAY['malfunction'::"text", 'battery'::"text", 'software'::"text", 'physical_damage'::"text", 'missing_parts'::"text", 'other'::"text"]))),
    CONSTRAINT "maintenance_requests_channel_check" CHECK (("channel" = ANY (ARRAY['staff'::"text", 'customer_portal'::"text", 'import'::"text", 'api'::"text"]))),
    CONSTRAINT "maintenance_requests_issue_check" CHECK ((("char_length"(TRIM(BOTH FROM "issue")) >= 3) AND ("char_length"(TRIM(BOTH FROM "issue")) <= 2000))),
    CONSTRAINT "maintenance_requests_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text", 'urgent'::"text"]))),
    CONSTRAINT "maintenance_requests_resolution_check" CHECK (("resolution" = ANY (ARRAY['none'::"text", 'repair'::"text", 'replacement'::"text", 'refund'::"text", 'external_service'::"text", 'rejected'::"text"]))),
    CONSTRAINT "maintenance_requests_status_check" CHECK (("status" = ANY (ARRAY['new'::"text", 'needs_review'::"text", 'approved'::"text", 'in_progress'::"text", 'waiting_for_customer'::"text", 'ready_for_pickup'::"text", 'completed'::"text", 'rejected'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "maintenance_requests_version_check" CHECK (("version" > 0))
);


ALTER TABLE "public"."maintenance_requests" OWNER TO "postgres";

--
-- Name: notification_preferences; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."notification_preferences" (
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "claim_created" boolean DEFAULT true NOT NULL,
    "claim_assigned" boolean DEFAULT true NOT NULL,
    "claim_overdue" boolean DEFAULT true NOT NULL,
    "ready_for_pickup" boolean DEFAULT true NOT NULL,
    "marketing" boolean DEFAULT false NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."notification_preferences" OWNER TO "postgres";

--
-- Name: notifications; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "event_type" "text" NOT NULL,
    "title" "text" NOT NULL,
    "body" "text" DEFAULT ''::"text" NOT NULL,
    "request_id" "uuid",
    "dedupe_key" "text" NOT NULL,
    "read_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "notifications_body_check" CHECK (("char_length"("body") <= 500)),
    CONSTRAINT "notifications_dedupe_key_check" CHECK ((("char_length"("dedupe_key") >= 8) AND ("char_length"("dedupe_key") <= 200))),
    CONSTRAINT "notifications_event_type_check" CHECK (("event_type" = ANY (ARRAY['claim_created'::"text", 'claim_assigned'::"text", 'claim_overdue'::"text", 'ready_for_pickup'::"text", 'system'::"text"]))),
    CONSTRAINT "notifications_title_check" CHECK ((("char_length"(TRIM(BOTH FROM "title")) >= 2) AND ("char_length"(TRIM(BOTH FROM "title")) <= 120)))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";

--
-- Name: plans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."plans" (
    "id" "text" NOT NULL,
    "name_ar" "text" NOT NULL,
    "monthly_price" numeric(10,2) NOT NULL,
    "yearly_price" numeric(10,2) NOT NULL,
    "max_members" integer NOT NULL,
    "monthly_warranties" integer NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "monthly_ai_imports" integer DEFAULT 0 NOT NULL,
    "max_branches" integer DEFAULT 1 NOT NULL,
    "api_access" boolean DEFAULT false NOT NULL,
    "webhook_access" boolean DEFAULT false NOT NULL,
    "custom_branding" boolean DEFAULT false NOT NULL,
    "monthly_ai_claim_reviews" integer DEFAULT 0 NOT NULL,
    CONSTRAINT "plans_max_branches_check" CHECK ((("max_branches" >= 1) AND ("max_branches" <= 1000))),
    CONSTRAINT "plans_max_members_check" CHECK (("max_members" > 0)),
    CONSTRAINT "plans_monthly_ai_claim_reviews_check" CHECK ((("monthly_ai_claim_reviews" >= 0) AND ("monthly_ai_claim_reviews" <= 10000))),
    CONSTRAINT "plans_monthly_ai_imports_check" CHECK ((("monthly_ai_imports" >= 0) AND ("monthly_ai_imports" <= 10000))),
    CONSTRAINT "plans_monthly_price_check" CHECK (("monthly_price" >= (0)::numeric)),
    CONSTRAINT "plans_monthly_warranties_check" CHECK (("monthly_warranties" > 0)),
    CONSTRAINT "plans_yearly_price_check" CHECK (("yearly_price" >= (0)::numeric))
);


ALTER TABLE "public"."plans" OWNER TO "postgres";

--
-- Name: COLUMN "plans"."monthly_ai_imports"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN "public"."plans"."monthly_ai_imports" IS 'Server-enforced monthly allowance for review-only product catalog extraction.';


--
-- Name: products; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."products" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "brand" "text" DEFAULT ''::"text" NOT NULL,
    "barcode" "text",
    "sku" "text",
    "warranty_months" integer DEFAULT 12 NOT NULL,
    "sale_price" numeric(12,2),
    "is_active" boolean DEFAULT true NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "category" "text" DEFAULT ''::"text" NOT NULL,
    "cost_price" numeric(14,3),
    "track_inventory" boolean DEFAULT true NOT NULL,
    "is_serialized" boolean DEFAULT false NOT NULL,
    "reorder_point" numeric(14,3) DEFAULT 2 NOT NULL,
    "warranty_policy" "text" DEFAULT ''::"text" NOT NULL,
    "warranty_exclusions" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "products_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 160))),
    CONSTRAINT "products_sale_price_check" CHECK ((("sale_price" IS NULL) OR ("sale_price" >= (0)::numeric))),
    CONSTRAINT "products_warranty_months_check" CHECK ((("warranty_months" >= 1) AND ("warranty_months" <= 120))),
    CONSTRAINT "products_warranty_policy_check" CHECK ((("char_length"("warranty_policy") <= 4000) AND ("char_length"("warranty_exclusions") <= 4000)))
);


ALTER TABLE "public"."products" OWNER TO "postgres";

--
-- Name: COLUMN "products"."warranty_policy"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN "public"."products"."warranty_policy" IS 'Optional product override; an empty value inherits the store policy.';


--
-- Name: COLUMN "products"."warranty_exclusions"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN "public"."products"."warranty_exclusions" IS 'Optional product override; an empty value inherits the store exclusions.';


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."profiles" (
    "id" "uuid" NOT NULL,
    "email" "text" DEFAULT ''::"text" NOT NULL,
    "full_name" "text" DEFAULT ''::"text" NOT NULL,
    "phone" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";

--
-- Name: purchase_order_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."purchase_order_lines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "purchase_order_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "product_name" "text" NOT NULL,
    "quantity" numeric(14,3) NOT NULL,
    "received_quantity" numeric(14,3) DEFAULT 0 NOT NULL,
    "unit_cost" numeric(14,3) NOT NULL,
    CONSTRAINT "purchase_order_lines_check" CHECK ((("received_quantity" >= (0)::numeric) AND ("received_quantity" <= "quantity"))),
    CONSTRAINT "purchase_order_lines_quantity_check" CHECK (("quantity" > (0)::numeric)),
    CONSTRAINT "purchase_order_lines_unit_cost_check" CHECK (("unit_cost" >= (0)::numeric))
);


ALTER TABLE "public"."purchase_order_lines" OWNER TO "postgres";

--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."purchase_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sequence_number" bigint NOT NULL,
    "store_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "supplier_id" "uuid" NOT NULL,
    "order_number" "text" NOT NULL,
    "status" "text" DEFAULT 'ordered'::"text" NOT NULL,
    "expected_at" timestamp with time zone,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "total_cost" numeric(14,3) DEFAULT 0 NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "purchase_orders_status_check" CHECK (("status" = ANY (ARRAY['draft'::"text", 'ordered'::"text", 'partially_received'::"text", 'received'::"text", 'cancelled'::"text"]))),
    CONSTRAINT "purchase_orders_total_cost_check" CHECK (("total_cost" >= (0)::numeric))
);


ALTER TABLE "public"."purchase_orders" OWNER TO "postgres";

--
-- Name: purchase_orders_sequence_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."purchase_orders" ALTER COLUMN "sequence_number" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."purchase_orders_sequence_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: register_sessions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."register_sessions" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "opened_by" "uuid",
    "closed_by" "uuid",
    "opening_cash" numeric(14,3) DEFAULT 0 NOT NULL,
    "cash_sales" numeric(14,3) DEFAULT 0 NOT NULL,
    "cash_refunds" numeric(14,3) DEFAULT 0 NOT NULL,
    "cash_in" numeric(14,3) DEFAULT 0 NOT NULL,
    "cash_out" numeric(14,3) DEFAULT 0 NOT NULL,
    "closing_cash" numeric(14,3) DEFAULT 0 NOT NULL,
    "status" "text" DEFAULT 'open'::"text" NOT NULL,
    "opened_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "closed_at" timestamp with time zone,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "register_sessions_cash_in_check" CHECK (("cash_in" >= (0)::numeric)),
    CONSTRAINT "register_sessions_cash_out_check" CHECK (("cash_out" >= (0)::numeric)),
    CONSTRAINT "register_sessions_cash_refunds_check" CHECK (("cash_refunds" >= (0)::numeric)),
    CONSTRAINT "register_sessions_cash_sales_check" CHECK (("cash_sales" >= (0)::numeric)),
    CONSTRAINT "register_sessions_closing_cash_check" CHECK (("closing_cash" >= (0)::numeric)),
    CONSTRAINT "register_sessions_opening_cash_check" CHECK (("opening_cash" >= (0)::numeric)),
    CONSTRAINT "register_sessions_status_check" CHECK (("status" = ANY (ARRAY['open'::"text", 'closed'::"text"])))
);


ALTER TABLE "public"."register_sessions" OWNER TO "postgres";

--
-- Name: sale_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."sale_lines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "product_name" "text" NOT NULL,
    "sku" "text" DEFAULT ''::"text" NOT NULL,
    "barcode" "text" DEFAULT ''::"text" NOT NULL,
    "quantity" numeric(14,3) NOT NULL,
    "returned_quantity" numeric(14,3) DEFAULT 0 NOT NULL,
    "unit_price" numeric(14,3) NOT NULL,
    "unit_cost" numeric(14,3) DEFAULT 0 NOT NULL,
    "discount_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "line_total" numeric(14,3) NOT NULL,
    "warranty_months" integer DEFAULT 0 NOT NULL,
    "serial_numbers" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    CONSTRAINT "sale_lines_check" CHECK ((("returned_quantity" >= (0)::numeric) AND ("returned_quantity" <= "quantity"))),
    CONSTRAINT "sale_lines_discount_amount_check" CHECK (("discount_amount" >= (0)::numeric)),
    CONSTRAINT "sale_lines_line_total_check" CHECK (("line_total" >= (0)::numeric)),
    CONSTRAINT "sale_lines_quantity_check" CHECK (("quantity" > (0)::numeric)),
    CONSTRAINT "sale_lines_tax_amount_check" CHECK (("tax_amount" >= (0)::numeric)),
    CONSTRAINT "sale_lines_unit_cost_check" CHECK (("unit_cost" >= (0)::numeric)),
    CONSTRAINT "sale_lines_unit_price_check" CHECK (("unit_price" >= (0)::numeric)),
    CONSTRAINT "sale_lines_warranty_months_check" CHECK ((("warranty_months" >= 0) AND ("warranty_months" <= 120)))
);


ALTER TABLE "public"."sale_lines" OWNER TO "postgres";

--
-- Name: sale_payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."sale_payments" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "payment_method" "text" NOT NULL,
    "amount" numeric(14,3) NOT NULL,
    "reference" "text" DEFAULT ''::"text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sale_payments_amount_check" CHECK (("amount" > (0)::numeric)),
    CONSTRAINT "sale_payments_payment_method_check" CHECK (("payment_method" = ANY (ARRAY['cash'::"text", 'card'::"text", 'bank_transfer'::"text", 'digital_wallet'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."sale_payments" OWNER TO "postgres";

--
-- Name: sale_return_lines; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."sale_return_lines" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "return_id" "uuid" NOT NULL,
    "sale_line_id" "uuid" NOT NULL,
    "quantity" numeric(14,3) NOT NULL,
    "refund_amount" numeric(14,3) NOT NULL,
    CONSTRAINT "sale_return_lines_quantity_check" CHECK (("quantity" > (0)::numeric)),
    CONSTRAINT "sale_return_lines_refund_amount_check" CHECK (("refund_amount" >= (0)::numeric))
);


ALTER TABLE "public"."sale_return_lines" OWNER TO "postgres";

--
-- Name: sale_returns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."sale_returns" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sale_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "refund_method" "text" NOT NULL,
    "refund_amount" numeric(14,3) NOT NULL,
    "reason" "text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sale_returns_refund_amount_check" CHECK (("refund_amount" > (0)::numeric)),
    CONSTRAINT "sale_returns_refund_method_check" CHECK (("refund_method" = ANY (ARRAY['cash'::"text", 'card'::"text", 'bank_transfer'::"text", 'digital_wallet'::"text", 'other'::"text"])))
);


ALTER TABLE "public"."sale_returns" OWNER TO "postgres";

--
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."sales" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "sequence_number" bigint NOT NULL,
    "store_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "customer_id" "uuid",
    "customer_name" "text" DEFAULT 'عميل نقدي'::"text" NOT NULL,
    "customer_phone" "text" DEFAULT ''::"text" NOT NULL,
    "invoice_number" "text" NOT NULL,
    "status" "text" DEFAULT 'completed'::"text" NOT NULL,
    "subtotal" numeric(14,3) NOT NULL,
    "discount_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "total" numeric(14,3) NOT NULL,
    "refunded_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "currency_code" "text" NOT NULL,
    "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
    "prices_include_tax" boolean DEFAULT true NOT NULL,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "cashier_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "sales_discount_amount_check" CHECK (("discount_amount" >= (0)::numeric)),
    CONSTRAINT "sales_refunded_amount_check" CHECK (("refunded_amount" >= (0)::numeric)),
    CONSTRAINT "sales_status_check" CHECK (("status" = ANY (ARRAY['completed'::"text", 'partially_returned'::"text", 'returned'::"text", 'voided'::"text"]))),
    CONSTRAINT "sales_subtotal_check" CHECK (("subtotal" >= (0)::numeric)),
    CONSTRAINT "sales_tax_amount_check" CHECK (("tax_amount" >= (0)::numeric)),
    CONSTRAINT "sales_total_check" CHECK (("total" >= (0)::numeric))
);


ALTER TABLE "public"."sales" OWNER TO "postgres";

--
-- Name: sales_sequence_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sales" ALTER COLUMN "sequence_number" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."sales_sequence_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: stock_movements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."stock_movements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "branch_id" "uuid" NOT NULL,
    "product_id" "uuid" NOT NULL,
    "movement_type" "text" NOT NULL,
    "quantity" numeric(14,3) NOT NULL,
    "unit_cost" numeric(14,3) DEFAULT 0 NOT NULL,
    "reference_type" "text" DEFAULT ''::"text" NOT NULL,
    "reference_id" "uuid",
    "note" "text" DEFAULT ''::"text" NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "stock_movements_movement_type_check" CHECK (("movement_type" = ANY (ARRAY['opening'::"text", 'purchase'::"text", 'sale'::"text", 'return_in'::"text", 'transfer_out'::"text", 'transfer_in'::"text", 'adjustment'::"text"]))),
    CONSTRAINT "stock_movements_quantity_check" CHECK (("quantity" <> (0)::numeric)),
    CONSTRAINT "stock_movements_unit_cost_check" CHECK (("unit_cost" >= (0)::numeric))
);


ALTER TABLE "public"."stock_movements" OWNER TO "postgres";

--
-- Name: store_api_keys; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."store_api_keys" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "key_prefix" "text" NOT NULL,
    "key_hash" "bytea" NOT NULL,
    "scopes" "text"[] DEFAULT ARRAY['warranties:read'::"text"] NOT NULL,
    "created_by" "uuid",
    "last_used_at" timestamp with time zone,
    "revoked_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_api_keys_key_prefix_check" CHECK ((("char_length"("key_prefix") >= 12) AND ("char_length"("key_prefix") <= 24))),
    CONSTRAINT "store_api_keys_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 80))),
    CONSTRAINT "store_api_keys_scopes_check" CHECK (("scopes" <@ ARRAY['warranties:read'::"text", 'claims:read'::"text", 'claims:write'::"text"]))
);


ALTER TABLE "public"."store_api_keys" OWNER TO "postgres";

--
-- Name: store_entitlements; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."store_entitlements" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid",
    "platform" "text" NOT NULL,
    "product_id" "text" NOT NULL,
    "base_plan_id" "text" DEFAULT ''::"text" NOT NULL,
    "plan_id" "text" NOT NULL,
    "billing_cycle" "text" NOT NULL,
    "transaction_id" "text" NOT NULL,
    "original_transaction_id" "text" NOT NULL,
    "status" "text" NOT NULL,
    "environment" "text" NOT NULL,
    "period_start" timestamp with time zone,
    "period_end" timestamp with time zone,
    "auto_renews" boolean DEFAULT false NOT NULL,
    "verified_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "next_verification_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "refresh_locked_at" timestamp with time zone,
    "refresh_failures" integer DEFAULT 0 NOT NULL,
    "superseded_at" timestamp with time zone,
    "superseded_by" "uuid",
    CONSTRAINT "store_entitlements_billing_cycle_check" CHECK (("billing_cycle" = ANY (ARRAY['monthly'::"text", 'yearly'::"text"]))),
    CONSTRAINT "store_entitlements_environment_check" CHECK (("environment" = ANY (ARRAY['sandbox'::"text", 'production'::"text"]))),
    CONSTRAINT "store_entitlements_platform_check" CHECK (("platform" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"]))),
    CONSTRAINT "store_entitlements_refresh_failures_check" CHECK ((("refresh_failures" >= 0) AND ("refresh_failures" <= 1000))),
    CONSTRAINT "store_entitlements_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'grace'::"text", 'past_due'::"text", 'canceled'::"text", 'expired'::"text", 'revoked'::"text"]))),
    CONSTRAINT "store_entitlements_superseded_state_check" CHECK (((("superseded_at" IS NULL) AND ("superseded_by" IS NULL)) OR ("superseded_at" IS NOT NULL)))
);


ALTER TABLE "public"."store_entitlements" OWNER TO "postgres";

--
-- Name: store_members; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."store_members" (
    "store_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "role" "text" NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "joined_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_members_role_check" CHECK (("role" = ANY (ARRAY['owner'::"text", 'manager'::"text", 'staff'::"text"]))),
    CONSTRAINT "store_members_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'suspended'::"text"])))
);


ALTER TABLE "public"."store_members" OWNER TO "postgres";

--
-- Name: store_member_directory; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW "public"."store_member_directory" WITH ("security_invoker"='true') AS
 SELECT "members"."store_id",
    "members"."user_id",
    "members"."role",
    "members"."status",
    "members"."joined_at",
    "profiles"."full_name",
    "profiles"."email"
   FROM ("public"."store_members" "members"
     JOIN "public"."profiles" "profiles" ON (("profiles"."id" = "members"."user_id")));


ALTER VIEW "public"."store_member_directory" OWNER TO "postgres";

--
-- Name: store_product_catalog; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."store_product_catalog" (
    "platform" "text" NOT NULL,
    "product_id" "text" NOT NULL,
    "base_plan_id" "text" DEFAULT ''::"text" NOT NULL,
    "plan_id" "text" NOT NULL,
    "billing_cycle" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_product_catalog_billing_cycle_check" CHECK (("billing_cycle" = ANY (ARRAY['monthly'::"text", 'yearly'::"text"]))),
    CONSTRAINT "store_product_catalog_platform_check" CHECK (("platform" = ANY (ARRAY['app_store'::"text", 'google_play'::"text"])))
);


ALTER TABLE "public"."store_product_catalog" OWNER TO "postgres";

--
-- Name: store_webhooks; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."store_webhooks" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "endpoint_url" "text" NOT NULL,
    "events" "text"[] NOT NULL,
    "signing_secret" "text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_by" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "store_webhooks_endpoint_url_check" CHECK ((("char_length"("endpoint_url") <= 500) AND ("endpoint_url" ~ '^https://'::"text"))),
    CONSTRAINT "store_webhooks_events_check" CHECK (("events" <@ ARRAY['claim.created'::"text", 'claim.updated'::"text"])),
    CONSTRAINT "store_webhooks_events_check1" CHECK ((("cardinality"("events") >= 1) AND ("cardinality"("events") <= 2)))
);


ALTER TABLE "public"."store_webhooks" OWNER TO "postgres";

--
-- Name: stores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."stores" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "phone" "text" DEFAULT ''::"text" NOT NULL,
    "city" "text" DEFAULT ''::"text" NOT NULL,
    "country_code" "text" DEFAULT 'SA'::"text" NOT NULL,
    "owner_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "currency_code" "text" DEFAULT 'SAR'::"text" NOT NULL,
    "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
    "prices_include_tax" boolean DEFAULT true NOT NULL,
    "tax_number" "text" DEFAULT ''::"text" NOT NULL,
    "commercial_registration" "text" DEFAULT ''::"text" NOT NULL,
    "address" "text" DEFAULT ''::"text" NOT NULL,
    "invoice_prefix" "text" DEFAULT 'INV'::"text" NOT NULL,
    "default_warranty_months" integer DEFAULT 12 NOT NULL,
    "logo_url" "text" DEFAULT ''::"text" NOT NULL,
    "brand_color" "text" DEFAULT '#087F5B'::"text" NOT NULL,
    "customer_portal_title" "text" DEFAULT 'بطاقة ضمان موثّقة'::"text" NOT NULL,
    "warranty_policy" "text" DEFAULT ''::"text" NOT NULL,
    "warranty_exclusions" "text" DEFAULT ''::"text" NOT NULL,
    CONSTRAINT "stores_brand_color_check" CHECK (("brand_color" = ANY (ARRAY['#087F5B'::"text", '#1D4ED8'::"text", '#6D28D9'::"text", '#9F1239'::"text", '#334155'::"text", '#7C2D12'::"text"]))),
    CONSTRAINT "stores_country_code_check" CHECK (("country_code" = ANY (ARRAY['SA'::"text", 'AE'::"text", 'KW'::"text", 'QA'::"text", 'BH'::"text", 'OM'::"text", 'SY'::"text"]))),
    CONSTRAINT "stores_currency_code_check" CHECK (("currency_code" = ANY (ARRAY['SAR'::"text", 'AED'::"text", 'KWD'::"text", 'QAR'::"text", 'BHD'::"text", 'OMR'::"text", 'USD'::"text", 'SYP'::"text"]))),
    CONSTRAINT "stores_default_warranty_months_check" CHECK ((("default_warranty_months" >= 1) AND ("default_warranty_months" <= 120))),
    CONSTRAINT "stores_invoice_prefix_check" CHECK (("invoice_prefix" ~ '^[A-Z0-9]{2,8}$'::"text")),
    CONSTRAINT "stores_logo_url_check" CHECK ((("logo_url" = ''::"text") OR (("char_length"("logo_url") <= 500) AND ("logo_url" ~ '^https://'::"text")))),
    CONSTRAINT "stores_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 120))),
    CONSTRAINT "stores_portal_title_check" CHECK ((("char_length"(TRIM(BOTH FROM "customer_portal_title")) >= 3) AND ("char_length"(TRIM(BOTH FROM "customer_portal_title")) <= 80))),
    CONSTRAINT "stores_tax_rate_check" CHECK (("tax_rate" = (0)::numeric)),
    CONSTRAINT "stores_warranty_policy_check" CHECK ((("char_length"("warranty_policy") <= 4000) AND ("char_length"("warranty_exclusions") <= 4000)))
);


ALTER TABLE "public"."stores" OWNER TO "postgres";

--
-- Name: subscription_requests; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."subscription_requests" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "requested_plan_id" "text" NOT NULL,
    "billing_cycle" "text" NOT NULL,
    "contact_phone" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "requested_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "subscription_requests_billing_cycle_check" CHECK (("billing_cycle" = ANY (ARRAY['monthly'::"text", 'yearly'::"text"]))),
    CONSTRAINT "subscription_requests_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'contacted'::"text", 'completed'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."subscription_requests" OWNER TO "postgres";

--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."suppliers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "store_id" "uuid" NOT NULL,
    "name" "text" NOT NULL,
    "contact_name" "text" DEFAULT ''::"text" NOT NULL,
    "phone" "text" DEFAULT ''::"text" NOT NULL,
    "email" "text",
    "tax_number" "text" DEFAULT ''::"text" NOT NULL,
    "address" "text" DEFAULT ''::"text" NOT NULL,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "suppliers_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "name")) <= 160)))
);


ALTER TABLE "public"."suppliers" OWNER TO "postgres";

--
-- Name: warranties; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."warranties" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "warranty_number" "text" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "product_id" "uuid",
    "customer_name" "text" NOT NULL,
    "customer_phone" "text" NOT NULL,
    "product_name" "text" NOT NULL,
    "barcode" "text",
    "serial_number" "text",
    "purchase_date" "date" NOT NULL,
    "expiry_date" "date" NOT NULL,
    "notes" "text" DEFAULT ''::"text" NOT NULL,
    "created_by" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "customer_id" "uuid" NOT NULL,
    "branch_id" "uuid",
    "invoice_number" "text",
    "sale_subtotal" numeric(14,3) DEFAULT 0 NOT NULL,
    "discount_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "tax_amount" numeric(14,3) DEFAULT 0 NOT NULL,
    "sale_total" numeric(14,3) DEFAULT 0 NOT NULL,
    "tax_rate" numeric(5,2) DEFAULT 0 NOT NULL,
    "currency_code" "text" DEFAULT 'SAR'::"text" NOT NULL,
    "payment_method" "text" DEFAULT 'cash'::"text" NOT NULL,
    "sale_id" "uuid",
    "sale_line_id" "uuid",
    "voided_at" timestamp with time zone,
    CONSTRAINT "warranties_amounts_check" CHECK ((("sale_subtotal" >= (0)::numeric) AND ("discount_amount" >= (0)::numeric) AND ("discount_amount" <= "sale_subtotal") AND ("tax_amount" >= (0)::numeric) AND ("sale_total" >= (0)::numeric))),
    CONSTRAINT "warranties_check" CHECK (("expiry_date" >= "purchase_date")),
    CONSTRAINT "warranties_currency_code_check" CHECK (("currency_code" = ANY (ARRAY['SAR'::"text", 'AED'::"text", 'KWD'::"text", 'QAR'::"text", 'BHD'::"text", 'OMR'::"text", 'USD'::"text", 'SYP'::"text"]))),
    CONSTRAINT "warranties_customer_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "customer_name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "customer_name")) <= 160))),
    CONSTRAINT "warranties_customer_phone_check" CHECK ((("char_length"(TRIM(BOTH FROM "customer_phone")) >= 7) AND ("char_length"(TRIM(BOTH FROM "customer_phone")) <= 30))),
    CONSTRAINT "warranties_payment_method_check" CHECK (("payment_method" = ANY (ARRAY['cash'::"text", 'card'::"text", 'bank_transfer'::"text", 'digital_wallet'::"text", 'other'::"text"]))),
    CONSTRAINT "warranties_product_name_check" CHECK ((("char_length"(TRIM(BOTH FROM "product_name")) >= 2) AND ("char_length"(TRIM(BOTH FROM "product_name")) <= 200))),
    CONSTRAINT "warranties_tax_rate_check" CHECK ((("tax_rate" >= (0)::numeric) AND ("tax_rate" <= (100)::numeric)))
);


ALTER TABLE "public"."warranties" OWNER TO "postgres";

--
-- Name: warranty_number_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "public"."warranty_number_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE "public"."warranty_number_seq" OWNER TO "postgres";

--
-- Name: webhook_deliveries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "public"."webhook_deliveries" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "webhook_id" "uuid" NOT NULL,
    "store_id" "uuid" NOT NULL,
    "event_name" "text" NOT NULL,
    "payload" "jsonb" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "attempts" integer DEFAULT 0 NOT NULL,
    "locked_at" timestamp with time zone,
    "next_attempt_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "response_status" integer,
    "last_error" "text",
    "delivered_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "webhook_deliveries_attempts_check" CHECK ((("attempts" >= 0) AND ("attempts" <= 8))),
    CONSTRAINT "webhook_deliveries_event_name_check" CHECK (("event_name" = ANY (ARRAY['claim.created'::"text", 'claim.updated'::"text"]))),
    CONSTRAINT "webhook_deliveries_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'processing'::"text", 'delivered'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."webhook_deliveries" OWNER TO "postgres";

--
-- Name: google_purchase_token_links google_purchase_token_links_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."google_purchase_token_links"
    ADD CONSTRAINT "google_purchase_token_links_pkey" PRIMARY KEY ("token_hash");


--
-- Name: invite_join_attempts invite_join_attempts_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."invite_join_attempts"
    ADD CONSTRAINT "invite_join_attempts_pkey" PRIMARY KEY ("user_id");


--
-- Name: store_purchase_verification_limits store_purchase_verification_limits_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_purchase_verification_limits"
    ADD CONSTRAINT "store_purchase_verification_limits_pkey" PRIMARY KEY ("user_id", "store_id");


--
-- Name: store_receipt_secrets store_receipt_secrets_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_receipt_secrets"
    ADD CONSTRAINT "store_receipt_secrets_pkey" PRIMARY KEY ("platform", "original_transaction_id");


--
-- Name: store_sandbox_review_grants store_sandbox_review_grants_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_grants"
    ADD CONSTRAINT "store_sandbox_review_grants_pkey" PRIMARY KEY ("id");


--
-- Name: store_sandbox_review_grants store_sandbox_review_grants_window_id_store_id_user_id_plat_key; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_grants"
    ADD CONSTRAINT "store_sandbox_review_grants_window_id_store_id_user_id_plat_key" UNIQUE ("window_id", "store_id", "user_id", "platform");


--
-- Name: store_sandbox_review_windows store_sandbox_review_windows_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_windows"
    ADD CONSTRAINT "store_sandbox_review_windows_pkey" PRIMARY KEY ("id");


--
-- Name: store_sandbox_testers store_sandbox_testers_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_testers"
    ADD CONSTRAINT "store_sandbox_testers_pkey" PRIMARY KEY ("store_id", "user_id", "platform");


--
-- Name: trial_account_claims trial_account_claims_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."trial_account_claims"
    ADD CONSTRAINT "trial_account_claims_pkey" PRIMARY KEY ("account_hash");


--
-- Name: trial_device_claims trial_device_claims_pkey; Type: CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."trial_device_claims"
    ADD CONSTRAINT "trial_device_claims_pkey" PRIMARY KEY ("device_hash");


--
-- Name: activation_codes activation_codes_code_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."activation_codes"
    ADD CONSTRAINT "activation_codes_code_hash_key" UNIQUE ("code_hash");


--
-- Name: activation_codes activation_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."activation_codes"
    ADD CONSTRAINT "activation_codes_pkey" PRIMARY KEY ("id");


--
-- Name: ai_claim_reviews ai_claim_reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_claim_reviews"
    ADD CONSTRAINT "ai_claim_reviews_pkey" PRIMARY KEY ("id");


--
-- Name: ai_import_jobs ai_import_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_import_jobs"
    ADD CONSTRAINT "ai_import_jobs_pkey" PRIMARY KEY ("id");


--
-- Name: api_request_logs api_request_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."api_request_logs"
    ADD CONSTRAINT "api_request_logs_pkey" PRIMARY KEY ("id");


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id");


--
-- Name: branches branches_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_pkey" PRIMARY KEY ("id");


--
-- Name: branches branches_store_id_code_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_store_id_code_key" UNIQUE ("store_id", "code");


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_pkey" PRIMARY KEY ("id");


--
-- Name: customers customers_store_id_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_store_id_phone_key" UNIQUE ("store_id", "phone");


--
-- Name: inventory_levels inventory_levels_branch_id_product_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."inventory_levels"
    ADD CONSTRAINT "inventory_levels_branch_id_product_id_key" UNIQUE ("branch_id", "product_id");


--
-- Name: inventory_levels inventory_levels_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."inventory_levels"
    ADD CONSTRAINT "inventory_levels_pkey" PRIMARY KEY ("id");


--
-- Name: invite_codes invite_codes_code_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."invite_codes"
    ADD CONSTRAINT "invite_codes_code_hash_key" UNIQUE ("code_hash");


--
-- Name: invite_codes invite_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."invite_codes"
    ADD CONSTRAINT "invite_codes_pkey" PRIMARY KEY ("id");


--
-- Name: maintenance_request_attachments maintenance_request_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_attachments"
    ADD CONSTRAINT "maintenance_request_attachments_pkey" PRIMARY KEY ("id");


--
-- Name: maintenance_request_attachments maintenance_request_attachments_storage_path_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_attachments"
    ADD CONSTRAINT "maintenance_request_attachments_storage_path_key" UNIQUE ("storage_path");


--
-- Name: maintenance_request_events maintenance_request_events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_events"
    ADD CONSTRAINT "maintenance_request_events_pkey" PRIMARY KEY ("id");


--
-- Name: maintenance_requests maintenance_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_pkey" PRIMARY KEY ("id");


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_pkey" PRIMARY KEY ("store_id", "user_id");


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");


--
-- Name: notifications notifications_user_id_dedupe_key_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_dedupe_key_key" UNIQUE ("user_id", "dedupe_key");


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."plans"
    ADD CONSTRAINT "plans_pkey" PRIMARY KEY ("id");


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_pkey" PRIMARY KEY ("id");


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");


--
-- Name: purchase_order_lines purchase_order_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_pkey" PRIMARY KEY ("id");


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_pkey" PRIMARY KEY ("id");


--
-- Name: purchase_orders purchase_orders_store_id_order_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_store_id_order_number_key" UNIQUE ("store_id", "order_number");


--
-- Name: register_sessions register_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."register_sessions"
    ADD CONSTRAINT "register_sessions_pkey" PRIMARY KEY ("id");


--
-- Name: sale_lines sale_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_lines"
    ADD CONSTRAINT "sale_lines_pkey" PRIMARY KEY ("id");


--
-- Name: sale_payments sale_payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_pkey" PRIMARY KEY ("id");


--
-- Name: sale_return_lines sale_return_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_return_lines"
    ADD CONSTRAINT "sale_return_lines_pkey" PRIMARY KEY ("id");


--
-- Name: sale_returns sale_returns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_returns"
    ADD CONSTRAINT "sale_returns_pkey" PRIMARY KEY ("id");


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_pkey" PRIMARY KEY ("id");


--
-- Name: sales sales_store_id_invoice_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_store_id_invoice_number_key" UNIQUE ("store_id", "invoice_number");


--
-- Name: stock_movements stock_movements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_pkey" PRIMARY KEY ("id");


--
-- Name: store_api_keys store_api_keys_key_hash_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_api_keys"
    ADD CONSTRAINT "store_api_keys_key_hash_key" UNIQUE ("key_hash");


--
-- Name: store_api_keys store_api_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_api_keys"
    ADD CONSTRAINT "store_api_keys_pkey" PRIMARY KEY ("id");


--
-- Name: store_entitlements store_entitlements_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_pkey" PRIMARY KEY ("id");


--
-- Name: store_entitlements store_entitlements_platform_original_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_platform_original_transaction_id_key" UNIQUE ("platform", "original_transaction_id");


--
-- Name: store_entitlements store_entitlements_platform_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_platform_transaction_id_key" UNIQUE ("platform", "transaction_id");


--
-- Name: store_entitlements store_entitlements_store_link_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_store_link_unique" UNIQUE ("store_id", "platform", "original_transaction_id", "environment");


--
-- Name: store_members store_members_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_members"
    ADD CONSTRAINT "store_members_pkey" PRIMARY KEY ("store_id", "user_id");


--
-- Name: store_product_catalog store_product_catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_product_catalog"
    ADD CONSTRAINT "store_product_catalog_pkey" PRIMARY KEY ("platform", "product_id", "base_plan_id");


--
-- Name: store_product_catalog store_product_catalog_platform_plan_id_billing_cycle_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_product_catalog"
    ADD CONSTRAINT "store_product_catalog_platform_plan_id_billing_cycle_key" UNIQUE ("platform", "plan_id", "billing_cycle");


--
-- Name: store_webhooks store_webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_webhooks"
    ADD CONSTRAINT "store_webhooks_pkey" PRIMARY KEY ("id");


--
-- Name: stores stores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_pkey" PRIMARY KEY ("id");


--
-- Name: subscription_requests subscription_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscription_requests"
    ADD CONSTRAINT "subscription_requests_pkey" PRIMARY KEY ("id");


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id");


--
-- Name: subscriptions subscriptions_store_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_store_id_key" UNIQUE ("store_id");


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_pkey" PRIMARY KEY ("id");


--
-- Name: warranties warranties_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_pkey" PRIMARY KEY ("id");


--
-- Name: warranties warranties_warranty_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_warranty_number_key" UNIQUE ("warranty_number");


--
-- Name: webhook_deliveries webhook_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."webhook_deliveries"
    ADD CONSTRAINT "webhook_deliveries_pkey" PRIMARY KEY ("id");


--
-- Name: google_purchase_token_links_predecessor_idx; Type: INDEX; Schema: private; Owner: postgres
--

CREATE INDEX "google_purchase_token_links_predecessor_idx" ON "private"."google_purchase_token_links" USING "btree" ("linked_token_hash") WHERE ("linked_token_hash" IS NOT NULL);


--
-- Name: trial_device_claims_account_idx; Type: INDEX; Schema: private; Owner: postgres
--

CREATE INDEX "trial_device_claims_account_idx" ON "private"."trial_device_claims" USING "btree" ("account_hash");


--
-- Name: ai_claim_reviews_request_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "ai_claim_reviews_request_created_idx" ON "public"."ai_claim_reviews" USING "btree" ("request_id", "created_at" DESC);


--
-- Name: ai_claim_reviews_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "ai_claim_reviews_store_created_idx" ON "public"."ai_claim_reviews" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: ai_import_jobs_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "ai_import_jobs_store_created_idx" ON "public"."ai_import_jobs" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: api_request_logs_key_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "api_request_logs_key_created_idx" ON "public"."api_request_logs" USING "btree" ("key_id", "created_at" DESC);


--
-- Name: audit_logs_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "audit_logs_store_created_idx" ON "public"."audit_logs" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: branches_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "branches_id_store_id_key" ON "public"."branches" USING "btree" ("id", "store_id");


--
-- Name: branches_one_main_per_store; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "branches_one_main_per_store" ON "public"."branches" USING "btree" ("store_id") WHERE ("is_main" AND "is_active");


--
-- Name: customers_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "customers_id_store_id_key" ON "public"."customers" USING "btree" ("id", "store_id");


--
-- Name: customers_store_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "customers_store_name_idx" ON "public"."customers" USING "btree" ("store_id", "name");


--
-- Name: customers_store_updated_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "customers_store_updated_idx" ON "public"."customers" USING "btree" ("store_id", "updated_at" DESC);


--
-- Name: inventory_levels_store_branch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "inventory_levels_store_branch_idx" ON "public"."inventory_levels" USING "btree" ("store_id", "branch_id", "product_id");


--
-- Name: inventory_levels_store_updated_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "inventory_levels_store_updated_idx" ON "public"."inventory_levels" USING "btree" ("store_id", "updated_at" DESC);


--
-- Name: invite_codes_store_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "invite_codes_store_active_idx" ON "public"."invite_codes" USING "btree" ("store_id", "is_active", "expires_at");


--
-- Name: maintenance_assignee_open_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_assignee_open_idx" ON "public"."maintenance_requests" USING "btree" ("store_id", "assigned_to", "sla_due_at") WHERE ("status" <> ALL (ARRAY['completed'::"text", 'rejected'::"text", 'cancelled'::"text"]));


--
-- Name: maintenance_attachments_request_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_attachments_request_created_idx" ON "public"."maintenance_request_attachments" USING "btree" ("request_id", "created_at" DESC);


--
-- Name: maintenance_attachments_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_attachments_store_created_idx" ON "public"."maintenance_request_attachments" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: maintenance_events_request_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_events_request_created_idx" ON "public"."maintenance_request_events" USING "btree" ("request_id", "created_at" DESC);


--
-- Name: maintenance_events_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_events_store_created_idx" ON "public"."maintenance_request_events" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: maintenance_public_submission_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "maintenance_public_submission_idx" ON "public"."maintenance_requests" USING "btree" ("public_submission_id") WHERE ("public_submission_id" IS NOT NULL);


--
-- Name: maintenance_store_claim_number_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "maintenance_store_claim_number_idx" ON "public"."maintenance_requests" USING "btree" ("store_id", "claim_number");


--
-- Name: maintenance_store_status_updated_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_store_status_updated_idx" ON "public"."maintenance_requests" USING "btree" ("store_id", "status", "updated_at" DESC);


--
-- Name: maintenance_store_updated_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "maintenance_store_updated_idx" ON "public"."maintenance_requests" USING "btree" ("store_id", "updated_at" DESC);


--
-- Name: notifications_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "notifications_store_created_idx" ON "public"."notifications" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: notifications_user_unread_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "notifications_user_unread_idx" ON "public"."notifications" USING "btree" ("user_id", "created_at" DESC) WHERE ("read_at" IS NULL);


--
-- Name: products_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "products_id_store_id_key" ON "public"."products" USING "btree" ("id", "store_id");


--
-- Name: products_store_barcode_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "products_store_barcode_unique" ON "public"."products" USING "btree" ("store_id", "barcode") WHERE (("barcode" IS NOT NULL) AND ("barcode" <> ''::"text"));


--
-- Name: products_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "products_store_created_idx" ON "public"."products" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: products_store_sku_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "products_store_sku_unique" ON "public"."products" USING "btree" ("store_id", "sku") WHERE (("sku" IS NOT NULL) AND ("sku" <> ''::"text"));


--
-- Name: purchase_order_lines_order_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "purchase_order_lines_order_idx" ON "public"."purchase_order_lines" USING "btree" ("purchase_order_id");


--
-- Name: purchase_orders_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "purchase_orders_store_created_idx" ON "public"."purchase_orders" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: register_sessions_one_open_per_branch; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "register_sessions_one_open_per_branch" ON "public"."register_sessions" USING "btree" ("branch_id") WHERE ("status" = 'open'::"text");


--
-- Name: register_sessions_store_opened_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "register_sessions_store_opened_idx" ON "public"."register_sessions" USING "btree" ("store_id", "opened_at" DESC);


--
-- Name: sale_lines_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "sale_lines_id_store_id_key" ON "public"."sale_lines" USING "btree" ("id", "store_id");


--
-- Name: sale_lines_sale_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sale_lines_sale_idx" ON "public"."sale_lines" USING "btree" ("sale_id");


--
-- Name: sale_payments_sale_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sale_payments_sale_idx" ON "public"."sale_payments" USING "btree" ("sale_id");


--
-- Name: sale_return_lines_return_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sale_return_lines_return_idx" ON "public"."sale_return_lines" USING "btree" ("return_id");


--
-- Name: sale_return_lines_sale_line_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sale_return_lines_sale_line_idx" ON "public"."sale_return_lines" USING "btree" ("sale_line_id");


--
-- Name: sale_returns_sale_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sale_returns_sale_idx" ON "public"."sale_returns" USING "btree" ("sale_id");


--
-- Name: sales_branch_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sales_branch_created_idx" ON "public"."sales" USING "btree" ("branch_id", "created_at" DESC);


--
-- Name: sales_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "sales_id_store_id_key" ON "public"."sales" USING "btree" ("id", "store_id");


--
-- Name: sales_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "sales_store_created_idx" ON "public"."sales" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: stock_movements_product_branch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "stock_movements_product_branch_idx" ON "public"."stock_movements" USING "btree" ("product_id", "branch_id", "created_at" DESC);


--
-- Name: stock_movements_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "stock_movements_store_created_idx" ON "public"."stock_movements" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: store_api_keys_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "store_api_keys_store_created_idx" ON "public"."store_api_keys" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: store_entitlements_one_current_per_store; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "store_entitlements_one_current_per_store" ON "public"."store_entitlements" USING "btree" ("store_id") WHERE ("superseded_at" IS NULL);


--
-- Name: store_entitlements_refresh_due_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "store_entitlements_refresh_due_idx" ON "public"."store_entitlements" USING "btree" ("next_verification_at", "verified_at") WHERE (("superseded_at" IS NULL) AND ("status" = ANY (ARRAY['active'::"text", 'grace'::"text", 'past_due'::"text"])));


--
-- Name: store_entitlements_store_id_id_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "store_entitlements_store_id_id_unique" ON "public"."store_entitlements" USING "btree" ("store_id", "id");


--
-- Name: store_entitlements_store_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "store_entitlements_store_status_idx" ON "public"."store_entitlements" USING "btree" ("store_id", "status", "period_end" DESC);


--
-- Name: store_members_user_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "store_members_user_active_idx" ON "public"."store_members" USING "btree" ("user_id", "status");


--
-- Name: store_webhooks_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "store_webhooks_store_created_idx" ON "public"."store_webhooks" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: subscriptions_store_receipt_unique; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "subscriptions_store_receipt_unique" ON "public"."subscriptions" USING "btree" ("billing_provider", "original_transaction_id") WHERE ("source" = 'store'::"text");


--
-- Name: suppliers_store_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "suppliers_store_name_idx" ON "public"."suppliers" USING "btree" ("store_id", "name");


--
-- Name: warranties_id_store_id_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "warranties_id_store_id_key" ON "public"."warranties" USING "btree" ("id", "store_id");


--
-- Name: warranties_sale_line_active_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_sale_line_active_idx" ON "public"."warranties" USING "btree" ("sale_line_id") WHERE (("sale_line_id" IS NOT NULL) AND ("voided_at" IS NULL));


--
-- Name: warranties_store_active_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_active_created_idx" ON "public"."warranties" USING "btree" ("store_id", "created_at" DESC) WHERE ("voided_at" IS NULL);


--
-- Name: warranties_store_barcode_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_barcode_idx" ON "public"."warranties" USING "btree" ("store_id", "barcode");


--
-- Name: warranties_store_branch_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_branch_idx" ON "public"."warranties" USING "btree" ("store_id", "branch_id", "created_at" DESC);


--
-- Name: warranties_store_created_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_created_idx" ON "public"."warranties" USING "btree" ("store_id", "created_at" DESC);


--
-- Name: warranties_store_customer_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_customer_idx" ON "public"."warranties" USING "btree" ("store_id", "customer_id", "created_at" DESC);


--
-- Name: warranties_store_invoice_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_invoice_idx" ON "public"."warranties" USING "btree" ("store_id", "invoice_number");


--
-- Name: warranties_store_phone_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_phone_idx" ON "public"."warranties" USING "btree" ("store_id", "customer_phone");


--
-- Name: warranties_store_serial_normalized_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "warranties_store_serial_normalized_idx" ON "public"."warranties" USING "btree" ("store_id", "upper"("regexp_replace"(TRIM(BOTH FROM "serial_number"), '[^A-Za-z0-9]'::"text", ''::"text", 'g'::"text"))) WHERE (("serial_number" IS NOT NULL) AND (TRIM(BOTH FROM "serial_number") <> ''::"text") AND ("voided_at" IS NULL));


--
-- Name: webhook_deliveries_pending_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "webhook_deliveries_pending_idx" ON "public"."webhook_deliveries" USING "btree" ("next_attempt_at", "created_at") WHERE ("status" = 'pending'::"text");


--
-- Name: branches branches_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "branches_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: branches branches_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "branches_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."audit_business_change"();


--
-- Name: branches branches_entitlement; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "branches_entitlement" BEFORE INSERT OR UPDATE OF "is_active", "store_id" ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_branch_entitlement"();


--
-- Name: branches branches_seed_inventory; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "branches_seed_inventory" AFTER INSERT ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."seed_inventory_for_branch"();


--
-- Name: branches branches_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "branches_updated_at" BEFORE UPDATE ON "public"."branches" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: customers customers_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "customers_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: customers customers_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "customers_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."audit_business_change"();


--
-- Name: customers customers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "customers_updated_at" BEFORE UPDATE ON "public"."customers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: inventory_levels inventory_levels_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "inventory_levels_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."inventory_levels" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: inventory_levels inventory_levels_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "inventory_levels_updated_at" BEFORE UPDATE ON "public"."inventory_levels" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: maintenance_request_attachments maintenance_attachments_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_attachments_guard" BEFORE INSERT OR UPDATE ON "public"."maintenance_request_attachments" FOR EACH ROW EXECUTE FUNCTION "public"."guard_maintenance_attachment"();


--
-- Name: maintenance_requests maintenance_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."audit_business_change"();


--
-- Name: maintenance_requests maintenance_requests_00_authenticated_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_requests_00_authenticated_guard" BEFORE INSERT OR UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_authenticated_claim_write"();


--
-- Name: maintenance_requests maintenance_requests_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_requests_guard" BEFORE INSERT OR UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."guard_maintenance_request"();


--
-- Name: maintenance_requests maintenance_requests_notifications; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_requests_notifications" AFTER INSERT OR UPDATE OF "assigned_to", "status" ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."create_claim_notifications"();


--
-- Name: maintenance_requests maintenance_requests_record_event; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_requests_record_event" AFTER INSERT OR UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."record_maintenance_request_event"();


--
-- Name: maintenance_requests maintenance_requests_webhooks; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_requests_webhooks" AFTER INSERT OR UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."queue_claim_webhooks"();


--
-- Name: maintenance_requests maintenance_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "maintenance_set_updated_at" BEFORE UPDATE ON "public"."maintenance_requests" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: products products_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "products_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: products products_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "products_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."audit_business_change"();


--
-- Name: products products_branding_entitlement; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "products_branding_entitlement" BEFORE INSERT OR UPDATE OF "warranty_policy", "warranty_exclusions" ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_product_branding_entitlement"();


--
-- Name: products products_seed_inventory; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "products_seed_inventory" AFTER INSERT ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."seed_inventory_for_product"();


--
-- Name: products products_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "products_set_updated_at" BEFORE UPDATE ON "public"."products" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: profiles profiles_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "profiles_set_updated_at" BEFORE UPDATE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: purchase_order_lines purchase_order_lines_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "purchase_order_lines_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."purchase_order_lines" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: purchase_orders purchase_orders_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "purchase_orders_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."purchase_orders" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: purchase_orders purchase_orders_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "purchase_orders_updated_at" BEFORE UPDATE ON "public"."purchase_orders" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: register_sessions register_sessions_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "register_sessions_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."register_sessions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: sale_lines sale_lines_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "sale_lines_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."sale_lines" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: sale_payments sale_payments_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "sale_payments_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."sale_payments" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: sale_returns sale_returns_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "sale_returns_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."sale_returns" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: sales sales_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "sales_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: sales sales_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "sales_updated_at" BEFORE UPDATE ON "public"."sales" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: stock_movements stock_movements_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "stock_movements_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."stock_movements" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: store_api_keys store_api_keys_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "store_api_keys_limit" BEFORE INSERT ON "public"."store_api_keys" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_store_api_key_limit"();


--
-- Name: store_entitlements store_entitlements_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "store_entitlements_updated_at" BEFORE UPDATE ON "public"."store_entitlements" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: store_members store_members_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "store_members_set_updated_at" BEFORE UPDATE ON "public"."store_members" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: store_product_catalog store_product_catalog_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "store_product_catalog_updated_at" BEFORE UPDATE ON "public"."store_product_catalog" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: store_webhooks store_webhooks_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "store_webhooks_limit" BEFORE INSERT OR UPDATE OF "is_active" ON "public"."store_webhooks" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_store_webhook_limit"();


--
-- Name: stores stores_branding_entitlement; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "stores_branding_entitlement" BEFORE UPDATE OF "logo_url", "brand_color", "customer_portal_title", "warranty_policy", "warranty_exclusions" ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_store_branding_entitlement"();


--
-- Name: stores stores_create_default_branch; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE CONSTRAINT TRIGGER "stores_create_default_branch" AFTER INSERT ON "public"."stores" DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE FUNCTION "public"."create_default_store_branch"();


--
-- Name: TRIGGER "stores_create_default_branch" ON "stores"; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER "stores_create_default_branch" ON "public"."stores" IS 'Creates the main branch after the new store trial subscription exists.';


--
-- Name: stores stores_financial_defaults; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "stores_financial_defaults" BEFORE INSERT OR UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."set_store_financial_defaults"();


--
-- Name: stores stores_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "stores_set_updated_at" BEFORE UPDATE ON "public"."stores" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: subscription_requests subscription_requests_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "subscription_requests_set_updated_at" BEFORE UPDATE ON "public"."subscription_requests" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: subscriptions subscriptions_enforce_member_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "subscriptions_enforce_member_limit" AFTER INSERT OR UPDATE OF "plan_id", "status", "trial_ends_at", "current_period_end" ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_subscription_member_limit"();


--
-- Name: subscriptions subscriptions_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "subscriptions_set_updated_at" BEFORE UPDATE ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: subscriptions subscriptions_trim_branches_to_plan; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "subscriptions_trim_branches_to_plan" AFTER INSERT OR UPDATE OF "plan_id", "status", "trial_ends_at", "current_period_end" ON "public"."subscriptions" FOR EACH ROW EXECUTE FUNCTION "public"."trim_branches_to_subscription_limit"();


--
-- Name: suppliers suppliers_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "suppliers_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."suppliers" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: suppliers suppliers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "suppliers_updated_at" BEFORE UPDATE ON "public"."suppliers" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: warranties warranties_00_subscription_write_guard; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "warranties_00_subscription_write_guard" BEFORE INSERT OR UPDATE ON "public"."warranties" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_usable_subscription_for_core_write"();


--
-- Name: warranties warranties_audit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "warranties_audit" AFTER INSERT OR DELETE OR UPDATE ON "public"."warranties" FOR EACH ROW EXECUTE FUNCTION "public"."audit_business_change"();


--
-- Name: warranties warranties_enforce_entitlement; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "warranties_enforce_entitlement" BEFORE INSERT ON "public"."warranties" FOR EACH ROW EXECUTE FUNCTION "public"."enforce_warranty_entitlement"();


--
-- Name: warranties warranties_set_invoice_number; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "warranties_set_invoice_number" BEFORE INSERT ON "public"."warranties" FOR EACH ROW EXECUTE FUNCTION "public"."set_warranty_invoice_number"();


--
-- Name: warranties warranties_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER "warranties_set_updated_at" BEFORE UPDATE ON "public"."warranties" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();


--
-- Name: google_purchase_token_links google_purchase_token_links_platform_original_transaction__fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."google_purchase_token_links"
    ADD CONSTRAINT "google_purchase_token_links_platform_original_transaction__fkey" FOREIGN KEY ("platform", "original_transaction_id") REFERENCES "public"."store_entitlements"("platform", "original_transaction_id") ON DELETE CASCADE;


--
-- Name: google_purchase_token_links google_purchase_token_links_store_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."google_purchase_token_links"
    ADD CONSTRAINT "google_purchase_token_links_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: google_purchase_token_links google_purchase_token_links_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."google_purchase_token_links"
    ADD CONSTRAINT "google_purchase_token_links_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: invite_join_attempts invite_join_attempts_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."invite_join_attempts"
    ADD CONSTRAINT "invite_join_attempts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: store_purchase_verification_limits store_purchase_verification_limits_store_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_purchase_verification_limits"
    ADD CONSTRAINT "store_purchase_verification_limits_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_purchase_verification_limits store_purchase_verification_limits_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_purchase_verification_limits"
    ADD CONSTRAINT "store_purchase_verification_limits_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: store_receipt_secrets store_receipt_secrets_entitlement_fk; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_receipt_secrets"
    ADD CONSTRAINT "store_receipt_secrets_entitlement_fk" FOREIGN KEY ("platform", "original_transaction_id") REFERENCES "public"."store_entitlements"("platform", "original_transaction_id") ON DELETE CASCADE;


--
-- Name: store_sandbox_review_grants store_sandbox_review_grants_store_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_grants"
    ADD CONSTRAINT "store_sandbox_review_grants_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_sandbox_review_grants store_sandbox_review_grants_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_grants"
    ADD CONSTRAINT "store_sandbox_review_grants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: store_sandbox_review_grants store_sandbox_review_grants_window_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_review_grants"
    ADD CONSTRAINT "store_sandbox_review_grants_window_id_fkey" FOREIGN KEY ("window_id") REFERENCES "private"."store_sandbox_review_windows"("id") ON DELETE RESTRICT;


--
-- Name: store_sandbox_testers store_sandbox_testers_store_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_testers"
    ADD CONSTRAINT "store_sandbox_testers_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_sandbox_testers store_sandbox_testers_user_id_fkey; Type: FK CONSTRAINT; Schema: private; Owner: postgres
--

ALTER TABLE ONLY "private"."store_sandbox_testers"
    ADD CONSTRAINT "store_sandbox_testers_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: activation_codes activation_codes_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."activation_codes"
    ADD CONSTRAINT "activation_codes_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");


--
-- Name: ai_claim_reviews ai_claim_reviews_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_claim_reviews"
    ADD CONSTRAINT "ai_claim_reviews_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."maintenance_requests"("id") ON DELETE CASCADE;


--
-- Name: ai_claim_reviews ai_claim_reviews_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_claim_reviews"
    ADD CONSTRAINT "ai_claim_reviews_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: ai_claim_reviews ai_claim_reviews_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_claim_reviews"
    ADD CONSTRAINT "ai_claim_reviews_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: ai_import_jobs ai_import_jobs_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_import_jobs"
    ADD CONSTRAINT "ai_import_jobs_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: ai_import_jobs ai_import_jobs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."ai_import_jobs"
    ADD CONSTRAINT "ai_import_jobs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: api_request_logs api_request_logs_key_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."api_request_logs"
    ADD CONSTRAINT "api_request_logs_key_id_fkey" FOREIGN KEY ("key_id") REFERENCES "public"."store_api_keys"("id") ON DELETE SET NULL;


--
-- Name: api_request_logs api_request_logs_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."api_request_logs"
    ADD CONSTRAINT "api_request_logs_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."audit_logs"
    ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: branches branches_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."branches"
    ADD CONSTRAINT "branches_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: customers customers_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: customers customers_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."customers"
    ADD CONSTRAINT "customers_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: inventory_levels inventory_levels_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."inventory_levels"
    ADD CONSTRAINT "inventory_levels_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE CASCADE;


--
-- Name: inventory_levels inventory_levels_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."inventory_levels"
    ADD CONSTRAINT "inventory_levels_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE CASCADE;


--
-- Name: inventory_levels inventory_levels_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."inventory_levels"
    ADD CONSTRAINT "inventory_levels_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: invite_codes invite_codes_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."invite_codes"
    ADD CONSTRAINT "invite_codes_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");


--
-- Name: invite_codes invite_codes_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."invite_codes"
    ADD CONSTRAINT "invite_codes_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: maintenance_request_attachments maintenance_request_attachments_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_attachments"
    ADD CONSTRAINT "maintenance_request_attachments_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: maintenance_request_attachments maintenance_request_attachments_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_attachments"
    ADD CONSTRAINT "maintenance_request_attachments_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."maintenance_requests"("id") ON DELETE CASCADE;


--
-- Name: maintenance_request_attachments maintenance_request_attachments_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_attachments"
    ADD CONSTRAINT "maintenance_request_attachments_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: maintenance_request_events maintenance_request_events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_events"
    ADD CONSTRAINT "maintenance_request_events_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: maintenance_request_events maintenance_request_events_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_events"
    ADD CONSTRAINT "maintenance_request_events_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."maintenance_requests"("id") ON DELETE CASCADE;


--
-- Name: maintenance_request_events maintenance_request_events_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_request_events"
    ADD CONSTRAINT "maintenance_request_events_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: maintenance_requests maintenance_requests_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_assigned_to_fkey" FOREIGN KEY ("assigned_to") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: maintenance_requests maintenance_requests_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");


--
-- Name: maintenance_requests maintenance_requests_service_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_service_branch_id_fkey" FOREIGN KEY ("service_branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;


--
-- Name: maintenance_requests maintenance_requests_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: maintenance_requests maintenance_requests_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_updated_by_fkey" FOREIGN KEY ("updated_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: maintenance_requests maintenance_requests_warranty_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_warranty_id_fkey" FOREIGN KEY ("warranty_id") REFERENCES "public"."warranties"("id") ON DELETE CASCADE;


--
-- Name: maintenance_requests maintenance_requests_warranty_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."maintenance_requests"
    ADD CONSTRAINT "maintenance_requests_warranty_store_fk" FOREIGN KEY ("warranty_id", "store_id") REFERENCES "public"."warranties"("id", "store_id") ON UPDATE RESTRICT ON DELETE CASCADE;


--
-- Name: notification_preferences notification_preferences_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: notification_preferences notification_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notification_preferences"
    ADD CONSTRAINT "notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: notifications notifications_request_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_request_id_fkey" FOREIGN KEY ("request_id") REFERENCES "public"."maintenance_requests"("id") ON DELETE CASCADE;


--
-- Name: notifications notifications_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: notifications notifications_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: products products_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");


--
-- Name: products products_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."products"
    ADD CONSTRAINT "products_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: purchase_order_lines purchase_order_lines_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE RESTRICT;


--
-- Name: purchase_order_lines purchase_order_lines_purchase_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_purchase_order_id_fkey" FOREIGN KEY ("purchase_order_id") REFERENCES "public"."purchase_orders"("id") ON DELETE CASCADE;


--
-- Name: purchase_order_lines purchase_order_lines_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_order_lines"
    ADD CONSTRAINT "purchase_order_lines_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: purchase_orders purchase_orders_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE RESTRICT;


--
-- Name: purchase_orders purchase_orders_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: purchase_orders purchase_orders_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: purchase_orders purchase_orders_supplier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."purchase_orders"
    ADD CONSTRAINT "purchase_orders_supplier_id_fkey" FOREIGN KEY ("supplier_id") REFERENCES "public"."suppliers"("id") ON DELETE RESTRICT;


--
-- Name: register_sessions register_sessions_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."register_sessions"
    ADD CONSTRAINT "register_sessions_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE RESTRICT;


--
-- Name: register_sessions register_sessions_closed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."register_sessions"
    ADD CONSTRAINT "register_sessions_closed_by_fkey" FOREIGN KEY ("closed_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: register_sessions register_sessions_opened_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."register_sessions"
    ADD CONSTRAINT "register_sessions_opened_by_fkey" FOREIGN KEY ("opened_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: register_sessions register_sessions_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."register_sessions"
    ADD CONSTRAINT "register_sessions_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: sale_lines sale_lines_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_lines"
    ADD CONSTRAINT "sale_lines_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE RESTRICT;


--
-- Name: sale_lines sale_lines_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_lines"
    ADD CONSTRAINT "sale_lines_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;


--
-- Name: sale_lines sale_lines_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_lines"
    ADD CONSTRAINT "sale_lines_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: sale_payments sale_payments_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE CASCADE;


--
-- Name: sale_payments sale_payments_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_payments"
    ADD CONSTRAINT "sale_payments_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: sale_return_lines sale_return_lines_return_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_return_lines"
    ADD CONSTRAINT "sale_return_lines_return_id_fkey" FOREIGN KEY ("return_id") REFERENCES "public"."sale_returns"("id") ON DELETE CASCADE;


--
-- Name: sale_return_lines sale_return_lines_sale_line_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_return_lines"
    ADD CONSTRAINT "sale_return_lines_sale_line_id_fkey" FOREIGN KEY ("sale_line_id") REFERENCES "public"."sale_lines"("id") ON DELETE RESTRICT;


--
-- Name: sale_returns sale_returns_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_returns"
    ADD CONSTRAINT "sale_returns_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: sale_returns sale_returns_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_returns"
    ADD CONSTRAINT "sale_returns_sale_id_fkey" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE RESTRICT;


--
-- Name: sale_returns sale_returns_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sale_returns"
    ADD CONSTRAINT "sale_returns_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: sales sales_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE RESTRICT;


--
-- Name: sales sales_cashier_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_cashier_id_fkey" FOREIGN KEY ("cashier_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: sales sales_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE SET NULL;


--
-- Name: sales sales_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."sales"
    ADD CONSTRAINT "sales_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: stock_movements stock_movements_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE RESTRICT;


--
-- Name: stock_movements stock_movements_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: stock_movements stock_movements_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE RESTRICT;


--
-- Name: stock_movements stock_movements_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stock_movements"
    ADD CONSTRAINT "stock_movements_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_api_keys store_api_keys_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_api_keys"
    ADD CONSTRAINT "store_api_keys_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: store_api_keys store_api_keys_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_api_keys"
    ADD CONSTRAINT "store_api_keys_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_entitlements store_entitlements_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");


--
-- Name: store_entitlements store_entitlements_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_entitlements store_entitlements_superseded_by_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_superseded_by_fk" FOREIGN KEY ("superseded_by") REFERENCES "public"."store_entitlements"("id") ON DELETE SET NULL;


--
-- Name: store_entitlements store_entitlements_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_entitlements"
    ADD CONSTRAINT "store_entitlements_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: store_members store_members_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_members"
    ADD CONSTRAINT "store_members_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: store_members store_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_members"
    ADD CONSTRAINT "store_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;


--
-- Name: store_product_catalog store_product_catalog_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_product_catalog"
    ADD CONSTRAINT "store_product_catalog_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");


--
-- Name: store_webhooks store_webhooks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_webhooks"
    ADD CONSTRAINT "store_webhooks_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id") ON DELETE SET NULL;


--
-- Name: store_webhooks store_webhooks_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."store_webhooks"
    ADD CONSTRAINT "store_webhooks_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: stores stores_owner_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."stores"
    ADD CONSTRAINT "stores_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "auth"."users"("id");


--
-- Name: subscription_requests subscription_requests_requested_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscription_requests"
    ADD CONSTRAINT "subscription_requests_requested_by_fkey" FOREIGN KEY ("requested_by") REFERENCES "auth"."users"("id");


--
-- Name: subscription_requests subscription_requests_requested_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscription_requests"
    ADD CONSTRAINT "subscription_requests_requested_plan_id_fkey" FOREIGN KEY ("requested_plan_id") REFERENCES "public"."plans"("id");


--
-- Name: subscription_requests subscription_requests_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscription_requests"
    ADD CONSTRAINT "subscription_requests_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_current_store_entitlement_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_current_store_entitlement_fk" FOREIGN KEY ("store_id", "store_entitlement_id") REFERENCES "public"."store_entitlements"("store_id", "id");


--
-- Name: subscriptions subscriptions_plan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_plan_id_fkey" FOREIGN KEY ("plan_id") REFERENCES "public"."plans"("id");


--
-- Name: subscriptions subscriptions_store_entitlement_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_store_entitlement_fk" FOREIGN KEY ("store_id", "billing_provider", "original_transaction_id", "store_environment") REFERENCES "public"."store_entitlements"("store_id", "platform", "original_transaction_id", "environment") DEFERRABLE INITIALLY DEFERRED;


--
-- Name: subscriptions subscriptions_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."subscriptions"
    ADD CONSTRAINT "subscriptions_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: suppliers suppliers_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."suppliers"
    ADD CONSTRAINT "suppliers_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: warranties warranties_branch_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_branch_id_fkey" FOREIGN KEY ("branch_id") REFERENCES "public"."branches"("id") ON DELETE SET NULL;


--
-- Name: warranties warranties_branch_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_branch_store_fk" FOREIGN KEY ("branch_id", "store_id") REFERENCES "public"."branches"("id", "store_id") ON UPDATE RESTRICT ON DELETE SET NULL ("branch_id");


--
-- Name: warranties warranties_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "auth"."users"("id");


--
-- Name: warranties warranties_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "public"."customers"("id") ON DELETE RESTRICT;


--
-- Name: warranties warranties_customer_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_customer_store_fk" FOREIGN KEY ("customer_id", "store_id") REFERENCES "public"."customers"("id", "store_id") ON UPDATE RESTRICT ON DELETE RESTRICT;


--
-- Name: warranties warranties_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON DELETE SET NULL;


--
-- Name: warranties warranties_product_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_product_store_fk" FOREIGN KEY ("product_id", "store_id") REFERENCES "public"."products"("id", "store_id") ON UPDATE RESTRICT ON DELETE SET NULL ("product_id");


--
-- Name: warranties warranties_sale_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_sale_fk" FOREIGN KEY ("sale_id") REFERENCES "public"."sales"("id") ON DELETE SET NULL;


--
-- Name: warranties warranties_sale_line_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_sale_line_fk" FOREIGN KEY ("sale_line_id") REFERENCES "public"."sale_lines"("id") ON DELETE SET NULL;


--
-- Name: warranties warranties_sale_line_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_sale_line_store_fk" FOREIGN KEY ("sale_line_id", "store_id") REFERENCES "public"."sale_lines"("id", "store_id") ON UPDATE RESTRICT ON DELETE SET NULL ("sale_line_id");


--
-- Name: warranties warranties_sale_store_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_sale_store_fk" FOREIGN KEY ("sale_id", "store_id") REFERENCES "public"."sales"("id", "store_id") ON UPDATE RESTRICT ON DELETE SET NULL ("sale_id");


--
-- Name: warranties warranties_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."warranties"
    ADD CONSTRAINT "warranties_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: webhook_deliveries webhook_deliveries_store_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."webhook_deliveries"
    ADD CONSTRAINT "webhook_deliveries_store_id_fkey" FOREIGN KEY ("store_id") REFERENCES "public"."stores"("id") ON DELETE CASCADE;


--
-- Name: webhook_deliveries webhook_deliveries_webhook_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "public"."webhook_deliveries"
    ADD CONSTRAINT "webhook_deliveries_webhook_id_fkey" FOREIGN KEY ("webhook_id") REFERENCES "public"."store_webhooks"("id") ON DELETE CASCADE;


--
-- Name: activation_codes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."activation_codes" ENABLE ROW LEVEL SECURITY;

--
-- Name: ai_claim_reviews; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."ai_claim_reviews" ENABLE ROW LEVEL SECURITY;

--
-- Name: ai_claim_reviews ai_claim_reviews_select_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ai_claim_reviews_select_managers" ON "public"."ai_claim_reviews" FOR SELECT TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: ai_import_jobs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."ai_import_jobs" ENABLE ROW LEVEL SECURITY;

--
-- Name: ai_import_jobs ai_import_jobs_select_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "ai_import_jobs_select_managers" ON "public"."ai_import_jobs" FOR SELECT TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: api_request_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."api_request_logs" ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."audit_logs" ENABLE ROW LEVEL SECURITY;

--
-- Name: audit_logs audit_logs_select_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "audit_logs_select_managers" ON "public"."audit_logs" FOR SELECT TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: branches; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."branches" ENABLE ROW LEVEL SECURITY;

--
-- Name: branches branches_delete_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "branches_delete_managers" ON "public"."branches" FOR DELETE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: branches branches_insert_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "branches_insert_managers" ON "public"."branches" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: branches branches_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "branches_select_members" ON "public"."branches" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: branches branches_update_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "branches_update_managers" ON "public"."branches" FOR UPDATE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"])) WITH CHECK ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: customers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."customers" ENABLE ROW LEVEL SECURITY;

--
-- Name: customers customers_delete_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "customers_delete_managers" ON "public"."customers" FOR DELETE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: customers customers_insert_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "customers_insert_members" ON "public"."customers" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_store_member"("store_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid"))));


--
-- Name: customers customers_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "customers_select_members" ON "public"."customers" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: customers customers_update_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "customers_update_members" ON "public"."customers" FOR UPDATE TO "authenticated" USING ("public"."is_store_member"("store_id")) WITH CHECK ("public"."is_store_member"("store_id"));


--
-- Name: inventory_levels; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."inventory_levels" ENABLE ROW LEVEL SECURITY;

--
-- Name: inventory_levels inventory_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "inventory_select_members" ON "public"."inventory_levels" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: invite_codes; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."invite_codes" ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance_request_attachments maintenance_attachments_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "maintenance_attachments_select_members" ON "public"."maintenance_request_attachments" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: maintenance_request_events maintenance_events_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "maintenance_events_select_members" ON "public"."maintenance_request_events" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: maintenance_requests maintenance_insert_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "maintenance_insert_members" ON "public"."maintenance_requests" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_store_member"("store_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid"))));


--
-- Name: maintenance_request_attachments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."maintenance_request_attachments" ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance_request_events; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."maintenance_request_events" ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance_requests; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."maintenance_requests" ENABLE ROW LEVEL SECURITY;

--
-- Name: maintenance_requests maintenance_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "maintenance_select_members" ON "public"."maintenance_requests" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: stock_movements movements_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "movements_select_members" ON "public"."stock_movements" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: notification_preferences; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."notification_preferences" ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_preferences notification_preferences_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "notification_preferences_own" ON "public"."notification_preferences" TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND "public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text", 'staff'::"text"]))) WITH CHECK ((("user_id" = "auth"."uid"()) AND "public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text", 'staff'::"text"])));


--
-- Name: notifications; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;

--
-- Name: notifications notifications_select_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "notifications_select_own" ON "public"."notifications" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) AND "public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text", 'staff'::"text"])));


--
-- Name: notifications notifications_update_own; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "notifications_update_own" ON "public"."notifications" FOR UPDATE TO "authenticated" USING (("user_id" = "auth"."uid"())) WITH CHECK (("user_id" = "auth"."uid"()));


--
-- Name: plans; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."plans" ENABLE ROW LEVEL SECURITY;

--
-- Name: plans plans_select_authenticated; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "plans_select_authenticated" ON "public"."plans" FOR SELECT TO "authenticated" USING ("is_active");


--
-- Name: products; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."products" ENABLE ROW LEVEL SECURITY;

--
-- Name: products products_delete_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "products_delete_managers" ON "public"."products" FOR DELETE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: products products_insert_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "products_insert_managers" ON "public"."products" FOR INSERT TO "authenticated" WITH CHECK (("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]) AND ("created_by" = ( SELECT "auth"."uid"() AS "uid"))));


--
-- Name: products products_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "products_select_members" ON "public"."products" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: products products_update_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "products_update_managers" ON "public"."products" FOR UPDATE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"])) WITH CHECK ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_select_team; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "profiles_select_team" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((("id" = ( SELECT "auth"."uid"() AS "uid")) OR "public"."shares_store"("id")));


--
-- Name: profiles profiles_update_self; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "profiles_update_self" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("id" = ( SELECT "auth"."uid"() AS "uid"))) WITH CHECK (("id" = ( SELECT "auth"."uid"() AS "uid")));


--
-- Name: purchase_order_lines purchase_lines_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "purchase_lines_select_members" ON "public"."purchase_order_lines" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: purchase_order_lines; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."purchase_order_lines" ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_orders; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."purchase_orders" ENABLE ROW LEVEL SECURITY;

--
-- Name: purchase_orders purchase_orders_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "purchase_orders_select_members" ON "public"."purchase_orders" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: register_sessions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."register_sessions" ENABLE ROW LEVEL SECURITY;

--
-- Name: register_sessions registers_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "registers_select_members" ON "public"."register_sessions" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: sale_lines; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sale_lines" ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_lines sale_lines_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sale_lines_select_members" ON "public"."sale_lines" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: sale_payments; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sale_payments" ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_payments sale_payments_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sale_payments_select_members" ON "public"."sale_payments" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: sale_return_lines; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sale_return_lines" ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_return_lines sale_return_lines_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sale_return_lines_select_members" ON "public"."sale_return_lines" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."sale_returns" "returns"
  WHERE (("returns"."id" = "sale_return_lines"."return_id") AND "public"."is_store_member"("returns"."store_id")))));


--
-- Name: sale_returns; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sale_returns" ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_returns sale_returns_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sale_returns_select_members" ON "public"."sale_returns" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: sales; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."sales" ENABLE ROW LEVEL SECURITY;

--
-- Name: sales sales_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "sales_select_members" ON "public"."sales" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: stock_movements; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."stock_movements" ENABLE ROW LEVEL SECURITY;

--
-- Name: store_api_keys; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."store_api_keys" ENABLE ROW LEVEL SECURITY;

--
-- Name: store_entitlements; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."store_entitlements" ENABLE ROW LEVEL SECURITY;

--
-- Name: store_entitlements store_entitlements_read_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "store_entitlements_read_members" ON "public"."store_entitlements" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: store_members; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."store_members" ENABLE ROW LEVEL SECURITY;

--
-- Name: store_members store_members_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "store_members_select_members" ON "public"."store_members" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: store_product_catalog; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."store_product_catalog" ENABLE ROW LEVEL SECURITY;

--
-- Name: store_product_catalog store_product_catalog_read; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "store_product_catalog_read" ON "public"."store_product_catalog" FOR SELECT TO "authenticated" USING ("is_active");


--
-- Name: store_webhooks; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."store_webhooks" ENABLE ROW LEVEL SECURITY;

--
-- Name: stores; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."stores" ENABLE ROW LEVEL SECURITY;

--
-- Name: stores stores_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "stores_select_members" ON "public"."stores" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("id"));


--
-- Name: stores stores_update_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "stores_update_managers" ON "public"."stores" FOR UPDATE TO "authenticated" USING ("public"."has_store_role"("id", ARRAY['owner'::"text", 'manager'::"text"])) WITH CHECK ("public"."has_store_role"("id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: subscription_requests; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."subscription_requests" ENABLE ROW LEVEL SECURITY;

--
-- Name: subscription_requests subscription_requests_select_owner; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "subscription_requests_select_owner" ON "public"."subscription_requests" FOR SELECT TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text"]));


--
-- Name: subscriptions; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."subscriptions" ENABLE ROW LEVEL SECURITY;

--
-- Name: subscriptions subscriptions_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "subscriptions_select_members" ON "public"."subscriptions" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: suppliers; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."suppliers" ENABLE ROW LEVEL SECURITY;

--
-- Name: suppliers suppliers_delete_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "suppliers_delete_managers" ON "public"."suppliers" FOR DELETE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: suppliers suppliers_insert_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "suppliers_insert_managers" ON "public"."suppliers" FOR INSERT TO "authenticated" WITH CHECK ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: suppliers suppliers_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "suppliers_select_members" ON "public"."suppliers" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: suppliers suppliers_update_managers; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "suppliers_update_managers" ON "public"."suppliers" FOR UPDATE TO "authenticated" USING ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"])) WITH CHECK ("public"."has_store_role"("store_id", ARRAY['owner'::"text", 'manager'::"text"]));


--
-- Name: warranties; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."warranties" ENABLE ROW LEVEL SECURITY;

--
-- Name: warranties warranties_insert_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "warranties_insert_members" ON "public"."warranties" FOR INSERT TO "authenticated" WITH CHECK (("public"."is_store_member"("store_id") AND ("created_by" = ( SELECT "auth"."uid"() AS "uid"))));


--
-- Name: warranties warranties_select_members; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY "warranties_select_members" ON "public"."warranties" FOR SELECT TO "authenticated" USING ("public"."is_store_member"("store_id"));


--
-- Name: webhook_deliveries; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE "public"."webhook_deliveries" ENABLE ROW LEVEL SECURITY;

--
-- Name: SCHEMA "public"; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";


--
-- Name: FUNCTION "claim_store_sandbox_access"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "external_original_transaction_id" "text", "allow_new_grant" boolean); Type: ACL; Schema: private; Owner: postgres
--

REVOKE ALL ON FUNCTION "private"."claim_store_sandbox_access"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "external_original_transaction_id" "text", "allow_new_grant" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "private"."claim_store_sandbox_access"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "external_original_transaction_id" "text", "allow_new_grant" boolean) TO "service_role";


--
-- Name: FUNCTION "create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text"); Type: ACL; Schema: private; Owner: postgres
--

REVOKE ALL ON FUNCTION "private"."create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "private"."create_sale_unlocked"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") TO "service_role";


--
-- Name: FUNCTION "lock_sale_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "sale_lines_input" "jsonb"); Type: ACL; Schema: private; Owner: postgres
--

REVOKE ALL ON FUNCTION "private"."lock_sale_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "sale_lines_input" "jsonb") FROM PUBLIC;


--
-- Name: FUNCTION "adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."adjust_inventory"("target_store_id" "uuid", "target_branch_id" "uuid", "target_product_id" "uuid", "new_quantity" numeric, "target_unit_cost" numeric, "target_note" "text") TO "authenticated";


--
-- Name: TABLE "subscriptions"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."subscriptions" TO "service_role";
GRANT SELECT ON TABLE "public"."subscriptions" TO "authenticated";


--
-- Name: FUNCTION "apply_verified_store_entitlement"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."apply_verified_store_entitlement"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean) FROM PUBLIC;


--
-- Name: FUNCTION "apply_verified_store_entitlement_with_receipt"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean, "raw_purchase_token" "text", "purchase_token_hash" "text", "linked_purchase_token_hash" "text", "expected_current_purchase_token_hash" "text", "allow_orphan_lineage_recovery" boolean, "orphan_old_account_id" "uuid", "orphan_old_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."apply_verified_store_entitlement_with_receipt"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean, "raw_purchase_token" "text", "purchase_token_hash" "text", "linked_purchase_token_hash" "text", "expected_current_purchase_token_hash" "text", "allow_orphan_lineage_recovery" boolean, "orphan_old_account_id" "uuid", "orphan_old_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."apply_verified_store_entitlement_with_receipt"("target_store_id" "uuid", "target_user_id" "uuid", "billing_platform" "text", "billed_product_id" "text", "billed_base_plan_id" "text", "external_transaction_id" "text", "external_original_transaction_id" "text", "entitlement_status" "text", "store_environment" "text", "entitlement_period_start" timestamp with time zone, "entitlement_period_end" timestamp with time zone, "entitlement_auto_renews" boolean, "raw_purchase_token" "text", "purchase_token_hash" "text", "linked_purchase_token_hash" "text", "expected_current_purchase_token_hash" "text", "allow_orphan_lineage_recovery" boolean, "orphan_old_account_id" "uuid", "orphan_old_store_id" "uuid") TO "service_role";


--
-- Name: FUNCTION "audit_business_change"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."audit_business_change"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."audit_business_change"() TO "service_role";


--
-- Name: FUNCTION "authenticate_store_api_key"("presented_key" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."authenticate_store_api_key"("presented_key" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."authenticate_store_api_key"("presented_key" "text") TO "service_role";


--
-- Name: FUNCTION "claim_ai_claim_review_job"("target_store_id" "uuid", "target_request_id" "uuid", "target_user_id" "uuid", "target_model" "text", "target_include_attachments" boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."claim_ai_claim_review_job"("target_store_id" "uuid", "target_request_id" "uuid", "target_user_id" "uuid", "target_model" "text", "target_include_attachments" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_ai_claim_review_job"("target_store_id" "uuid", "target_request_id" "uuid", "target_user_id" "uuid", "target_model" "text", "target_include_attachments" boolean) TO "service_role";


--
-- Name: FUNCTION "claim_ai_import_job"("target_store_id" "uuid", "target_user_id" "uuid", "target_filename" "text", "target_mime_type" "text", "target_size_bytes" bigint, "target_provider" "text", "target_pricing_tier" "text", "target_model" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."claim_ai_import_job"("target_store_id" "uuid", "target_user_id" "uuid", "target_filename" "text", "target_mime_type" "text", "target_size_bytes" bigint, "target_provider" "text", "target_pricing_tier" "text", "target_model" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_ai_import_job"("target_store_id" "uuid", "target_user_id" "uuid", "target_filename" "text", "target_mime_type" "text", "target_size_bytes" bigint, "target_provider" "text", "target_pricing_tier" "text", "target_model" "text") TO "service_role";


--
-- Name: FUNCTION "claim_store_entitlement_refreshes"("requested_limit" integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."claim_store_entitlement_refreshes"("requested_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_store_entitlement_refreshes"("requested_limit" integer) TO "service_role";


--
-- Name: FUNCTION "claim_webhook_deliveries"("requested_limit" integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."claim_webhook_deliveries"("requested_limit" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."claim_webhook_deliveries"("requested_limit" integer) TO "service_role";


--
-- Name: FUNCTION "close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."close_register"("target_session_id" "uuid", "target_closing_cash" numeric, "target_notes" "text") TO "authenticated";


--
-- Name: FUNCTION "create_claim_notifications"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_claim_notifications"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_claim_notifications"() TO "service_role";


--
-- Name: FUNCTION "create_default_store_branch"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_default_store_branch"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_default_store_branch"() TO "service_role";


--
-- Name: FUNCTION "create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_priority" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_priority" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_priority" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_maintenance_request"("target_store_id" "uuid", "target_warranty_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_priority" "text") TO "authenticated";


--
-- Name: FUNCTION "create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_purchase_order"("target_store_id" "uuid", "target_branch_id" "uuid", "target_supplier_id" "uuid", "target_expected_at" timestamp with time zone, "target_notes" "text", "purchase_lines_input" "jsonb") TO "authenticated";


--
-- Name: FUNCTION "create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_sale"("target_store_id" "uuid", "target_branch_id" "uuid", "target_customer_id" "uuid", "target_customer_name" "text", "target_customer_phone" "text", "sale_lines_input" "jsonb", "sale_payments_input" "jsonb", "order_discount" numeric, "target_notes" "text") TO "authenticated";


--
-- Name: FUNCTION "create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[]) TO "service_role";
GRANT ALL ON FUNCTION "public"."create_store_api_key"("target_store_id" "uuid", "key_name" "text", "requested_scopes" "text"[]) TO "authenticated";


--
-- Name: FUNCTION "create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer) TO "service_role";
GRANT ALL ON FUNCTION "public"."create_store_invite"("target_store_id" "uuid", "target_role" "text", "allowed_uses" integer) TO "authenticated";


--
-- Name: FUNCTION "create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]) TO "service_role";
GRANT ALL ON FUNCTION "public"."create_store_webhook"("target_store_id" "uuid", "target_url" "text", "target_events" "text"[]) TO "authenticated";


--
-- Name: FUNCTION "create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text") TO "authenticated";


--
-- Name: FUNCTION "create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."create_store_with_trial"("store_name" "text", "store_phone" "text", "store_city" "text", "store_country_code" "text", "device_claim" "text") TO "authenticated";


--
-- Name: FUNCTION "current_warranty_usage"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."current_warranty_usage"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."current_warranty_usage"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."current_warranty_usage"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "delete_current_account"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."delete_current_account"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."delete_current_account"() TO "service_role";
GRANT ALL ON FUNCTION "public"."delete_current_account"() TO "authenticated";


--
-- Name: FUNCTION "enforce_authenticated_claim_write"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_authenticated_claim_write"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_authenticated_claim_write"() TO "service_role";


--
-- Name: FUNCTION "enforce_branch_entitlement"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_branch_entitlement"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_branch_entitlement"() TO "service_role";


--
-- Name: FUNCTION "enforce_product_branding_entitlement"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_product_branding_entitlement"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_product_branding_entitlement"() TO "service_role";


--
-- Name: FUNCTION "enforce_store_api_key_limit"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_store_api_key_limit"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_store_api_key_limit"() TO "service_role";


--
-- Name: FUNCTION "enforce_store_branding_entitlement"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_store_branding_entitlement"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_store_branding_entitlement"() TO "service_role";


--
-- Name: FUNCTION "enforce_store_webhook_limit"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_store_webhook_limit"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_store_webhook_limit"() TO "service_role";


--
-- Name: FUNCTION "enforce_subscription_member_limit"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_subscription_member_limit"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_subscription_member_limit"() TO "service_role";


--
-- Name: FUNCTION "enforce_usable_subscription_for_core_write"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_usable_subscription_for_core_write"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_usable_subscription_for_core_write"() TO "service_role";


--
-- Name: FUNCTION "enforce_warranty_entitlement"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enforce_warranty_entitlement"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enforce_warranty_entitlement"() TO "service_role";


--
-- Name: FUNCTION "enqueue_overdue_claim_notifications"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."enqueue_overdue_claim_notifications"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."enqueue_overdue_claim_notifications"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."enqueue_overdue_claim_notifications"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."find_warranty_by_serial"("target_store_id" "uuid", "target_serial" "text") TO "authenticated";


--
-- Name: FUNCTION "finish_api_request"("target_log_id" bigint, "target_status" integer); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."finish_api_request"("target_log_id" bigint, "target_status" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."finish_api_request"("target_log_id" bigint, "target_status" integer) TO "service_role";


--
-- Name: FUNCTION "get_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."get_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."get_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text") TO "service_role";


--
-- Name: FUNCTION "guard_maintenance_attachment"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."guard_maintenance_attachment"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."guard_maintenance_attachment"() TO "service_role";


--
-- Name: FUNCTION "guard_maintenance_request"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."guard_maintenance_request"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."guard_maintenance_request"() TO "service_role";


--
-- Name: FUNCTION "handle_new_user"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."handle_new_user"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";


--
-- Name: FUNCTION "has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]) TO "service_role";
GRANT ALL ON FUNCTION "public"."has_store_role"("target_store_id" "uuid", "allowed_roles" "text"[]) TO "authenticated";


--
-- Name: FUNCTION "is_store_member"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."is_store_member"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."is_store_member"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."is_store_member"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "join_store_by_code"("invitation_code" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."join_store_by_code"("invitation_code" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."join_store_by_code"("invitation_code" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."join_store_by_code"("invitation_code" "text") TO "authenticated";


--
-- Name: FUNCTION "list_store_api_keys"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."list_store_api_keys"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_store_api_keys"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."list_store_api_keys"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "list_store_webhooks"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."list_store_webhooks"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."list_store_webhooks"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."list_store_webhooks"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."open_register"("target_store_id" "uuid", "target_branch_id" "uuid", "target_opening_cash" numeric, "target_notes" "text") TO "authenticated";


--
-- Name: FUNCTION "queue_claim_webhooks"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."queue_claim_webhooks"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."queue_claim_webhooks"() TO "service_role";


--
-- Name: FUNCTION "receive_purchase_order"("target_purchase_order_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."receive_purchase_order"("target_purchase_order_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."receive_purchase_order"("target_purchase_order_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."receive_purchase_order"("target_purchase_order_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "record_maintenance_request_event"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."record_maintenance_request_event"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."record_maintenance_request_event"() TO "service_role";


--
-- Name: FUNCTION "redeem_subscription_code"("target_store_id" "uuid", "activation_code" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."redeem_subscription_code"("target_store_id" "uuid", "activation_code" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."redeem_subscription_code"("target_store_id" "uuid", "activation_code" "text") TO "service_role";


--
-- Name: FUNCTION "register_trial_device"("target_store_id" "uuid", "device_claim" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."register_trial_device"("target_store_id" "uuid", "device_claim" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."register_trial_device"("target_store_id" "uuid", "device_claim" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."register_trial_device"("target_store_id" "uuid", "device_claim" "text") TO "authenticated";


--
-- Name: FUNCTION "release_store_entitlement_refresh"("target_entitlement_id" "uuid", "refresh_succeeded" boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."release_store_entitlement_refresh"("target_entitlement_id" "uuid", "refresh_succeeded" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."release_store_entitlement_refresh"("target_entitlement_id" "uuid", "refresh_succeeded" boolean) TO "service_role";


--
-- Name: FUNCTION "reserve_api_request"("target_key_id" "uuid", "target_store_id" "uuid", "target_method" "text", "target_path" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."reserve_api_request"("target_key_id" "uuid", "target_store_id" "uuid", "target_method" "text", "target_path" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reserve_api_request"("target_key_id" "uuid", "target_store_id" "uuid", "target_method" "text", "target_path" "text") TO "service_role";


--
-- Name: FUNCTION "reserve_store_purchase_verification"("target_store_id" "uuid", "target_user_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."reserve_store_purchase_verification"("target_store_id" "uuid", "target_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."reserve_store_purchase_verification"("target_store_id" "uuid", "target_user_id" "uuid") TO "service_role";


--
-- Name: FUNCTION "resolve_google_purchase_token_binding"("raw_purchase_token" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."resolve_google_purchase_token_binding"("raw_purchase_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."resolve_google_purchase_token_binding"("raw_purchase_token" "text") TO "service_role";


--
-- Name: FUNCTION "return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."return_sale"("target_store_id" "uuid", "target_sale_id" "uuid", "returned_lines" "jsonb", "refund_method" "text", "return_reason" "text") TO "authenticated";


--
-- Name: FUNCTION "revoke_store_api_key"("target_key_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."revoke_store_api_key"("target_key_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."revoke_store_api_key"("target_key_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."revoke_store_api_key"("target_key_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "save_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text", "raw_purchase_token" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."save_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text", "raw_purchase_token" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."save_store_receipt_secret"("billing_platform" "text", "external_original_transaction_id" "text", "raw_purchase_token" "text") TO "service_role";


--
-- Name: FUNCTION "seed_inventory_for_branch"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."seed_inventory_for_branch"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seed_inventory_for_branch"() TO "service_role";


--
-- Name: FUNCTION "seed_inventory_for_product"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."seed_inventory_for_product"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."seed_inventory_for_product"() TO "service_role";


--
-- Name: FUNCTION "set_store_financial_defaults"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."set_store_financial_defaults"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_store_financial_defaults"() TO "service_role";


--
-- Name: FUNCTION "set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean) TO "service_role";
GRANT ALL ON FUNCTION "public"."set_store_webhook_active"("target_webhook_id" "uuid", "target_active" boolean) TO "authenticated";


--
-- Name: FUNCTION "set_updated_at"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."set_updated_at"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";


--
-- Name: FUNCTION "set_warranty_invoice_number"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."set_warranty_invoice_number"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."set_warranty_invoice_number"() TO "service_role";


--
-- Name: FUNCTION "shares_store"("target_user_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."shares_store"("target_user_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."shares_store"("target_user_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."shares_store"("target_user_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "store_plan_allows"("target_store_id" "uuid", "entitlement_name" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."store_plan_allows"("target_store_id" "uuid", "entitlement_name" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."store_plan_allows"("target_store_id" "uuid", "entitlement_name" "text") TO "service_role";


--
-- Name: FUNCTION "submit_public_warranty_claim"("target_warranty_id" "uuid", "submission_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_customer_notes" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."submit_public_warranty_claim"("target_warranty_id" "uuid", "submission_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_customer_notes" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."submit_public_warranty_claim"("target_warranty_id" "uuid", "submission_id" "uuid", "claim_issue" "text", "claim_category" "text", "claim_customer_notes" "text") TO "service_role";


--
-- Name: FUNCTION "subscription_is_usable"("target_store_id" "uuid"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."subscription_is_usable"("target_store_id" "uuid") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."subscription_is_usable"("target_store_id" "uuid") TO "service_role";
GRANT ALL ON FUNCTION "public"."subscription_is_usable"("target_store_id" "uuid") TO "authenticated";


--
-- Name: FUNCTION "transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."transfer_inventory"("target_store_id" "uuid", "target_product_id" "uuid", "source_branch_id" "uuid", "destination_branch_id" "uuid", "target_quantity" numeric, "target_note" "text") TO "authenticated";


--
-- Name: FUNCTION "trim_branches_to_subscription_limit"(); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."trim_branches_to_subscription_limit"() FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."trim_branches_to_subscription_limit"() TO "service_role";


--
-- Name: FUNCTION "update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb") TO "service_role";
GRANT ALL ON FUNCTION "public"."update_maintenance_request"("target_request_id" "uuid", "expected_version" integer, "patch" "jsonb") TO "authenticated";


--
-- Name: FUNCTION "update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text"); Type: ACL; Schema: public; Owner: postgres
--

REVOKE ALL ON FUNCTION "public"."update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text") TO "service_role";
GRANT ALL ON FUNCTION "public"."update_store_member"("target_store_id" "uuid", "target_user_id" "uuid", "target_role" "text", "target_status" "text") TO "authenticated";


--
-- Name: TABLE "activation_codes"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."activation_codes" TO "service_role";


--
-- Name: TABLE "ai_claim_reviews"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."ai_claim_reviews" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_claim_reviews" TO "authenticated";


--
-- Name: TABLE "ai_import_jobs"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."ai_import_jobs" TO "service_role";
GRANT SELECT ON TABLE "public"."ai_import_jobs" TO "authenticated";


--
-- Name: TABLE "api_request_logs"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."api_request_logs" TO "service_role";


--
-- Name: SEQUENCE "api_request_logs_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."api_request_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."api_request_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."api_request_logs_id_seq" TO "service_role";


--
-- Name: TABLE "audit_logs"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."audit_logs" TO "service_role";
GRANT SELECT ON TABLE "public"."audit_logs" TO "authenticated";


--
-- Name: SEQUENCE "audit_logs_id_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."audit_logs_id_seq" TO "service_role";


--
-- Name: TABLE "branches"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."branches" TO "service_role";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."branches" TO "authenticated";


--
-- Name: TABLE "customers"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."customers" TO "service_role";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."customers" TO "authenticated";


--
-- Name: TABLE "inventory_levels"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."inventory_levels" TO "service_role";
GRANT SELECT ON TABLE "public"."inventory_levels" TO "authenticated";


--
-- Name: TABLE "invite_codes"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."invite_codes" TO "service_role";


--
-- Name: SEQUENCE "maintenance_claim_number_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."maintenance_claim_number_seq" TO "service_role";
GRANT SELECT,USAGE ON SEQUENCE "public"."maintenance_claim_number_seq" TO "authenticated";


--
-- Name: TABLE "maintenance_request_attachments"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."maintenance_request_attachments" TO "service_role";
GRANT SELECT ON TABLE "public"."maintenance_request_attachments" TO "authenticated";


--
-- Name: TABLE "maintenance_request_events"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."maintenance_request_events" TO "service_role";
GRANT SELECT ON TABLE "public"."maintenance_request_events" TO "authenticated";


--
-- Name: TABLE "maintenance_requests"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."maintenance_requests" TO "service_role";
GRANT SELECT,INSERT ON TABLE "public"."maintenance_requests" TO "authenticated";


--
-- Name: TABLE "notification_preferences"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."notification_preferences" TO "service_role";
GRANT SELECT,INSERT,UPDATE ON TABLE "public"."notification_preferences" TO "authenticated";


--
-- Name: TABLE "notifications"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."notifications" TO "service_role";
GRANT SELECT,UPDATE ON TABLE "public"."notifications" TO "authenticated";


--
-- Name: TABLE "plans"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."plans" TO "service_role";
GRANT SELECT ON TABLE "public"."plans" TO "authenticated";


--
-- Name: TABLE "products"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."products" TO "service_role";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."products" TO "authenticated";


--
-- Name: TABLE "profiles"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."profiles" TO "service_role";
GRANT SELECT,UPDATE ON TABLE "public"."profiles" TO "authenticated";


--
-- Name: TABLE "purchase_order_lines"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."purchase_order_lines" TO "service_role";
GRANT SELECT ON TABLE "public"."purchase_order_lines" TO "authenticated";


--
-- Name: TABLE "purchase_orders"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."purchase_orders" TO "service_role";
GRANT SELECT ON TABLE "public"."purchase_orders" TO "authenticated";


--
-- Name: SEQUENCE "purchase_orders_sequence_number_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."purchase_orders_sequence_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."purchase_orders_sequence_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."purchase_orders_sequence_number_seq" TO "service_role";


--
-- Name: TABLE "register_sessions"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."register_sessions" TO "service_role";
GRANT SELECT ON TABLE "public"."register_sessions" TO "authenticated";


--
-- Name: TABLE "sale_lines"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."sale_lines" TO "service_role";
GRANT SELECT ON TABLE "public"."sale_lines" TO "authenticated";


--
-- Name: TABLE "sale_payments"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."sale_payments" TO "service_role";
GRANT SELECT ON TABLE "public"."sale_payments" TO "authenticated";


--
-- Name: TABLE "sale_return_lines"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."sale_return_lines" TO "service_role";
GRANT SELECT ON TABLE "public"."sale_return_lines" TO "authenticated";


--
-- Name: TABLE "sale_returns"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."sale_returns" TO "service_role";
GRANT SELECT ON TABLE "public"."sale_returns" TO "authenticated";


--
-- Name: TABLE "sales"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."sales" TO "service_role";
GRANT SELECT ON TABLE "public"."sales" TO "authenticated";


--
-- Name: SEQUENCE "sales_sequence_number_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."sales_sequence_number_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."sales_sequence_number_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."sales_sequence_number_seq" TO "service_role";


--
-- Name: TABLE "stock_movements"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."stock_movements" TO "service_role";
GRANT SELECT ON TABLE "public"."stock_movements" TO "authenticated";


--
-- Name: TABLE "store_api_keys"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_api_keys" TO "service_role";


--
-- Name: TABLE "store_entitlements"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_entitlements" TO "service_role";
GRANT SELECT ON TABLE "public"."store_entitlements" TO "authenticated";


--
-- Name: TABLE "store_members"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_members" TO "service_role";
GRANT SELECT ON TABLE "public"."store_members" TO "authenticated";


--
-- Name: TABLE "store_member_directory"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_member_directory" TO "service_role";
GRANT SELECT ON TABLE "public"."store_member_directory" TO "authenticated";


--
-- Name: TABLE "store_product_catalog"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_product_catalog" TO "service_role";
GRANT SELECT ON TABLE "public"."store_product_catalog" TO "authenticated";


--
-- Name: TABLE "store_webhooks"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."store_webhooks" TO "service_role";


--
-- Name: TABLE "stores"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."stores" TO "service_role";
GRANT SELECT ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."name"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("name") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."phone"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("phone") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."city"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("city") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."country_code"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("country_code") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."updated_at"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("updated_at") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."currency_code"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("currency_code") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."tax_rate"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("tax_rate") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."prices_include_tax"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("prices_include_tax") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."tax_number"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("tax_number") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."commercial_registration"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("commercial_registration") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."address"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("address") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."invoice_prefix"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("invoice_prefix") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."default_warranty_months"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("default_warranty_months") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."logo_url"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("logo_url") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."brand_color"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("brand_color") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."customer_portal_title"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("customer_portal_title") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."warranty_policy"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("warranty_policy") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: COLUMN "stores"."warranty_exclusions"; Type: ACL; Schema: public; Owner: postgres
--

GRANT UPDATE("warranty_exclusions") ON TABLE "public"."stores" TO "authenticated";


--
-- Name: TABLE "subscription_requests"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."subscription_requests" TO "service_role";
GRANT SELECT ON TABLE "public"."subscription_requests" TO "authenticated";


--
-- Name: TABLE "suppliers"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."suppliers" TO "service_role";
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE "public"."suppliers" TO "authenticated";


--
-- Name: TABLE "warranties"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."warranties" TO "service_role";
GRANT SELECT,INSERT ON TABLE "public"."warranties" TO "authenticated";


--
-- Name: SEQUENCE "warranty_number_seq"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE "public"."warranty_number_seq" TO "service_role";


--
-- Name: TABLE "webhook_deliveries"; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE "public"."webhook_deliveries" TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: supabase_admin
--

ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "supabase_admin" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";


--
-- PostgreSQL database dump complete
--

\unrestrict Hf0IjshAfeh5GTy3LjzAS2aaH6ZZZufnvvVxcH9euoLoR7u4PKBkMAdTtscm94o


--
-- Damanak migrations applied after the latest portable pg_dump snapshot.
-- Docker was unavailable for a fresh pg_dump; these idempotent definitions
-- keep this checked-in bootstrap schema consistent with production.
--

-- Build 25 can always create or recover the caller's owned store. A one-time
-- Starter trial is still granted only when both the account and installation
-- are new. Build 24 keeps using create_store_with_trial unchanged so an older
-- client can never enter a newly created, payment-locked workspace.

create or replace function public.store_requires_initial_payment(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.subscriptions subscription
    where subscription.store_id = target_store_id
      and subscription.plan_id = 'starter'
      and subscription.status = 'canceled'
      and subscription.source = 'trial'
      and subscription.trial_ends_at is null
      and subscription.current_period_start is null
      and subscription.current_period_end is null
      and subscription.billing_provider is null
      and subscription.store_product_id is null
      and subscription.billing_cycle is null
      and subscription.original_transaction_id is null
      and not subscription.auto_renews
      and subscription.last_store_verified_at is null
      and subscription.store_environment is null
      and subscription.store_entitlement_id is null
  )
$$;

comment on function public.store_requires_initial_payment(uuid) is
  'Identifies the non-entitled Build 25 initial-payment placeholder; it does not classify expired historical subscriptions.';

-- The account lock bounds the five-device limit. The device lock makes a
-- simultaneous registration from two accounts deterministic. The fallback
-- ON CONFLICT branch also remains safe while Build 24 is still active because
-- that legacy RPC predates these advisory-lock namespaces.
create or replace function public.register_trial_device(
  target_store_id uuid,
  device_claim text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_account_hash bytea;
  current_device_hash bytea;
  linked_account_hash bytea;
  registered_devices integer;
  inserted_rows integer;
  normalized_claim text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(device_claim, ''))
  );
begin
  if (select auth.uid()) is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;
  if not exists (
    select 1
    from public.store_members member
    join public.stores store on store.id = member.store_id
    where member.store_id = target_store_id
      and member.user_id = (select auth.uid())
      and member.role = 'owner'
      and member.status = 'active'
      and store.owner_id = (select auth.uid())
  ) then
    raise exception 'STORE_OWNER_REQUIRED';
  end if;

  current_account_hash := extensions.digest(
    'damanak:trial-account:v1:' || (select auth.uid())::text,
    'sha256'
  );
  current_device_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-account-lock:v1:' ||
        pg_catalog.encode(current_account_hash, 'hex'),
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-device-lock:v1:' ||
        pg_catalog.encode(current_device_hash, 'hex'),
      0
    )
  );

  insert into private.trial_account_claims(account_hash)
  values (current_account_hash)
  on conflict (account_hash) do update
  set last_seen_at = pg_catalog.now();

  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = current_device_hash
  for update;
  if found then
    if linked_account_hash <> current_account_hash then
      return false;
    end if;
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = current_device_hash;
    return true;
  end if;

  select pg_catalog.count(*)
  into registered_devices
  from private.trial_device_claims claim
  where claim.account_hash = current_account_hash;
  if registered_devices >= 5 then
    return false;
  end if;

  insert into private.trial_device_claims(device_hash, account_hash)
  values (current_device_hash, current_account_hash)
  on conflict (device_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  if inserted_rows = 1 then
    return true;
  end if;

  -- A concurrent legacy Build 24 transaction may have won the unique key
  -- without taking the advisory lock. Re-read its committed owner safely.
  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = current_device_hash;
  if linked_account_hash = current_account_hash then
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = current_device_hash;
    return true;
  end if;
  return false;
end;
$$;

create or replace function public.create_store_with_subscription(
  store_name text,
  store_phone text,
  store_city text,
  store_country_code text,
  device_claim text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor uuid := (select auth.uid());
  created_store_id uuid;
  existing_store_id uuid;
  inserted_rows integer;
  account_claim_hash bytea;
  device_claim_hash bytea;
  linked_account_hash bytea;
  device_already_claimed boolean;
  account_claim_inserted boolean := false;
  device_claim_inserted boolean := false;
  registered_devices integer;
  trial_granted boolean := false;
  normalized_claim text := pg_catalog.lower(
    pg_catalog.btrim(coalesce(device_claim, ''))
  );
begin
  if actor is null then
    raise exception 'AUTH_REQUIRED';
  end if;
  if char_length(pg_catalog.btrim(coalesce(store_name, ''))) < 2 then
    raise exception 'STORE_NAME_REQUIRED';
  end if;
  if coalesce(store_country_code, '') not in (
    'SA', 'AE', 'KW', 'QA', 'BH', 'OM'
  ) then
    raise exception 'COUNTRY_NOT_SUPPORTED';
  end if;
  if normalized_claim !~
    '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
  then
    raise exception 'TRIAL_DEVICE_CLAIM_INVALID';
  end if;

  account_claim_hash := extensions.digest(
    'damanak:trial-account:v1:' || actor::text,
    'sha256'
  );
  device_claim_hash := extensions.digest(
    'damanak:trial-device:v1:' || normalized_claim,
    'sha256'
  );

  -- Every caller follows account then device order. Besides protecting the
  -- eligibility decision, the account lock is the idempotency boundary for
  -- two simultaneous onboarding requests from the same authenticated user.
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-account-lock:v1:' ||
        pg_catalog.encode(account_claim_hash, 'hex'),
      0
    )
  );
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      'damanak:trial-device-lock:v1:' ||
        pg_catalog.encode(device_claim_hash, 'hex'),
      0
    )
  );

  select store.id
  into existing_store_id
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = actor
   and member.role = 'owner'
   and member.status = 'active'
  where store.owner_id = actor
  order by store.created_at, store.id
  limit 1;
  if existing_store_id is not null then
    insert into private.trial_account_claims(account_hash)
    values (account_claim_hash)
    on conflict (account_hash) do update
    set last_seen_at = pg_catalog.now();

    select claim.account_hash
    into linked_account_hash
    from private.trial_device_claims claim
    where claim.device_hash = device_claim_hash
    for update;
    if found and linked_account_hash = account_claim_hash then
      update private.trial_device_claims
      set last_seen_at = pg_catalog.now()
      where device_hash = device_claim_hash;
    elsif not found then
      select pg_catalog.count(*)
      into registered_devices
      from private.trial_device_claims claim
      where claim.account_hash = account_claim_hash;
      if registered_devices < 5 then
        insert into private.trial_device_claims(device_hash, account_hash)
        values (device_claim_hash, account_claim_hash)
        on conflict (device_hash) do nothing;
        -- A legacy caller may win the device key while ignoring our lock. It
        -- is never overwritten, regardless of which account won the race.
        update private.trial_device_claims
        set last_seen_at = pg_catalog.now()
        where device_hash = device_claim_hash
          and account_hash = account_claim_hash;
      end if;
    end if;
    return existing_store_id;
  end if;

  select claim.account_hash
  into linked_account_hash
  from private.trial_device_claims claim
  where claim.device_hash = device_claim_hash
  for update;
  device_already_claimed := found;

  -- INSERT, not a preceding EXISTS read, decides account eligibility. This
  -- closes the gap with a concurrent Build 24 caller that does not honor the
  -- advisory lock but still contends on the primary key.
  insert into private.trial_account_claims(account_hash)
  values (account_claim_hash)
  on conflict (account_hash) do nothing;
  get diagnostics inserted_rows = row_count;
  account_claim_inserted := inserted_rows = 1;
  if not account_claim_inserted then
    update private.trial_account_claims
    set last_seen_at = pg_catalog.now()
    where account_hash = account_claim_hash;
  end if;

  -- Bind every previously unseen installation to this account (up to the
  -- existing five-device ceiling), even when no trial is granted. Otherwise a
  -- logout followed by a new account on that installation could reopen trial.
  if not device_already_claimed then
    select pg_catalog.count(*)
    into registered_devices
    from private.trial_device_claims claim
    where claim.account_hash = account_claim_hash;
    if registered_devices < 5 then
      insert into private.trial_device_claims(device_hash, account_hash)
      values (device_claim_hash, account_claim_hash)
      on conflict (device_hash) do nothing;
      get diagnostics inserted_rows = row_count;
      device_claim_inserted := inserted_rows = 1;
      if not device_claim_inserted then
        select claim.account_hash
        into linked_account_hash
        from private.trial_device_claims claim
        where claim.device_hash = device_claim_hash;
        if linked_account_hash = account_claim_hash then
          update private.trial_device_claims
          set last_seen_at = pg_catalog.now()
          where device_hash = device_claim_hash;
        end if;
      end if;
    end if;
  elsif linked_account_hash = account_claim_hash then
    update private.trial_device_claims
    set last_seen_at = pg_catalog.now()
    where device_hash = device_claim_hash;
  end if;
  trial_granted := account_claim_inserted and device_claim_inserted;

  -- A concurrent Build 24 call does not take our advisory lock. If it won the
  -- account primary key and committed its store while this call waited, return
  -- that now-visible store instead of creating a second locked workspace.
  select store.id
  into existing_store_id
  from public.stores store
  join public.store_members member
    on member.store_id = store.id
   and member.user_id = actor
   and member.role = 'owner'
   and member.status = 'active'
  where store.owner_id = actor
  order by store.created_at, store.id
  limit 1;
  if existing_store_id is not null then
    return existing_store_id;
  end if;

  insert into public.stores(name, phone, city, country_code, owner_id)
  values (
    pg_catalog.btrim(store_name),
    pg_catalog.btrim(coalesce(store_phone, '')),
    pg_catalog.btrim(coalesce(store_city, '')),
    store_country_code,
    actor
  )
  returning id into created_store_id;

  insert into public.store_members(store_id, user_id, role)
  values (created_store_id, actor, 'owner');

  -- canceled + trial + NULL end dates is the explicit initial-payment state.
  -- It is deliberately unusable and has no StoreKit/Play entitlement row.
  insert into public.subscriptions(
    store_id,
    plan_id,
    status,
    trial_ends_at,
    current_period_start,
    current_period_end,
    source
  ) values (
    created_store_id,
    'starter',
    case when trial_granted then 'trialing' else 'canceled' end,
    case
      when trial_granted then pg_catalog.now() + interval '14 days'
      else null
    end,
    null,
    null,
    'trial'
  );

  insert into public.audit_logs(
    store_id,
    user_id,
    action,
    entity_type,
    entity_id,
    metadata
  ) values (
    created_store_id,
    actor,
    'store_created',
    'store',
    created_store_id,
    pg_catalog.jsonb_build_object(
      'trial_guard', 'account_and_device_v1',
      'trial_granted', trial_granted,
      'initial_payment_required', not trial_granted,
      'subscription_required', not trial_granted
    )
  );

  return created_store_id;
end;
$$;

-- The stores trigger remains DEFERRABLE INITIALLY DEFERRED. Its target now
-- returns quietly for a non-usable subscription. A subscription transition to
-- usable independently creates/reactivates MAIN, including first paid access
-- for a store that started in the initial-payment state.
create or replace function private.ensure_default_store_branch(
  target_store_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  store_row public.stores%rowtype;
  branch_limit integer;
  active_branch_count integer;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(target_store_id::text || ':branches', 0)
  );
  if not public.subscription_is_usable(target_store_id) then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.code = 'MAIN'
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;

  -- Repair an active MAIN code that lost only its main flag. If another
  -- branch is already the active main, preserve that explicit choice and do
  -- not violate branches_one_main_per_store.
  update public.branches branch
  set is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and branch.is_active
    and not branch.is_main
    and not exists (
      select 1
      from public.branches other
      where other.store_id = target_store_id
        and other.is_active
        and other.is_main
    );
  if found then
    return;
  end if;
  if exists (
    select 1
    from public.branches branch
    where branch.store_id = target_store_id
      and branch.is_active
      and branch.is_main
  ) then
    return;
  end if;

  select plan.max_branches
  into branch_limit
  from public.subscriptions subscription
  join public.plans plan on plan.id = subscription.plan_id
  where subscription.store_id = target_store_id;
  select pg_catalog.count(*)
  into active_branch_count
  from public.branches branch
  where branch.store_id = target_store_id
    and branch.is_active;
  if branch_limit is null or active_branch_count >= branch_limit then
    return;
  end if;

  update public.branches branch
  set is_active = true,
      is_main = true,
      updated_at = pg_catalog.now()
  where branch.store_id = target_store_id
    and branch.code = 'MAIN'
    and not branch.is_active;
  if found then
    return;
  end if;

  select *
  into store_row
  from public.stores store
  where store.id = target_store_id;
  if store_row.id is null then
    return;
  end if;

  insert into public.branches(
    store_id,
    name,
    code,
    city,
    address,
    phone,
    is_main
  ) values (
    store_row.id,
    'الفرع الرئيسي',
    'MAIN',
    store_row.city,
    store_row.address,
    store_row.phone,
    true
  )
  on conflict (store_id, code) do nothing;
end;
$$;

create or replace function public.create_default_store_branch()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.ensure_default_store_branch(new.id);
  return new;
end;
$$;

create or replace function public.ensure_default_store_branch_after_subscription()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.ensure_default_store_branch(new.store_id);
  return new;
end;
$$;

drop trigger if exists subscriptions_ensure_default_branch
  on public.subscriptions;
create trigger subscriptions_ensure_default_branch
after insert or update of
  plan_id,
  status,
  trial_ends_at,
  current_period_end,
  source
on public.subscriptions
for each row execute function
  public.ensure_default_store_branch_after_subscription();

comment on trigger stores_create_default_branch on public.stores is
  'Runs at the deferred store boundary and creates MAIN only when the subscription is usable.';
comment on trigger subscriptions_ensure_default_branch
on public.subscriptions is
  'Creates or reactivates MAIN on the first usable subscription transition.';

-- Initial-payment stores cannot create invitation or claim work records even
-- through SECURITY DEFINER/service-role paths. Historical records remain
-- readable and editable after a normal paid or trial subscription expires,
-- because that state is deliberately not classified as initial-payment.
create or replace function public.reject_initial_payment_store_write()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if public.store_requires_initial_payment(new.store_id) then
    raise exception 'INITIAL_PAYMENT_REQUIRED';
  end if;
  return new;
end;
$$;

drop trigger if exists invite_codes_00_initial_payment_guard
  on public.invite_codes;
create trigger invite_codes_00_initial_payment_guard
before insert on public.invite_codes
for each row execute function public.reject_initial_payment_store_write();

drop trigger if exists maintenance_requests_00_initial_payment_guard
  on public.maintenance_requests;
create trigger maintenance_requests_00_initial_payment_guard
before insert or update on public.maintenance_requests
for each row execute function public.reject_initial_payment_store_write();

-- warranty-card issues a new public link only after an authenticated member
-- can SELECT the warranty row. Keep that read available for normally expired
-- stores, but hide rows from the exact never-activated placeholder. Existing
-- public historical cards continue through the service-role read path.
create or replace function public.can_access_warranty_records(
  target_store_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_store_member(target_store_id)
    and not public.store_requires_initial_payment(target_store_id)
$$;

drop policy if exists warranties_select_members on public.warranties;
create policy warranties_select_members
on public.warranties for select to authenticated
using (public.can_access_warranty_records(store_id));

revoke all on function public.create_store_with_subscription(
  text, text, text, text, text
) from public, anon, authenticated;
grant execute on function public.create_store_with_subscription(
  text, text, text, text, text
) to authenticated;

revoke all on function public.register_trial_device(uuid, text)
  from public, anon, authenticated;
grant execute on function public.register_trial_device(uuid, text)
  to authenticated;

revoke all on function public.store_requires_initial_payment(uuid)
  from public, anon, authenticated;
revoke all on function public.can_access_warranty_records(uuid)
  from public, anon, authenticated;
grant execute on function public.can_access_warranty_records(uuid)
  to authenticated;
revoke all on function private.ensure_default_store_branch(uuid)
  from public, anon, authenticated;
revoke all on function public.create_default_store_branch()
  from public, anon, authenticated;
revoke all on function
  public.ensure_default_store_branch_after_subscription()
  from public, anon, authenticated;
revoke all on function public.reject_initial_payment_store_write()
  from public, anon, authenticated;

comment on function public.create_store_with_subscription(
  text, text, text, text, text
) is 'Build 25 idempotent onboarding: always returns an owned store and grants a 14-day Starter trial only when account and installation are both eligible.';

comment on function public.register_trial_device(uuid, text) is
  'Registers up to five protected installations under account-then-device transaction locks without granting subscription access.';

comment on function private.ensure_default_store_branch(uuid) is
  'Creates or reactivates MAIN only after the store subscription becomes usable.';

comment on function public.can_access_warranty_records(uuid) is
  'Allows authenticated member warranty reads except for the exact never-activated initial-payment state.';

comment on function public.reject_initial_payment_store_write() is
  'Rejects invitation and maintenance mutations only for the exact never-activated initial-payment state.';

-- Keep the Build 25 onboarding entry point available only to a signed-in
-- client. Supabase's default function privileges grant service_role an
-- explicit EXECUTE entry, so remove it after the main onboarding migration.

revoke execute on function public.create_store_with_subscription(
  text, text, text, text, text
) from service_role;

revoke execute on function public.register_trial_device(uuid, text)
  from service_role;
revoke execute on function public.store_requires_initial_payment(uuid)
  from service_role;
revoke execute on function public.can_access_warranty_records(uuid)
  from service_role;

revoke execute on function private.ensure_default_store_branch(uuid)
  from service_role;
revoke execute on function public.create_default_store_branch()
  from service_role;
revoke execute on function
  public.ensure_default_store_branch_after_subscription()
  from service_role;
revoke execute on function public.reject_initial_payment_store_write()
  from service_role;
