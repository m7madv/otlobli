# Otlobli AI Handoff

Read `CURRENT_STATE.md`, then `AGENTS.md`, before editing.

## Current Candidate

- Branch: `codex/customer-wallet-group-orders`.
- Candidate: v85.8.17, event-driven SHEIN runtime; not device-proven.
- Stable rollback/reference: v85.8.5 / `a914d81` and the user-provided v85.8.5 IPA.
- Last built artifact remains v85.8.16 until the v85.8.17 CI build completes.

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

## Failed Paths / Do Not Reintroduce

- v86-v88, `hidden + FAKE_VISIBLE`, broad CSS, viewport widening, broad storage clearing, reload/setUrl loops, or full SHEIN script at documentStart.
- Do not change payment, wallet, completed orders, Temu, or cart design during this SHEIN pass.
- Do not call the issue fixed until iPhone 6 and iPhone 16 Pro Max pass the acceptance list in `CURRENT_STATE.md`.

## Next Step

Build the v85.8.17 unsigned IPA, verify the embedded marker/hash, then test repeated SHEIN entry and several minutes of product/gallery/back navigation on both phones. If a device still freezes, collect the matching WebKit/app console or Apple Jetsam/crash log before adding another workaround.
