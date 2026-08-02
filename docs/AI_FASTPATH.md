# AI Fast Path — read this to work CHEAP and FAST on otlobli

Purpose: stop burning tokens/credits re-deriving context. Follow this before touching SHEIN/Temu capture code.

## Golden rules (cost)

1. **Never read `src/services/sheinBrowserScript.ts` whole.** It is ~550 KB / ~10k lines and ships as one string under a hard budget. Use the function map below + `Read(offset, limit)` to read only the 30–60 lines you need.
2. **For any "wrong color/size/price in cart" bug: get the on-device `تشخيص` report FIRST** (red button, bottom-left of the store page → «نسخ»). It prints the exact captured `color|size|key`, the container classes, and the last add-to-cart payload. One report replaces an hour of reading. Do not guess from product screenshots — the DOM is what matters.
3. **Verify on the real device with REAL taps, not synthetic clicks.** Synthetic `dispatchEvent('click')` does NOT reliably trigger SHEIN's selection listeners (e.g. the price/variant MutationObserver in `sheinTrackSelectedSkuPrice`), so it gives false negatives. Use `adb shell input tap`.
4. **Batch edits, build once.** The perf budget (`largest JS raw` ≤ 1,200,000) has tiny headroom; adding shipped bytes usually means trimming an Arabic comment elsewhere. Plan the trims, then one `npm run build`.
5. **Windows worktree has `git core.autocrlf=true`** → it inflates the local SHEIN-source byte count (CRLF). The committed blob is LF; keep the file LF if the source-raw budget trips only locally.

## Device debug playbook (the proven fast path)

Device: Galaxy Note 8 `988e16384e4f51395230` (screenless; ADB works). See `docs`/memory `project_note8_adb_recovery` for ADB re-auth.

```bash
# 1. build + install (env lives in MAIN repo root, gitignored)
cp ../../.env ../../.env.local ../../.env.relay.local .   # from main repo root into worktree
node scripts/inject-relay-key.cjs
npm run build && npx cap sync android
(cd android && ./gradlew assembleDebug)                    # needs android/local.properties: sdk.dir=...
adb -s <serial> install -r android/app/build/outputs/apk/debug/app-debug.apk

# 2. open the WebView over CDP
adb -s <serial> shell input keyevent KEYCODE_WAKEUP
adb -s <serial> shell cat /proc/net/unix | tr -d '\000' | grep -o 'webview_devtools_remote_[0-9]*'
adb -s <serial> forward tcp:9222 localabstract:webview_devtools_remote_<pid>
curl -s http://127.0.0.1:9222/json          # find the m.shein.com page ws URL

# 3. drive + inspect (real device DOM, no rebuild)
node scripts/otlobli-cdp.mjs <ws> nav "https://m.shein.com/ar/...-p-<id>.html"
printf '%s' "JSON.stringify({k:window.__otlobliDiag.key(),c:window.__otlobliDiag.color(),s:window.__otlobliDiag.size()})" > /tmp/d.js
node scripts/otlobli-cdp.mjs <ws> eval /tmp/d.js
```

Cart ground truth: the app cart lives on the `https://localhost/` page in `localStorage['talabieh.cartsByStore']`.

## Function map — `src/services/sheinBrowserScript.ts`

Two shipped strings: `OTLOBLI_NAV_BOOTSTRAP_SCRIPT` (line ~64) and `SHEIN_CAPTURE_SCRIPT` (line ~420, everything below). Diagnostics overlay is a SEPARATE file `src/services/sheinPriceDiagnostics.ts` (not in the SHEIN-source budget).

Capture / SKU (the usual suspects for color/size/price bugs):
- `sheinTrackSelectedSkuPrice` ~2554 — click listener; sets up the price MutationObserver + stashes the committed variant (color/size/image) at selection time.
- `getPrice` ~2640, `sheinSelectedSkuPricePending` ~2631 — price, incl. committed-mutation fallback when the drawer closes.
- `sheinIsQuantityEl` ~2891 — excludes the "الكمية" group (title can be a non-sibling ancestor).
- `findOptionContainer` ~2914, `getSelectedWithin` ~3029, `sheinLooksVisuallySelected` ~3016 — pick the color/size container + the selected option.
- `getColorState` ~3347, `getSizeState` ~3403, `sheinDrawerCompoundSizeState` ~3378, `sheinPageColorHeading` ~3337.
- `getSelectedColorSwatchImage` ~3292, `swatchImageFrom` ~3232, `getMainImage` ~2862.
- `captureProductPayload` ~5225 — builds the addToCart payload (dedup + committed-variant preference live here).
- `addToCartFlow` ~5333, `sheinOpenSkuDrawer` ~3474, `sheinSkuSelectionEntry` ~3445, `showAddingOverlay` ~5571.

Region/shipping guard: ~652–2311. Temu: ~3706–5210 and ~7520–9520. (Line numbers drift; re-grep `^\s*function \w+` if off.)

## Current state

- Branch `claude/color-capture-fixes-v8655`; version `v86.57` (`917`).
- Fixed + device-verified (real taps → cart `localStorage`):
  - swan tray `p-517537202` → `color=لون القرنفل`, `size=""` (no `1PC` leak).
  - jewelry tray `p-534350565` → `color=أخضر داكن` + green swatch image (drawer color = the variant committed at price-mutation time, so a closed sheet no longer ships the stale main-page `أرجواني أحمر`).
