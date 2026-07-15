# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Candidate: local v85.8.20 on top of v85.8.19; exact OneTrust acceptance, trusted SHEIN size binding, and one bounded recovery for a geo-confirmed VPN session that receives SHEIN's short WAF/block document. Not device-proven.
- Stable rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.19.ipa`; run `29452454010`; SHA-256 `0CE0C4480D1D60CCD1BC11787A1C6F69293C13B4F0C1EB7521CF309FFD710F03`.

## Why v85.8.17 Exists

The monolithic capture script had accumulated overlapping permanent loops: full page every 300ms, header/nav every 120ms, security body text every second, cookie/bootstrap every 250ms, plus MutationObserver-triggered ticks. This continuously competed with SHEIN on old WKWebView and was the clean architectural problem to remove before more selector patches.

## Runtime Contract

- SHEIN full maintenance is finite and event-driven: initial load, history/pop/hash navigation, trusted page click, pageshow/foreground, online, or explicit reinjection.
- A newer burst cancels the prior burst; work does not stack.
- The persistent SHEIN MutationObserver may only remount a missing `#otlobli-nav`. It must not call full `tick()`.
- Duplicate injection into one document must call `window.__otlobliRequestMaintenance` and return.
- Saudi repair may repeat only while `sheinNativeCoverRepairActive` and must stop within 15 seconds.
- Cookie/frame/bootstrap observers are bounded and disconnected after hydration.
- Temu keeps its prior scheduler and was not part of this refactor.
- The InAppBrowser must not place its launch-image privacy overlay over a live store for ordinary iOS `willResignActive` transitions; that overlay was the confirmed Notification Center white flash.
- Cookie handling must gate the top SHEIN document before a fresh consent surface paints, click only exact `Accept all` / `قبول الكل` in its owning frame, and release after acceptance. The mutation path stays bounded and may not become another polling loop.

## v85.8.20 Runtime Notes

- Prefer OneTrust's exact accept button and native click handler. `AllowAll()` alone grants categories but is not the documented banner-dismiss action.
- Size selection must accept a real trusted tap for the same product even if SHEIN replaces the option node or adds invisible RTL markers. Never restore acceptance of an automatic multi-option default; final `DE/EU/US` rejection stays in both script and bridge.
- `sheinBlocked` after a confirmed non-Syrian geo uses the one existing bounded fresh-WebView/cache recovery, then reports preparation if repeated. Do not falsely reject a confirmed US/Germany/etc. server without new network evidence.

## Failed Paths / Do Not Reintroduce

- v86-v88, `hidden + FAKE_VISIBLE`, broad CSS, viewport widening, broad storage clearing, reload/setUrl loops, or full SHEIN script at documentStart.
- Do not change payment, wallet, completed orders, Temu, or cart design during this SHEIN pass.
- Do not call the issue fixed until iPhone 6 and iPhone 16 Pro Max pass the acceptance list in `CURRENT_STATE.md`.

## Next Step

Build/install v85.8.20. Fresh-install checks: consent is accepted before reveal, a manually selected size is captured, an untouched multi-option default is rejected, and US VPN entry does not receive a false server warning after the bounded recovery. Separately test v85.8.19's Notification Center change, which remains untested.
