-- نقل التطبيق كله إلى الليرة السورية الجديدة (حذف صفرين — 100 قديمة = 1 جديدة).
--
-- سوريا حذفت صفرين في 1 كانون الثاني 2026، وشام كاش يعمل بالجديدة بينما كل
-- الحساب الداخلي هنا بالقديمة. النتيجة: التطبيق يطلب من الزبون تحويل مليون
-- بينما الصحيح عشرة آلاف، والمطابقة التلقائية لا تنجح لأن الويبهوك يقارن الرقم
-- كما هو. هذه الهجرة تُنهي الازدواجية من جذرها بدل تحويلٍ عند حدود شام كاش.
--
-- لماذا لا يحتاج الويبهوك أي قسمة بعد هذه الهجرة: مصدر الحقيقة للسعر هو
-- الدولار (SHEIN يسعّر بالدولار)، والليرة مشتقّة منه عبر usd_to_syp_rate. فبعد
-- تقسيم السعر على 100 تصير كل القيم المشتقّة بالليرة الجديدة تلقائياً، وتطابق
-- ما يكتبه إشعار شام كاش حرفياً. وتزول أيضاً مشكلة الكسور: خطوة الإزاحة تبقى
-- 1 (ليرة جديدة) فلا تظهر مبالغ مثل 6620.16 يتعذّر تحويلها.
--
-- تحقّق من المصدر (sp-today.com بتاريخ 2026-08-10):
--   USD → SYP (new): Buy 131.20 / Sell 131.70   ويقابلها 13,120 / 13,170 قديمة.
-- فالنسبة 100 بالضبط. نعتمد سعر المبيع 131.70 كما كانت القاعدة سابقاً.
--
-- ما لا تمسّه هذه الهجرة عمداً:
--   • أي عمود بالدولار (amount_usd / price_usd / requested_amount_usd / …)
--     — الدولار لم يتغيّر.
--   • payment_events.parsed_amount — سجلّ تاريخي لما أرسله شام كاش فعلاً
--     لحظتها؛ تعديله يزوّر السجل.
--   • النيّات المعلّقة بالدولار — الدولار غير معنيّ بحذف الأصفار.
--
-- الهجرة idempotent: تتوقف فوراً إذا كان app_settings.syp_denomination = 'new'.

do $$
declare
  already_new text;
  moved_orders integer;
  moved_items integer;
  moved_wallet integer;
begin
  select value into already_new
  from public.app_settings
  where key = 'syp_denomination';

  if already_new = 'new' then
    raise notice 'الليرة الجديدة مطبَّقة سلفاً — لا شيء ليُنفَّذ';
    return;
  end if;

  -- (1) إلغاء كل نيّة دفع معلّقة بالليرة: مبلغها المخزَّن بالقديمة، ولو بقيت
  -- لطلبنا من الزبون مبلغاً خاطئاً بمئة ضعف. الزبون يعيد المحاولة فيحصل على
  -- مبلغ صحيح بالجديدة. النيّات بالدولار تبقى كما هي.
  update public.orders
  set payment_status = 'فشل المطابقة'
  where payment_status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  update public.wallet_topups
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  update public.order_issue_payments
  set status = 'منتهي'
  where status = 'بانتظار الدفع'
    and payment_currency = 'SYP';

  -- (2) كل مبلغ مخزَّن بالليرة ÷ 100.
  update public.orders
  set total_syp = round(coalesce(total_syp, 0) / 100.0)::integer,
      wallet_reserved_syp = round(coalesce(wallet_reserved_syp, 0) / 100.0)::integer,
      payment_amount = case
        when payment_currency = 'SYP' and payment_amount is not null
          then round(payment_amount / 100.0, 2)
        else payment_amount
      end;
  get diagnostics moved_orders = row_count;

  update public.order_items
  set price_syp = round(coalesce(price_syp, 0) / 100.0)::integer;
  get diagnostics moved_items = row_count;

  update public.cart_group_items
  set price_syp = round(coalesce(price_syp, 0) / 100.0)::integer;

  -- رصيد المحفظة يُحسب من sum(amount_syp) في available_wallet_syp، وتحويله
  -- للدولار يقسم على السعر. وبما أن السعر يُقسم على 100 هنا أيضاً، تبقى قيمة
  -- الرصيد بالدولار كما هي بالضبط.
  update public.wallet_transactions
  set amount_syp = round(coalesce(amount_syp, 0) / 100.0)::integer;
  get diagnostics moved_wallet = row_count;

  update public.wallet_topups
  set requested_amount_syp = round(coalesce(requested_amount_syp, 0) / 100.0)::integer,
      payment_amount = case
        when payment_currency = 'SYP'
          then round(payment_amount / 100.0, 2)
        else payment_amount
      end;

  update public.order_issue_payments
  set payment_amount = case
    when payment_currency = 'SYP'
      then round(payment_amount / 100.0, 2)
    else payment_amount
  end;

  update public.coupons
  set min_subtotal_syp = round(coalesce(min_subtotal_syp, 0) / 100.0)::integer;

  update public.coupon_redemptions
  set discount_syp = round(coalesce(discount_syp, 0) / 100.0)::integer;

  update public.payment_verifications
  set amount_syp = round(coalesce(amount_syp, 0) / 100.0)::integer;

  -- (3) الإعدادات: كل مفتاح ينتهي بـ _syp يُقسم على 100، والسعر يُستبدل
  -- بسعر المبيع الجديد. القسمة هنا نصّية لأن العمود text.
  update public.app_settings
  set value = greatest(round(value::numeric / 100.0), 0)::bigint::text
  where key like '%\_syp'
    and value ~ '^\d+(\.\d+)?$';

  insert into public.app_settings (key, value)
  values ('usd_to_syp_rate', '131.70')
  on conflict (key) do update set value = excluded.value;

  insert into public.app_settings (key, value)
  values ('syp_denomination', 'new')
  on conflict (key) do update set value = excluded.value;

  raise notice 'تمّ التحويل للّيرة الجديدة — طلبات: %، بنود: %، حركات محفظة: %',
    moved_orders, moved_items, moved_wallet;
