# RevenueCat setup

## Implemented

- Product IDs: `voicebrief_pro_monthly`, `voicebrief_pro_annual`.
- Entitlement: `pro`; offering: `default`.
- Supabase user UUID becomes RevenueCat App User ID after authentication.
- Localized product price strings come from RevenueCat in production; checked-in QAR strings exist only in the fake repository.
- Purchase cancellation/failure, restore, login/logout, and store subscription management links are handled.
- Webhook authorization, UUID validation, event replay protection, out-of-order event protection, and atomic server entitlement/quota update are implemented.
- RevenueCat confirmation is reconciled with a rate-limited authenticated `sync-subscription` request followed by bounded retries. The request may confirm only a Pro generation already established by the signed webhook/`TRANSFER`; untrusted client input can never create a new 300-minute generation. A missing purchase/transfer webhook therefore remains pending and fails closed instead of exposing a refilled balance, while an authoritative Free snapshot can repair a missed expiration.
- Pro always grants 300 minutes per anchored monthly window. A monthly purchase has one window, while an annual purchase normally has 12 independent windows; restore/replay keeps existing usage instead of refilling the current window.
- Every subscription-state webhook uses a fresh server-side RevenueCat Customer Info snapshot. A lagging `TRANSFER` remains retryable while any source RevenueCat alias—including an anonymous alias—is still Pro; exactly one stored destination UUID must match before mutation. Transfer moves the quota high-water mark atomically and revokes source access only after reconciliation. Non-subscription webhook types are audited and ignored without changing access.
- Billing grace extends the final paid quota window without creating another 300-minute refill.
- Server quota generations prevent historical product windows from being selected after a product change. An App Store renewal received before its future billing-period start temporarily keeps the prior active quota, then switches automatically at the server timestamp without granting 300 minutes early. Flutter reads this as one atomic server RPC and never decides entitlement from the device clock.
- Migrations `20260902010000_monthly_subscription_quota.sql` and `20260902011000_revenuecat_special_events.sql` plus the updated `revenuecat-webhook` and `sync-subscription` must be deployed together before a build containing this client reconciliation is released; source presence alone does not change the live quota.

## Store dashboard state — 2026-08-26

- App Store Connect app `VoiceBrief` (`6805194629`) now has subscription group `VoiceBrief Pro` (`22335194`).
- Apple products are created and localized in Arabic and English:
  - `voicebrief_pro_monthly` (`6805232846`), one month, `29.99 QAR` in Qatar with Apple-managed regional pricing.
  - `voicebrief_pro_annual` (`6805233746`), one year, `229.00 QAR` in Qatar with Apple-managed regional pricing.
