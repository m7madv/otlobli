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

  test(
    'حارس التجربة يمنع تكرارها على الحساب والجهاز ولا يخزن المعرّف الخام',
    () {
      final migration = File(
        'supabase/migrations/20260831030000_damanak_trial_abuse_guard.sql',
      ).readAsStringSync();
      final repository = File(
        'lib/data/supabase_repository.dart',
      ).readAsStringSync();

      for (final token in [
        'private.trial_account_claims',
        'private.trial_device_claims',
        "'damanak:trial-account:v1:'",
        "'damanak:trial-device:v1:'",
        'TRIAL_ALREADY_USED_BY_ACCOUNT',
        'TRIAL_ALREADY_USED_ON_DEVICE',
        'APP_UPDATE_REQUIRED_FOR_TRIAL',
        'register_trial_device',
        'revoke all on function public.register_trial_device',
      ]) {
        expect(migration, contains(token));
      }
      expect(migration, isNot(contains('raw_device_claim')));
      expect(repository, contains("'device_claim'"));
      expect(repository, contains("'claim_free_plan_device'"));
    },
  );

  test('إنشاء المتجر يبقى متاحاً بلا تجربة أو حصة عند عدم الأهلية', () {
    final migration = File(
      'supabase/migrations/20260901010000_damanak_paid_store_without_repeat_trial.sql',
    ).readAsStringSync();
    final repository = File(
      'lib/data/supabase_repository.dart',
    ).readAsStringSync();

    for (final token in [
      'trial_granted boolean := false',
      'create or replace function public.create_store_with_subscription(',
      "case when trial_granted then 'trialing' else 'canceled' end",
      "subscription.status = 'canceled'",
      "subscription.source = 'trial'",
      'subscription.trial_ends_at is null',
      'subscription.current_period_start is null',
      'subscription.current_period_end is null',
      "'subscription_required', not trial_granted",
      'ensure_default_store_branch_after_subscription',
      'reject_initial_payment_store_write',
      'revoke all on function public.create_store_with_subscription',
    ]) {
      expect(migration, contains(token));
    }
    expect(repository, contains("'create_store_with_free_access'"));
    expect(repository, isNot(contains("'create_store_with_trial'")));
    expect(
      migration,
      isNot(contains("raise exception 'TRIAL_ALREADY_USED_BY_ACCOUNT'")),
    );
    expect(
      migration,
      isNot(contains("raise exception 'TRIAL_ALREADY_USED_ON_DEVICE'")),
    );
  });

  test('الخطة المجانية منفصلة عن الفوترة ومحمية بحصة دقيقة', () {
    final migration = File(
      'supabase/migrations/20260901200000_damanak_free_access_and_billing_repair.sql',
    ).readAsStringSync();
    final repository = File(
      'lib/data/supabase_repository.dart',
    ).readAsStringSync();

    for (final token in [
      "'free'",
      'monthly_warranties',
      'private.free_plan_grants',
      'private.free_session_claims',
      'private.effective_store_plan_id',
      'current_store_access',
      'claim_free_plan_device',
      'create_store_with_free_access',
      'reserve_store_subscription_refresh',
      'apply_verified_sandbox_terminal_entitlement',
      'store_entitlements_schedule_after_verification',
      'subscriptions_non_store_metadata_clean_check',
      'drop trigger if exists subscriptions_prevent_active_store_plan_downgrade',
      'subscriptions_free_access_mirror_check',
      'subscription.free_access_mirror',
      'create_store_with_subscription_legacy_core',
      'create or replace function public.create_store_with_trial(',
      'on conflict (store_id, account_hash, device_hash) do update',
      'and entitlement.platform = \'app_store\'',
      "and blocked_billing.store_environment = 'production'",
      "subscription.source = 'manual'",
      "tester.platform = 'app_store'",
      "when effective_plan_id = 'free' then included_limit",
      "status = 'revoked'",
      "WEBHOOK_PLAN_NOT_INCLUDED",
    ]) {
      expect(migration, contains(token));
    }
    expect(repository, contains("'current_store_access'"));
    expect(repository, contains("'claim_free_plan_device'"));
    expect(repository, contains("'create_store_with_free_access'"));
    expect(repository, contains(".neq('id', 'free')"));
    expect(
      migration,
      isNot(contains('select distinct on (entitlement.store_id')),
    );
    expect(
      migration,
      isNot(
        contains('delete from private.store_purchase_verification_limits;'),
      ),
    );
    expect(
      migration,
      isNot(
        contains('delete from private.store_subscription_refresh_limits;'),
      ),
    );
    expect(
      migration,
      isNot(contains("raise exception 'ACTIVE_STORE_PLAN_DOWNGRADE_BLOCKED'")),
    );
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
      'gemini-3.5-flash-lite',
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

  test('حواجز الاستحقاق والحصص تستخدم مسارات ذرية ولا تترك تنفيذًا للزائر', () {
    final posture = File(
      'supabase/migrations/20260831040000_damanak_security_posture.sql',
    ).readAsStringSync();
    final guards = File(
      'supabase/migrations/20260831050000_damanak_entitlement_and_quota_guards.sql',
    ).readAsStringSync();

    expect(posture, contains('DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS'));
    for (final token in [
      'claim_ai_import_job',
      'claim_ai_claim_review_job',
      'reserve_api_request',
      'finish_api_request',
      "pg_advisory_xact_lock",
      "status = 'trialing'",
      'current_period_end > now()',
      'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS',
    ]) {
      expect(guards, contains(token));
    }
  });

  test('مزامنة المتجر دورية ومحدودة بالاستحقاقات القابلة للاستعمال', () {
    final migration = File(
      'supabase/migrations/20260831060000_damanak_recurring_entitlement_security.sql',
    ).readAsStringSync();
    final function = File(
      'supabase/functions/refresh-store-entitlements/index.ts',
    ).readAsStringSync();

    for (final token in [
      'next_verification_at',
      'claim_store_entitlement_refreshes',
      "status in ('active', 'grace', 'past_due')",
      'for update skip locked',
      'damanak-entitlement-refresh',
      'entitlement_refresh_secret',
      'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS',
    ]) {
      expect(migration, contains(token));
    }
    expect(function, contains('ENTITLEMENT_REFRESH_SECRET'));
    expect(function, contains('verifyApplePurchase'));
    expect(function, contains('verifyGooglePurchase'));
  });

  test('مسارات الكتابة تمنع نقل الملكية وتزوير المطالبات وتخمن الدعوات', () {
    final migration = File(
      'supabase/migrations/20260831070000_damanak_write_path_hardening.sql',
    ).readAsStringSync();
    final repository = File(
      'lib/data/supabase_repository.dart',
    ).readAsStringSync();

    for (final token in [
      'revoke update on table public.stores from authenticated',
      'enforce_authenticated_claim_write',
      'CLAIM_IMMUTABLE_FIELDS',
      'create_maintenance_request',
      'revoke update on table public.maintenance_requests',
      'private.invite_join_attempts',
      'INVITE_RATE_LIMITED',
      'gen_random_bytes(16)',
      "[A-F0-9]{32}",
      'drop policy if exists invites_select_managers',
      'revoke select on table public.invite_codes',
      'private.store_purchase_verification_limits',
      'reserve_store_purchase_verification',
      'window_attempts >= 10',
      'day_attempts >= 50',
      'subscriptions_enforce_member_limit',
      'member_suspended_for_plan_limit',
      "target_status = 'active'",
      'enforce_usable_subscription_for_core_write',
      'core_write_triggers',
      "'register_sessions'",
      "table_name || '_usable_subscription_guard'",
      'SUBSCRIPTION_INACTIVE',
      'DAMANAK_ANON_FUNCTION_EXECUTE_REMAINS',
    ]) {
      expect(migration, contains(token));
    }
    expect(repository, contains("'create_maintenance_request'"));
    expect(
      repository,
      isNot(contains(".from('maintenance_requests')\n        .insert")),
    );
  });

  test(
    'حارس الكتابة يجعل التشغيل منتهي الاشتراك للقراءة فقط ويحفظ المرتجع',
    () {
      final migration = File(
        'supabase/migrations/20260831080000_damanak_business_write_paywall.sql',
      ).readAsStringSync();

      for (final token in [
        'enforce_usable_subscription_for_core_write',
        "coalesce((select auth.role()), '') <> 'authenticated'",
        'before insert or update',
        "table_name || '_00_subscription_write_guard'",
        "'register_sessions'",
        "'sale_returns'",
        "'warranties'",
        "current_setting('damanak.write_context', true)",
        "set_config('damanak.write_context', 'return_sale', true)",
        "to_jsonb(old)->>'status' = 'open'",
        "to_jsonb(new)->>'status' = 'closed'",
        'SUBSCRIPTION_INACTIVE',
      ]) {
        expect(migration, contains(token));
      }
      expect(migration, isNot(contains('before insert or update or delete')));
    },
  );

  test('محدد تحقق المتجر يستخدم وقتًا UTC بلا تعارض مع CURRENT_TIME', () {
    final migration = File(
      'supabase/migrations/20260831100000_damanak_purchase_verification_limiter_fix.sql',
    ).readAsStringSync();
    expect(migration, contains('request_time timestamptz'));
    expect(migration, contains("request_time at time zone 'UTC'"));
    expect(migration, isNot(contains('current_time timestamptz')));
  });

  test('حارس الكتابة العام لا يفترض حقول سجل خاصة بجدول واحد', () {
    final migration = File(
      'supabase/migrations/20260831110000_damanak_generic_write_trigger_record_fix.sql',
    ).readAsStringSync();
    expect(migration, contains("to_jsonb(old)->>'status'"));
    expect(migration, contains("to_jsonb(new)->>'store_id'"));
    expect(migration, isNot(contains('old.status')));
    expect(migration, isNot(contains('new.status')));
  });

  test('ربط إيصال المتجر ذري وSandbox محصور بمختبر مؤقت', () {
    final migration = File(
      'supabase/migrations/20260831120000_damanak_atomic_store_receipt_link.sql',
    ).readAsStringSync();
    final verifier = File(
      'supabase/functions/verify-store-purchase/index.ts',
    ).readAsStringSync();

    for (final token in [
      'private.store_sandbox_testers',
      "interval '24 hours'",
      'pg_advisory_xact_lock',
      'STORE_PURCHASE_ALREADY_LINKED',
      'SANDBOX_TESTER_NOT_ALLOWED',
      'SANDBOX_CANNOT_REPLACE_PRODUCTION',
      'subscriptions_store_receipt_unique',
      'subscriptions_store_entitlement_fk',
      'subscriptions_store_receipt_complete_check',
      'apply_verified_store_entitlement_with_receipt',
      'raw_purchase_token',
      'current_period_end > pg_catalog.now()',
    ]) {
      expect(migration, contains(token));
    }
    expect(verifier, contains('apply_verified_store_entitlement_with_receipt'));
    expect(verifier, isNot(contains('"save_store_receipt_secret",')));
  });

  test('حصة الضمان والفروع والهوية لا تعاد تدويرها بعد خفض الخطة', () {
    final migration = File(
      'supabase/migrations/20260831130000_damanak_quota_and_branding_integrity.sql',
    ).readAsStringSync();
    final portal = File(
      'supabase/functions/warranty-card/index.ts',
    ).readAsStringSync();

    for (final token in [
      'new.created_at := pg_catalog.now()',
      'new.created_by := actor',
      'new.voided_at := null',
      'revoke delete on table public.warranties',
      'before insert or update of is_active, store_id',
      'trim_branches_to_subscription_limit',
      "actor_role <> 'authenticated'",
      'new.warranty_policy is distinct from old.warranty_policy',
      'products_branding_entitlement',
      'PLAN_BRANDING_REQUIRED',
    ]) {
      expect(migration, contains(token));
    }
    expect(migration, isNot(contains('and warranty.voided_at is null')));
    expect(portal, contains('brandingAllowed === true'));
    expect(portal, contains('const publicStore'));
  });

  test('مراجع الضمان لا تستطيع عبور حدود المتجر', () {
    final migration = File(
      'supabase/migrations/20260831140000_damanak_warranty_tenant_integrity.sql',
    ).readAsStringSync();

    for (final token in [
      'branches_id_store_id_key',
      'customers_id_store_id_key',
      'products_id_store_id_key',
      'sales_id_store_id_key',
      'sale_lines_id_store_id_key',
      'warranties_customer_store_fk',
      'warranties_product_store_fk',
      'warranties_branch_store_fk',
      'warranties_sale_store_fk',
      'warranties_sale_line_store_fk',
      'foreign key (customer_id, store_id)',
      'foreign key (product_id, store_id)',
      'foreign key (branch_id, store_id)',
      'foreign key (sale_id, store_id)',
      'foreign key (sale_line_id, store_id)',
      'on delete set null (product_id)',
      'on delete set null (branch_id)',
      'on delete set null (sale_id)',
      'on delete set null (sale_line_id)',
    ]) {
      expect(migration, contains(token));
    }
  });

  test('المطالبة لا تستطيع الارتباط بضمان من متجر آخر', () {
    final migration = File(
      'supabase/migrations/20260831150000_damanak_claim_warranty_tenant_integrity.sql',
    ).readAsStringSync();
    final portal = File(
      'supabase/functions/warranty-card/index.ts',
    ).readAsStringSync();

    for (final token in [
      'warranties_id_store_id_key',
      'maintenance_requests_warranty_store_fk',
      'foreign key (warranty_id, store_id)',
      'references public.warranties(id, store_id)',
      'request.store_id <> warranty.store_id',
    ]) {
      expect(migration, contains(token));
    }
    expect(portal, contains('.eq("warranty_id", warranty.id)'));
    expect(portal, contains('.eq("store_id", warranty.store_id)'));
  });

  test('دورة اشتراك المتجر تبقي استحقاقًا حاليًا واحدًا وسلسلة إيصال معزولة', () {
    final migration = File(
      'supabase/migrations/20260831160000_damanak_subscription_lifecycle_integrity.sql',
    ).readAsStringSync();

    for (final token in [
      'store_entitlements_one_current_per_store',
      'store_entitlements_store_id_id_unique',
      'where superseded_at is null',
      'store_entitlement_id uuid',
      'foreign key (store_id, store_entitlement_id)',
      'references public.store_entitlements(store_id, id)',
      'subscriptions_current_store_entitlement_check',
      'private.google_purchase_token_links',
      'GOOGLE_PURCHASE_LINEAGE_CONFLICT',
      'GOOGLE_PURCHASE_TOKEN_SUPERSEDED',
      'GOOGLE_LINKED_PURCHASE_UNRESOLVED',
      'linked_purchase_token_hash',
      'on delete set null',
      'ACTIVE_STORE_PROVIDER_CHANGE_BLOCKED',
      'ACTIVE_STORE_SUBSCRIPTION_REPLACEMENT_BLOCKED',
      'private.store_sandbox_review_windows',
      "closes_at <= opens_at + interval '72 hours'",
      "expires_at <= granted_at + interval '24 hours'",
      'max_grants between 1 and 20',
      'sandbox_review_access_granted',
      'allow_new_grant boolean',
      "entitlement_status in ('active', 'grace')",
      "entitlement_status <> 'revoked'",
      "effective_entitlement_status := 'active'",
      'expected_current_purchase_token_hash text',
      "extensions.digest(current_receipt_token, 'sha256')",
      'STORE_RECEIPT_STALE',
      'store_subscription_terminated_for_account_deletion',
      'external_billing_cancellation_required',
      'current_warranty_usage',
      'claim_store_entitlement_refreshes',
      'least(requested_limit, 100)',
      'release_store_entitlement_refresh',
      'pg_catalog.power(',
      'DAMANAK_MULTIPLE_CURRENT_STORE_ENTITLEMENTS',
      'DAMANAK_STORE_ENTITLEMENT_TENANT_FK_INVALID',
      'DAMANAK_STORE_BILLING_EXECUTE_EXPOSED',
      'DAMANAK_RAW_STORE_ENTITLEMENT_APPLY_EXPOSED',
    ]) {
      expect(migration, contains(token));
    }

    expect(migration, contains('account_delete_definition'));
    expect(migration, contains("pg_catalog.strpos("));

    final sandboxClaimStart = migration.indexOf(
      'create or replace function private.claim_store_sandbox_access(',
    );
    final sandboxClaimEnd = migration.indexOf(
      'revoke all on function private.claim_store_sandbox_access(',
      sandboxClaimStart,
    );
    expect(sandboxClaimStart, greaterThanOrEqualTo(0));
    expect(sandboxClaimEnd, greaterThan(sandboxClaimStart));
    final sandboxClaim = migration.substring(
      sandboxClaimStart,
      sandboxClaimEnd,
    );
    expect(sandboxClaim, isNot(contains('skip locked')));
    expect(
      sandboxClaim.indexOf('if found then'),
      lessThan(sandboxClaim.indexOf('if not coalesce(allow_new_grant, false)')),
    );

    final receiptApplyStart = migration.indexOf(
      'create function public.apply_verified_store_entitlement_with_receipt(',
    );
    final receiptApplyEnd = migration.indexOf(
      'revoke all on function public.apply_verified_store_entitlement_with_receipt(',
      receiptApplyStart,
    );
    expect(receiptApplyStart, greaterThanOrEqualTo(0));
    expect(receiptApplyEnd, greaterThan(receiptApplyStart));
    final receiptApply = migration.substring(
      receiptApplyStart,
      receiptApplyEnd,
    );
    expect(
      receiptApply.indexOf('STORE_RECEIPT_STALE'),
      lessThan(
        receiptApply.indexOf(
          'subscription_row := public.apply_verified_store_entitlement(',
        ),
      ),
    );

    final rawApplyAclStart = migration.indexOf(
      'revoke all on function public.apply_verified_store_entitlement(',
    );
    final rawApplyAclEnd = migration.indexOf(
      'drop function if exists public.apply_verified_store_entitlement_with_receipt(',
      rawApplyAclStart,
    );
    expect(rawApplyAclStart, greaterThanOrEqualTo(0));
    expect(rawApplyAclEnd, greaterThan(rawApplyAclStart));
    final rawApplyAcl = migration.substring(rawApplyAclStart, rawApplyAclEnd);
    expect(
      rawApplyAcl,
      contains('from public, anon, authenticated, service_role;'),
    );
    expect(rawApplyAcl, isNot(contains('grant execute')));

    final accountDeleteStart = migration.indexOf(
      'create or replace function public.delete_current_account()',
    );
    final accountDeleteEnd = migration.indexOf(
      'revoke all on function public.delete_current_account()',
      accountDeleteStart,
    );
    expect(accountDeleteStart, greaterThanOrEqualTo(0));
    expect(accountDeleteEnd, greaterThan(accountDeleteStart));
    final accountDelete = migration.substring(
      accountDeleteStart,
      accountDeleteEnd,
    );
    expect(
      accountDelete,
      isNot(
        contains(
          "raise exception 'ACTIVE_STORE_SUBSCRIPTION_MUST_BE_RESOLVED'",
        ),
      ),
    );
    expect(
      accountDelete.indexOf('pg_advisory_xact_lock'),
      lessThan(accountDelete.indexOf('for update;')),
    );
    expect(accountDelete, contains("set status = 'canceled'"));
    expect(accountDelete, contains('period_end = least('));
    expect(accountDelete, contains('auto_renews = false'));
    expect(
      accountDelete,
      contains('subscription.store_entitlement_id = terminated_entitlement_id'),
    );
  });

  test('حذف حساب المالك يبقي الخلف مالكًا نشطًا قبل إلغاء الاشتراك', () {
    final migration = File(
      'supabase/migrations/20260831170000_damanak_account_deletion_successor_fix.sql',
    ).readAsStringSync();
    final liveTest = File(
      'supabase/tests/account_deletion_successor_live.sql',
    ).readAsStringSync();

    final promotion = migration.indexOf("set role = 'owner',");
    final activeStatus = migration.indexOf("status = 'active'", promotion);
    final cancellation = migration.indexOf(
      'update public.store_entitlements entitlement',
    );
    expect(promotion, greaterThanOrEqualTo(0));
    expect(activeStatus, greaterThan(promotion));
    expect(cancellation, greaterThan(activeStatus));
    expect(
      migration,
      contains('DAMANAK_ACCOUNT_SUCCESSOR_PROMOTION_ORDER_INVALID'),
    );
    expect(liveTest, contains('perform public.delete_current_account();'));
    expect(liveTest, contains("successor_status <> 'active'"));
    expect(liveTest, contains('rollback;'));
  });

  test('سلسلة Google لا تقبل فرعًا شقيقًا أو توكنًا غير حالي', () {
    final migration = File(
      'supabase/migrations/20260831180000_damanak_google_lineage_predecessor_cas.sql',
    ).readAsStringSync();
    final liveTest = File(
      'supabase/tests/subscription_lifecycle_live.sql',
    ).readAsStringSync();

    final applyStart = migration.indexOf(
      'create or replace function public.apply_verified_store_entitlement_with_receipt(',
    );
    final applyEnd = migration.indexOf(
      'revoke all on function public.apply_verified_store_entitlement_with_receipt(',
      applyStart,
    );
    expect(applyStart, greaterThanOrEqualTo(0));
    expect(applyEnd, greaterThan(applyStart));
    final receiptApply = migration.substring(applyStart, applyEnd);
    final mutation = receiptApply.indexOf(
      'subscription_row := public.apply_verified_store_entitlement(',
    );
    expect(receiptApply, contains('current_token_is_known := found;'));
    expect(receiptApply, contains('GOOGLE_PURCHASE_TOKEN_SUPERSEDED'));
    expect(receiptApply, contains("subscription.source = 'store'"));
    expect(receiptApply, contains('subscription.store_entitlement_id'));
    expect(
      receiptApply,
      contains(
        'subscription.original_transaction_id =\n          current_link.original_transaction_id',
      ),
    );
    expect(
      receiptApply,
      contains("extensions.digest(current_receipt_token, 'sha256')"),
    );
    expect(
      receiptApply.indexOf(') <> purchase_token_hash then'),
      lessThan(mutation),
    );
    expect(
      receiptApply.indexOf(') <> linked_purchase_token_hash then'),
      lessThan(mutation),
    );

    for (final token in [
      'create or replace function public.resolve_google_purchase_token_binding(',
      'returns jsonb',
      "extensions.digest(raw_purchase_token, 'sha256')",
      "'store_id', token_link.store_id",
      "'user_id', token_link.user_id",
      "'original_transaction_id', token_link.original_transaction_id",
      'from public, anon, authenticated, service_role;',
      'to service_role;',
      'DAMANAK_GOOGLE_TOKEN_RESOLVER_ACL_INVALID',
    ]) {
      expect(migration, contains(token));
    }

    expect(liveTest, contains('token_c_hash'));
    expect(
      liveTest,
      contains('A sibling Google token was accepted from stale A'),
    );
    expect(liveTest, contains('Current-token replay did not preserve B'));
    expect(
      liveTest,
      contains('An old known lineage replaced independent current C'),
    );
    expect(
      liveTest,
      contains('Rejected old-lineage replay did not preserve current C'),
    );
    expect(
      liveTest,
      contains('public.resolve_google_purchase_token_binding(token_b)'),
    );
    expect(liveTest, contains('rollback;'));
  });
}
