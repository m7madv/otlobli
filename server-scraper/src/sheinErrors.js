export class SheinImportError extends Error {
  constructor(code, details = {}) {
    const messages = {
      INVALID_SHEIN_URL: 'الرابط ليس رابط Shein صحيح',
      PRODUCT_ID_NOT_FOUND: 'لم نتمكن من استخراج معرّف المنتج من الرابط',
      FETCH_FAILED: 'فشل جلب بيانات المنتج من Shein',
      PRODUCT_PARSE_FAILED: 'لم نتمكن من قراءة بيانات المنتج',
      PRODUCT_UNAVAILABLE: 'المنتج غير متاح حالياً',
      PRICE_NOT_FOUND: 'لم نتمكن من قراءة سعر المنتج',
      VARIANTS_NOT_FOUND: 'لم نتمكن من قراءة خيارات المنتج',
      RATE_NOT_CONFIGURED: 'سعر صرف الدولار غير مهيأ',
    }
    super(messages[code] || code)
    this.code = code
    this.details = details
  }
}