end;
$$;

-- (4) شبكة أمان مزدوجة على صفّ السعر:
--
--   أ. كل دالة تحسب بالليرة تحتوي احتياطياً ثابتاً 13000 يُستعمل إذا غاب صف
--      السعر أو صار صفراً — فلو اختفى الصف لصارت كل الحسابات أعلى بمئة ضعف
--      صامتةً. نمنع حذفه أو إفراغه بدل إعادة كتابة إحدى عشرة دالة (إحداها
--      مخزَّنة بترميز عربي تالف في الإنتاج — إصلاحها مهمة مستقلة).
--
--   ب. الأهم: التطبيق ينادي /api/exchange-rate على سيرفر أوراكل، وذلك الطابع
--      يسحب السعر من sp-today ويكتبه هنا. ونسخة السيرفر الحيّة تقرأ العمود
--      القديم (13,170) وترفض أي رقم أقل من 1000. فلو نُشرت هذه الهجرة ولم
--      يُحدَّث السيرفر يدوياً (لا CI له — scp + pm2 restart)، لأعاد السعر
--      القديم خلال 30 دقيقة وصارت كل الأسعار مئة ضعف بلا أي إنذار.
--      لذلك: بعد اعتماد الليرة الجديدة نرفض أي سعر بحجم الليرة القديمة.
--      النتيجة خطأ صريح في سجلّ السيرفر بدل إفساد صامت للأسعار.
create or replace function public.guard_usd_rate_setting()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  denomination text;
begin
  if tg_op = 'DELETE' then
    if old.key = 'usd_to_syp_rate' then
      raise exception 'usd_to_syp_rate must never be deleted';
    end if;
    return old;
  end if;

  if new.key <> 'usd_to_syp_rate' then
    return new;
  end if;

  if new.value !~ '^\d+(\.\d+)?$' or new.value::numeric <= 0 then
    raise exception 'usd_to_syp_rate must be a positive number, got %', new.value;
  end if;

  select value into denomination
  from public.app_settings
  where key = 'syp_denomination';

  if coalesce(denomination, '') = 'new' and new.value::numeric >= 1000 then
    raise exception
      'usd_to_syp_rate % looks like the OLD Syrian lira; this project moved to the new lira (divide by 100). Update the writer (server/src/routes.js on the Oracle VM, or .github/scripts/update-exchange-rate.mjs) before retrying.',
      new.value;
  end if;

  return new;
end;
$$;

drop trigger if exists app_settings_guard_usd_rate on public.app_settings;
create trigger app_settings_guard_usd_rate
before insert or update or delete on public.app_settings
for each row execute function public.guard_usd_rate_setting();
