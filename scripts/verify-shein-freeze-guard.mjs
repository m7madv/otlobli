import { readFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const projectRoot = resolve(dirname(fileURLToPath(import.meta.url)), '..')

const checks = [
  {
    label: 'persistent patch',
    file: 'patches/@capgo+capacitor-inappbrowser+8.6.25.patch',
    markers: [
      'func otlobliForceRecompose(force: Bool = false)',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      '@objc func appWillEnterForeground(_ notification: NSNotification)',
      'UIApplication.willEnterForegroundNotification',
      'private func otlobliRecomposeAllWebViews()',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'controller.otlobliForceRecompose(force: true)',
      'messageBody["__otlobliRecompose"] as? Bool == true',
      'public void otlobliOnHostResume()',
    ],
  },
  {
    label: 'applied iOS lifecycle patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/InAppBrowserPlugin.swift',
    markers: [
      '@objc func appDidBecomeActive(_ notification: NSNotification)',
      '@objc func appWillEnterForeground(_ notification: NSNotification)',
      'UIApplication.willEnterForegroundNotification',
      'private func otlobliRecomposeAllWebViews()',
      'for delay in [0.12, 0.5, 1.2, 2.2]',
      'controller.otlobliForceRecompose(force: true)',
    ],
  },
  {
    label: 'applied iOS WKWebView patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/ios/Sources/InAppBrowserPlugin/WKWebViewController.swift',
    markers: [
      'func otlobliForceRecompose(force: Bool = false)',
      'webView.removeFromSuperview()',
      'self.view.addSubview(webView)',
      'webView.scrollView.setContentOffset(offset, animated: false)',
      'messageBody["__otlobliRecompose"] as? Bool == true',
    ],
  },
  {
    label: 'applied Android host-resume patch',
    file: 'node_modules/@capgo/capacitor-inappbrowser/android/src/main/java/ee/forgr/capacitor_inappbrowser/WebViewDialog.java',
    markers: [
      'public void otlobliOnHostResume()',
      'webView.onResume()',
      'webView.invalidate()',
      'webView.requestLayout()',
    ],
  },
  {
    label: 'store-region rebuild guard',
    file: 'src/App.tsx',
    markers: [
      'const previousStoreRegionsRef = useRef(storeRegions)',
      'if (JSON.stringify(previous[activeStore]) === JSON.stringify(storeRegions[activeStore])) return',
    ],
  },
]

const failures = []

for (const check of checks) {
  const absolutePath = resolve(projectRoot, check.file)
  let contents
  try {
    contents = readFileSync(absolutePath, 'utf8')
  } catch (error) {
    failures.push(`${check.label}: cannot read ${check.file} (${error.message})`)
    continue
  }

  for (const marker of check.markers) {
    if (!contents.includes(marker)) {
      failures.push(`${check.label}: missing ${JSON.stringify(marker)} in ${check.file}`)
    }
  }
}

if (failures.length > 0) {
  console.error('\nSHEIN iPhone freeze guard FAILED:\n')
  for (const failure of failures) console.error(`- ${failure}`)
  console.error('\nRead docs/SHEIN_IOS_FREEZE_GUARD.md before changing the patch or lifecycle.\n')
  process.exit(1)
}

console.log('SHEIN iPhone freeze guard: OK')
