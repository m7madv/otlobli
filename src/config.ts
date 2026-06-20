// إعدادات تشغيل التطبيق المركزية

// وضع الدفع:
//  - 'auto'     : الطلب يُسجَّل "مدفوع" فوراً عند تأكيده (شام كاش معطّل مؤقتاً
//                 حتى يكتمل المشروع). الطلبات تصل للوحة الإدارة مباشرة.
//  - 'shamcash' : نظام شام كاش الكامل بالمبلغ الفريد + مطابقة تلقائية.
//                 يتطلب تطبيق supabase/schema.sql الكامل أولاً (الدوال
//                 create_pending_order / confirm_payment_by_amount /
//                 get_order_payment_status وجدول app_settings والأعمدة الجديدة).
//
// لتفعيل الدفع لاحقاً: طبّق schema.sql على Supabase ثم غيّر هذا إلى 'shamcash'.
export const PAYMENT_MODE: 'auto' | 'shamcash' = 'auto'

// رقم النسخة — يظهر في شاشة الدخول لمعرفة أي بناء مثبّت على الجهاز عند التشخيص.
export const APP_VERSION = '2026.06.20-orders-fix'
