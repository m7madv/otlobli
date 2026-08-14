import UIKit
import WebKit
import Capacitor

/// A deliberately small, app-owned SHEIN browser for iOS.
///
/// SHEIN no longer runs through the generic modal in-app-browser plugin. This
/// surface has one WKWebView, one message bridge, one persistent website data
/// store, and one foreground lifecycle. The existing store JavaScript remains
/// a web concern; presentation/session ownership stays here.
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

    private static let processPool = WKProcessPool()
    private static let messageHandlers = ["messageHandler", "close", "hide", "show", "navigate"]

    private var browserId = ""
    private var surfaceView: UIView?
    private var webView: WKWebView?
    private var urlObservation: NSKeyValueObservation?
    private var loadingCover: UIView?
    private var loadingSpinner: UIActivityIndicatorView?
    private var nativeBackButton: UIButton?
    private var nativeBackTopConstraint: NSLayoutConstraint?
    private var nativeBackTarget = "home"
    private var isSurfaceHidden = true

    // A one-shot display-linked foreground repair. The same WKWebView and its
    // DOM/session survive; only its remote rendering layer is reattached.
    private var needsForegroundRebind = false
    private var rebindDisplayLink: CADisplayLink?
    private var rebindFallback: DispatchWorkItem?
    private var rebindSnapshot: UIView?
    private var rebindOffset = CGPoint.zero
    private var rebindReadinessAttempt = 0

    public override func load() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopForegroundRebind()
    }

    @objc func openWebView(_ call: CAPPluginCall) {
        guard let urlString = call.getString("url"),
              let url = URL(string: urlString),
              isAllowedStoreURL(url) else {
            call.reject("A valid SHEIN URL is required")
            return
        }

        DispatchQueue.main.async {
            guard let hostView = self.bridge?.viewController?.view else {
                call.reject("Capacitor host view is unavailable")
                return
            }

            self.closeBrowser(emitEvent: false)
            self.browserId = "otlobli-shein-\(UUID().uuidString.lowercased())"
            self.isSurfaceHidden = call.getBool("hidden", false)

            let contentController = WKUserContentController()
            for name in Self.messageHandlers {
                contentController.add(self, name: name)
            }
            contentController.addUserScript(WKUserScript(
                source: self.mobileBridgeScript(),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
            if let documentStartScript = call.getString("otlobliDocumentStartScript"),
               !documentStartScript.isEmpty {
                contentController.addUserScript(WKUserScript(
                    source: documentStartScript,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                ))
            }

            let configuration = WKWebViewConfiguration()
            configuration.websiteDataStore = .default()
            configuration.processPool = Self.processPool
            configuration.userContentController = contentController
            configuration.allowsInlineMediaPlayback = true
            configuration.mediaTypesRequiringUserActionForPlayback = []
            configuration.suppressesIncrementalRendering = false
            if #available(iOS 14.0, *) {
                configuration.defaultWebpagePreferences.allowsContentJavaScript = true
                configuration.defaultWebpagePreferences.preferredContentMode = .mobile
            }

            let surface = UIView(frame: .zero)
            surface.translatesAutoresizingMaskIntoConstraints = false
            surface.backgroundColor = .white
            surface.isOpaque = true
            surface.isHidden = self.isSurfaceHidden
            surface.isUserInteractionEnabled = !self.isSurfaceHidden
            hostView.addSubview(surface)
            NSLayoutConstraint.activate([
                surface.topAnchor.constraint(equalTo: hostView.topAnchor),
                surface.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                surface.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
                surface.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
            ])

            let storeWebView = WKWebView(frame: .zero, configuration: configuration)
            storeWebView.navigationDelegate = self
            storeWebView.uiDelegate = self
            storeWebView.allowsBackForwardNavigationGestures = true
            storeWebView.scrollView.bounces = true
            storeWebView.scrollView.alwaysBounceVertical = false
            storeWebView.isOpaque = true
            storeWebView.backgroundColor = .white
            storeWebView.scrollView.backgroundColor = .white

            self.surfaceView = surface
            self.webView = storeWebView
            self.attachWebView(storeWebView, to: surface)
            self.installNativeBackButton(in: surface, webView: storeWebView)
            if call.getBool("otlobliLoadingCover", true) {
                self.installLoadingCover(in: surface)
            }

            self.urlObservation = storeWebView.observe(\.url, options: [.new]) { [weak self, weak storeWebView] _, change in
                guard let self,
                      let storeWebView,
                      self.webView === storeWebView,
                      let changedURL = change.newValue ?? storeWebView.url else { return }
                self.emit("urlChangeEvent", extra: ["url": changedURL.absoluteString])
            }

            hostView.bringSubviewToFront(surface)
            storeWebView.load(self.initialRequest(url: url, call: call))
            call.resolve(["id": self.browserId])
        }
    }

    @objc func show(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let surface = self.surfaceView else {
                call.reject("SHEIN browser is not initialized")
                return
            }
            self.isSurfaceHidden = false
            surface.isHidden = false
            surface.isUserInteractionEnabled = true
            surface.superview?.bringSubviewToFront(surface)
            if self.needsForegroundRebind {
                self.beginForegroundRebindWhenReady()
            }
            call.resolve()
        }
    }

    @objc func hide(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.hideSurface()
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
              isAllowedStoreURL(url) else {
            call.reject("A valid SHEIN URL is required")
            return
        }
        DispatchQueue.main.async {
            guard let webView = self.webView else {
                call.reject("SHEIN browser is not initialized")
                return
            }
            webView.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 45))
            call.resolve()
        }
    }

    @objc func executeScript(_ call: CAPPluginCall) {
        guard let code = call.getString("code"), !code.isEmpty else {
            call.reject("JavaScript code is required")
            return
        }
        DispatchQueue.main.async {
            guard let webView = self.webView else {
                call.reject("SHEIN browser is not initialized")
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
            guard let webView = self.webView else {
                call.reject("SHEIN browser is not initialized")
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

    private func isAllowedStoreURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host?.lowercased() else { return false }
        return host == "shein.com" || host.hasSuffix(".shein.com")
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

    private func attachWebView(_ webView: WKWebView, to surface: UIView) {
        webView.removeFromSuperview()
        webView.translatesAutoresizingMaskIntoConstraints = false
        surface.insertSubview(webView, at: 0)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: surface.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: surface.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: surface.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: surface.bottomAnchor)
        ])
    }

    private func emit(_ name: String, detail: [String: Any]? = nil, extra: [String: Any] = [:]) {
        guard !browserId.isEmpty else { return }
        var payload = extra
        payload["id"] = browserId
        if let detail { payload["detail"] = detail }
        notifyListeners(name, data: payload)
    }

    private func hideSurface() {
        isSurfaceHidden = true
        surfaceView?.isUserInteractionEnabled = false
        surfaceView?.isHidden = true
    }

    private func closeBrowser(emitEvent: Bool) {
        let closingId = browserId
        let closingURL = webView?.url?.absoluteString ?? ""
        stopForegroundRebind()
        urlObservation?.invalidate()
        urlObservation = nil
        webView?.stopLoading()
        webView?.navigationDelegate = nil
        webView?.uiDelegate = nil
        if let contentController = webView?.configuration.userContentController {
            for name in Self.messageHandlers {
                contentController.removeScriptMessageHandler(forName: name)
            }
            contentController.removeAllUserScripts()
        }
        webView?.removeFromSuperview()
        surfaceView?.removeFromSuperview()
        webView = nil
        surfaceView = nil
        loadingCover = nil
        loadingSpinner = nil
        nativeBackButton = nil
        nativeBackTopConstraint = nil
        nativeBackTarget = "home"
        browserId = ""
        isSurfaceHidden = true
        needsForegroundRebind = false
        if emitEvent && !closingId.isEmpty {
            notifyListeners("closeEvent", data: ["id": closingId, "url": closingURL])
        }
    }

    private func installLoadingCover(in surface: UIView) {
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
        label.text = "جاري تجهيز المتجر…"
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

    private func installNativeBackButton(in surface: UIView, webView: WKWebView) {
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
        let top = button.topAnchor.constraint(equalTo: webView.topAnchor, constant: 12)
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
        switch nativeBackTarget {
        case "cart":
            emit("messageFromWebview", detail: ["type": "backToCart"])
        case "exit":
            emit("messageFromWebview", detail: ["type": "requestStoreExit", "store": "shein"])
        default:
            if webView?.canGoBack == true {
                webView?.goBack()
            } else if let home = URL(string: "https://m.shein.com/ar/") {
                webView?.load(URLRequest(url: home))
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
        guard message.webView === webView else { return }
        switch message.name {
        case "messageHandler":
            guard let body = message.body as? [String: Any],
                  let detail = body["detail"] as? [String: Any] else { return }
            if detail["type"] as? String == "otlobliBackButtonState" {
                updateNativeBackButton(detail)
                return
            }
            let readyTypes = ["sheinSaudiReady", "sheinPageInteractive", "humanCheck", "humanCheckResolved"]
            if let type = detail["type"] as? String, readyTypes.contains(type) {
                hideLoadingCover()
            }
            emit("messageFromWebview", detail: detail)
        case "close":
            closeBrowser(emitEvent: true)
        case "hide":
            hideSurface()
        case "show":
            isSurfaceHidden = false
            surfaceView?.isHidden = false
            surfaceView?.isUserInteractionEnabled = true
            if let surface = surfaceView { surface.superview?.bringSubviewToFront(surface) }
        case "navigate":
            guard let target = message.body as? String,
                  ["orders", "cart", "profile", "store-select"].contains(target) else { return }
            hideSurface()
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
        emit("browserPageLoaded", extra: ["url": webView.url?.absoluteString ?? ""])
    }

    public func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        emitPageError(error, phase: "didFailProvisionalNavigation")
    }

    public func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        emitPageError(error, phase: "didFailNavigation")
    }

    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        emit("pageLoadError", extra: [
            "phase": "webContentProcessDidTerminate",
            "url": webView.url?.absoluteString ?? ""
        ])
    }

    private func emitPageError(_ error: Error, phase: String) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }
        emit("pageLoadError", extra: [
            "phase": phase,
            "code": nsError.code,
            "domain": nsError.domain,
            "message": nsError.localizedDescription,
            "url": webView?.url?.absoluteString ?? ""
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
                webView.load(URLRequest(url: url))
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

    @objc private func applicationDidEnterBackground() {
        if webView != nil { needsForegroundRebind = true }
    }

    @objc private func applicationDidBecomeActive() {
        guard needsForegroundRebind, !isSurfaceHidden else { return }
        beginForegroundRebindWhenReady()
    }

    private func beginForegroundRebindWhenReady() {
        guard rebindDisplayLink == nil,
              UIApplication.shared.applicationState == .active,
              let surface = surfaceView,
              let webView,
              webView.superview === surface else { return }

        guard surface.window != nil, webView.window != nil else {
            guard rebindReadinessAttempt < 40 else {
                // Keep the repair armed. A later explicit show/activation gets
                // a fresh readiness window without ever detaching off-window.
                rebindReadinessAttempt = 0
                return
            }
            rebindReadinessAttempt += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.beginForegroundRebindWhenReady()
            }
            return
        }

        rebindReadinessAttempt = 0
        needsForegroundRebind = false
        rebindOffset = webView.scrollView.contentOffset
        let snapshot = webView.snapshotView(afterScreenUpdates: false)
        if let snapshot {
            snapshot.frame = webView.frame
            snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            snapshot.isUserInteractionEnabled = false
            surface.insertSubview(snapshot, aboveSubview: webView)
        }
        rebindSnapshot = snapshot
        webView.removeFromSuperview()

        let link = CADisplayLink(target: self, selector: #selector(finishForegroundRebind))
        link.add(to: .main, forMode: .common)
        rebindDisplayLink = link

        let fallback = DispatchWorkItem { [weak self] in self?.finishForegroundRebind() }
        rebindFallback = fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: fallback)
    }

    @objc private func finishForegroundRebind() {
        rebindDisplayLink?.invalidate()
        rebindDisplayLink = nil
        rebindFallback?.cancel()
        rebindFallback = nil

        guard let surface = surfaceView,
              let webView,
              webView.superview == nil else {
            rebindSnapshot?.removeFromSuperview()
            rebindSnapshot = nil
            return
        }

        attachWebView(webView, to: surface)
        surface.layoutIfNeeded()
        webView.scrollView.setContentOffset(rebindOffset, animated: false)
        webView.setNeedsDisplay()
        webView.scrollView.setNeedsDisplay()
        webView.evaluateJavaScript("window.dispatchEvent(new Event('resize'));", completionHandler: nil)

        if let snapshot = rebindSnapshot {
            surface.bringSubviewToFront(snapshot)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak snapshot] in
                snapshot?.removeFromSuperview()
            }
        }
        rebindSnapshot = nil
        if let cover = loadingCover { surface.bringSubviewToFront(cover) }
        if let button = nativeBackButton, !button.isHidden { surface.bringSubviewToFront(button) }
    }

    private func stopForegroundRebind() {
        rebindDisplayLink?.invalidate()
        rebindDisplayLink = nil
        rebindFallback?.cancel()
        rebindFallback = nil
        rebindSnapshot?.removeFromSuperview()
        rebindSnapshot = nil
        rebindReadinessAttempt = 0
    }
}
