# RevenueCat setup

## Implemented

- Product IDs: `voicebrief_pro_monthly`, `voicebrief_pro_annual`.
- Entitlement: `pro`; offering: `default`.
- Supabase user UUID becomes RevenueCat App User ID after authentication.
- Localized product price strings come from RevenueCat in production; checked-in QAR strings exist only in the fake repository.
- Purchase cancellation/failure, restore, login/logout, and store subscription management links are handled.
- Webhook authorization, UUID validation, event replay protection, out-of-order event protection, and atomic server entitlement/quota update are implemented.

## Owner/dashboard work

1. Create one subscription group and monthly/annual auto-renewing products in App Store Connect; create matching Google Play subscriptions/base plans.
2. Target 29 QAR/month and 229 QAR/year, but configure regional pricing in the stores.
3. Import products to RevenueCat, attach entitlement `pro`, and add both packages to offering `default`.
4. Add public iOS/Android SDK keys to private Dart defines.
5. Set the RevenueCat App User ID to the authenticated Supabase UUID (the repository already calls `Purchases.logIn`).
6. Configure webhook URL `https://PROJECT.supabase.co/functions/v1/revenuecat-webhook` with Authorization `Bearer YOUR_RANDOM_SECRET`; store only the random value as `REVENUECAT_WEBHOOK_SECRET`.

The live webhook URL is `https://jyehqpdbayslhzebdycj.supabase.co/functions/v1/revenuecat-webhook`, and the function is deployed. On 2026-08-24 the RevenueCat dashboard was at its login screen, so no account/app/product/offering or public SDK key was created without owner sign-in. Configure the random webhook secret only after the RevenueCat project exists so the same value can be placed in both systems without entering source control.

## Verification

- New verified account gets 10 lifetime free minutes.
- Monthly and annual sandbox purchases grant the same Pro features and a 300-minute subscription period.
- Annual is selected by default but monthly remains selectable; prices/currency match the store locale.
- Cancellation does not revoke access before expiration; renewal creates/updates the new quota period; older out-of-order events cannot roll back newer state.
- Restore works after reinstall/device change, logout clears local customer state, and webhook replay reports `duplicate: true` without resetting quota.

Store products and subscriptions are not created or purchased automatically by this repository.