- Both Apple products are `Prepare for Submission`. Their first submission must be attached to a new app version, and review screenshots are still required.
- Google Play app `VoiceBrief` (`4973918177043935523`, package `app.voicebrief.mobile`) exists in developer account `SAMIR KHALED ALZOUBI` (`8441225038702199576`). Products `voicebrief_pro_monthly` and `voicebrief_pro_annual` are created with Arabic names and benefits.
- A production-configured `0.1.0 (7)` AAB was uploaded to an internal-release draft to unlock monetization. The uploaded AAB is 58,909,813 bytes with SHA-256 `B314E144FB3F19769D3668F03EAFCC168A1E877401124511071CE2EC099919A3`; it is signed with the private VoiceBrief upload key and `jarsigner -verify` passes with the expected self-signed upload-certificate warnings.
- Google Play currently rejects both fully populated base plans with the dashboard message `تعذَّر حفظ التغييرات.`. This first reproduced for monthly and annual plans with only Qatar selected. A final owner-session retry selected all 177 current/future regions, successfully converted the monthly seed price and displayed Qatar at the exact `29.00 QAR`, but the subsequent Save still failed with the same dashboard message. Therefore the catalog values are valid, but neither Google base plan is saved or active yet. The closest attractive annual price calculated by Google in the earlier console attempt was `230.00 QAR`; the API automation preserves the requested exact Qatar price of `229.00 QAR`.
- Service account `damanak-play-verifier@damanak-production.iam.gserviceaccount.com` now has VoiceBrief-only access with the minimum explicit permissions for financial viewing, order/subscription management, and store-presence/product management. Play Console confirmed `تم تحديث تفاصيل المستخدم.` The Developer API immediately changed subscription reads from `403` to `200`, but price conversion and base-plan writes still return `The caller does not have permission`; Google documents that permission changes may take time to propagate. Because an account-owner Play Console save also fails after price conversion, treat this as an unresolved Google account-side monetization/save condition rather than an application-data or request-shape error.
- `scripts/google_play_subscriptions.mjs` safely inspects the two existing products, refuses to replace partial configuration, converts the exact `29/229 QAR` seed prices into regional prices, creates `monthly`/`annual` auto-renewing base plans, and activates them only with `--activate`. It accepts either a service-account JSON environment value or a private-key path and never writes credentials to its report. Current reports under `build/google-play-subscriptions/` confirm both plans are still `MISSING` and activation is permission-blocked.
- The separate Google Play developer account reached through `mhm1981x@gmail.com` is `Mohammad samir Alzouabi` (`7616754513484681287`). It cannot publish because Google reports failed identity verification and an unconfirmed contact phone, and it does not contain the current VoiceBrief app. Do not move the app or change developer-account permissions without owner approval.
- RevenueCat project `VoiceBrief` exists with project ID `59213dad`. Entitlement `pro` and offering `default` are active. The monthly and annual packages each contain their matching App Store and Google Play products; the onboarding lifetime package remains Test Store-only and is not offered by either production app.
- RevenueCat App Store app `VoiceBrief (App Store)` was saved successfully with app ID `app85cd86a950`, bundle ID `app.voicebrief.mobile`, In-App Purchase key ID `49HN3HGNM2`, and Apple Issuer ID `631dc2f6-b1d1-423e-8617-d3d37fc4514a`. RevenueCat displayed `App created successfully`; the private P8 remains outside Git.
- RevenueCat Google Play app `VoiceBrief (Play Store)` was saved successfully with app ID `appa60d40b8c1` and package `app.voicebrief.mobile`. The uploaded service-account JSON remains private outside Git at `C:\Users\MOHAMMAD\.voicebrief\google\revenuecat-play-service-account.json`; its SHA-256 is `60BF02E2D1AD0C9AE2B2321A4EC207B7EAD0134C38D52AC5D467E15D56497107`, and its Windows ACL allows only the current user and SYSTEM.
- RevenueCat products were created manually because automatic import was unavailable: App Store monthly `prodd7310149f3`, App Store annual `prod917a173c57`, Google monthly `prod4fffb4ba55` (`voicebrief_pro_monthly:monthly`), and Google annual `prode9c5469afa` (`voicebrief_pro_annual:annual`). All four are attached to entitlement `pro`; monthly products are mapped to `$rc_monthly`, and annual products to `$rc_annual` in offering `default`.
- The public SDK keys generated for both production apps are stored as GitHub Actions secrets `VOICEBRIEF_REVENUECAT_IOS_PUBLIC_SDK_KEY` and `VOICEBRIEF_REVENUECAT_ANDROID_PUBLIC_SDK_KEY`. Build `0.1.0+8` is the first source version prepared to consume them. Signed run `32922142795` was accepted by Apple, completed processing as TestFlight build `71d308f7-b859-46ec-9d56-7622e58ffe79`, and is attached to `VoiceBrief Internal`. RevenueCat still shows the account email as unconfirmed, and no sandbox purchase has been completed yet.

## Remaining owner/dashboard work

1. Re-run `scripts/google_play_subscriptions.mjs --activate` after Google finishes propagating the VoiceBrief grant. If the owner-session Save still fails, open a Play Console support case with the reproduced message and account/app IDs; after Google clears the account-side condition, verify both plans report `ACTIVE`.
2. Attach both Apple subscriptions to the next app-version submission and add review screenshots.
3. Confirm the RevenueCat account email.
4. Install TestFlight build `0.1.0 (8)`, then complete Apple sandbox purchase and restore checks. Repeat on Android only after Google saves and activates both base plans.

The live webhook URL is `https://jyehqpdbayslhzebdycj.supabase.co/functions/v1/revenuecat-webhook`, and the function is deployed. On 2026-08-26 both store connections, all four production product mappings, entitlement `pro`, offering `default`, and both public SDK build keys were completed. A 32-byte random secret was stored only as Supabase secret `REVENUECAT_WEBHOOK_SECRET` and the matching `Bearer` authorization value was saved in RevenueCat webhook `whintgr41c91a4676` (`VoiceBrief Supabase`) for production and sandbox events. The stored digest matched the generated value, and an unauthenticated request returned `401`; a RevenueCat test event has not been sent yet.

The updated webhook and authenticated `sync-subscription` function require the backend-only project secret `REVENUECAT_SECRET_API_KEY` for `GET /v1/subscribers/{app_user_id}`; the same server secret is used by account deletion for `DELETE` and must never be bundled in Flutter. Confirm this Supabase secret exists before deploying the migration/functions together.

## Verification

- New verified account gets 10 lifetime free minutes.
- Monthly and annual sandbox purchases grant the same Pro features and 300 minutes per month; the annual period is split into 12 anchored monthly quota windows.
- Annual is selected by default but monthly remains selectable; prices/currency match the store locale.
- Cancellation does not revoke access before expiration; renewal creates/updates the new quota period; older out-of-order events cannot roll back newer state.
- Restore works after reinstall/device change, logout clears local customer state, and webhook replay reports `duplicate: true` without resetting the current month's quota.

RevenueCat's production store connections, product-to-entitlement links, offering package mappings, public SDK build keys, and authorized Supabase webhook are configured. Google base plans, account email confirmation, a webhook test event, and sandbox purchases remain incomplete. No purchase was made.
