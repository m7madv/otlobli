import UIKit
import WebKit
import Capacitor
import OSLog

@objc(SheinCleanBrowserPlugin)
public final class SheinCleanBrowserPlugin: CAPPlugin, CAPBridgedPlugin,
    SheinCleanBrowserViewControllerDelegate {

    public let identifier = "SheinCleanBrowserPlugin"
    public let jsName = "SheinCleanBrowser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "openWebView", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "executeScript", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "postMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearCache", returnType: CAPPluginReturnPromise)
    ]

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.otlobli.app",
        category: "SheinCleanBrowser"
    )

    private var activeController: SheinCleanBrowserViewController?
    private var pendingOpenCall: CAPPluginCall?
    private var selectorNavigationController: UINavigationController?

    @objc func openWebView(_ call: CAPPluginCall) {
        guard let rawURL = call.getString("url"),
              let requestedURL = URL(string: rawURL),
              isSheinURL(requestedURL) else {
            call.reject("A valid SHEIN URL is required")
            return
        }

        DispatchQueue.main.async {
            guard self.pendingOpenCall == nil, self.activeController == nil,
                  self.selectorNavigationController == nil else {
                self.log("duplicate-open-rejected", [
                    "hasPendingCall": self.pendingOpenCall != nil,
                    "hasSelector": self.selectorNavigationController != nil,
                    "hasController": self.activeController != nil
                ])
                call.reject(
                    "A SHEIN clean-room session or mode selector is already active",
                    "SHEIN_CLEAN_OPEN_ACTIVE"
                )
                return
            }
            guard let presenter = self.presentationController() else {
                call.reject("Capacitor host controller is unavailable")
                return
            }

            self.pendingOpenCall = call
            let selector = SheinCleanModeSelectorViewController()
            selector.onCancel = { [weak self] in self?.cancelModeSelection() }
            selector.onSelect = { [weak self] mode in self?.select(mode: mode) }
            let navigation = UINavigationController(rootViewController: selector)
            navigation.modalPresentationStyle = .fullScreen
            self.selectorNavigationController = navigation
            self.log("mode-selector-presented", [
                "requestedUrl": self.safeURL(requestedURL),
                "requestedOptionsIgnored": true
            ])
            presenter.present(navigation, animated: true)
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let controller = self.activeController,
                  controller.presentingViewController != nil || controller.navigationController?.presentingViewController != nil else {
                call.reject("Clean browser sessions are dismissed, not parked; open a new locked session")
                return
            }
            self.log("host-show-noop", ["mode": controller.mode.wireName])
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if self.dismissPendingSelector(
                reason: "host-hide-cancels-selector",
                completion: { call.resolve() }
            ) { return }
            self.log("host-hide-dismisses-session")
            self.dismissActiveController(emitCloseEvent: true, reason: "host-hide") { call.resolve() }
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if self.dismissPendingSelector(
                reason: "host-close-cancels-selector",
                completion: { call.resolve() }
            ) { return }
            if let requestedId = call.getString("id"),
               let active = self.activeController,
               !requestedId.isEmpty,
               requestedId != active.browserId {
                call.resolve()
                return
            }
            self.log("host-close-dismisses-session")
            self.dismissActiveController(emitCloseEvent: true, reason: "host-close") { call.resolve() }
        }
    }

    @objc func setUrl(_ call: CAPPluginCall) {
        log("host-set-url-rejected", ["reason": "mode-locked-clean-room"])
        call.reject("setUrl is disabled for the locked clean-room session")
    }

    @objc func executeScript(_ call: CAPPluginCall) {
        log("host-execute-script-rejected", ["reason": "production-script-isolation"])
        call.reject("Host script execution is disabled for clean-room modes")
    }

    @objc func postMessage(_ call: CAPPluginCall) {
        // Acknowledge host chrome/capture messages without evaluating anything
        // in the page. This keeps legacy runtime state outside the clean WebView.
        log("host-post-message-ignored", ["reason": "production-bridge-isolation"])
        call.resolve()
    }

    @objc func clearCache(_ call: CAPPluginCall) {
        // Mode containers are evidence. Never clear or mutate them implicitly.
        log("host-cache-clear-ignored", ["reason": "persistent-mode-evidence"])
        call.resolve()
    }

    private func select(mode: SheinCleanBrowserMode) {
        guard let call = pendingOpenCall, let selector = selectorNavigationController else { return }
        log("mode-selected", [
            "mode": mode.wireName,
            "container": mode.dataStoreIdentity,
            "cacheGuard": mode.usesCacheGuard,
            "capture": mode.usesCapture,
            "blocking": mode.usesBlocking,
            "implementation": mode.browserImplementation
        ])
        // Release the selector identity before its dismissal animation. The
        // host becomes visible during that transition; retaining this pointer
        // until completion caused an immediate retry to be rejected as stale.
        selectorNavigationController = nil
        selector.dismiss(animated: true) { [weak self] in
            guard let self else { return }
            if mode == .legacyControl {
                self.pendingOpenCall = nil
                call.resolve([
                    "implementation": "legacy-control",
                    "mode": mode.wireName,
                    "diagnosticVersion": SheinCleanBrowserMode.diagnosticVersion
                ])
                return
            }
            self.prepareCleanBrowser(mode: mode, call: call)
        }
    }

    private func cancelModeSelection() {
        _ = dismissPendingSelector(reason: "mode-selection-cancelled") {}
    }

    @discardableResult
    private func dismissPendingSelector(
        reason: String,
        completion: @escaping () -> Void
    ) -> Bool {
        guard let pending = pendingOpenCall else { return false }
        let selector = selectorNavigationController
        pendingOpenCall = nil
        selectorNavigationController = nil
        log(reason)
        selector?.dismiss(animated: true)
        pending.reject(
            "SHEIN clean-room mode selection was cancelled",
            "SHEIN_CLEAN_SELECTION_CANCELLED"
        )
        completion()
        return true
    }

    private func prepareCleanBrowser(mode: SheinCleanBrowserMode, call: CAPPluginCall) {
        guard #available(iOS 17.0, *) else {
            pendingOpenCall = nil
            log("clean-open-rejected", ["reason": "persistent-profile-data-store-unavailable"])
            call.reject("Clean modes require iOS 17 or newer for isolated persistent website-data profiles")
            return
        }
        guard let identifier = mode.dataStoreIdentifier else {
            pendingOpenCall = nil
            call.reject("The selected clean mode has no persistent profile identifier")
            return
        }

        let dataStore = WKWebsiteDataStore(forIdentifier: identifier)
        if mode.usesCacheGuard {
            guard let store = WKContentRuleListStore.default() else {
                pendingOpenCall = nil
                log("clean-open-rejected", ["reason": "content-rule-store-unavailable"])
                call.reject("The cache-guard content-rule store is unavailable")
                return
            }
            store.compileContentRuleList(
                forIdentifier: SheinCleanBrowserContentRule.identifier,
                encodedContentRuleList: SheinCleanBrowserContentRule.json
            ) { [weak self] rule, error in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let rule, error == nil else {
                        self.pendingOpenCall = nil
                        self.log("clean-open-rejected", [
                            "reason": "content-rule-compile-failed",
                            "error": error?.localizedDescription ?? "compiled rule unavailable"
                        ])
                        call.reject("The exact raw-only cache guard could not compile or attach")
                        return
                    }
                    self.presentCleanBrowser(mode: mode, dataStore: dataStore, contentRule: rule, call: call)
                }
            }
            return
        }

        presentCleanBrowser(mode: mode, dataStore: dataStore, contentRule: nil, call: call)
    }

    private func presentCleanBrowser(
        mode: SheinCleanBrowserMode,
        dataStore: WKWebsiteDataStore,
        contentRule: WKContentRuleList?,
        call: CAPPluginCall
    ) {
        guard pendingOpenCall === call, let presenter = presentationController() else {
            pendingOpenCall = nil
            call.reject("Capacitor host controller became unavailable")
            return
        }
        let runId = UUID().uuidString.lowercased()
        let browserId = "otlobli-shein-clean-\(UUID().uuidString.lowercased())"
        let controller = SheinCleanBrowserViewController(
            mode: mode,
            runId: runId,
            browserId: browserId,
            websiteDataStore: dataStore,
            contentRule: contentRule
        )
        controller.delegate = self
        let navigation = UINavigationController(rootViewController: controller)
        navigation.modalPresentationStyle = .fullScreen
        activeController = controller
        pendingOpenCall = nil
        presenter.present(navigation, animated: true) {
            self.log("clean-open-resolved", [
                "mode": mode.wireName,
                "runId": runId,
                "browserId": browserId,
                "container": mode.dataStoreIdentity,
                "contentRuleAttached": contentRule != nil
            ])
            call.resolve([
                "id": browserId,
                "implementation": "clean-controller",
                "mode": mode.wireName,
                "runId": runId,
                "websiteDataContainer": mode.dataStoreIdentity,
                "contentRuleAttached": contentRule != nil,
                "captureEnabled": mode.usesCapture,
                "blockingEnabled": mode.usesBlocking,
                "diagnosticVersion": SheinCleanBrowserMode.diagnosticVersion
            ])
        }
    }

    private func dismissActiveController(
        emitCloseEvent: Bool,
        reason: String,
        completion: @escaping () -> Void
    ) {
        guard let controller = activeController else {
            completion()
            return
        }
        let closingId = controller.browserId
        activeController = nil
        let presented = controller.navigationController ?? controller
        presented.dismiss(animated: true) {
            if emitCloseEvent {
                self.notifyListeners("closeEvent", data: ["id": closingId, "url": "", "reason": reason])
            }
            completion()
        }
    }

    func cleanBrowser(_ controller: SheinCleanBrowserViewController, didEmit event: String, data: [String: Any]) {
        guard controller === activeController else { return }
        notifyListeners(event, data: data)
    }

    func cleanBrowserDidClose(_ controller: SheinCleanBrowserViewController) {
        guard controller === activeController else { return }
        let closingId = controller.browserId
        activeController = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.notifyListeners("closeEvent", data: [
                "id": closingId,
                "url": "",
                "reason": "native-close"
            ])
        }
    }

    private func presentationController() -> UIViewController? {
        var controller = bridge?.viewController
        while let presented = controller?.presentedViewController,
              !presented.isBeingDismissed {
            controller = presented
        }
        return controller
    }

    private func isSheinURL(_ url: URL) -> Bool {
        guard let host = url.host?.lowercased() else { return false }
        return host == "shein.com" || host.hasSuffix(".shein.com")
    }

    private func safeURL(_ url: URL) -> String {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        return components?.url?.absoluteString ?? ""
    }

    private func log(_ event: String, _ fields: [String: Any] = [:]) {
        var payload = fields
        payload["event"] = event
        payload["prefix"] = "[OTLOBLI_SHEIN_CLEAN]"
        payload["diagnosticVersion"] = SheinCleanBrowserMode.diagnosticVersion
        payload["at"] = Int64(Date().timeIntervalSince1970 * 1000)
        let safe = payload.mapValues { value -> Any in
            let text = String(describing: value)
            return text.count > 500 ? String(text.prefix(500)) : value
        }
        let data = try? JSONSerialization.data(withJSONObject: safe, options: [.sortedKeys])
        let json = data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        Self.logger.notice("[OTLOBLI_SHEIN_CLEAN] \(json, privacy: .public)")
    }
}

