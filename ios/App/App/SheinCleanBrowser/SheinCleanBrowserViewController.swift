import UIKit
import WebKit
import OSLog

protocol SheinCleanBrowserViewControllerDelegate: AnyObject {
    func cleanBrowser(_ controller: SheinCleanBrowserViewController, didEmit event: String, data: [String: Any])
    func cleanBrowserDidClose(_ controller: SheinCleanBrowserViewController)
}

final class SheinCleanBrowserViewController: UIViewController,
    WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    static let guestLandingURL = URL(string: "https://m.shein.com/")!
    private static let diagnosticHandler = "otlobliCleanDiagnostics"
    private static let blockingHandler = "otlobliCleanBlocking"
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.otlobli.app",
        category: "SheinCleanBrowser"
    )

    weak var delegate: SheinCleanBrowserViewControllerDelegate?

    let mode: SheinCleanBrowserMode
    let runId: String
    let browserId: String
    let webViewId: String
    let dataStoreIdentity: String

    private let websiteDataStore: WKWebsiteDataStore
    private let contentRule: WKContentRuleList?
    private var webView: WKWebView!
    private var didLoadGuestLanding = false
    private var didCleanUp = false
    private var navigationSequence = 0
    private var navigationId = "navigation-0"
    private var diagnosticSequence = 0
    private var lifecycleObservers: [NSObjectProtocol] = []

    init(
        mode: SheinCleanBrowserMode,
        runId: String,
        browserId: String,
        websiteDataStore: WKWebsiteDataStore,
        contentRule: WKContentRuleList?
    ) {
        self.mode = mode
        self.runId = runId
        self.browserId = browserId
        self.webViewId = "clean-webview-\(UUID().uuidString.lowercased())"
        self.websiteDataStore = websiteDataStore
        self.dataStoreIdentity = mode.dataStoreIdentity
        self.contentRule = contentRule
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let root = UIView(frame: .zero)
        root.backgroundColor = .systemBackground

        let userContentController = WKUserContentController()
        if let contentRule {
            userContentController.add(contentRule)
        }
        userContentController.add(self, name: Self.diagnosticHandler)
        if mode.usesBlocking {
            userContentController.add(self, name: Self.blockingHandler)
        }
        for script in SheinCleanBrowserScripts.userScripts(for: mode, runId: runId) {
            userContentController.addUserScript(script)
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = websiteDataStore
        configuration.userContentController = userContentController

        let cleanWebView = WKWebView(frame: .zero, configuration: configuration)
        cleanWebView.translatesAutoresizingMaskIntoConstraints = false
        cleanWebView.navigationDelegate = self
        cleanWebView.uiDelegate = self
        cleanWebView.backgroundColor = .systemBackground
        cleanWebView.scrollView.backgroundColor = .systemBackground
        if #available(iOS 16.4, *) {
            cleanWebView.isInspectable = true
        }
        webView = cleanWebView

        root.addSubview(cleanWebView)
        NSLayoutConstraint.activate([
            cleanWebView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            cleanWebView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            cleanWebView.topAnchor.constraint(equalTo: root.safeAreaLayoutGuide.topAnchor),
            cleanWebView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])
        view = root

        configureNativeChrome()
        installLifecycleObservers()
        log("controller-created", [
            "userScriptCount": userContentController.userScripts.count,
            "contentRuleAttached": contentRule != nil,
            "captureEnabled": mode.usesCapture,
            "blockingEnabled": mode.usesBlocking,
            "guestUrl": safeURL(Self.guestLandingURL)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log("controller-visible", hierarchyFields())
        guard !didLoadGuestLanding else { return }
        didLoadGuestLanding = true
        log("guest-load-requested", ["url": safeURL(Self.guestLandingURL)])
        webView.load(URLRequest(url: Self.guestLandingURL))
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            cleanUp()
        }
    }

    deinit {
        cleanUp()
    }

    private func configureNativeChrome() {
        title = mode.title
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closePressed)
        )
        let back = UIBarButtonItem(
            title: "Back",
            style: .plain,
            target: self,
            action: #selector(backPressed)
        )
        back.accessibilityIdentifier = "shein-clean-back"
        navigationItem.rightBarButtonItems = mode.usesCapture
            ? [UIBarButtonItem(
                title: "Add to Otlobli",
                style: .done,
                target: self,
                action: #selector(addPressed)
            ), back]
            : [back]
        updateBackButton()
    }

    @objc private func closePressed() {
        log("close-pressed", hierarchyFields())
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            self.cleanUp()
            self.delegate?.cleanBrowserDidClose(self)
        }
    }

    @objc private func backPressed() {
        let root = isCanonicalSheinRoot(webView.url)
        log("back-pressed", [
            "canGoBack": webView.canGoBack,
            "canonicalRoot": root,
            "url": safeURL(webView.url)
        ])
        guard webView.canGoBack, !root else {
            updateBackButton()
            return
        }
        webView.goBack()
    }

    @objc private func addPressed() {
        guard mode.usesCapture else { return }
        let script = "window.__otlobliCleanCapture && window.__otlobliCleanCapture.snapshot ? window.__otlobliCleanCapture.snapshot() : null"
        webView.evaluateJavaScript(script) { [weak self] result, error in
            guard let self else { return }
            if let error {
                self.log("capture-evaluation-failed", ["error": self.safeText(error.localizedDescription)])
                self.showCaptureAlert("Product capture could not run on this page.")
                return
            }
            guard let snapshot = result as? [String: Any],
                  snapshot["isProductPage"] as? Bool == true,
                  var product = snapshot["product"] as? [String: Any],
                  let title = product["title"] as? String,
                  !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.log("capture-rejected-not-product", ["url": self.safeURL(self.webView.url)])
                self.showCaptureAlert("Open a SHEIN product page before adding it to Otlobli.")
                return
            }

            let documentId = snapshot["documentId"] as? String ?? ""
            product["title"] = self.safeText(title, limit: 300)
            product["link"] = self.safeURLString(product["link"] as? String)
            self.log("capture-emitted", [
                "documentId": documentId,
                "hasPrice": (product["priceUsd"] as? NSNumber)?.doubleValue ?? 0 > 0,
                "hasColor": !(product["color"] as? String ?? "").isEmpty,
                "hasSize": !(product["size"] as? String ?? "").isEmpty
            ])
            self.delegate?.cleanBrowser(self, didEmit: "messageFromWebview", data: [
                "id": self.browserId,
                "detail": [
                    "type": "addToCart",
                    "protocolVersion": 1,
                    "moduleVersion": snapshot["moduleVersion"] as? String ?? "1.0.0",
                    "documentId": documentId,
                    "navigationId": self.navigationId,
                    "product": product
                ]
            ])
        }
    }

    private func showCaptureAlert(_ message: String) {
        guard presentedViewController == nil else { return }
        let alert = UIAlertController(title: "SHEIN Clean Capture", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func updateBackButton() {
        guard let back = navigationItem.rightBarButtonItems?.last else { return }
        back.isEnabled = webView?.canGoBack == true && !isCanonicalSheinRoot(webView?.url)
    }

    private func isCanonicalSheinRoot(_ url: URL?) -> Bool {
        guard let url,
              let host = url.host?.lowercased(),
              host == "shein.com" || host.hasSuffix(".shein.com") else { return false }
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if path.isEmpty { return true }
        return path.range(of: #"^[a-z]{2}(?:-[a-z]{2})?$"#, options: .regularExpression) != nil
    }

    private func installLifecycleObservers() {
        let names: [(Notification.Name, String)] = [
            (UIApplication.willResignActiveNotification, "will-resign-active"),
            (UIApplication.didEnterBackgroundNotification, "did-enter-background"),
            (UIApplication.willEnterForegroundNotification, "will-enter-foreground"),
            (UIApplication.didBecomeActiveNotification, "did-become-active"),
            (UIApplication.didReceiveMemoryWarningNotification, "memory-warning")
        ]
        for (name, label) in names {
            lifecycleObservers.append(NotificationCenter.default.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.log("lifecycle", self.hierarchyFields().merging(["event": label]) { current, _ in current })
            })
        }
    }

    private func cleanUp() {
        guard !didCleanUp else { return }
        didCleanUp = true
        log("controller-cleanup", hierarchyFields())
        for observer in lifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        lifecycleObservers.removeAll()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.diagnosticHandler)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: Self.blockingHandler)
    }

    func requestPassiveSnapshot(reason: String) {
        let encoded = Self.jsonString(reason)
        webView.evaluateJavaScript("window.__otlobliCleanDiagnosticProbe && window.__otlobliCleanDiagnosticProbe.snapshot(\(encoded))") { _, _ in }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.webView === webView else { return }
        if message.name == Self.diagnosticHandler,
           let body = message.body as? [String: Any] {
            log("web-probe", sanitizeDictionary(body))
            return
        }
        if message.name == Self.blockingHandler,
           let body = message.body as? [String: Any] {
            log("blocking-event", sanitizeDictionary(body))
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationSequence += 1
        navigationId = "navigation-\(navigationSequence)"
        log("navigation-start", ["url": safeURL(webView.url)])
        updateBackButton()
    }

    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        log("navigation-redirect", ["url": safeURL(webView.url)])
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        log("navigation-commit", ["url": safeURL(webView.url)])
        updateBackButton()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        log("navigation-finish", ["url": safeURL(webView.url)])
        updateBackButton()
        requestPassiveSnapshot(reason: "navigation-finish")
        delegate?.cleanBrowser(self, didEmit: "browserPageLoaded", data: [
            "id": browserId,
            "url": safeURL(webView.url),
            "cleanMode": mode.wireName
        ])
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        log("navigation-provisional-failure", [
            "url": safeURL(webView.url),
            "error": safeText(error.localizedDescription)
        ])
        updateBackButton()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        log("navigation-failure", [
            "url": safeURL(webView.url),
            "error": safeText(error.localizedDescription)
        ])
        updateBackButton()
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        // Evidence only. No reload, recreation, recovery, or store switch.
        log("webcontent-terminated", ["url": safeURL(webView.url)])
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        // Keep the one-WebView invariant. A target=_blank navigation is loaded
        // in the existing view instead of creating a second rendering process.
        if navigationAction.targetFrame == nil, let requestURL = navigationAction.request.url {
            log("single-webview-new-window-navigation", ["url": safeURL(requestURL)])
            webView.load(navigationAction.request)
        }
        return nil
    }

    private func hierarchyFields() -> [String: Any] {
        let applicationState: String
        switch UIApplication.shared.applicationState {
        case .active: applicationState = "active"
        case .inactive: applicationState = "inactive"
        case .background: applicationState = "background"
        @unknown default: applicationState = "unknown"
        }
        return [
            "applicationState": applicationState,
            "viewLoaded": isViewLoaded,
            "viewInWindow": viewIfLoaded?.window != nil,
            "webViewInWindow": webView?.window != nil,
            "webViewHidden": webView?.isHidden ?? true,
            "webViewAlpha": Double(webView?.alpha ?? 0),
            "webViewInteractionEnabled": webView?.isUserInteractionEnabled ?? false,
            "presentedController": presentedViewController.map { String(describing: type(of: $0)) } ?? "none",
            "webViewCount": webView == nil ? 0 : 1
        ]
    }

    private func log(_ event: String, _ fields: [String: Any] = [:]) {
        diagnosticSequence += 1
        var payload = sanitizeDictionary(fields)
        payload["prefix"] = "[OTLOBLI_SHEIN_CLEAN]"
        payload["event"] = event
        payload["sequence"] = diagnosticSequence
        payload["at"] = Int64(Date().timeIntervalSince1970 * 1000)
        payload["runId"] = runId
        payload["mode"] = mode.wireName
        payload["diagnosticVersion"] = SheinCleanBrowserMode.diagnosticVersion
        payload["appPid"] = ProcessInfo.processInfo.processIdentifier
        payload["webContentPid"] = "unavailable-public-api"
        payload["browserId"] = browserId
        payload["webViewId"] = webViewId
        payload["navigationId"] = navigationId
        payload["websiteDataContainer"] = dataStoreIdentity
        payload["contentRuleIdentifier"] = mode.contentRuleIdentity
        payload["contentRuleAttached"] = contentRule != nil
        let json = Self.jsonString(payload)
        Self.logger.notice("[OTLOBLI_SHEIN_CLEAN] \(json, privacy: .public)")
    }

    private func sanitizeDictionary(_ input: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        for (key, value) in input {
            let lower = key.lowercased()
            if lower.contains("token") || lower.contains("cookie") || lower.contains("address") ||
                lower.contains("account") || lower.contains("storagevalue") {
                continue
            }
            output[key] = sanitizeValue(value)
        }
        return output
    }

    private func sanitizeValue(_ value: Any) -> Any {
        if let text = value as? String {
            if text.contains("://") { return safeURLString(text) }
            return safeText(text)
        }
        if let dictionary = value as? [String: Any] { return sanitizeDictionary(dictionary) }
        if let array = value as? [Any] { return Array(array.prefix(40)).map(sanitizeValue) }
        if value is NSNumber || value is NSNull { return value }
        return safeText(String(describing: value))
    }

    private func safeURL(_ url: URL?) -> String {
        guard let url else { return "" }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil
        return components?.url?.absoluteString ?? ""
    }

    private func safeURLString(_ raw: String?) -> String {
        guard let raw, let url = URL(string: raw) else { return "" }
        return safeURL(url)
    }

    private func safeText(_ raw: String, limit: Int = 480) -> String {
        String(raw.prefix(limit))
    }

    private static func jsonString(_ value: Any) -> String {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8) else {
            if let text = value as? String,
               let data = try? JSONSerialization.data(withJSONObject: [text]),
               let encoded = String(data: data, encoding: .utf8) {
                return String(encoded.dropFirst().dropLast())
            }
            return "{}"
        }
        return text
    }
}
