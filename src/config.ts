// إعدادات تشغيل التطبيق المركزية

// يزيل BOM (U+FEFF) و zero-width space (U+200B) والمسافات من قيم متغيرات البيئة.
export const cleanEnvValue = (value: string | undefined | null): string =>
  (value ?? '').replace(/[\uFEFF\u200B]/g, '').trim()

// الدفع الحقيقي فقط. لم يعد متغير بيئة من جهة العميل قادراً على تعليم الطلب
// كمدفوع؛ التأكيد يأتي من معاملة المحفظة الذرية أو Webhook شام كاش الموقّع.
export const PAYMENT_MODE: 'auto' | 'shamcash' = 'shamcash'

// بلد المصدر الذي تُجلب منه المنتجات من SHEIN ويُجمع فيه الشحن قبل سوريا.
export const SOURCE_COUNTRY: 'JO' | 'LB' | 'SA' = 'SA'

// رقم النسخة الظاهر داخل التطبيق.
export const APP_VERSION = '2026.07.14-clean-v80-rollback-v83'
