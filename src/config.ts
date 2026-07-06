// إعدادات تشغيل التطبيق المركزية

// يزيل BOM (U+FEFF) و zero-width space (U+200B) والمسافات من قيم متغيرات البيئة.
export const cleanEnvValue = (value: string | undefined | null): string =>
  (value ?? '').replace(/[\uFEFF\u200B]/g, '').trim()

// وضع الدفع:
//  - 'auto'     : وضع مؤقت يعلّم الطلب كمدفوع مباشرة.
//  - 'shamcash' : نظام شام كاش الحقيقي بالمبلغ الفريد والمطابقة الفعلية.
// الافتراضي الآن هو شام كاش. يمكن إرجاع auto فقط عبر VITE_PAYMENT_MODE=auto.
const envPaymentMode = cleanEnvValue(import.meta.env.VITE_PAYMENT_MODE)
export const PAYMENT_MODE: 'auto' | 'shamcash' = envPaymentMode === 'auto' ? 'auto' : 'shamcash'

// بلد المصدر الذي تُجلب منه المنتجات من SHEIN ويُجمع فيه الشحن قبل سوريا.
export const SOURCE_COUNTRY: 'JO' | 'LB' | 'SA' = 'SA'

// رقم النسخة الظاهر داخل التطبيق.
export const APP_VERSION = '2026.07.06-shamcash-admin-session-v36'
