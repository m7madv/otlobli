import UIKit
import WebKit
import Capacitor
import OSLog

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
        CAPPluginMethod(name: "clearCache", returnType: CAPPluginReturnPromise)
    ]

    private static let messageHandlers = ["messageHandler", "close", "hide", "show", "navigate"]
    private static let rootCauseLogger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.otlobli.app",
        category: "SheinRootCause"
    )

    private var browserId = ""
    private var savedURL: URL?
    private var documentStartScript = ""
    private var loadingCoverEnabled = true
    private var isBrowserVisible = false
    private let diagnosticRunId = UUID().uuidString.lowercased()
    private let diagnosticPID = ProcessInfo.processInfo.processIdentifier
    private var diagnosticSequence = 0
    private var diagnosticWebViewId = ""
    private var diagnosticNavigationSequence = 0
    private var diagnosticNavigationId = ""
    private var diagnosticLifecycleObservers: [NSObjectProtocol] = []

    private var surfaceView: UIView?
    private var storeWebView: WKWebView?
    private var urlObservation: NSKeyValueObservation?
    private var loadingCover: UIView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var nativeBackButton: UIButton?
    private var nativeBackTopConstraint: NSLayoutConstraint?
    private var nativeBackTarget = "home"
    private var nativeBackLocked = false
    private var pendingNativeBackTraceAction: String?

    public override func load() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        installRootCauseLifecycleObservers()
        logDiagnostic("plugin-load", surfaceStateFields())
    }

    deinit {
        logDiagnostic("plugin-deinit", surfaceStateFields())
        for observer in diagnosticLifecycleObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }

    @objc func openWebView(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url) else {
            call.reject("A valid SHEIN URL is required")
            return
        }

        DispatchQueue.main.async {
            self.closeBrowser(emitEvent: false)
            self.browserId = "otlobli-shein-\(UUID().uuidString.lowercased())"
            self.diagnosticWebViewId = "webview-\(UUID().uuidString.lowercased())"
            self.diagnosticNavigationSequence = 0
            self.diagnosticNavigationId = "navigation-0"
            self.savedURL = url
            self.documentStartScript = call.getString("otlobliDocumentStartScript", "")
            self.loadingCoverEnabled = call.getBool("otlobliLoadingCover", true)
            self.isBrowserVisible = true
            self.logDiagnostic("open-request", self.surfaceStateFields().merging([
                "requestedUrl": self.safeURLString(url)
            ]) { current, _ in current })

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
            self.captureCookieMetadata("OPEN_RESOLVED")
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
            self.requestWebProbeSnapshot("SHOW_BEFORE")
            self.isBrowserVisible = true
            if let surface = self.surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                self.refreshVisibleSurfaceLayout()
            } else if !self.createRenderSurface(loadingMessage: "جاري استعادة المتجر…") {
                call.reject("Capacitor host view is unavailable")
                return
            }
            self.logDiagnostic("show-after", self.surfaceStateFields())
            self.requestWebProbeSnapshot("SHOW_AFTER")
            self.captureCookieMetadata("SHOW_AFTER")
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.logDiagnostic("hide-before", self.surfaceStateFields())
            self.requestWebProbeSnapshot("PARK_BEFORE")
            self.isBrowserVisible = false
            self.parkRenderSurfaceBehindApp()
            self.logDiagnostic("hide-after", self.surfaceStateFields())
            self.requestWebProbeSnapshot("PARKED")
            self.captureCookieMetadata("PARKED")
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
            self.logDiagnostic("set-url", ["requestedUrl": self.safeURLString(url)])
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
        let types: Set<String> = [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast) {
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

        let contentController = WKUserContentController()
        for name in Self.messageHandlers {
            contentController.add(self, name: name)
        }
        contentController.addUserScript(WKUserScript(
            source: mobileBridgeScript(),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        contentController.addUserScript(WKUserScript(
            source: rootCauseNativeContextScript(),
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
        // Preserve the now device-accepted root-Back behavior while keeping
        // SHEIN's retained SPA schedulable across app inactivity on modern iOS.
        if #available(iOS 17.0, *) {
            configuration.preferences.inactiveSchedulingPolicy = .throttle
        }
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
            configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        }

        let surface = UIView(frame: .zero)
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
        // Diagnostic build only: exposes this exact custom SHEIN WKWebView to
        // Safari/pymobiledevice Web Inspector without changing page behavior.
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        }
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
        logDiagnostic("surface-created", surfaceStateFields())
        webView.load(request ?? URLRequest(
            url: targetURL,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 45
        ))
        return true
    }

    private func destroyRenderSurface() {
        logDiagnostic("surface-destroy-before", surfaceStateFields())
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
        nativeBackLocked = false
        pendingNativeBackTraceAction = nil
        logDiagnostic("surface-destroy-after", [
            "browserIdBeforeDestroy": browserId,
            "webViewIdBeforeDestroy": diagnosticWebViewId
        ])
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
        logDiagnostic("navigate-request", ["targetUrl": safeURLString(url)])
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
            "emitEvent": emitEvent
        ]) { current, _ in current })
        let closingId = browserId
        let closingWebViewId = diagnosticWebViewId
        let closingURL = storeWebView?.url?.absoluteString ?? savedURL?.absoluteString ?? ""
        destroyRenderSurface()
        browserId = ""
        savedURL = nil
        documentStartScript = ""
        isBrowserVisible = false
        if emitEvent && !closingId.isEmpty {
            notifyListeners("closeEvent", data: ["id": closingId, "url": closingURL])
        }
        logDiagnostic("browser-close-end", [
            "closingBrowserId": closingId,
            "closingWebViewId": closingWebViewId,
            "emitEvent": emitEvent
        ])
        diagnosticWebViewId = ""
        diagnosticNavigationId = ""
    }

    private func observeStoreURL(on webView: WKWebView) {
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self, weak webView] _, change in
            guard let self,
                  let webView,
                  self.storeWebView === webView,
                  let changedURL = change.newValue ?? webView.url,
                  self.isAllowedStoreURL(changedURL) else { return }
            self.savedURL = changedURL
            self.logDiagnostic("url-change", self.surfaceStateFields().merging([
                "url": self.safeURLString(changedURL)
            ]) { current, _ in current })
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

    private func installRootCauseLifecycleObservers() {
        let lifecycleEvents: [(Notification.Name, String)] = [
            (UIApplication.willResignActiveNotification, "WILL_RESIGN_ACTIVE"),
            (UIApplication.didEnterBackgroundNotification, "DID_ENTER_BACKGROUND"),
            (UIApplication.willEnterForegroundNotification, "WILL_ENTER_FOREGROUND"),
            (UIApplication.didBecomeActiveNotification, "DID_BECOME_ACTIVE"),
            (UIApplication.willTerminateNotification, "WILL_TERMINATE")
        ]
        for (notification, label) in lifecycleEvents {
            let observer = NotificationCenter.default.addObserver(
                forName: notification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                self.logDiagnostic("application-lifecycle", self.surfaceStateFields().merging([
                    "snapshotLabel": label
                ]) { current, _ in current })
                self.requestWebProbeSnapshot(label)
                self.captureCookieMetadata(label)
            }
            diagnosticLifecycleObservers.append(observer)
        }
    }

    private func safeURLString(_ url: URL?) -> String {
        guard let url else { return "" }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.user = nil
        components?.password = nil
        components?.query = nil
        components?.fragment = nil
        return components?.string ?? "\(url.scheme ?? "")://\(url.host ?? "")\(url.path)"
    }

    private func objectLabel(_ object: AnyObject?) -> String {
        guard let object else { return "nil" }
        return String(describing: ObjectIdentifier(object))
    }

    private func frameLabel(_ frame: CGRect) -> String {
        [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height]
            .map { String(Int($0.rounded())) }
            .joined(separator: ",")
    }

    private func hierarchyDepth(_ view: UIView?) -> Int {
        var depth = 0
        var current = view
        while let parent = current?.superview {
            depth += 1
            current = parent
            if depth >= 64 { break }
        }
        return depth
    }

    private func surfaceStateFields() -> [String: Any] {
        let hostController = bridge?.viewController
        let hostView = hostController?.view
        let appWebView = bridge?.webView
        let surface = surfaceView
        let webView = storeWebView
        let surfaceIndex = hostView.flatMap { owner in
            surface.flatMap { owner.subviews.firstIndex(of: $0) }
        }
        let appIndex = hostView.flatMap { owner in
            appWebView.flatMap { owner.subviews.firstIndex(of: $0) }
        }
        let backItems = webView?.backForwardList.backList.suffix(5).map { safeURLString($0.url) } ?? []
        let forwardItems = webView?.backForwardList.forwardList.prefix(5).map { safeURLString($0.url) } ?? []
        let sceneState = webView?.window?.windowScene?.activationState.rawValue
            ?? surface?.window?.windowScene?.activationState.rawValue
            ?? -1
        var fields: [String: Any] = [
            "applicationState": UIApplication.shared.applicationState.rawValue,
            "sceneActivationState": sceneState,
            "browserVisible": isBrowserVisible,
            "url": safeURLString(webView?.url ?? savedURL),
            "browserId": browserId,
            "webViewId": diagnosticWebViewId,
            "nativeWebViewObject": objectLabel(webView),
            "surfaceObject": objectLabel(surface),
            "webViewWindowAttached": webView?.window != nil,
            "webViewSuperviewAttached": webView?.superview != nil,
            "webViewSuperviewClass": webView?.superview.map { String(describing: type(of: $0)) } ?? "nil",
            "webViewHidden": webView?.isHidden ?? true,
            "webViewAlpha": Double(webView?.alpha ?? -1),
            "webViewInteractionEnabled": webView?.isUserInteractionEnabled ?? false,
            "webViewFrame": frameLabel(webView?.frame ?? .zero),
            "webViewBounds": frameLabel(webView?.bounds ?? .zero),
            "webViewHierarchyDepth": hierarchyDepth(webView),
            "webViewFirstResponder": webView?.isFirstResponder ?? false,
            "surfaceWindowAttached": surface?.window != nil,
            "surfaceSuperviewAttached": surface?.superview != nil,
            "surfaceSuperviewClass": surface?.superview.map { String(describing: type(of: $0)) } ?? "nil",
            "surfaceHidden": surface?.isHidden ?? true,
            "surfaceAlpha": Double(surface?.alpha ?? -1),
            "surfaceInteractionEnabled": surface?.isUserInteractionEnabled ?? false,
            "surfaceFrame": frameLabel(surface?.frame ?? .zero),
            "surfaceBounds": frameLabel(surface?.bounds ?? .zero),
            "surfaceHierarchyDepth": hierarchyDepth(surface),
            "surfaceSubviewIndex": surfaceIndex ?? -1,
            "appSubviewIndex": appIndex ?? -1,
            "hostSubviewCount": hostView?.subviews.count ?? -1,
            "surfaceSubviewCount": surface?.subviews.count ?? -1,
            "hostControllerClass": hostController.map { String(describing: type(of: $0)) } ?? "nil",
            "hostChildControllerCount": hostController?.children.count ?? -1,
            "webViewGestureCount": webView?.gestureRecognizers?.count ?? -1,
            "scrollGestureCount": webView?.scrollView.gestureRecognizers?.count ?? -1,
            "scrollEnabled": webView?.scrollView.isScrollEnabled ?? false,
            "panGestureState": webView?.scrollView.panGestureRecognizer.state.rawValue ?? -1,
            "loadingCoverPresent": loadingCover != nil,
            "nativeBackVisible": nativeBackButton?.isHidden == false,
            "nativeBackInteractionEnabled": nativeBackButton?.isUserInteractionEnabled ?? false,
            "canGoBack": webView?.canGoBack ?? false,
            "canGoForward": webView?.canGoForward ?? false,
            "currentHistoryPath": safeURLString(webView?.backForwardList.currentItem?.url),
            "backListCount": webView?.backForwardList.backList.count ?? -1,
            "backListPaths": backItems,
            "forwardListCount": webView?.backForwardList.forwardList.count ?? -1,
            "forwardListPaths": forwardItems,
            "websiteDataStoreId": objectLabel(webView?.configuration.websiteDataStore),
            "defaultWebsiteDataStore": webView?.configuration.websiteDataStore === WKWebsiteDataStore.default(),
            "processPoolId": objectLabel(webView?.configuration.processPool),
            "userContentControllerId": objectLabel(webView?.configuration.userContentController),
            "userScriptCount": webView?.configuration.userContentController.userScripts.count ?? -1
        ]
        if #available(iOS 16.4, *) {
            fields["inspectable"] = webView?.isInspectable ?? false
        } else {
            fields["inspectable"] = "unsupported"
        }
        return fields
    }

    private func rootCauseNativeContextScript() -> String {
        let context: [String: String] = [
            "runId": diagnosticRunId,
            "browserId": browserId,
            "webViewId": diagnosticWebViewId,
            "navigationId": diagnosticNavigationId
        ]
        guard JSONSerialization.isValidJSONObject(context),
              let data = try? JSONSerialization.data(withJSONObject: context, options: [.sortedKeys]),
              let json = String(data: data, encoding: .utf8) else { return "" }
        return "window.__otlobliRootCauseNativeContext=Object.assign({},window.__otlobliRootCauseNativeContext||{},\(json));"
    }

    private func updatePageNavigationContext() {
        guard let webView = storeWebView,
              let data = try? JSONEncoder().encode(diagnosticNavigationId),
              let json = String(data: data, encoding: .utf8) else { return }
        webView.evaluateJavaScript(
            "if(window.__otlobliRootCauseNativeContext){window.__otlobliRootCauseNativeContext.navigationId=\(json)}",
            completionHandler: nil
        )
    }

    private func requestWebProbeSnapshot(_ label: String) {
        guard let webView = storeWebView,
              let data = try? JSONEncoder().encode(label),
              let json = String(data: data, encoding: .utf8) else { return }
        logDiagnostic("evaluate-javascript-requested", ["snapshotLabel": label])
        webView.evaluateJavaScript(
            "window.__otlobliRootCauseProbe&&window.__otlobliRootCauseProbe.snapshot(\(json))"
        ) { [weak self, weak webView] result, error in
            guard let self, let webView, self.storeWebView === webView else { return }
            let errorMessage = error.map { String($0.localizedDescription.prefix(1_024)) } ?? ""
            self.logDiagnostic("evaluate-javascript-completed", [
                "snapshotLabel": label,
                "succeeded": error == nil,
                "returnedResult": result != nil,
                "error": errorMessage
            ])
        }
    }

    private func captureCookieMetadata(_ label: String) {
        guard let dataStore = storeWebView?.configuration.websiteDataStore else { return }
        dataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }
            let names = Array(Set(cookies.map(\.name))).sorted()
            self.logDiagnostic("cookie-metadata", [
                "snapshotLabel": label,
                "cookieCount": cookies.count,
                "cookieNames": names
            ])
        }
    }

    private func boundedDiagnosticValue(_ value: Any, key: String, depth: Int = 0) -> Any? {
        if depth > 7 { return "[depth-limit]" }
        let lowercaseKey = key.lowercased()
        if lowercaseKey.contains("authorization") || lowercaseKey.contains("password") ||
            lowercaseKey.contains("secret") || lowercaseKey.contains("tokenvalue") ||
            lowercaseKey.contains("cookievalue") || lowercaseKey.contains("storagevalue") ||
            lowercaseKey.contains("addressvalue") {
            return nil
        }
        if value is NSNull { return NSNull() }
        if let value = value as? Bool { return value }
        if let value = value as? NSNumber { return value }
        if let value = value as? String {
            let limit = lowercaseKey == "stack" ? 4_096 :
                (lowercaseKey.contains("message") || lowercaseKey == "error" ? 1_024 : 1_200)
            return String(value.prefix(limit))
        }
        if let values = value as? [Any] {
            return values.prefix(240).compactMap {
                boundedDiagnosticValue($0, key: key, depth: depth + 1)
            }
        }
        if let values = value as? [String: Any] {
            var result: [String: Any] = [:]
            for nestedKey in values.keys.sorted().prefix(240) {
                guard let nestedValue = values[nestedKey],
                      let bounded = boundedDiagnosticValue(nestedValue, key: nestedKey, depth: depth + 1) else { continue }
                result[nestedKey] = bounded
            }
            return result
        }
        return String(describing: value).prefix(1_200).description
    }

    private func logWebRuntimeDiagnostic(_ detail: [String: Any]) {
        guard detail["type"] as? String == "otlobliRootCauseProbe" else { return }
        var evidence: [String: Any] = [:]
        for key in detail.keys.sorted() where key != "type" {
            guard let value = detail[key],
                  let bounded = boundedDiagnosticValue(value, key: key) else { continue }
            evidence[key] = bounded
        }
        logDiagnostic("web-runtime", evidence)
        if detail["stage"] as? String == "root-cause-snapshot" {
            let label = detail["snapshotLabel"] as? String ?? "WEB_SNAPSHOT"
            logDiagnostic("native-snapshot", surfaceStateFields().merging([
                "snapshotLabel": label,
                "documentId": detail["documentId"] as? String ?? ""
            ]) { current, _ in current })
            captureCookieMetadata(label)
        }
    }

    private func logDiagnostic(_ event: String, _ fields: [String: Any] = [:]) {
        diagnosticSequence += 1
        let sequence = diagnosticSequence
        var payload: [String: Any] = [:]
        for key in fields.keys.sorted() {
            guard let value = fields[key],
                  let bounded = boundedDiagnosticValue(value, key: key) else { continue }
            payload[key] = bounded
        }
        payload["event"] = event
        payload["runId"] = diagnosticRunId
        payload["pid"] = diagnosticPID
        payload["nativeSequence"] = sequence
        payload["browserId"] = payload["browserId"] ?? browserId
        payload["webViewId"] = payload["webViewId"] ?? diagnosticWebViewId
        payload["navigationId"] = payload["navigationId"] ?? diagnosticNavigationId
        guard JSONSerialization.isValidJSONObject(payload),
              let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]) else {
            Self.rootCauseLogger.error("[OtlobliRootCause] event=serialization-error run=\(self.diagnosticRunId, privacy: .public) pid=\(self.diagnosticPID) seq=\(sequence)")
            return
        }
        let base64 = data.base64EncodedString()
        let chunkSize = 680
        let chunkCount = max(1, Int(ceil(Double(base64.count) / Double(chunkSize))))
        for part in 0..<chunkCount {
            let start = base64.index(base64.startIndex, offsetBy: part * chunkSize)
            let end = base64.index(start, offsetBy: min(chunkSize, base64.distance(from: start, to: base64.endIndex)))
            let chunk = String(base64[start..<end])
            Self.rootCauseLogger.notice("[OtlobliRootCause] event=\(event, privacy: .public) run=\(self.diagnosticRunId, privacy: .public) pid=\(self.diagnosticPID) seq=\(sequence) part=\(part + 1)/\(chunkCount) payload_b64=\(chunk, privacy: .public)")
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

    private func isCanonicalSheinHomeURL(_ url: URL?) -> Bool {
        guard let url, isAllowedStoreURL(url) else { return false }
        let path = url.path
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
        return path.isEmpty || path == "ar"
    }

    private func nativeBackPageType(_ url: URL?) -> String {
        guard let url else { return "missing" }
        if isCanonicalSheinHomeURL(url) { return "home-root" }
        if url.path.range(of: "-p-[0-9]+", options: .regularExpression) != nil {
            return "product"
        }
        return "other"
    }

    private func nativeNavigationTypeName(_ type: WKNavigationType) -> String {
        switch type {
        case .linkActivated: return "linkActivated"
        case .formSubmitted: return "formSubmitted"
        case .backForward: return "backForward"
        case .reload: return "reload"
        case .formResubmitted: return "formResubmitted"
        case .other: return "other"
        @unknown default: return "unknown"
        }
    }

    private func logNativeBack(
        webView: WKWebView?,
        chosenAction: String,
        navigationType: String
    ) {
        let url = webView?.url
        let backList = webView?.backForwardList.backList ?? []
        let recentBackList = backList.suffix(5)
            .map { safeURLString($0.url) }
            .joined(separator: " | ")
        NSLog(
            "[OTLOBLI_BACK] pageType=%@ currentURL=%@ currentPath=%@ canGoBack=%@ backListCount=%@ target=%@ chosenAction=%@ navigationType=%@ backList=%@",
            nativeBackPageType(url),
            safeURLString(url),
            url?.path ?? "",
            webView?.canGoBack == true ? "true" : "false",
            String(backList.count),
            nativeBackTarget,
            chosenAction,
            navigationType,
            recentBackList
        )
        logDiagnostic("native-back", surfaceStateFields().merging([
            "pageType": nativeBackPageType(url),
            "chosenAction": chosenAction,
            "navigationType": navigationType,
            "nativeBackTarget": nativeBackTarget
        ]) { current, _ in current })
        requestWebProbeSnapshot("BACK_\(chosenAction.uppercased())")
    }

    private func lockNativeBackBriefly() {
        nativeBackLocked = true
        nativeBackButton?.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.nativeBackLocked = false
            self?.nativeBackButton?.isUserInteractionEnabled = true
        }
    }

    @objc private func nativeBackPressed() {
        guard let webView = storeWebView else {
            logNativeBack(webView: nil, chosenAction: "ignored-no-webview", navigationType: "none")
            return
        }
        guard !nativeBackLocked else {
            logNativeBack(webView: webView, chosenAction: "ignored-locked", navigationType: "none")
            return
        }
        lockNativeBackBriefly()

        if nativeBackTarget == "cart" {
            logNativeBack(webView: webView, chosenAction: "backToCart", navigationType: "none")
            emit("messageFromWebview", detail: ["type": "backToCart"])
            return
        }

        // The injected page state is asynchronous. After product -> Home it
        // can still say "home" for one maintenance tick. Resolve the live URL
        // at the instant of the native tap before consulting WebKit history.
        if isCanonicalSheinHomeURL(webView.url) {
            logNativeBack(webView: webView, chosenAction: "parkStoreAtRoot", navigationType: "none")
            emit("messageFromWebview", detail: ["type": "closeStore"])
            return
        }

        if webView.canGoBack {
            pendingNativeBackTraceAction = "goBack"
            logNativeBack(webView: webView, chosenAction: "goBack", navigationType: "pending")
            webView.goBack()
        } else if let home = URL(string: "https://m.shein.com/ar/") {
            pendingNativeBackTraceAction = "loadHomeFallback"
            logNativeBack(webView: webView, chosenAction: "loadHomeFallback", navigationType: "pending")
            navigateInCurrentWebView(to: home)
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
            if detail["type"] as? String == "otlobliRootCauseProbe" {
                logWebRuntimeDiagnostic(detail)
                return
            }
            if detail["type"] as? String == "otlobliBackButtonState" {
                updateNativeBackButton(detail)
                return
            }
            let readyTypes = ["sheinSaudiReady", "sheinPageInteractive", "humanCheck", "humanCheckResolved"]
            if let type = detail["type"] as? String, readyTypes.contains(type) {
                logDiagnostic("web-readiness-message", ["messageType": type])
                hideLoadingCover()
            }
            emit("messageFromWebview", detail: detail)
        case "close":
            logDiagnostic("bridge-close", surfaceStateFields())
            closeBrowser(emitEvent: true)
        case "hide":
            logDiagnostic("bridge-hide-before", surfaceStateFields())
            requestWebProbeSnapshot("BRIDGE_PARK_BEFORE")
            isBrowserVisible = false
            parkRenderSurfaceBehindApp()
            logDiagnostic("bridge-hide-after", surfaceStateFields())
            requestWebProbeSnapshot("BRIDGE_PARKED")
        case "show":
            logDiagnostic("bridge-show-before", surfaceStateFields())
            requestWebProbeSnapshot("BRIDGE_SHOW_BEFORE")
            isBrowserVisible = true
            if let surface = surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                refreshVisibleSurfaceLayout()
            } else {
                _ = createRenderSurface(loadingMessage: "جاري استعادة المتجر…")
            }
            logDiagnostic("bridge-show-after", surfaceStateFields())
            requestWebProbeSnapshot("BRIDGE_SHOW_AFTER")
        case "navigate":
            guard let target = message.body as? String,
                  ["orders", "cart", "profile", "store-select"].contains(target) else { return }
            isBrowserVisible = false
            logDiagnostic("bridge-host-navigate", surfaceStateFields().merging([
                "target": target
            ]) { current, _ in current })
            requestWebProbeSnapshot("HOST_NAVIGATE_\(target.uppercased())")
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

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        logDiagnostic("navigation-started", surfaceStateFields())
    }

    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        logDiagnostic("navigation-redirected", surfaceStateFields())
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        updatePageNavigationContext()
        logDiagnostic("navigation-committed", surfaceStateFields())
        requestWebProbeSnapshot("NAVIGATION_COMMITTED")
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        logDiagnostic("navigation-finished", surfaceStateFields())
        requestWebProbeSnapshot("NAVIGATION_FINISHED")
        captureCookieMetadata("NAVIGATION_FINISHED")
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
        logDiagnostic("webcontent-terminated", surfaceStateFields().merging([
            "recoveryUrl": safeURLString(recoveryURL)
        ]) { current, _ in current })
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
        logDiagnostic("navigation-error", surfaceStateFields().merging([
            "phase": phase,
            "code": nsError.code,
            "domain": nsError.domain,
            "message": String(nsError.localizedDescription.prefix(1_024))
        ]) { current, _ in current })
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
        logDiagnostic("new-window-request", [
            "targetUrl": safeURLString(navigationAction.request.url),
            "mainFrame": navigationAction.targetFrame?.isMainFrame ?? false,
            "navigationType": nativeNavigationTypeName(navigationAction.navigationType)
        ])
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
        let isTopLevel = navigationAction.targetFrame?.isMainFrame == true || navigationAction.targetFrame == nil
        if isTopLevel {
            diagnosticNavigationSequence += 1
            diagnosticNavigationId = "navigation-\(diagnosticNavigationSequence)"
            updatePageNavigationContext()
        }
        logDiagnostic("navigation-policy", surfaceStateFields().merging([
            "targetUrl": safeURLString(navigationAction.request.url),
            "sourceUrl": safeURLString(navigationAction.sourceFrame.request.url),
            "mainFrame": isTopLevel,
            "newWindow": navigationAction.targetFrame == nil,
            "navigationType": nativeNavigationTypeName(navigationAction.navigationType),
            "httpMethod": navigationAction.request.httpMethod ?? ""
        ]) { current, _ in current })
        guard let url = navigationAction.request.url,
              let scheme = url.scheme?.lowercased() else {
            decisionHandler(.cancel)
            return
        }
        if isTopLevel, let pendingAction = pendingNativeBackTraceAction {
            logNativeBack(
                webView: webView,
                chosenAction: pendingAction,
                navigationType: nativeNavigationTypeName(navigationAction.navigationType)
            )
            pendingNativeBackTraceAction = nil
        }
        if scheme == "http" || scheme == "https" {
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
