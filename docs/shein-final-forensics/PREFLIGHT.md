# SHEIN final forensics preflight

Captured: 2026-08-21 (Asia/Riyadh)

## Repository identity

- Worktree: `C:\Users\MOHAMMAD\Projects\otlobli-ios-v86-205-shein-clean-room-selector-fix`
- Branch: `codex/ios-v86-205-shein-clean-room-selector-fix`
- HEAD: `846de3798e5decc4e46fb9e7ca40e90c74e201f7`
- HEAD subject: `docs(ios): record selector fix artifact`
- Working tree before this document: clean and equal to the remote branch.
- iOS version/build in `project.pbxproj`: `86.205/1067`.
- Installed physical-device version/build: `86.205/1067` (`com.otlobli.app`).
- Installed app data container: recorded by the private AFC/app-container service for tool routing only; it is deliberately omitted from this report because it is installation-specific.
- Installed build signing identity: development signed; minimum iOS `15.0`.

## Protected evidence history

The protected and evidence-bearing refs resolve to their recorded commits:

- `codex/ios-v86-193-passive-native-foreground`: `a6e0ca943c4d9a2722b5962a4193d3e34d2da248`
- `codex/ios-v86-194-root-cause-diagnostic`: `9a91e9f6680d1dce48ae5a04bfe6544d8d26b954`
- `codex/ios-v86-202-root-cause-timeline-diagnostic`: `2d7332cd5b6a3a3d87b4d1bab32efe8cb9919df0`
- `codex/ios-v86-203-shein-prefetch-cache-fix`: `de255a935ce3a985c05694f36899ff34d7585103` (the preserved behavior commit remains `c914b52c2dbc539a196d4d74385b350fffd20577`).

No protected ref was reset, rebased, moved, merged into, or rewritten during preflight. The legacy plugin remains byte-identical at SHA-256 `6A6D6A16A5EED040618988C9D5B5AC6D8F88DDD187F4BC095C0F1C1AA710382E`.

The preserved v86.202 evidence hashes match the handoff:

- unified log: `C631A88843ECEE42FCE6A52F21837A99B9F6798B1421D210C9689EB4951E9C67`
- CDP network capture: `0C10A637A91E804816CAA8FF6294CDC2C693BA1351D6DDF30EC25BEE63E27A3D`
- chunk `68498` cache record: `93673AE71EC2ED5870A7D207EFD2DACC969FE155787BA33D1A0FD59DD68B70AF`
- chunk `26652` cache record: `A346B7B024D3A2F83BBD33D80494A51B9867F8BE13263E6B78FA1B7491B5E4F5`

## Clean-room implementation locations

- Mode definitions, cache-rule identity, and fixed v86.205 profile IDs:
  `ios/App/App/SheinCleanBrowser/SheinCleanBrowserMode.swift`
- Selector, browser ownership, presentation, and native event forwarding:
  `ios/App/App/SheinCleanBrowser/SheinCleanBrowserPlugin.swift`
- WKWebView construction, lifecycle/navigation IDs, native chrome, and logging:
  `ios/App/App/SheinCleanBrowser/SheinCleanBrowserViewController.swift`
- Passive diagnostics plus independent Capture and Blocking modules:
  `ios/App/App/SheinCleanBrowser/SheinCleanBrowserScripts.swift`
- React/native backend ownership:
  `src/services/storeBrowser.ts` and `src/App.tsx`
- CDP recorder, native-log decoder, and network analyzer:
  `scripts/capture-shein-cdp-network.mjs`,
  `scripts/decode-shein-clean-room-log.mjs`, and
  `scripts/analyze-shein-cdp-network.mjs`.

## Physical device and available diagnostics

- USB device: iPhone 16 Pro Max, `iPhone17,2`, iOS `27.0` beta (`24A5380h`).
- Target UDID: `00008140-001E6D581E11801C`; the USB identity matches exactly.
- Required Windows tool: bundled `pymobiledevice3 10.10.0` at
  `C:\Users\MOHAMMAD\.codex\tools\ios-usb-diagnostics\Scripts\pymobiledevice3.exe`.
- DeveloperDiskImage: mounted read-only at `/System/Developer`; personalized image services are available.
- Unified logging: `syslog live` with JSON/text output, subsystem/category/PID filtering, and file output.
- Web Inspector/CDP: native `webinspector cdp` bridge on `127.0.0.1:9222`; the existing recorder consumes its browser-level endpoint.
- Process identity: DVT process list and bundle-ID-to-PID lookup; the app was not running at preflight (`PID 0`).
- Screenshot capture: DVT screenshot command.
- App-container evidence: private app AFC pull can copy diagnostic files and WebKit records without mutation.
- Cache inspection: existing v86.202 read-only record evidence and app-container pull are available. A scenario pull must occur only after capture is stopped and must never remove or alter website data.
- Existing v86.205 native events include app PID, run ID, browser ID, WebView ID, navigation ID, container ID, lifecycle, WebContent termination, root snapshots, event-loop heartbeat, click reaction, ChunkLoadError, and relevant resource timing.

## Measurements still missing

No current v86.205 run has a synchronized operator-marker, unified-log, CDP, PID/WebContent, screenshot, and cache-record bundle. Therefore these remain unmeasured for Incident A and Incident B:

- whether the reported leave/re-enter sequence was hide/show, background/foreground, or a true cold process;
- the first v86.205 failing PID, WebView ID, document ID, navigation ID, and earliest divergence;
- whether the first observed `CAPTURE + BLOCKING` container was genuinely unused;
- the Script versus XHR/Fetch/raw classification and response-body state for each current required chunk;
- whether the current freezes contain a bodyless-304/ChunkLoadError sequence;
- the exact WebContent process identity correlated with each app PID;
- per-operation Capture/Blocking timing and root fingerprints;
- clean-install, in-place-upgrade, hide/show, background/foreground, and ten-cycle cold-launch acceptance.

## Installed-build sufficiency decision

The installed v86.205 build is sufficient to verify that the selector can open a clean controller and to collect a non-authoritative observation from its existing fixed profiles. It is **not sufficient for final causal capture**:

1. every clean mode is hard-wired to one persistent UUID;
2. the operator has already exercised multiple modes, including container `720b1500-0a4b-4a00-9000-000000000004`;
3. the app cannot create a fresh persistent scenario container or reuse one generated ID across a controlled first/second process;
4. consequently, v86.205 cannot prove first-entry freshness or separate prior contamination from module interaction.

One additional forensic IPA is therefore required and authorized by the task. Its scope must be diagnostic infrastructure only: select/generate a unique persistent scenario identifier before WKWebView creation, persist it across the scenario's processes, display/log it, add owned-operation measurements, and preserve all website data. It must not clear cache/storage, alter requests, recover by reload, or contain a speculative freeze fix.

