# SHEIN v86.196 clean runtime diagnostic

This is a diagnostic protocol, not a production acceptance test and not a fix.
The build preserves the v86.193 store behavior while collecting passive runtime
evidence. Do not clear website data, disable scripts, reload, or use a synthetic
tap during the test.

## Capture setup

1. Sign and install v86.196/1058 after deleting the previously installed app.
2. Connect the iPhone to a Mac, trust the computer, enable **Settings → Safari →
   Advanced → Web Inspector**, and enable Safari's **Develop** menu on the Mac.
3. Before opening Otlobli, open macOS **Console**, select the connected iPhone
   under **Devices**, start streaming, and filter for subsystem
   `com.otlobli.app` and category `SheinCleanRuntime`. Export or copy the
   filtered text as `Otlobli-v86.196-SHEIN-runtime.log` after the reproduction.
   A normal macOS
   `log stream` command reads the Mac, not the attached iPhone, and must not be
   substituted for the device stream.

4. Enter SHEIN for the first time. In Safari choose **Develop → [iPhone] →
   [SHEIN page]**. Preserve the Console and Network logs, but do not enable any
   option that disables cache or changes storage. Record the Sources error,
   Console stack, failed Network requests/responses, and the Storage/Service
   Worker state.
5. Confirm the first entry is interactive. Leave the inspector and unified-log
   capture running, open the App Switcher, and kill Otlobli.
6. Cold-launch Otlobli, enter SHEIN again, and attach Safari to the newly listed
   inspectable page. Do not reload or clear anything. Reproduce the frozen state,
   then export the Console and Network evidence from this second page.
7. Stop the unified-log capture only after the second frozen state is recorded.

The native log uses a new `runId` and PID after the App Switcher kill. That is
the boundary between the successful first process and the frozen second process.
Each evidence record is Base64 chunked so an exact JavaScript message and stack
cannot be silently truncated by unified logging.

## Decode the native evidence

From the repository root:

```bash
npm run decode:shein-runtime -- /path/to/Otlobli-v86.196-SHEIN-runtime.log \
  > Otlobli-v86.196-SHEIN-runtime.jsonl
```

The decoder fails if a record is incomplete. Keep the raw log, decoded JSONL,
Safari Console export/screenshots, Network HAR, and both run IDs together. The
diagnostic records JavaScript errors/rejections, resource errors and bounded
resource timings, storage fingerprints/counts, navigation timing, document/app
lifecycle, native navigation callbacks, the WKWebView/data-store/process-pool
identities, and WebContent termination. Cookie and storage values are never
logged; URL query strings and fragments are stripped.
