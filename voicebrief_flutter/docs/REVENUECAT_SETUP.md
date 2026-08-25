# RevenueCat setup

## Implemented

- Product IDs: `voicebrief_pro_monthly`, `voicebrief_pro_annual`.
- Entitlement: `pro`; offering: `default`.
- Supabase user UUID becomes RevenueCat App User ID after authentication.
- Localized product price strings come from RevenueCat in production; checked-in QAR strings exist only in the fake repository.
- Purchase cancellation/failure, restore, login/logout, and store subscription management links are handled.
- Webhook authorization, UUID validation, event replay protection, out-of-order event protection, and atomic server entitlement/quota update are implemented.

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
- The RevenueCat dashboard still redirects to login, so no project, store import, entitlement, offering, SDK keys, or webhook secret has been configured there.

## Remaining owner/dashboard work

1. Re-run `scripts/google_play_subscriptions.mjs --activate` after Google finishes propagating the VoiceBrief grant. If the owner-session Save still fails, open a Play Console support case with the reproduced message and account/app IDs; after Google clears the account-side condition, verify both plans report `ACTIVE`.
2. Attach both Apple subscriptions to the next app-version submission and add review screenshots.
3. Log in to RevenueCat, import the Apple and Google products, attach entitlement `pro`, and add both packages to offering `default`.
4. Add public iOS/Android SDK keys to private Dart defines.
5. Set the RevenueCat App User ID to the authenticated Supabase UUID (the repository already calls `Purchases.logIn`).
6. Configure webhook URL `https://jyehqpdbayslhzebdycj.supabase.co/functions/v1/revenuecat-webhook` with Authorization `Bearer YOUR_RANDOM_SECRET`; store only the random value as `REVENUECAT_WEBHOOK_SECRET`.

The live webhook URL is `https://jyehqpdbayslhzebdycj.supabase.co/functions/v1/revenuecat-webhook`, and the function is deployed. On 2026-08-26 the RevenueCat dashboard was still at its login screen, so no account/app/product/offering or public SDK key was created without owner sign-in. Configure the random webhook secret only after the RevenueCat project exists so the same value can be placed in both systems without entering source control.

## Verification

- New verified account gets 10 lifetime free minutes.
- Monthly and annual sandbox purchases grant the same Pro features and a 300-minute subscription period.
- Annual is selected by default but monthly remains selectable; prices/currency match the store locale.
- Cancellation does not revoke access before expiration; renewal creates/updates the new quota period; older out-of-order events cannot roll back newer state.
- Restore works after reinstall/device change, logout clears local customer state, and webhook replay reports `duplicate: true` without resetting quota.

Store products are now created in both stores, but Google base plans and all RevenueCat dashboard objects remain incomplete. No purchase was made.
