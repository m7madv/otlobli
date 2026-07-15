# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Candidate: v85.8.19 local, native iOS inactive-state white-flash fix on top of v85.8.18; not device-proven.
- Stable rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- IPA: `C:\Users\MOHAMMAD\Desktop\otlobli-v85.8.18.ipa`; run `29446101794`; SHA-256 `ABF792A41F8A1BF3271B3B793DD21C2769F1E04F96362B6A8D1AC40EFCF666DB`.

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

## Failed Paths / Do Not Reintroduce

- v86-v88, `hidden + FAKE_VISIBLE`, broad CSS, viewport widening, broad storage clearing, reload/setUrl loops, or full SHEIN script at documentStart.
- Do not change payment, wallet, completed orders, Temu, or cart design during this SHEIN pass.
- Do not call the issue fixed until iPhone 6 and iPhone 16 Pro Max pass the acceptance list in `CURRENT_STATE.md`.

## Next Step

Build/install v85.8.19, then pull and dismiss Notification Center repeatedly over both SHEIN and Temu on iPhone 6 and iPhone 16 Pro Max. The current store frame must remain visible with no white flash or reload. Continue the v85.8.18 consent and repeated-navigation checks afterward.
