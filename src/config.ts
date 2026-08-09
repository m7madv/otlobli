// إعدادات تشغيل التطبيق المركزية

// يزيل BOM (U+FEFF) و zero-width space (U+200B) والمسافات من قيم متغيرات البيئة.
export const cleanEnvValue = (value: string | undefined | null): string =>
  (value ?? '').replace(/[\uFEFF\u200B]/g, '').trim()

// الدفع الحقيقي فقط. لم يعد متغير بيئة من جهة العميل قادراً على تعليم الطلب
// كمدفوع؛ التأكيد يأتي من معاملة المحفظة الذرية أو Webhook شام كاش الموقّع.
export const PAYMENT_MODE: 'auto' | 'shamcash' = 'shamcash'

// بلد المصدر الذي تُجلب منه المنتجات من SHEIN ويُجمع فيه الشحن قبل سوريا.
export const SOURCE_COUNTRY: 'JO' | 'LB' | 'SA' = 'SA'

// TEST IPA ONLY: skips the local OTP screens so repeated delete/install checks
// can reach the store immediately. This does not bypass server authentication
// and must be false before any production build.
export const TEST_ONLY_AUTH_BYPASS = false

// Diagnostic tools ship disabled in normal customer builds. Enable only in a
// dedicated diagnostic release after recording the affected device and steps.
export const SHEIN_IOS_FREEZE_DIAGNOSTICS = false
export const SHEIN_IOS_FREEZE_DIAGNOSTICS_BYPASS_RECOVERY = false

// رقم النسخة الظاهر داخل التطبيق.
export const APP_VERSION = '2026.08.09-v86.115-qa-vpn-back-layer'
