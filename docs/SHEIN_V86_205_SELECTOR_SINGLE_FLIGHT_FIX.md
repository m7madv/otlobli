# SHEIN v86.205 clean-room selector single-flight fix

Status: built and archive-inspected candidate; physical confirmation is
pending. This version fixes the selector/open transaction only. It does not
change RAW, the cache rule, capture, blocking, mode profiles, or the legacy
browser, and it does not claim the SHEIN freeze is fixed.

## Physical symptom from v86.204

The native mode selector appeared. Choosing any of its six options dismissed
the selector and returned to Otlobli with:

`A SHEIN clean-room session or mode selector is already active`

This common result across every mode occurs before mode-specific WebView
behavior, so it is a selector/open ownership failure, not a RAW, guard,
capture, blocking, or SHEIN-page result.

## Root cause

`StoreBrowser.openWebView()` set `activeBackend = 'clean-shein'` only after the
native promise resolved. That promise deliberately remains pending while the
user reads the selector. During that interval the host still appeared to own
no clean session. A delayed settings/region effect could therefore reset the
legacy singleton flags and schedule another open while the first native
selector remained active.

The second native call correctly rejected as a duplicate. Its React rejection
handler then cleared `sheinOpenedRef`, returned to the chooser, and caused the
first successfully selected result to be treated as stale and closed. This is
why every selector option produced the same failure.

## Fix boundary

- Mark the backend `clean-shein` before awaiting the selector; cancel/error
  rolls it back safely.
- Add `cleanRoomOpenInFlightRef`, independent from legacy WebView flags, to
  suppress a second open for the entire selector transaction.
- Do not run the old damaged-session cache reset for a clean-room entry.
- Clear the selector controller identity before its dismissal animation.
- Lock selector interaction after the first Select or Cancel tap.
- A host Close now cancels and dismisses a pending selector and rejects the
  pending open with `SHEIN_CLEAN_SELECTION_CANCELLED`.
- Duplicate native opens are logged with structured state and code
  `SHEIN_CLEAN_OPEN_ACTIVE`; the customer UI no longer exposes the raw English
  native error.

The legacy bounded cache-reset path remains enabled and guarded outside clean
mode. `OtlobliSheinBrowserPlugin.swift` remains byte-identical at SHA-256
`6a6d6a16a5eed040618988c9d5b5ac6d8f88ddd187f4bc095c0f1c1aa710382e`.

## Version and branch

- Version/build: `86.205/1067`
- Branch: `codex/ios-v86-205-shein-clean-room-selector-fix`
- Worktree:
  `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-205-shein-clean-room-selector-fix`
- Base: v86.204 final handoff commit
  `5b1b687d195f57227e9da28a68fc4e1cfa8492c0`
- Marker: `2026.08.21-v86.205-shein-clean-room-selector-fix`

## Regression proof

`verify:shein-clean-room` now requires:

- the clean backend assignment to occur before the selector await;
- the dedicated React single-flight state;
- clean-mode exclusion from the old cache reset;
- selector identity clearing before dismissal;
- a one-tap selection lock and coded cancellation.

The existing freeze guard still requires the bounded legacy damaged-session
cache-reset path and now also requires the explicit clean-room exclusion.

Local TypeScript, the changed TypeScript file's ESLint, full production build,
release hardening, performance, SHEIN freeze/clean-room, Temu, store-surface,
Capacitor iOS sync, and `git diff --check` pass.

## Required physical confirmation

1. Install signed v86.205 over v86.204 or as a clean install.
2. Tap SHEIN once and confirm exactly one selector appears.
3. Choose RAW and confirm the clean controller opens instead of returning to
   the chooser.
4. Close it natively, re-enter immediately, and choose RAW again.
5. Open the selector, press Cancel, then immediately re-enter.
6. Repeat one open with each remaining mode. Each must reach its correct
   controller, or the unchanged legacy controller for Mode 5.
7. Confirm no `duplicate-open-rejected` or customer-facing
   `SHEIN_CLEAN_OPEN_ACTIVE` error occurs.
8. Only after this selector acceptance should the v86.204 RAW/guard causal
   protocol continue unchanged.

## Delivery record

- Implementation commit:
  `23282957a14ddc363f430379105780098ce057e9`.
- GitHub Actions run/job: `32422731308` / `96598044268`; success in `3m40s`.
- Artifact ID/name: `9426368736` /
  `otlobli-ios-v86.205-ipad-iphone-universal`.
- Artifact archive digest:
  `sha256:4c1b3e485ff244efa03e7ef03c26d245618c15fe40afa64e2a00752b2781bbca`.
- IPA path:
  `C:\Users\MOHAMMAD\Documents\Codex\2026-08-21\shein-current-state-handoff-md-c\outputs\otlobli-ios-v86.205-ipad-iphone-universal\otlobli-v86.205-ipad-iphone-universal-unsigned.ipa`.
- IPA size: `6,638,066` bytes.
- IPA SHA-256:
  `90BE1FC810DDB5F2CC1F8420661C8E96ED765328C28EE75C457C0F750A3452E0`.
- Inspection: `com.otlobli.app`, `86.205/1067`, ARM64, iOS 15+,
  iPhone/iPad `[1,2]`, unsigned/unprovisioned, no source maps.
- Built markers present: `[OTLOBLI_SHEIN_CLEAN]`,
  `SHEIN_CLEAN_OPEN_ACTIVE`, `SHEIN_CLEAN_SELECTION_CANCELLED`,
  `RAW_WITH_CACHE_GUARD`, and the exact content-rule identity.
- Physical selector acceptance: pending.
