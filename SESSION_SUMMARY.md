# SESSION_SUMMARY.md

Copy this into a new AI chat before continuing work.

## Start here

Project path:

```text
C:\Users\MOHAMMAD\Projects\SHEIN IN SIRYA
```

Active branch:

```text
codex/customer-wallet-group-orders
```

Before editing, read:

0. `AI_QUICK_HANDOFF.md`
1. `AGENTS.md`
2. `CURRENT_STATE.md`
3. `AI-HANDOFF.md`
4. `CLAUDE.md` if using Claude Code

Then run:

```bash
git status --short
git rev-parse --abbrev-ref HEAD
git log -5 --oneline
```

## آخر عمل (Claude — إخفاء أزرار هيدر تيمو + منع صفحة تسجيل الدخول)

تاريخ: 2026-07-09. اختُبر على محاكي أندرويد `emulator-5554` (`com.otlobli.app`) بصرياً + بالسجلات.

المشكلة والحل الجذري:
- أزرار هيدر تيمو (عربة التسوق / الحساب / الفئات) كلها من نوع `DIV.tab-d3nPD`،
  والبحث `DIV.searchBar-3m_IK`، وكلها كانت داخل حاوية أب `display:none` فأبعادها
  `0x0` — لهذا فشلت كل محاولات الحجب المعتمدة على الموقع/الأبعاد سابقاً، وكانت
  أسماؤها في `aria-label` (أيقونات SVG بلا نص) فتخطّتها الفحوصات النصية أيضاً.
- الحل النهائي (الأسهل والأضمن): حقن CSS في `injectTemuHeaderHideCSS()` داخل
  `src/services/sheinBrowserScript.ts` يستهدف `[class*="tab-d3nPD"]` + aria الدقيق
  (عربة التسوق/الحساب/الفئات) بـ `display:none`. النتيجة: الأزرار الثلاثة تختفي،
  ويبقى البحث والشعار.
- بانر "تسوّق مثل الملياردير" (بانر تنزيل تطبيق تيمو): حاويته الجذر
  `DIV.downloadsWrapper` وتحتها `downloadUI`. أُضيف للـ CSS نفسه
  `[class*="downloadsWrapper"], [class*="downloadUI"]` فاختفى البانر نهائياً.
- إصلاح الوميض (FOUC): كان الإخفاء يُحقن متأخراً عبر tick فتظهر العناصر لحظة عند
  أول دخول أو عند الرجوع من منتج. الحل: `OTLOBLI_TEMU_HIDE_CSS` صار ثابتاً،
  و`injectTemuHeaderHideCSS()` تُحقن **فوراً عند تحميل السكربت** (documentStart،
  في `document.head || document.documentElement`)، ولم تعد تعتمد على flag لمرة
  واحدة بل تفحص وجود `#otlobli-temu-header-hide` فتعيد الحقن لو أزالته تيمو،
  وأُضيفت لدورة الـ 120ms السريعة. تأكّد بتسجيل فيديو + استخراج 42 إطاراً حول
  لحظة الرجوع: كل الإطارات نظيفة، صفر وميض.
- منع صفحة تسجيل الدخول: في `src/App.tsx` داخل معالج `urlChangeEvent`، أُضيف
  `TEMU_LOGIN_RE` — أي انتقال لـ `login.html`/`/login`/`signin`/`login.temu.com`
  يُعاد فوراً إلى `https://www.temu.com/jo/` (مع throttle 3 محاولات/15ث عبر
  `temuLoginBlockRef`). تأكّد بالسجل: النقر على "تسجيل الدخول" أطلق `login.html`
  فاعتُرض وأُعيد للرئيسية دون ظهور صفحة login.

ملاحظات:
- تنظيف: أُزيل كل كود التشخيص المؤقت وحقن force-open shadow DOM (لم يكن هناك shadow).
- الملفان المعدّلان: `src/services/sheinBrowserScript.ts` و `src/App.tsx`.
- اختُبر كامل على محاكي أندرويد؛ نسخة iOS تُبنى عبر workflow `ios-unsigned-build.yml`.

## Critical rule

Do not assume `main` is latest. Do not restore old code from another branch unless manually comparing and cherry-picking only the needed pieces.

Existing staged/untracked files may be work from another AI or the user. Do not revert them.

## Current fragile areas

- SHEIN mobile browsing:
  - must stay on `m.shein.com/ar`
  - country Saudi Arabia
  - currency USD
  - language Arabic
  - `site_uid=pwar`
  - no custom User-Agent spoofing
  - do not broadly overwrite SHEIN storage keys
  - do not treat random country names inside product titles/descriptions as wrong region
- Temu WebView:
  - bottom otlobli nav must remain fixed and visible
  - search must remain visible
  - hide only confirmed Temu account/cart/login distractions, not product content
- Group cart:
  - invite links must work from WhatsApp
  - recipient should confirm linking before joining
  - carts should sync quickly and unlink after order
- Admin:
  - do not auto-open the first order
  - mobile layout is important
  - coupons, drivers, product issues, wallet/order actions are current features
- Payments/wallet:
  - do not change payment/wallet logic unless explicitly requested

## Last confirmed Codex state

- 2026-07-09 group-cart invite fix:
  - `src/App.tsx` now clears a different stale local `cartGroup` when a WhatsApp invite opens, so the recipient sees the confirmation card and can join the host group instead of seeing their old "waiting for friend" state.
  - `android/app/src/main/AndroidManifest.xml` now handles `https://talabieh.vercel.app/group` links in addition to the existing app/deep links.
  - `npm run build` passed after the fix.
- 2026-07-09 group-cart member-key fix:
  - Group membership/items now use a per-device `memberKey`, so two devices using the same WhatsApp phone during testing can still become two distinct members.
  - Creating a group no longer reuses the host's old open group; each create action generates a new code/link.
  - Group totals and per-person shares display via the app currency formatter from SYP totals/exchange rate, avoiding the old `$current / $40` line.
  - Production Supabase migration `20260709_group_cart_member_keys.sql` was pushed, `cart-groups` was deployed, and same-phone/two-member production test returned `members=2` and both owners' products.
- Android APK was built and installed on emulator.
- SHEIN home opened Arabic/Saudi/USD.
- SHEIN product page opened successfully after fixing the Saudi guard.
- AI guardrail files were added so Claude/Codex/other models read current state before editing.
- Dangerous uncommitted Claude WIP that reverted SHEIN to older `/jo` behavior and removed group/wallet schema was backed up to Temp and removed from the working tree.
- Customer/admin builds passed after cleanup.
- Latest iOS unsigned GitHub workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28971384749`
- Previous iOS unsigned workflow succeeded:
  - `https://github.com/m7madv/otlobli/actions/runs/28935943927`
- Supabase customer reset helper exists:
  - `supabase/RESET_CUSTOMER_DATA.sql`
  - Not executed automatically because local env files do not contain a usable Supabase service role/database password.

## Handoff habit

At the end of every long session, update:

- `CURRENT_STATE.md`
- `AI-HANDOFF.md`
- `SESSION_SUMMARY.md`

Then give the user a short Arabic summary with:

- what changed
- what was tested
- what was pushed/built
- what the next AI must read first
