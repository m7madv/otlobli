import UIKit
import WebKit
import Capacitor

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

    private enum SheinRouteClass: String {
        case allowedPublic = "allowed-public"
        case home, category, search, product
        case humanVerification = "human-verification"
        case blockedLogin = "blocked-login"
        case blockedSignup = "blocked-signup"
        case blockedAccount = "blocked-account"
        case blockedCountry = "blocked-country"
        case blockedRegion = "blocked-region"
        case blockedLanguage = "blocked-language"
        case blockedCurrency = "blocked-currency"
        case blockedCheckout = "blocked-checkout"
        case external, unknown
    }

    private static let sheinPolicyVersion = "2026.08.21-v86.208-policy-v1"

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

    private var browserId = ""
    private var savedURL: URL?
    private var lastSafePublicURL: URL?
    private var lastBlockedRoute: SheinRouteClass?
    private var lastBlockedRouteAt: Date?
    private var documentStartScript = ""
    private var loadingCoverEnabled = true
    private var isBrowserVisible = false

    private var surfaceView: UIView?
    private var storeWebView: WKWebView?
    private var urlObservation: NSKeyValueObservation?
    private var loadingCover: UIView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var loadingHomeTapTimeout: DispatchWorkItem?
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
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc func openWebView(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url),
              !isBlockedRoute(classifySheinRoute(url)) else {
            call.reject("A valid SHEIN URL is required")
            return
        }

        DispatchQueue.main.async {
            self.closeBrowser(emitEvent: false)
            self.browserId = "otlobli-shein-\(UUID().uuidString.lowercased())"
            self.savedURL = url
            self.lastSafePublicURL = self.isSafePublicRoute(url) ? url : nil
            self.documentStartScript = call.getString("otlobliDocumentStartScript", "")
            self.loadingCoverEnabled = call.getBool("otlobliLoadingCover", true)
            self.isBrowserVisible = true

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
            call.resolve(["id": self.browserId])
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard !self.browserId.isEmpty, self.savedURL != nil else {
                call.reject("SHEIN browser is not initialized")
                return
            }
            self.isBrowserVisible = true
            if let surface = self.surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                self.refreshVisibleSurfaceLayout()
            } else if !self.createRenderSurface(loadingMessage: "جاري استعادة المتجر…") {
                call.reject("Capacitor host view is unavailable")
                return
            }
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.isBrowserVisible = false
            self.parkRenderSurfaceBehindApp()
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
            self.closeBrowser(emitEvent: true)
            call.resolve()
        }
    }

    @objc func setUrl(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url),
              !isBlockedRoute(classifySheinRoute(url)) else {
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
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.bounces = true
        webView.scrollView.alwaysBounceVertical = false
        webView.isOpaque = true
        webView.backgroundColor = .white
        webView.scrollView.backgroundColor = .white
        if #available(iOS 16.4, *) {
#if DEBUG
            webView.isInspectable = true
#else
            webView.isInspectable = false
#endif
        }

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
        return true
    }

    private func destroyRenderSurface() {
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
        loadingHomeTapTimeout?.cancel()
        loadingHomeTapTimeout = nil
        nativeBackButton = nil
        nativeBackTopConstraint = nil
        nativeBackTarget = "home"
        nativeBackLocked = false
        pendingNativeBackTraceAction = nil
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
        let closingId = browserId
        let closingURL = storeWebView?.url?.absoluteString ?? savedURL?.absoluteString ?? ""
        destroyRenderSurface()
        browserId = ""
        savedURL = nil
        lastSafePublicURL = nil
        lastBlockedRoute = nil
        lastBlockedRouteAt = nil
        documentStartScript = ""
        isBrowserVisible = false
        if emitEvent && !closingId.isEmpty {
            notifyListeners("closeEvent", data: ["id": closingId, "url": closingURL])
        }
    }

    private func observeStoreURL(on webView: WKWebView) {
        urlObservation = webView.observe(\.url, options: [.new]) { [weak self, weak webView] _, change in
            guard let self,
                  let webView,
                  self.storeWebView === webView,
                  let changedURL = change.newValue ?? webView.url,
                  self.isAllowedStoreURL(changedURL) else { return }
            self.savedURL = changedURL
            if self.isSafePublicRoute(changedURL) {
                self.lastSafePublicURL = changedURL
            }
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

    private func matches(_ pattern: String, in value: String) -> Bool {
        value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private func classifySheinRoute(_ url: URL) -> SheinRouteClass {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else { return .unknown }
        guard isAllowedStoreURL(url) else { return .external }
        let path = url.path.lowercased()
        let route = path + (url.query.map { "?" + $0 } ?? "") + (url.fragment.map { "#" + $0 } ?? "")
        if matches(#"/(?:cdn-cgi|challenge|captcha|verify|verification|security|robot|risk|anti[-_]?bot|human)(?:[/?#.-]|$)"#, in: path) ||
            matches(#"(?:^|[?&#])(?:captcha|challenge|verification|security_token|risk|robot|anti[-_]?bot|human)="#, in: route) { return .humanVerification }
        if matches(#"/(?:user/)?(?:login|signin|sign-in|auth/login)(?:[/?#.-]|$)"#, in: path) { return .blockedLogin }
        if matches(#"/(?:user/)?(?:register|signup|sign-up|join)(?:[/?#.-]|$)"#, in: path) { return .blockedSignup }
        if matches(#"/(?:user|account|profile|my-account|member|orders?)(?:[/?#.-]|$)"#, in: path) { return .blockedAccount }
        if matches(#"/(?:country|countries|ship-to|shipping-country)(?:[/?#.-]|$)"#, in: path) { return .blockedCountry }
        if matches(#"/(?:region|location|shipping-address|address-book)(?:[/?#.-]|$)"#, in: path) { return .blockedRegion }
        if matches(#"/(?:language|languages|locale)(?:[/?#.-]|$)"#, in: path) { return .blockedLanguage }
        if matches(#"/(?:currency|currencies)(?:[/?#.-]|$)"#, in: path) { return .blockedCurrency }
        if matches(#"/(?:cart|bag|checkout|order-confirm|payment)(?:[/?#.-]|$)"#, in: path) { return .blockedCheckout }
        if matches(#"(?:-p-[0-9]+|/product/|/goods/|/item/)"#, in: path) ||
            matches(#"[?&](?:goods_id|goodsid|product_id|productid|mallcode|skc)="#, in: route) { return .product }
        if matches(#"/(?:search|search-result)(?:[/?#.-]|$)"#, in: path) || URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.contains(where: { $0.name.lowercased() == "search" }) == true { return .search }
        if matches(#"/(?:category|categories|collection|collections|campaign|daily|women|men|kids|curve|home-living)(?:[/?#.-]|$)"#, in: path) { return .category }
        let normalized = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if normalized.isEmpty || matches(#"^[a-z]{2}(?:-[a-z]{2})?$"#, in: normalized) { return .home }
        return .allowedPublic
    }

    private func isBlockedRoute(_ route: SheinRouteClass) -> Bool {
        switch route {
        case .blockedLogin, .blockedSignup, .blockedAccount, .blockedCountry,
             .blockedRegion, .blockedLanguage, .blockedCurrency, .blockedCheckout:
            return true
        default:
            return false
        }
    }

    private func isSafePublicRoute(_ url: URL) -> Bool {
        let route = classifySheinRoute(url)
        return isAllowedStoreURL(url) && !isBlockedRoute(route) && route != .humanVerification && route != .unknown
    }

    private func emitPolicyBlocked(_ route: SheinRouteClass) {
        let now = Date()
        if lastBlockedRoute == route,
           let lastBlockedRouteAt,
           now.timeIntervalSince(lastBlockedRouteAt) < 1 {
            return
        }
        lastBlockedRoute = route
        lastBlockedRouteAt = now
        emit("messageFromWebview", detail: [
            "type": "sheinPolicyRouteBlocked",
            "version": Self.sheinPolicyVersion,
            "routeClass": route.rawValue
        ])
    }

    private func emit(_ name: String, detail: [String: Any]? = nil, extra: [String: Any] = [:]) {
        guard !browserId.isEmpty else { return }
        var payload = extra
        payload["id"] = browserId
        if let detail { payload["detail"] = detail }
        notifyListeners(name, data: payload)
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
        let navigation = makeLoadingNavigation()
        cover.addSubview(navigation)
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
            label.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
            navigation.leadingAnchor.constraint(equalTo: cover.leadingAnchor),
            navigation.trailingAnchor.constraint(equalTo: cover.trailingAnchor),
            navigation.topAnchor.constraint(equalTo: cover.safeAreaLayoutGuide.bottomAnchor, constant: -74),
            navigation.bottomAnchor.constraint(equalTo: cover.bottomAnchor)
        ])
        loadingCover = cover
        loadingSpinner = spinner
    }

    private func hideLoadingCover() {
        loadingSpinner?.stopAnimating()
        loadingHomeTapTimeout?.cancel()
        loadingHomeTapTimeout = nil
        loadingCover?.removeFromSuperview()
        loadingCover = nil
        loadingSpinner = nil
    }

    private func makeLoadingNavigation() -> UIView {
        let navigation = UIView(frame: .zero)
        navigation.translatesAutoresizingMaskIntoConstraints = false
        navigation.backgroundColor = .white
        navigation.accessibilityViewIsModal = true

        let separator = UIView(frame: .zero)
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor(red: 188.0 / 255.0, green: 202.0 / 255.0, blue: 192.0 / 255.0, alpha: 1)
        navigation.addSubview(separator)

        let stack = UIStackView(frame: .zero)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.semanticContentAttribute = .forceRightToLeft
        navigation.addSubview(stack)

        let labels = ["الرئيسية", "طلباتي", "السلة", "حسابي"]
        let routes = ["store-select", "orders", "cart", "profile"]
        var homeButton: UIButton?
        for index in labels.indices {
            let button = UIButton(type: .system)
            let color = index == 0
                ? UIColor(red: 0, green: 105.0 / 255.0, blue: 72.0 / 255.0, alpha: 1)
                : UIColor(red: 61.0 / 255.0, green: 74.0 / 255.0, blue: 66.0 / 255.0, alpha: 1)
            button.tag = index
            button.accessibilityLabel = index == 0
                ? "اختيار المتجر؛ اضغط مرتين بسرعة"
                : labels[index]
            button.accessibilityHint = index == 0
                ? "يفتح قائمة اختيار المتجر"
                : "ينتقل إلى \(labels[index]) ويُبقي المتجر قيد التحميل"
            button.accessibilityIdentifier = routes[index]
            var configuration = UIButton.Configuration.plain()
            configuration.title = labels[index]
            // The permanent React/injected bar uses Otlobli's own 24-point
            // SVG paths. SF Symbols have visibly different silhouettes, so
            // the loading cover used to flash a different-looking bar before
            // the permanent one appeared. Draw the exact same paths here.
            configuration.image = makeLoadingNavigationIcon(route: routes[index], color: color)
            configuration.imagePlacement = .top
            configuration.imagePadding = 4
            configuration.baseForegroundColor = color
            configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 12, weight: .bold)
                outgoing.foregroundColor = color
                return outgoing
            }
            configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0)
            configuration.background.backgroundColor = .clear
            button.configuration = configuration
            button.configurationUpdateHandler = { updatedButton in
                // Keep the loading copy visually identical while pressed;
                // UIKit's default highlighted treatment otherwise briefly
                // dims and reshapes a configured system button.
                updatedButton.alpha = 1
                updatedButton.transform = .identity
                guard var stableConfiguration = updatedButton.configuration else { return }
                stableConfiguration.baseForegroundColor = color
                stableConfiguration.background.backgroundColor = .clear
                updatedButton.configuration = stableConfiguration
            }
            button.addTarget(self, action: #selector(loadingNavigationPressed(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            if index == 0 { homeButton = button }
        }

        let selectedIndicator = UIView(frame: .zero)
        selectedIndicator.translatesAutoresizingMaskIntoConstraints = false
        selectedIndicator.backgroundColor = UIColor(red: 0, green: 105.0 / 255.0, blue: 72.0 / 255.0, alpha: 1)
        selectedIndicator.layer.cornerRadius = 2
        navigation.addSubview(selectedIndicator)
        guard let homeButton else { return navigation }

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: navigation.topAnchor),
            separator.leadingAnchor.constraint(equalTo: navigation.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: navigation.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1),
            stack.topAnchor.constraint(equalTo: navigation.topAnchor, constant: 1),
            stack.leadingAnchor.constraint(equalTo: navigation.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: navigation.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: navigation.safeAreaLayoutGuide.bottomAnchor),
            selectedIndicator.topAnchor.constraint(equalTo: navigation.topAnchor, constant: 1),
            selectedIndicator.centerXAnchor.constraint(equalTo: homeButton.centerXAnchor),
            selectedIndicator.widthAnchor.constraint(equalToConstant: 32),
            selectedIndicator.heightAnchor.constraint(equalToConstant: 4)
        ])
        return navigation
    }

    private func makeLoadingNavigationIcon(route: String, color: UIColor) -> UIImage {
        let canvas = CGSize(width: 22, height: 22)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.saveGState()
            context.scaleBy(x: canvas.width / 24, y: canvas.height / 24)
            color.setStroke()

            func strokedPath() -> UIBezierPath {
                let path = UIBezierPath()
                path.lineWidth = 1.8
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                return path
            }

            switch route {
            case "store-select":
                let roof = strokedPath()
                roof.move(to: CGPoint(x: 4, y: 11.5))
                roof.addLine(to: CGPoint(x: 12, y: 4))
                roof.addLine(to: CGPoint(x: 20, y: 11.5))
                roof.stroke()

                let house = strokedPath()
                house.move(to: CGPoint(x: 6, y: 10))
                house.addLine(to: CGPoint(x: 6, y: 19))
                house.addLine(to: CGPoint(x: 18, y: 19))
                house.addLine(to: CGPoint(x: 18, y: 10))
                house.stroke()

                let door = strokedPath()
                door.move(to: CGPoint(x: 10, y: 19))
                door.addLine(to: CGPoint(x: 10, y: 14))
                door.addLine(to: CGPoint(x: 14, y: 14))
                door.addLine(to: CGPoint(x: 14, y: 19))
                door.stroke()

            case "orders":
                let parcel = UIBezierPath(roundedRect: CGRect(x: 4, y: 7, width: 16, height: 13), cornerRadius: 1.3)
                parcel.lineWidth = 1.8
                parcel.lineCapStyle = .round
                parcel.lineJoinStyle = .round
                parcel.stroke()

                let fold = strokedPath()
                fold.move(to: CGPoint(x: 4, y: 7))
                fold.addLine(to: CGPoint(x: 12, y: 3))
                fold.addLine(to: CGPoint(x: 20, y: 7))
                fold.move(to: CGPoint(x: 12, y: 11))
                fold.addLine(to: CGPoint(x: 12, y: 20))
                fold.stroke()

            case "cart":
                let basket = strokedPath()
                basket.move(to: CGPoint(x: 3, y: 4))
                basket.addLine(to: CGPoint(x: 5, y: 4))
                basket.addLine(to: CGPoint(x: 7.2, y: 15.5))
                basket.addCurve(
                    to: CGPoint(x: 9.2, y: 17.1),
                    controlPoint1: CGPoint(x: 7.4, y: 16.5),
                    controlPoint2: CGPoint(x: 8.2, y: 17.1)
                )
                basket.addLine(to: CGPoint(x: 17.8, y: 17.1))
                basket.addCurve(
                    to: CGPoint(x: 19.8, y: 15.5),
                    controlPoint1: CGPoint(x: 18.8, y: 17.1),
                    controlPoint2: CGPoint(x: 19.6, y: 16.5)
                )
                basket.addLine(to: CGPoint(x: 21, y: 8))
                basket.addLine(to: CGPoint(x: 6, y: 8))
                basket.stroke()

                let firstWheel = UIBezierPath(ovalIn: CGRect(x: 7.7, y: 18.7, width: 2.6, height: 2.6))
                firstWheel.lineWidth = 1.8
                firstWheel.stroke()
                let secondWheel = UIBezierPath(ovalIn: CGRect(x: 16.7, y: 18.7, width: 2.6, height: 2.6))
                secondWheel.lineWidth = 1.8
                secondWheel.stroke()

            default:
                let head = UIBezierPath(ovalIn: CGRect(x: 8.4, y: 4.4, width: 7.2, height: 7.2))
                head.lineWidth = 1.8
                head.stroke()

                let shoulders = strokedPath()
                shoulders.move(to: CGPoint(x: 5, y: 20))
                shoulders.addCurve(
                    to: CGPoint(x: 12, y: 13.6),
                    controlPoint1: CGPoint(x: 5, y: 16.2),
                    controlPoint2: CGPoint(x: 8.1, y: 13.6)
                )
                shoulders.addCurve(
                    to: CGPoint(x: 19, y: 20),
                    controlPoint1: CGPoint(x: 15.9, y: 13.6),
                    controlPoint2: CGPoint(x: 19, y: 16.2)
                )
                shoulders.stroke()
            }

            context.restoreGState()
        }.withRenderingMode(.alwaysOriginal)
    }

    @objc private func loadingNavigationPressed(_ sender: UIButton) {
        guard let target = sender.accessibilityIdentifier else { return }
        if target != "store-select" {
            loadingHomeTapTimeout?.cancel()
            loadingHomeTapTimeout = nil
            navigateHost(to: target)
            return
        }
        if UIAccessibility.isVoiceOverRunning {
            navigateHost(to: target)
            return
        }
        if loadingHomeTapTimeout != nil {
            loadingHomeTapTimeout?.cancel()
            loadingHomeTapTimeout = nil
            navigateHost(to: target)
            return
        }
        let timeout = DispatchWorkItem { [weak self] in
            self?.loadingHomeTapTimeout = nil
        }
        loadingHomeTapTimeout = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32, execute: timeout)
    }

    private func navigateHost(to target: String) {
        guard ["orders", "cart", "profile", "store-select"].contains(target) else { return }
        isBrowserVisible = false
        let encoded = target.replacingOccurrences(of: "'", with: "\\'")
        guard let hostWebView = bridge?.webView else {
            parkRenderSurfaceBehindApp()
            return
        }
        let revealHost = DispatchWorkItem { [weak self] in
            self?.parkRenderSurfaceBehindApp()
        }
        hostWebView.evaluateJavaScript(
            "window.dispatchEvent(new CustomEvent('otlobli:nativeNavigate',{detail:'\(encoded)'}));",
            completionHandler: { [weak self] _, _ in
                revealHost.cancel()
                self?.parkRenderSurfaceBehindApp()
            }
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: revealHost)
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
        NSLog(
            "[OTLOBLI_BACK] pageType=%@ currentPath=%@ canGoBack=%@ backListCount=%@ target=%@ chosenAction=%@ navigationType=%@",
            nativeBackPageType(url),
            url?.path ?? "",
            webView?.canGoBack == true ? "true" : "false",
            String(backList.count),
            nativeBackTarget,
            chosenAction,
            navigationType
        )
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
            if detail["type"] as? String == "otlobliBackButtonState" {
                updateNativeBackButton(detail)
                return
            }
            // A painted page is not sufficient readiness. Keep the cover until
            // required state is verified, or reveal the genuine human check.
            let readyTypes = ["sheinSaudiReady", "humanCheck", "humanCheckResolved"]
            if let type = detail["type"] as? String, readyTypes.contains(type) {
                hideLoadingCover()
            }
            emit("messageFromWebview", detail: detail)
        case "close":
            closeBrowser(emitEvent: true)
        case "hide":
            isBrowserVisible = false
            parkRenderSurfaceBehindApp()
        case "show":
            isBrowserVisible = true
            if let surface = surfaceView {
                surface.isHidden = false
                surface.superview?.bringSubviewToFront(surface)
                refreshVisibleSurfaceLayout()
            } else {
                _ = createRenderSurface(loadingMessage: "جاري استعادة المتجر…")
            }
        case "navigate":
            guard let target = message.body as? String,
                  ["orders", "cart", "profile", "store-select"].contains(target) else { return }
            navigateHost(to: target)
        default:
            break
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        emit("messageFromWebview", detail: ["type": "sheinOpeningPhase", "phase": "navigationFinish"])
        emit("browserPageLoaded", extra: ["url": webView.url?.absoluteString ?? ""])
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        emit("messageFromWebview", detail: ["type": "sheinOpeningPhase", "phase": "initialNavigationStart"])
    }

    public func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard webView === storeWebView else { return }
        emit("messageFromWebview", detail: ["type": "sheinOpeningPhase", "phase": "navigationCommit"])
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
            let route = classifySheinRoute(url)
            if isBlockedRoute(route) {
                emitPolicyBlocked(route)
            } else if isAllowedStoreURL(url) {
                savedURL = url
                if isSafePublicRoute(url) { lastSafePublicURL = url }
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
        let isTopLevel = navigationAction.targetFrame?.isMainFrame == true || navigationAction.targetFrame == nil
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
            if isTopLevel {
                let route = classifySheinRoute(url)
                if isBlockedRoute(route) {
                    emitPolicyBlocked(route)
                    decisionHandler(.cancel)
                    return
                }
                if isSafePublicRoute(url) {
                    lastSafePublicURL = url
                }
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
        guard !isBrowserVisible, storeWebView != nil else { return }
        destroyRenderSurface()
    }
}
