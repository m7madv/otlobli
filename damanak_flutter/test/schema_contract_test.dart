import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('مخطط قاعدة البيانات يفعّل العزل وفرض الاشتراك', () {
    final schema = File(
      'supabase/migrations/20260824090000_damanak_core.sql',
    ).readAsStringSync();

    for (final table in [
      'profiles',
      'stores',
      'store_members',
      'subscriptions',
      'products',
      'warranties',
      'maintenance_requests',
      'invite_codes',
      'subscription_requests',
      'activation_codes',
      'audit_logs',
    ]) {
      expect(
        schema,
        contains('alter table public.$table enable row level security;'),
      );
    }

    expect(schema, contains('create_store_with_trial'));
    expect(schema, contains('join_store_by_code'));
    expect(schema, contains('enforce_warranty_entitlement'));
    expect(schema, contains('SEAT_LIMIT_REACHED'));
    expect(schema, contains('WARRANTY_LIMIT_REACHED'));
  });

  test('مخطط العمليات يربط العملة والضريبة والعملاء والفروع بالفاتورة', () {
    final schema = File(
      'supabase/migrations/20260824130000_damanak_business_operations.sql',
    ).readAsStringSync();

    for (final token in [
      'currency_code',
      'tax_rate',
      'prices_include_tax',
      'create table if not exists public.branches',
      'create table if not exists public.customers',
      'customer_id',
      'branch_id',
      'invoice_number',
      'sale_subtotal',
      'discount_amount',
      'tax_amount',
      'sale_total',
      'payment_method',
      'warranties_set_invoice_number',
    ]) {
      expect(schema, contains(token));
    }

    expect(
      schema,
      contains('alter table public.branches enable row level security;'),
    );
    expect(
      schema,
      contains('alter table public.customers enable row level security;'),
    );
  });

  test('مخطط التجزئة يعزل البيع والمخزون والمشتريات ويستخدم عمليات ذرية', () {
    final schema = File(
      'supabase/migrations/20260824160000_damanak_retail_operations.sql',
    ).readAsStringSync();

    for (final table in [
      'inventory_levels',
      'stock_movements',
      'sales',
      'sale_lines',
      'sale_payments',
      'sale_returns',
      'register_sessions',
      'suppliers',
      'purchase_orders',
      'purchase_order_lines',
    ]) {
      expect(
        schema,
        contains('alter table public.$table enable row level security;'),
      );
    }

    for (final function in [
      'adjust_inventory',
      'transfer_inventory',
      'create_sale',
      'return_sale',
      'open_register',
      'close_register',
      'create_purchase_order',
      'receive_purchase_order',
      'delete_current_account',
    ]) {
      expect(schema, contains('function public.$function'));
    }
  });
}
