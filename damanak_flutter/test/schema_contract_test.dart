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

  test('مخطط العمليات يبقي حقول التوافق ويربط العملاء والفروع بالإيصال', () {
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

  test('ترحيل الإيصالات يلغي الضريبة المستقبلية ولا يعيد كتابة المبيعات', () {
    final migration = File(
      'supabase/migrations/20260825190000_damanak_simple_receipts.sql',
    ).readAsStringSync();

    expect(migration, contains('set tax_rate = 0'));
    expect(migration, contains('alter column tax_rate set default 0'));
    expect(migration, contains('check (tax_rate = 0)'));
    expect(migration, isNot(contains('update public.sales')));
    expect(migration, isNot(contains('update public.warranties')));
  });

  test('مخطط فوترة المتاجر يمنع التفعيل اليدوي ويعزل الاستحقاقات', () {
    final schema = File(
      'supabase/migrations/20260824180000_damanak_store_billing.sql',
    ).readAsStringSync();
    final verifier = File(
      'supabase/functions/verify-store-purchase/index.ts',
    ).readAsStringSync();

    for (final token in [
      'store_product_catalog',
      'store_entitlements',
      'private.store_receipt_secrets',
      'apply_verified_store_entitlement',
      'save_store_receipt_secret',
      'get_store_receipt_secret',
      "billing_provider in ('app_store', 'google_play')",
      'revoke insert on table public.subscription_requests',
      'revoke execute on function public.redeem_subscription_code',
      'to service_role',
    ]) {
      expect(schema, contains(token));
    }

    for (final token in [
      'api.storekit.apple.com',
      'api.storekit-sandbox.apple.com',
      'purchases/subscriptionsv2/tokens',
      'GOOGLE_PLAY_SERVICE_ACCOUNT_JSON',
      'APPLE_IAP_PRIVATE_KEY_P8',
      'STORE_OWNER_REQUIRED',
      'refresh === true',
    ]) {
      expect(verifier, contains(token));
    }
  });

  test('مخطط المطالبات يفرض دورة خدمة معزولة وتحديثاً متزامناً آمناً', () {
    final schema = File(
      'supabase/migrations/20260830160000_damanak_claims_foundation.sql',
    ).readAsStringSync();

    for (final token in [
      'claim_number',
      'needs_review',
      'waiting_for_customer',
      'ready_for_pickup',
      'decision_reason',
      'sla_due_at',
      'maintenance_request_events',
      'guard_maintenance_request',
      'CLAIM_VERSION_CONFLICT',
      'CLAIM_MANAGER_REQUIRED',
      'update_maintenance_request',
      'enable row level security',
    ]) {
      expect(schema, contains(token));
    }

    expect(
      schema,
      contains('grant execute on function public.update_maintenance_request'),
    );
    expect(
      schema,
      contains('revoke all on table public.maintenance_request_events'),
    );
  });

  test(
    'بوابة العميل تعزل الملفات وتحد الإرسال ولا تكشف الملاحظات الداخلية',
    () {
      final migration = File(
        'supabase/migrations/20260830170000_damanak_customer_claim_portal.sql',
      ).readAsStringSync();
      final function = File(
        'supabase/functions/warranty-card/index.ts',
      ).readAsStringSync();

      for (final token in [
        'maintenance_request_attachments',
        'submit_public_warranty_claim',
        'CLAIM_RATE_LIMITED',
        'WARRANTY_EXPIRED',
        'public_submission_id',
        'pg_advisory_xact_lock',
        'claim-attachments',
        'to service_role',
        'enable row level security',
      ]) {
        expect(migration, contains(token));
      }

      for (final token in [
        'multipart/form-data',
        'allowedAttachmentTypes',
        'maxAttachmentBytes',
        'submitPublicClaim',
        'form-action \'self\'',
        'referrer-policy',
        'maintenance_request_attachments',
        'customer_notes',
      ]) {
        expect(function, contains(token));
      }

      expect(
        function,
        isNot(contains('select("*,maintenance_request_attachments(*)")')),
      );
      expect(function, isNot(contains('internal_notes')));
    },
  );

  test('حارس التكرار يعزل المتجر ويطبع الرقم التسلسلي قبل المطابقة', () {
    final migration = File(
      'supabase/migrations/20260830180000_damanak_duplicate_guards.sql',
    ).readAsStringSync();

    for (final token in [
      'warranties_store_serial_normalized_idx',
      'find_warranty_by_serial',
      'regexp_replace',
      'is_store_member',
      'voided_at is null',
      'to authenticated',
    ]) {
      expect(migration, contains(token));
    }
  });

  test('استيراد الذكاء الاصطناعي مسجل التكلفة ومتاح للمدير فقط', () {
    final migration = File(
      'supabase/migrations/20260830190000_damanak_ai_import_jobs.sql',
    ).readAsStringSync();
    final function = File(
      'supabase/functions/import-products-ai/index.ts',
    ).readAsStringSync();
    final routing = File(
      'supabase/migrations/20260830200000_damanak_ai_provider_routing.sql',
    ).readAsStringSync();

    for (final token in [
      'ai_import_jobs',
      'estimated_cost_usd',
      'ai_import_jobs_select_managers',
      "has_store_role(store_id, array['owner', 'manager'])",
      'enable row level security',
    ]) {
      expect(migration, contains(token));
    }
    for (final token in [
      'OPENAI_API_KEY',
      'GEMINI_API_KEY',
      'gemini-2.5-flash-lite',
      'gpt-5.6-luna',
      'json_schema',
      'store: false',
      'AI_IMPORT_MONTHLY_LIMIT',
      'AI_IMPORT_DAILY_SAFETY_LIMIT',
      'IMPORT_MANAGER_REQUIRED',
      'productImportSchema',
      'confidence',
    ]) {
      expect(function, contains(token));
    }
    expect(function, contains('env("OPENAI_API_KEY")'));
    expect(function, isNot(contains('sk-proj-')));
    for (final token in [
      'monthly_ai_imports',
      'provider_attempts',
      'max_branches',
      'enforce_branch_entitlement',
    ]) {
      expect(routing, contains(token));
    }
  });

  test('الإشعارات والتكاملات تفرض الخطة وتخفي الأسرار', () {
    final notifications = File(
      'supabase/migrations/20260830220000_damanak_notification_center.sql',
    ).readAsStringSync();
    final integrations = File(
      'supabase/migrations/20260830230000_damanak_integrations.sql',
    ).readAsStringSync();
    for (final token in [
      'notification_preferences',
      'notifications_select_own',
      'enqueue_overdue_claim_notifications',
      'marketing boolean not null default false',
    ]) {
      expect(notifications, contains(token));
    }
    for (final token in [
      'extensions.digest(plain_key',
      'store_plan_allows',
      'PLAN_API_REQUIRED',
      'PLAN_WEBHOOK_REQUIRED',
      'authenticate_store_api_key',
      'queue_claim_webhooks',
      'claim_webhook_deliveries',
      'for update skip locked',
    ]) {
      expect(integrations, contains(token));
    }
    expect(
      integrations,
      isNot(
        contains(
          'grant select on table public.store_api_keys to authenticated',
        ),
      ),
    );
  });

  test('فرز المطالبة بالذكاء الاصطناعي مساعد بشري محدود ومحمي', () {
    final migration = File(
      'supabase/migrations/20260831000000_damanak_claim_ai_reviews.sql',
    ).readAsStringSync();
    final function = File(
      'supabase/functions/analyze-claim-ai/index.ts',
    ).readAsStringSync();

    for (final token in [
      'monthly_ai_claim_reviews',
      'ai_claim_reviews',
      'ai_claim_reviews_select_managers',
      "has_store_role(store_id, array['owner', 'manager'])",
      'estimated_cost_usd',
    ]) {
      expect(migration, contains(token));
    }
    for (final token in [
      'gpt-5.6-luna',
      'store: false',
      'includeAttachments',
      'CLAIM_AI_MONTHLY_LIMIT',
      'CLAIM_AI_COOLDOWN',
      'CLAIM_REVIEW_MANAGER_REQUIRED',
      'لا تقترح قبول المطالبة أو رفضها',
    ]) {
      expect(function, contains(token));
    }
    expect(function, isNot(contains('customer_name')));
    expect(function, isNot(contains('customer_phone')));
    expect(function, isNot(contains('.from("maintenance_requests").update')));
  });
}
