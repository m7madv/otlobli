# SHEIN v86.202 root-cause timeline diagnostic

This build is instrumentation, not a freeze fix. It starts from exact v86.201
commit `0b462a93030b5c7114012d5848ce61eac49b8b17`, preserves its store behavior,
and uses version/build `86.202/1064` only because those numbers were verified
unused before the branch was created.

## Passive boundary

The only page namespace added is `window.__otlobliRootCauseProbe`. It does not:

- modify the SHEIN document;
- prevent, stop, replay, or synthesize input;
- patch `fetch`, `XMLHttpRequest`, console methods, or history methods;
- reload, navigate, clear data, or write cookies/storage;
- export the removed v86.194/v86.195 tap context or `SHEIN_REQUIRED_COUNTRY`.

Two timers run at bounded diagnostic cadence: a 400 ms event-loop kick and a
one-second aggregate report. The MutationObserver heartbeat mutates only a
detached Text node that is never attached to SHEIN. Interaction listeners are
capture/passive and stop recording after 60 bounded events.

Swift adds read-only unified logging, Web Inspector access, native view-state
snapshots, safe back-forward paths, navigation callbacks, and cookie
names/counts. Its app lifecycle observers only log and request a probe snapshot;
they never reload, detach, reattach, hide, show, or rebuild the WKWebView.

No cookie value, storage value, query, fragment, address, token, or personal
field is logged. Storage records contain key names, counts, and approximate
character sizes only. IndexedDB records contain database names/versions; Cache
Storage contains cache names; Service Worker records contain sanitized scopes,
script paths, and worker states.

## Evidence identity

Every native record contains:

- `runId` and app PID;
- `browserId`;
- diagnostic `webViewId` plus native `ObjectIdentifier`;
- `navigationId`;
- native sequence and timestamp.

Every web record also contains `documentId`, probe version, page sequence,
timestamp, visibility/focus/ready state, sanitized path, and the same native
context. An App Switcher kill is therefore a new run/PID; a new document inside
one retained WKWebView changes only document/navigation identity.

## What is measured

- Promise, `queueMicrotask`, timeout, interval, rAF, MutationObserver, and
  MessageChannel heartbeat counts/ages;
- `visibilitychange`, `pageshow/pagehide` with `persisted`, focus/blur,
  freeze/resume, DOMContentLoaded/load, beforeunload, online/offline, popstate,
  and hashchange;
- real pointer/touch/click target and `elementFromPoint`, followed by reaction
  snapshots at +50/+250/+1000 ms;
- URL/history/root-structure/body/interactives/scripts/images/skeletons/frames;
- performance navigation type/timing and bounded resource timing evidence;
- JavaScript errors, unhandled rejections, resource errors, and CSP violations;
- storage/session metadata only;
- WKWebView/surface windows, superviews, hierarchy depth, hidden/alpha/
  interaction flags, frames/bounds, gestures, host controller containment,
  app/scene state, process pool, website data store, history, and termination.

## USB capture setup

On the iPhone enable **Settings → Apps → Safari → Advanced → Web Inspector**.
Do not enable cache disabling and do not clear Safari/website data.

With the device connected, mount the matching DeveloperDiskImage once and then
start the log before launching the app:

```powershell
& 'C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe' mounter auto-mount --userspace
& 'C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe' syslog live --userspace --subsystem com.otlobli.app --category SheinRootCause --label --out 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-raw.log'
```

The logging command stays running for the complete matrix. Do not stop it
between background/foreground or App Switcher kill/cold-launch tests.

When a manual label is requested, evaluate this in the inspectable SHEIN page:

```js
window.__otlobliRootCauseProbe.snapshot('FIRST_GOOD')
```

Replace the label with the exact matrix label. This call only records a
snapshot; it does not alter SHEIN.

## Reproduction matrix

Run tests independently and do not infer same-WKWebView behavior from a killed
process.

### A — first good

1. Clean-install the diagnostic IPA only if the first-install state is required.
2. Launch Otlobli and open SHEIN.
3. Open two or three products and return normally.
4. Confirm categories/products remain interactive.
5. Record `FIRST_GOOD`.

### B — internal navigation

1. At working home record `INTERNAL_BEFORE_TRIGGER`.
2. Open product → Back, then another product → Back.
3. Exercise the current root-Back behavior once.
4. Record `INTERNAL_TRIGGER`, then either `INTERNAL_WORKING` or
   `INTERNAL_FROZEN` according to the actual state.

v86.201 already guards root Back by returning to the chooser instead of
reloading history. Do not remove that accepted guard to manufacture the older
reload trigger.

### C — chooser park/show

1. In working SHEIN record `PARK_BEFORE`.
2. Return to the store chooser through the current UI.
3. Reopen SHEIN without killing/backgrounding the app.
4. Record `SHOW_WORKING` or `SHOW_FROZEN` before random repeated taps.

Native logging also emits automatic `PARK_BEFORE`, `PARKED`, `SHOW_BEFORE`, and
`SHOW_AFTER` snapshots.

### D — background/foreground

1. Record `BACKGROUND_BEFORE`.
2. Send Otlobli to the background without killing it.
3. Return once and record `FOREGROUND_AFTER`.

Native and page lifecycle stages are automatic.

### E — App Switcher kill/cold launch

1. Record the current run as `COLD_FIRST_PROCESS`.
2. Kill Otlobli from App Switcher.
3. Cold-launch it and enter SHEIN.
4. Record `COLD_NEW_PROCESS`, then `COLD_ENTRY_WORKING` or
   `COLD_ENTRY_FROZEN`.

## Decode and compare

```powershell
npm run decode:shein-root-cause -- 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause-raw.log' > 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause.jsonl'
npm run analyze:shein-root-cause -- 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-root-cause.jsonl' --good=FIRST_GOOD --frozen=SHOW_FROZEN > 'C:\Users\MOHAMMAD\Desktop\Otlobli-v86.202-comparison.json'
```

The decoder fails on missing Base64 chunks. Preserve the raw log. The analyzer
compares web/native snapshots, heartbeat ages, identities, relevant errors, and
a timeline around the frozen label. Final causal analysis must still inspect
the event order; a final-state difference alone is not a root cause.
