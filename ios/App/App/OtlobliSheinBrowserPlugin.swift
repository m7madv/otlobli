import UIKit
import WebKit
import Capacitor
import OSLog

private final class OtlobliSheinDiagnosticSurfaceView: UIView {
    var touchReporter: ((CGPoint, Int, UIView?) -> Void)?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let target = super.hitTest(point, with: event)
        if event?.type == .touches {
            touchReporter?(point, event?.allTouches?.first?.phase.rawValue ?? -1, target)
        }
        return target
    }
}

/// Otlobli's single iOS SHEIN browser boundary.
///
/// One WKWebView owns one complete SHEIN browsing session. Route changes,
/// verification, products and back/forward navigation stay in that same
/// WebContent process, just like Safari. Website data remains persistent in
/// WKWebsiteDataStore.default(); the view is destroyed only on an explicit
/// close or a hidden low-memory eviction. An actual WebContent termination is
/// recovered by loading the last route back into the same WKWebView object.
@objc(OtlobliSheinBrowserPlugin)
public final class OtlobliSheinBrowserPlugin: CAPPlugin, CAPBridgedPlugin,
    WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {

    public let identifier = "OtlobliSheinBrowserPlugin"
    public let jsName = "OtlobliSheinBrowser"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "openWebView", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "show", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "hide", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "setUrl", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "executeScript", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "postMessage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clearCache", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "recordDiagnostic", returnType: CAPPluginReturnPromise)
    ]

    private static let messageHandlers = ["messageHandler", "close", "hide", "show", "navigate"]

    private var browserId = ""
    private var savedURL: URL?
    private var documentStartScript = ""
    private var loadingCoverEnabled = true
    private var isBrowserVisible = false
    private var diagnosticsEnabled = false

    private static let diagnosticsLogger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.otlobli.app",
        category: "SheinRootCause"
    )

    private var surfaceView: UIView?
    private var storeWebView: WKWebView?
    private var urlObservation: NSKeyValueObservation?
    private var loadingCover: UIView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var nativeBackButton: UIButton?
    private var nativeBackTopConstraint: NSLayoutConstraint?
    private var nativeBackTarget = "home"

    public override func load() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func openWebView(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url) else {
            call.reject("A valid SHEIN URL is required")
            return
        }

        let requestedDiagnostics = call.getBool("otlobliFreezeDiagnostics", false) ||
            call.getBool("otlobliTapDiagnostics", false)
        DispatchQueue.main.async {
            self.closeBrowser(emitEvent: false)
            self.diagnosticsEnabled = requestedDiagnostics
            self.browserId = "otlobli-shein-\(UUID().uuidString.lowercased())"
            self.savedURL = url
            self.documentStartScript = call.getString("otlobliDocumentStartScript", "")
            self.loadingCoverEnabled = call.getBool("otlobliLoadingCover", true)
            self.isBrowserVisible = true
            self.logDiagnostic("open-request", ["route": self.routeLabel(url)])

            // The old API requested an initially hidden browser. This browser
            // never creates hidden WebKit surfaces; its native loading cover is
            // the only pre-ready presentation.
            guard self.createRenderSurface(
                request: self.initialRequest(url: url, call: call),
                loadingMessage: "جاري تجهيز المتجر…"
            ) else {
                self.closeBrowser(emitEvent: false)
                call.reject("Capacitor host view is unavailable")
                return
            }
            self.logDiagnostic("open-resolved", self.surfaceStateFields())
            call.resolve(["id": self.browserId])
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard !self.browserId.isEmpty, self.savedURL != nil else {
                call.reject("SHEIN browser is not initialized")
                return
            }
            self.logDiagnostic("show-before", self.surfaceStateFields())
            self.isBrowserVisible = true
            if let surface = self.surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                self.refreshVisibleSurfaceLayout()
            } else if !self.createRenderSurface(loadingMessage: "جاري استعادة المتجر…") {
                call.reject("Capacitor host view is unavailable")
                return
            }
            self.requestPersistentStateSnapshot("native-show")
            self.logDiagnostic("show-after", self.surfaceStateFields())
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.logDiagnostic("hide-before", self.surfaceStateFields())
            self.requestPersistentStateSnapshot("native-hide")
            self.isBrowserVisible = false
            self.parkRenderSurfaceBehindApp()
            self.logDiagnostic("hide-after", self.surfaceStateFields())
            call.resolve()
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if let requestedId = call.getString("id"),
               !requestedId.isEmpty,
               requestedId != self.browserId {
                call.resolve()
                return
            }
            self.logDiagnostic("close-call", self.surfaceStateFields())
            self.closeBrowser(emitEvent: true)
            call.resolve()
        }
    }

    @objc func setUrl(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url) else {
            call.reject("A valid SHEIN URL is required")
            return
        }
        DispatchQueue.main.async {
            guard !self.browserId.isEmpty else {
                call.reject("SHEIN browser is not initialized")
                return
            }
            self.savedURL = url
            self.navigateInCurrentWebView(to: url)
            call.resolve()
        }
    }

    @objc func executeScript(_ call: CAPPluginCall) {
        guard let code = call.getString("code"), !code.isEmpty else {
            call.reject("JavaScript code is required")
            return
        }
        DispatchQueue.main.async {
            guard let webView = self.storeWebView else {
                call.reject("SHEIN render surface is not active")
                return
            }
            webView.evaluateJavaScript(code) { _, error in
                if let error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve()
                }
            }
        }
    }

    @objc func postMessage(_ call: CAPPluginCall) {
        let detail = call.getObject("detail", [:])
        guard !detail.isEmpty,
              JSONSerialization.isValidJSONObject(detail),
              let data = try? JSONSerialization.data(withJSONObject: detail),
              let json = String(data: data, encoding: .utf8) else {
            call.reject("Message detail must be JSON serializable")
            return
        }
        DispatchQueue.main.async {
            guard let webView = self.storeWebView else {
                call.reject("SHEIN render surface is not active")
                return
            }
            let script = "window.dispatchEvent(new CustomEvent('messageFromNative',{detail:\(json)}));"
            webView.evaluateJavaScript(script) { _, error in
                if let error {
                    call.reject(error.localizedDescription)
                } else {
                    call.resolve()
                }
            }
        }
    }

    @objc func clearCache(_ call: CAPPluginCall) {
        logDiagnostic("clear-http-cache")
        let types: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
            call.resolve()
        }
    }

    @objc func recordDiagnostic(_ call: CAPPluginCall) {
        let detail = call.getObject("detail", [:])
        DispatchQueue.main.async {
            guard self.diagnosticsEnabled else {
                call.resolve()
                return
            }
            var fields: [String: String] = [:]
            for key in ["stage", "trigger", "decision", "screen", "store", "opened", "ready", "challenge"] {
                if let value = detail[key] {
                    fields[key] = self.diagnosticScalar(value)
                }
            }
            self.logDiagnostic("host-decision", fields)
            call.resolve()
        }
    }

    private func createRenderSurface(
        request: URLRequest? = nil,
        loadingMessage: String
    ) -> Bool {
        guard storeWebView == nil,
              surfaceView == nil,
              let hostView = bridge?.viewController?.view,
              let targetURL = request?.url ?? savedURL,
              isAllowedStoreURL(targetURL) else { return false }

        logDiagnostic("surface-create-begin", ["route": routeLabel(targetURL)])

        let contentController = WKUserContentController()
        for name in Self.messageHandlers {
            contentController.add(self, name: name)
        }
        contentController.addUserScript(WKUserScript(
            source: mobileBridgeScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        if !documentStartScript.isEmpty {
            contentController.addUserScript(WKUserScript(
                source: documentStartScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.userContentController = contentController
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.suppressesIncrementalRendering = false
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }

        let surface = OtlobliSheinDiagnosticSurfaceView(frame: .zero)
        surface.touchReporter = { [weak self, weak surface] point, phase, target in
            guard let self, let surface else { return }
            self.logDiagnostic("native-hit-test", [
                "phase": String(phase),
                "point": self.pointLabel(point),
                "target": self.viewClassLabel(target),
                "targetId": self.objectLabel(target),
                "webId": self.objectLabel(self.storeWebView),
                "surfaceId": self.objectLabel(surface),
            ].merging(self.surfaceStateFields()) { current, _ in current })
        }
        surface.translatesAutoresizingMaskIntoConstraints = false
        surface.backgroundColor = .white
        surface.isOpaque = true
        hostView.addSubview(surface)
        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: hostView.topAnchor),
            surface.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            surface.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = false
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white

        surfaceView = surface
        storeWebView = webView
        attachWebView(webView, to: surface)
        installNativeBackButton(in: surface)
        if loadingCoverEnabled {
            installLoadingCover(in: surface, message: loadingMessage)
        }
        observeStoreURL(on: webView)
        hostView.bringSubviewToFront(surface)
        webView.load(request ?? URLRequest(
            url: targetURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 45
        ))
        logDiagnostic("surface-create-end", surfaceStateFields().merging([
            "route": routeLabel(targetURL),
        ]) { current, _ in current })
        return true
    }

    private func destroyRenderSurface() {
        logDiagnostic("surface-destroy-begin", surfaceStateFields())
        if let currentURL = storeWebView?.url, isAllowedStoreURL(currentURL) {
            savedURL = currentURL
        }
        urlObservation?.invalidate()
        urlObservation = nil
        storeWebView?.stopLoading()
        storeWebView?.navigationDelegate = nil
        storeWebView?.uiDelegate = nil
        if let contentController = storeWebView?.configuration.userContentController {
            for name in Self.messageHandlers {
                contentController.removeScriptMessageHandler(forName: name)
            }
            contentController.removeAllUserScripts()
        }
        storeWebView?.removeFromSuperview()
        surfaceView?.removeFromSuperview()
        storeWebView = nil
        surfaceView = nil
        loadingCover = nil
        loadingSpinner = nil
        nativeBackButton = nil
        nativeBackTopConstraint = nil
        nativeBackTarget = "home"
        logDiagnostic("surface-destroy-end", ["hasSurface": "false", "hasWeb": "false"])
    }

    /// Keep the verified WebContent process alive while Otlobli's Capacitor
    /// screen is visible. Hiding or removing WKWebView would let modern iOS
    /// discard its remote layer tree and, more importantly, its live risk-
    /// verification state.
    private func parkRenderSurfaceBehindApp() {
        guard let surface = surfaceView,
              let hostView = bridge?.viewController?.view else { return }
        surface.isHidden = false
        surface.alpha = 1
        if let appWebView = bridge?.webView, appWebView.superview === hostView {
            hostView.insertSubview(surface, belowSubview: appWebView)
        } else {
            hostView.sendSubviewToBack(surface)
        }
        logDiagnostic("surface-parked", surfaceStateFields())
    }

    private func refreshVisibleSurfaceLayout() {
        guard let surface = surfaceView, let webView = storeWebView else { return }
        surface.setNeedsLayout()
        surface.superview?.layoutIfNeeded()
        webView.setNeedsLayout()
        webView.layoutIfNeeded()
        webView.setNeedsDisplay()
    }

    /// Route inside the currently verified page whenever possible. A normal
    /// WKNavigation remains the fallback, but it still uses the same WKWebView.
    private func navigateInCurrentWebView(to url: URL) {
        guard isAllowedStoreURL(url) else { return }
        logDiagnostic("navigate-request", ["route": routeLabel(url)])
        savedURL = url
        guard let webView = storeWebView else {
            if isBrowserVisible {
                _ = createRenderSurface(
                    request: URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45),
                    loadingMessage: "جاري استعادة المتجر…"
                )
            }
            return
        }
        guard let data = try? JSONEncoder().encode(url.absoluteString),
              let encodedURL = String(data: data, encoding: .utf8) else {
            webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45))
            return
        }
        webView.evaluateJavaScript("window.location.assign(\(encodedURL));") { [weak self, weak webView] _, error in
            guard error != nil,
                  let self,
                  let webView,
                  self.storeWebView === webView else { return }
            webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45))
        }
    }

    private func closeBrowser(emitEvent: Bool) {
        logDiagnostic("browser-close-begin", surfaceStateFields().merging([
            "emit": emitEvent ? "true" : "false",
        ]) { current, _ in current })
        let closingId = browserId
        let closingURL = storeWebView?.url?.absoluteString ?? savedURL?.absoluteString ?? ""
        destroyRenderSurface()
        browserId = ""
        savedURL = nil
        documentStartScript = ""
        isBrowserVisible = false
        if emitEvent && !closingId.isEmpty {
            notifyListeners("closeEvent", data: ["id": closingId, "url": closingURL])
        }
        logDiagnostic("browser-close-end", ["emit": emitEvent ? "true" : "false"])
        diagnosticsEnabled = false
    }

    private func observeStoreURL(on webView: WKWebView) {
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self, weak webView] _, change in
            guard let self,
                  let webView,
                  self.storeWebView === webView,
                  let changedURL = change.newValue ?? webView.url,
                  self.isAllowedStoreURL(changedURL) else { return }
            self.savedURL = changedURL
            self.logDiagnostic("url-change", ["route": self.routeLabel(changedURL)])
            self.emit("urlChangeEvent", extra: ["url": changedURL.absoluteString])
        }
    }

    private func attachWebView(_ webView: WKWebView, to surface: UIView) {
        webView.translatesAutoresizingMaskIntoConstraints = false
        surface.insertSubview(webView, at: 0)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: surface.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: surface.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: surface.bottomAnchor)
        ])
    }

    private func initialRequest(url: URL, call: CAPPluginCall) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45)
        let method = call.getString("method", "GET").trimmingCharacters(in: .whitespacesAndNewlines)
        request.httpMethod = method.isEmpty ? "GET" : method.uppercased()
        if let body = call.getString("body"), !body.isEmpty {
            request.httpBody = body.data(using: .utf8)
        }
        for (field, value) in call.getObject("headers", [:]) {
            request.setValue(String(describing: value), forHTTPHeaderField: field)
        }
        return request
    }

    private func isAllowedStoreURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return false }
        return host == "shein.com" || host.hasSuffix(".shein.com")
    }

    private func emit(_ name: String, detail: [String: Any]? = nil, extra: [String: Any] = [:]) {
        guard !browserId.isEmpty else { return }
        var payload = extra
        payload["id"] = browserId
        if let detail { payload["detail"] = detail }
        notifyListeners(name, data: payload)
    }

    private func stableHash(_ value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }

    private func diagnosticScalar(_ value: Any?) -> String {
        if let value = value as? Bool { return value ? "true" : "false" }
        if let value = value as? NSNumber { return value.stringValue }
        if let value = value as? String { return sanitizeLogValue(value) }
        return value == nil ? "nil" : sanitizeLogValue(String(describing: value!))
    }

    private func sanitizeLogValue(_ value: String, limit: Int = 96) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_.:/"))
        let mapped = value.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : "_" }
        return String(mapped.prefix(limit))
    }

    private func objectLabel(_ object: AnyObject?) -> String {
        guard let object else { return "nil" }
        return sanitizeLogValue(String(describing: ObjectIdentifier(object)), limit: 40)
    }

    private func viewClassLabel(_ view: UIView?) -> String {
        guard let view else { return "nil" }
        return sanitizeLogValue(String(describing: type(of: view)), limit: 64)
    }

    private func pointLabel(_ point: CGPoint) -> String {
        "\(Int(point.x.rounded())),\(Int(point.y.rounded()))"
    }

    private func frameLabel(_ frame: CGRect) -> String {
        [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]
            .map { String(Int($0.rounded())) }
            .joined(separator: ",")
    }

    private func routeLabel(_ url: URL?) -> String {
        guard let url else { return "nil" }
        let path = url.path
        let kind: String
        if path.range(of: "challenge|captcha|/risk/", options: .regularExpression) != nil {
            kind = "challenge"
        } else if path.range(of: "-p-[0-9]+", options: .regularExpression) != nil {
            kind = "product"
        } else if path.isEmpty || path == "/" || path.range(of: "^/[a-zA-Z-]{2,7}/?$", options: .regularExpression) != nil {
            kind = "home"
        } else if path.range(of: "search|category|collection|campaign|daily|recommend", options: [.regularExpression, .caseInsensitive]) != nil {
            kind = "list"
        } else {
            kind = "other"
        }
        return "\(sanitizeLogValue(url.host ?? "host")):\(kind):\(stableHash((url.host ?? "") + path))"
    }

    private func surfaceStateFields() -> [String: String] {
        guard diagnosticsEnabled else { return [:] }
        let host = bridge?.viewController?.view
        let surface = surfaceView
        let webView = storeWebView
        let surfaceIndex = host.flatMap { owner in surface.flatMap { owner.subviews.firstIndex(of: $0) } }
        let appIndex = host.flatMap { owner in bridge?.webView.flatMap { owner.subviews.firstIndex(of: $0) } }
        var fields: [String: String] = [
            "appState": String(UIApplication.shared.applicationState.rawValue),
            "browser": browserId.isEmpty ? "none" : stableHash(browserId),
            "visible": isBrowserVisible ? "true" : "false",
            "surfaceId": objectLabel(surface),
            "webId": objectLabel(webView),
            "surfaceWindow": surface?.window == nil ? "false" : "true",
            "webWindow": webView?.window == nil ? "false" : "true",
            "surfaceHidden": surface?.isHidden == true ? "true" : "false",
            "surfaceInteractive": surface?.isUserInteractionEnabled == true ? "true" : "false",
            "surfaceAlpha": String(format: "%.2f", surface?.alpha ?? -1),
            "surfaceFrame": frameLabel(surface?.frame ?? .zero),
            "webFrame": frameLabel(webView?.frame ?? .zero),
            "surfaceIndex": surfaceIndex.map(String.init) ?? "nil",
            "appIndex": appIndex.map(String.init) ?? "nil",
            "hostChildren": String(host?.subviews.count ?? -1),
            "frontClass": viewClassLabel(host?.subviews.last),
        ]
        if let host, let surface {
            let center = surface.convert(CGPoint(x: surface.bounds.midX, y: surface.bounds.midY), to: host)
            fields["centerHit"] = viewClassLabel(host.hitTest(center, with: nil))
        }
        return fields
    }

    private func logDiagnostic(_ event: String, _ fields: [String: String] = [:]) {
        guard diagnosticsEnabled else { return }
        let pairs = fields.sorted { $0.key < $1.key }.map {
            "\(sanitizeLogValue($0.key, limit: 40))=\(sanitizeLogValue($0.value))"
        }
        let suffix = pairs.isEmpty ? "" : " " + pairs.joined(separator: " ")
        let line = "[OtlobliSheinDiag] event=\(sanitizeLogValue(event, limit: 64))\(suffix)"
        Self.diagnosticsLogger.notice("\(line, privacy: .public)")
    }

    private func diagnosticNode(_ value: Any?) -> String {
        guard let node = value as? [String: Any] else { return "nil" }
        let tag = sanitizeLogValue(node["tag"] as? String ?? "nil", limit: 24)
        let idHash = stableHash(node["id"] as? String ?? "")
        let classHash = stableHash(node["cls"] as? String ?? "")
        let pointer = sanitizeLogValue(node["pe"] as? String ?? "nil", limit: 20)
        let display = sanitizeLogValue(node["display"] as? String ?? "nil", limit: 20)
        let visibility = sanitizeLogValue(node["visibility"] as? String ?? "nil", limit: 20)
        let position = sanitizeLogValue(node["position"] as? String ?? "nil", limit: 20)
        return "\(tag).\(idHash).\(classHash).\(pointer).\(display).\(visibility).\(position)"
    }

    private func logWebDiagnostic(_ detail: [String: Any]) {
        guard diagnosticsEnabled, let type = detail["type"] as? String else { return }
        if type == "otlobliPersistentStateDiagnostic" {
            var fields: [String: String] = [:]
            for key in [
                "stage", "seq", "route", "routeHash", "ready", "visibility",
                "cookieCount", "cookieKeysHash", "cookieStateHash",
                "localCount", "localKeysHash", "localStateHash",
                "sessionCount", "sessionKeysHash", "sessionStateHash",
                "cacheCount", "cacheHash", "workerCount", "workerHash",
                "workerControlled", "databaseCount", "databaseHash",
            ] where detail[key] != nil {
                fields[key] = diagnosticScalar(detail[key])
            }
            logDiagnostic("persistent-state", fields)
            return
        }
        if type == "otlobliTapDiagnostic" {
            var fields: [String: String] = [:]
            for key in ["stage", "attempt", "event", "phase", "isTrusted", "defaultPrevented", "bubbleSeen", "x", "y", "hrefChanged", "productDetected"] where detail[key] != nil {
                fields[key] = diagnosticScalar(detail[key])
            }
            if let snapshot = detail["snapshot"] as? [String: Any] {
                fields["target"] = diagnosticNode(snapshot["target"])
                fields["top"] = diagnosticNode(snapshot["elementFromPoint"])
                if let fixed = snapshot["fixedLayers"] as? [Any] {
                    fields["fixedCount"] = String(fixed.count)
                    fields["fixedTop"] = diagnosticNode(fixed.first)
                }
            }
            logDiagnostic("dom-tap", fields)
            return
        }
        if type == "otlobliFreezeDiagnostic" {
            var fields: [String: String] = [:]
            for key in ["stage", "v", "r", "perf"] where detail[key] != nil {
                fields[key] = diagnosticScalar(detail[key])
            }
            if let path = detail["p"] as? String {
                fields["pathHash"] = stableHash(path)
            }
            if let message = detail["m"] as? String {
                fields["messageHash"] = stableHash(message)
            }
            logDiagnostic("document-lifecycle", fields)
            return
        }
        if ["sheinSaudiReady", "sheinPageInteractive", "humanCheck", "humanCheckResolved", "requestStoreExit", "closeStore"].contains(type) {
            logDiagnostic("web-message", ["type": type])
        }
    }

    private func requestPersistentStateSnapshot(_ stage: String) {
        guard diagnosticsEnabled, let webView = storeWebView,
              let encoded = try? JSONEncoder().encode(stage),
              let stageJSON = String(data: encoded, encoding: .utf8) else { return }
        let script = "window.__otlobliPersistentStateDiagnostic&&window.__otlobliPersistentStateDiagnostic(\(stageJSON));"
        webView.evaluateJavaScript(script) { [weak self] _, error in
            guard let self, let error else { return }
            self.logDiagnostic("snapshot-request-error", ["stage": stage, "errorHash": self.stableHash(error.localizedDescription)])
        }
    }

    private func installLoadingCover(in surface: UIView, message: String) {
        let cover = UIView(frame: .zero)
        cover.translatesAutoresizingMaskIntoConstraints = false
        cover.backgroundColor = .white
        cover.isOpaque = true
        cover.isUserInteractionEnabled = true

        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.color = UIColor(red: 0, green: 105.0 / 255.0, blue: 72.0 / 255.0, alpha: 1)
        spinner.startAnimating()

        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = message
        label.textColor = UIColor(red: 0.08, green: 0.18, blue: 0.14, alpha: 1)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textAlignment = .center

        cover.addSubview(spinner)
        cover.addSubview(label)
        surface.addSubview(cover)
        NSLayoutConstraint.activate([
            cover.topAnchor.constraint(equalTo: surface.topAnchor),
            cover.leadingAnchor.constraint(equalTo: surface.leadingAnchor),
            cover.trailingAnchor.constraint(equalTo: surface.trailingAnchor),
            cover.bottomAnchor.constraint(equalTo: surface.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: cover.centerYAnchor, constant: -18),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 14),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: cover.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(lessThanOrEqualTo: cover.trailingAnchor, constant: -24),
            label.centerXAnchor.constraint(equalTo: cover.centerXAnchor)
        ])
        loadingCover = cover
        loadingSpinner = spinner
    }

    private func hideLoadingCover() {
        loadingSpinner?.stopAnimating()
        loadingCover?.removeFromSuperview()
        loadingCover = nil
        loadingSpinner = nil
    }

    private func installNativeBackButton(in surface: UIView) {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("‹", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 34, weight: .medium)
        button.backgroundColor = UIColor(red: 0, green: 105.0 / 255.0, blue: 72.0 / 255.0, alpha: 0.94)
        button.layer.cornerRadius = 22
        button.isHidden = true
        button.accessibilityLabel = "رجوع"
        button.addTarget(self, action: #selector(nativeBackPressed), for: .touchUpInside)
        surface.addSubview(button)
        let top = button.topAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.topAnchor, constant: 12)
        NSLayoutConstraint.activate([
            top,
            button.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -12),
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        nativeBackButton = button
        nativeBackTopConstraint = top
    }

    private func updateNativeBackButton(_ detail: [String: Any]) {
        let visible = detail["visible"] as? Bool ?? false
        let top = (detail["top"] as? NSNumber)?.doubleValue ?? 12
        nativeBackTarget = detail["target"] as? String ?? "home"
        nativeBackTopConstraint?.constant = CGFloat(max(8, min(top, 120)))
        nativeBackButton?.isHidden = !visible
        if let button = nativeBackButton, visible {
            surfaceView?.bringSubviewToFront(button)
        }
    }

    @objc private func nativeBackPressed() {
        logDiagnostic("native-back", ["target": nativeBackTarget])
        switch nativeBackTarget {
        case "cart":
            emit("messageFromWebview", detail: ["type": "backToCart"])
        case "exit":
            emit("messageFromWebview", detail: ["type": "requestStoreExit", "store": "shein"])
        default:
            if storeWebView?.canGoBack == true {
                storeWebView?.goBack()
            } else if let home = URL(string: "https://m.shein.com/ar/") {
                navigateInCurrentWebView(to: home)
            }
        }
    }

    private func mobileBridgeScript() -> String {
        """
        window.mobileApp=Object.assign({},window.mobileApp||{}, {
          postMessage:function(message){
            if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.messageHandler){
              window.webkit.messageHandlers.messageHandler.postMessage(message);
            }
          },
          close:function(){window.webkit.messageHandlers.close.postMessage(null);},
          hide:function(){window.webkit.messageHandlers.hide.postMessage(null);},
          show:function(){window.webkit.messageHandlers.show.postMessage(null);},
          navigate:function(target){window.webkit.messageHandlers.navigate.postMessage(String(target||''));}
        });
        """
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.webView === storeWebView else { return }
        switch message.name {
        case "messageHandler":
            guard let body = message.body as? [String: Any],
                  let detail = body["detail"] as? [String: Any] else { return }
            logWebDiagnostic(detail)
            if detail["type"] as? String == "otlobliBackButtonState" {
                updateNativeBackButton(detail)
                return
            }
            let readyTypes = ["sheinSaudiReady", "sheinPageInteractive", "humanCheck", "humanCheckResolved"]
            if let type = detail["type"] as? String, readyTypes.contains(type) {
                hideLoadingCover()
                requestPersistentStateSnapshot("ready-\(type)")
            }
            emit("messageFromWebview", detail: detail)
        case "close":
            logDiagnostic("bridge-close")
            closeBrowser(emitEvent: true)
        case "hide":
            logDiagnostic("bridge-hide-before", surfaceStateFields())
            requestPersistentStateSnapshot("native-hide-bridge")
            isBrowserVisible = false
            parkRenderSurfaceBehindApp()
            logDiagnostic("bridge-hide-after", surfaceStateFields())
        case "show":
            logDiagnostic("bridge-show-before", surfaceStateFields())
            isBrowserVisible = true
            if let surface = surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                refreshVisibleSurfaceLayout()
            } else {
                _ = createRenderSurface(loadingMessage: "جاري استعادة المتجر…")
            }
            requestPersistentStateSnapshot("native-show-bridge")
            logDiagnostic("bridge-show-after", surfaceStateFields())
        case "navigate":
            guard let target = message.body as? String,
                  ["orders", "cart", "profile", "store-select"].contains(target) else { return }
            isBrowserVisible = false
            logDiagnostic("bridge-navigate", ["target": target])
            requestPersistentStateSnapshot("native-hide-navigate")
            parkRenderSurfaceBehindApp()
            let encoded = target.replacingOccurrences(of: "'", with: "\\'")
            bridge?.webView?.evaluateJavaScript(
                "window.dispatchEvent(new CustomEvent('otlobli:nativeNavigate',{detail:'\(encoded)'}));",
                completionHandler: nil
            )
        default:
            break
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        logDiagnostic("navigation-finished", surfaceStateFields().merging([
            "route": routeLabel(webView.url),
        ]) { current, _ in current })
        requestPersistentStateSnapshot("navigation-finished")
        emit("browserPageLoaded", extra: ["url": webView.url?.absoluteString ?? ""])
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        guard webView === storeWebView else { return }
        emitPageError(error, phase: "didFailProvisionalNavigation")
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        guard webView === storeWebView else { return }
        emitPageError(error, phase: "didFailNavigation")
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        guard webView === storeWebView else { return }
        let recoveryURL = webView.url ?? savedURL
        logDiagnostic("webcontent-terminated", ["route": routeLabel(recoveryURL)])
        emit("messageFromWebview", detail: [
            "type": "sheinWebContentRestarted",
            "url": recoveryURL?.absoluteString ?? ""
        ])
        if isBrowserVisible, loadingCoverEnabled, loadingCover == nil, let surface = surfaceView {
            installLoadingCover(in: surface, message: "جاري استعادة المتجر…")
        }
        if let recoveryURL {
            webView.load(URLRequest(
                url: recoveryURL,
                cachePolicy: .useProtocolCachePolicy,
                timeoutInterval: 45
            ))
        }
    }

    private func emitPageError(_ error: Error, phase: String) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        logDiagnostic("navigation-error", [
            "phase": phase,
            "code": String(nsError.code),
            "domain": nsError.domain,
            "route": routeLabel(storeWebView?.url ?? savedURL),
            "messageHash": stableHash(nsError.localizedDescription),
        ])
        emit("pageLoadError", extra: [
            "phase": phase,
            "code": nsError.code,
            "domain": nsError.domain,
            "message": nsError.localizedDescription,
            "url": storeWebView?.url?.absoluteString ?? savedURL?.absoluteString ?? ""
        ])
    }

    public func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if isAllowedStoreURL(url) {
                savedURL = url
                webView.load(navigationAction.request)
            } else if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        return nil
    }

    public func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }
        if scheme == "http" || scheme == "https" {
            let isTopLevel = navigationAction.targetFrame?.isMainFrame == true || navigationAction.targetFrame == nil
            if isTopLevel && !isAllowedStoreURL(url) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }

    @objc private func applicationDidReceiveMemoryWarning() {
        // A visible store is never sacrificed. If iOS warns while the store is
        // parked behind Otlobli, releasing it is the only intentional fallback;
        // persistent cookies still allow a later recovery.
        logDiagnostic("memory-warning", surfaceStateFields())
        guard !isBrowserVisible, storeWebView != nil else { return }
        destroyRenderSurface()
    }
}
