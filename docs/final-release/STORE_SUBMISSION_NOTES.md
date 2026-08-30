# Store submission notes and checklist

## Candidate release notes (Arabic)

> حسّنا موثوقية فتح المتاجر والتنقل بينها، ونظّفنا أدوات الفحص الداخلية من
> نسخة العملاء. أضفنا تسجيل الدخول عبر Google على iPhone وخيار Sign in with
> Apple، وإدارة الإشعارات بشكل أفضل، وإمكانية حذف الحساب من داخل التطبيق.

Do not publish these notes until the corresponding physical OAuth/push tests
pass.

## App Review notes draft

- Otlobli is a purchasing/intermediation application. SHEIN and Temu pages are
  displayed only to browse public categories/products and select product
  variants for Otlobli's cart.
- Third-party store login, account, checkout, country, region, language, and
  currency controls are intentionally unavailable. Users authenticate only to
  Otlobli through phone, Google, or Apple.
- SHEIN may present its own human-verification challenge. Otlobli leaves that
  challenge visible and the reviewer completes it manually; the app does not
  bypass it.
- Account deletion: Profile → **حذف الحساب نهائياً**, then confirm twice.
- Notifications are used for order/payment/wallet and service updates. They are
  optional; denied users can open system Settings from the notification screen.
- The cart explains the exact remaining amount when the minimum order is not
  met. Customization and availability blockers include an actionable Arabic
  reason, and tapping the checkout action always returns visible feedback.
- A normal pending order keeps the exact two-hour payment window returned by
  the server. Wallet top-ups and payments created to resolve an order issue use
  their separate five-minute window; the app displays the server deadline.
- Supply a review/demo account only after confirming its login method works in
  the review environment. Never place a password in this repository.

## Submission checklist

- Verify signed artifact contains `86.244/1112`, Bundle ID/package
  `com.otlobli.app`, correct production APNs entitlement, Sign in with Apple,
  and no diagnostic markers/source maps.
- Verify public privacy policy, support URL, account-deletion page/instructions,
  and domain association files.
- Complete App Privacy and Google Play Data safety declarations from actual
  collected data and SDK behavior.
- Prepare required iPhone/iPad and Android screenshots without diagnostic UI or
  third-party personal data.
- Complete age rating/content declarations and permission explanations.
- Run the physical matrix and attach sanitized evidence to the reports.
- Upload only after explicit owner authorization. This task does not submit.