private final class SheinCleanModeSelectorViewController: UITableViewController {
    var onSelect: ((SheinCleanBrowserMode) -> Void)?
    var onCancel: (() -> Void)?
    private var selectionLocked = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SHEIN Clean-Room"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelPressed)
        )
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "mode")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 190
        tableView.accessibilityIdentifier = "shein-clean-mode-selector"
    }

    @objc private func cancelPressed() {
        guard !selectionLocked else { return }
        selectionLocked = true
        navigationItem.leftBarButtonItem?.isEnabled = false
        tableView.isUserInteractionEnabled = false
        onCancel?()
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        SheinCleanBrowserMode.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "Select one mode. It stays locked for the entire browser session."
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "Diagnostic \(SheinCleanBrowserMode.diagnosticVersion). Clean modes use persistent, isolated profiles on iOS 17+. No mode clears another mode's data."
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mode = SheinCleanBrowserMode.allCases[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = mode.title
        cell.textLabel?.font = .preferredFont(forTextStyle: .headline)
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.font = .preferredFont(forTextStyle: .caption1)
        cell.detailTextLabel?.text = """
        \(mode.summary)
        Container: \(mode.dataStoreIdentity)
        Foundation: \(mode.foundationName)
        Cache guard: \(mode.usesCacheGuard ? "attached before first request" : mode == .legacyControl ? "legacy-owned" : "absent")
        Capture: \(mode.usesCapture ? "enabled" : "absent") · Blocking: \(mode.usesBlocking ? "enabled" : "absent")
        Browser: \(mode.browserImplementation)
        """
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "shein-clean-mode-\(mode.rawValue)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !selectionLocked else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let mode = SheinCleanBrowserMode.allCases[indexPath.row]
        if mode.usesCleanController {
            if #unavailable(iOS 17.0) {
                let alert = UIAlertController(
                    title: "Persistent isolation unavailable",
                    message: "Clean modes require iOS 17 or newer. Use LEGACY CONTROL on this device; do not compare modes with a shared default cache.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        }
        selectionLocked = true
        navigationItem.leftBarButtonItem?.isEnabled = false
        tableView.isUserInteractionEnabled = false
        onSelect?(mode)
    }
}
