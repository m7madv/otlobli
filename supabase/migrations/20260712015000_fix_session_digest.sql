-- إصلاح عاجل لخطأ «function digest(text, unknown) does not exist» عند إنشاء
-- أي طلب: امتداد pgcrypto على Supabase يسكن مخطط extensions، بينما دالة
-- require_customer_session مقفولة على search_path = public فلا ترى digest().
-- نضيف extensions إلى المسار دون أي تغيير في المنطق أو الصلاحيات.
-- (ملاحظة: hotfix الجلسة الموازية 20260712020000 يتضمن الإصلاح نفسه ضمن
-- إعادة تعريف أشمل، لكنه غير قابل للتطبيق حالياً — فيه قطعة مفقودة حول
-- السطر 505 تلتحم فيها دالتا create_wallet_topup وconfirm_shamcash.)
alter function public.require_customer_session(text, text)
  set search_path = extensions, public;
