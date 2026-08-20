import Foundation
import WebKit

enum SheinCleanBrowserScripts {
    private static func quoted(_ value: String) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: [value]),
              let encoded = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return String(encoded.dropFirst().dropLast())
    }

    static func userScripts(for mode: SheinCleanBrowserMode, runId: String) -> [WKUserScript] {
        guard mode.usesCleanController else { return [] }
        var scripts = [WKUserScript(
            source: passiveDiagnostics(runId: runId, mode: mode),
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )]
        if mode.usesCapture {
            scripts.append(WKUserScript(
                source: captureModule,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }
        if mode.usesBlocking {
            scripts.append(WKUserScript(
                source: blockingModule,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }
        return scripts
    }

    private static func passiveDiagnostics(runId: String, mode: SheinCleanBrowserMode) -> String {
        passiveDiagnosticsTemplate
            .replacingOccurrences(of: "__RUN_ID__", with: quoted(runId))
            .replacingOccurrences(of: "__MODE__", with: quoted(mode.wireName))
            .replacingOccurrences(of: "__VERSION__", with: quoted(SheinCleanBrowserMode.diagnosticVersion))
    }

    // This is diagnostics only. It does not patch console, history, fetch, XHR,
    // storage, events, or page DOM. The MutationObserver heartbeat uses a
    // detached Text node, matching the bounded v86.202 passive-probe design.
    private static let passiveDiagnosticsTemplate = #"""
    (function () {
      'use strict';
      if (window.top !== window || window.__otlobliCleanDiagnosticProbe) return;

      var runId = __RUN_ID__;
      var mode = __MODE__;
      var version = __VERSION__;
      var documentId = (self.crypto && typeof self.crypto.randomUUID === 'function')
        ? self.crypto.randomUUID()
        : 'document-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
      var sequence = 0;
      var stopped = false;
      var lastClick = null;
      var heartbeat = { interval: 0, timeout: 0, raf: 0, promise: 0, message: 0, mutation: 0 };
      var detachedText = document.createTextNode('0');
      var mutationObserver = new MutationObserver(function () { heartbeat.mutation += 1; });
      mutationObserver.observe(detachedText, { characterData: true });

      function safeUrl(raw) {
        try {
          var value = new URL(String(raw || ''), location.href);
          return value.origin + value.pathname;
        } catch (_) {
          return '';
        }
      }

      function safeText(raw) {
        return String(raw == null ? '' : raw)
          .replace(/https?:\/\/[^\s)]+/gi, function (value) { return safeUrl(value); })
          .replace(/[?#][^\s]*/g, '')
          .slice(0, 480);
      }

      function rootState() {
        var branch = document.getElementById('shein-branch');
        var app = document.getElementById('app');
        return {
          sheinBranchExists: !!branch,
          appExists: !!app,
          onlyAppRoot: !!app && !branch,
          readyState: document.readyState,
          hidden: document.hidden,
          hasFocus: typeof document.hasFocus === 'function' ? document.hasFocus() : null,
          path: location.pathname
        };
      }

      function post(kind, fields) {
        if (stopped) return;
        var handler = window.webkit && window.webkit.messageHandlers &&
          window.webkit.messageHandlers.otlobliCleanDiagnostics;
        if (!handler || typeof handler.postMessage !== 'function') return;
        var payload = Object.assign({
          protocolVersion: 1,
          diagnosticVersion: version,
          runId: runId,
          mode: mode,
          documentId: documentId,
          sequence: ++sequence,
          kind: kind,
          at: Date.now(),
          monotonicMs: Math.round(performance.now())
        }, fields || {});
        try { handler.postMessage(payload); } catch (_) {}
      }

      function errorShape(value) {
        if (!value) return { name: '', message: '' };
        return {
          name: safeText(value.name || ''),
          message: safeText(value.message || value.reason || value),
          stack: safeText(value.stack || '')
        };
      }

      function reportResources(entries) {
        for (var i = 0; i < entries.length; i += 1) {
          var entry = entries[i];
          var url = safeUrl(entry.name);
          if (!/^https:\/\/sheinm\.ltwebstatic\.com\/pwa_dist\/assets\/.*\.js$/i.test(url)) continue;
          post('resource', {
            url: url,
            initiator: safeText(entry.initiatorType || ''),
            resourceType: safeText(entry.initiatorType || 'other'),
            transferSize: Number(entry.transferSize || 0),
            encodedBodySize: Number(entry.encodedBodySize || 0),
            decodedBodySize: Number(entry.decodedBodySize || 0),
            durationMs: Math.round(Number(entry.duration || 0)),
            responseStatus: Number(entry.responseStatus || 0) || null
          });
        }
      }

      window.addEventListener('error', function (event) {
        var target = event && event.target;
        if (target && target !== window) {
          post('resource-error', {
            tag: safeText(target.tagName || ''),
            url: safeUrl(target.src || target.href || '')
          });
          return;
        }
        post('javascript-error', Object.assign(errorShape(event && event.error), {
          message: safeText((event && event.message) || '')
        }));
      }, true);

      window.addEventListener('unhandledrejection', function (event) {
        var shape = errorShape(event && event.reason);
        post(/ChunkLoadError|Loading chunk/i.test(shape.message + ' ' + shape.stack)
          ? 'chunk-load-error'
          : 'unhandled-rejection', shape);
      });

      document.addEventListener('securitypolicyviolation', function (event) {
        post('csp-violation', {
          directive: safeText(event.effectiveDirective || event.violatedDirective || ''),
          blockedUrl: safeUrl(event.blockedURI || ''),
          disposition: safeText(event.disposition || '')
        });
      });

      document.addEventListener('click', function (event) {
        if (!event.isTrusted || lastClick) return;
        var before = rootState();
        lastClick = { at: Date.now(), path: before.path };
        post('trusted-click', {
          defaultPrevented: !!event.defaultPrevented,
          targetTag: safeText(event.target && event.target.tagName || ''),
          before: before
        });
        setTimeout(function () {
          var after = rootState();
          post('click-reaction', {
            delayMs: 500,
            pathChanged: after.path !== lastClick.path,
            after: after
          });
          lastClick = null;
        }, 500);
      }, { capture: true, passive: true });

      ['pageshow', 'pagehide', 'visibilitychange', 'freeze', 'resume'].forEach(function (name) {
        var target = name === 'visibilitychange' ? document : window;
        target.addEventListener(name, function (event) {
          post('lifecycle', {
            event: name,
            persisted: typeof event.persisted === 'boolean' ? event.persisted : null,
            root: rootState()
          });
        }, { passive: true });
      });

      if (typeof PerformanceObserver === 'function') {
        try {
          var resourceObserver = new PerformanceObserver(function (list) {
            reportResources(list.getEntries());
          });
          resourceObserver.observe({ type: 'resource', buffered: true });
        } catch (_) {}
      }

      var channel = typeof MessageChannel === 'function' ? new MessageChannel() : null;
      if (channel) {
        channel.port1.onmessage = function () { heartbeat.message += 1; };
      }

      function heartbeatTick() {
        if (stopped) return;
        heartbeat.interval += 1;
        Promise.resolve().then(function () { heartbeat.promise += 1; });
        setTimeout(function () { heartbeat.timeout += 1; }, 0);
        if (typeof requestAnimationFrame === 'function') {
          requestAnimationFrame(function () { heartbeat.raf += 1; });
        }
        if (channel) channel.port2.postMessage(heartbeat.interval);
        detachedText.data = String(heartbeat.interval);
      }

      setInterval(heartbeatTick, 400);
      setInterval(function () {
        post('heartbeat', { counters: Object.assign({}, heartbeat), root: rootState() });
      }, 1000);

      window.__otlobliCleanDiagnosticProbe = Object.freeze({
        version: version,
        runId: runId,
        mode: mode,
        documentId: documentId,
        snapshot: function (reason) {
          post('snapshot', { reason: safeText(reason || 'external'), root: rootState() });
        }
      });
      post('document-start', { root: rootState(), wasDiscarded: !!document.wasDiscarded });
    })();
    """#

    // Installed only in CAPTURE_ONLY and CAPTURE_AND_BLOCKING. It performs no
    // polling or mutation observation. The native Add button calls snapshot()
    // once, so DOM work is bounded to explicit user intent.
    static let captureModule = #"""
    (function () {
      'use strict';
      if (window.top !== window || window.__otlobliCleanCapture) return;
      var installedAt = performance.now();
      var documentId = (self.crypto && typeof self.crypto.randomUUID === 'function')
        ? self.crypto.randomUUID()
        : 'capture-document-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
      var installRootBefore = rootFingerprint();

      function rootFingerprint() {
        return {
          path: location.pathname,
          readyState: document.readyState,
          app: !!document.getElementById('app'),
          sheinBranch: !!document.getElementById('shein-branch'),
          documentElementChildren: document.documentElement ? document.documentElement.childElementCount : 0,
          bodyChildren: document.body ? document.body.childElementCount : 0
        };
      }
      function report(operation, fields) {
        var handler = window.webkit && window.webkit.messageHandlers &&
          window.webkit.messageHandlers.otlobliCleanDiagnostics;
        if (!handler || typeof handler.postMessage !== 'function') return;
        try {
          handler.postMessage(Object.assign({
            protocolVersion: 1,
            kind: 'module-operation',
            module: 'capture',
            operation: operation,
            documentId: documentId,
            at: Date.now()
          }, fields || {}));
        } catch (_) {}
      }

      function text(selector) {
        var node = document.querySelector(selector);
        return node ? String(node.getAttribute('content') || node.textContent || '').trim().slice(0, 300) : '';
      }
      function cleanPrice(raw) {
        var match = String(raw || '').replace(/,/g, '').match(/(?:USD|US\$|\$)?\s*(\d+(?:\.\d{1,2})?)/i);
        return match ? Number(match[1]) : 0;
      }
      function selectedValue(kind) {
        var exact = kind === 'size'
          ? ['[data-attr-name="size"] [role="radio"][aria-checked="true"]', '[data-attr-name="Size"] [role="radio"][aria-checked="true"]']
          : ['[data-attr-name="color"] [role="radio"][aria-checked="true"]', '[data-attr-name="Color"] [role="radio"][aria-checked="true"]'];
        for (var i = 0; i < exact.length; i += 1) {
          var node = document.querySelector(exact[i]);
          if (!node) continue;
          var value = String(node.getAttribute('aria-label') || node.getAttribute('data-value') || node.textContent || '').trim();
          if (value && value.length <= 100) return value;
        }
        return '';
      }
      function safeLink() {
        return location.origin + location.pathname;
      }
      function productId() {
        var match = location.pathname.match(/-p-(\d+)/i);
        return match ? match[1] : text('meta[property="product:retailer_item_id"]');
      }
      function snapshot() {
        var before = rootFingerprint();
        var startedAt = performance.now();
        try {
          var id = productId();
          var title = text('meta[property="og:title"]') || text('h1');
          var priceText = text('meta[property="product:price:amount"]') ||
            text('[data-testid="product-price"]') || text('[class*="bsc-main-price"]');
          var result = {
            protocolVersion: 1,
            moduleVersion: '1.0.0',
            documentId: documentId,
            isProductPage: !!id,
            product: {
              id: id,
              sku: text('meta[property="product:retailer_item_id"]') || id,
              title: title,
              image: text('meta[property="og:image"]'),
              priceUsd: cleanPrice(priceText),
              currency: text('meta[property="product:price:currency"]') || 'USD',
              color: selectedValue('color'),
              size: selectedValue('size'),
              link: safeLink()
            }
          };
          report('snapshot', {
            durationMs: Math.round((performance.now() - startedAt) * 1000) / 1000,
            selectorCategory: 'product-metadata-and-selected-variants',
            elementsMatched: id ? 1 : 0,
            elementsChanged: 0,
            isProductPage: !!id,
            rootBefore: before,
            rootAfter: rootFingerprint()
          });
          return result;
        } catch (error) {
          report('snapshot-error', {
            durationMs: Math.round((performance.now() - startedAt) * 1000) / 1000,
            message: String(error && (error.message || error) || '').slice(0, 300),
            rootBefore: before,
            rootAfter: rootFingerprint()
          });
          throw error;
        }
      }
      window.__otlobliCleanCapture = Object.freeze({
        version: '1.0.0',
        documentId: documentId,
        snapshot: snapshot
      });
      report('module-install', {
        durationMs: Math.round((performance.now() - installedAt) * 1000) / 1000,
        selectorCategory: 'none',
        elementsMatched: 0,
        elementsChanged: 0,
        rootBefore: installRootBefore,
        rootAfter: rootFingerprint()
      });
    })();
    """#

    // Installed only in BLOCKING_ONLY and CAPTURE_AND_BLOCKING. Business scope:
    // block confirmed semantic SHEIN purchase controls so checkout cannot occur
    // outside Otlobli. It does not touch login, risk, privacy, navigation, the
    // application root, or generic clicks.
    static let blockingModule = #"""
    (function () {
      'use strict';
      if (window.top !== window || window.__otlobliCleanBlocking) return;
      var documentId = (self.crypto && typeof self.crypto.randomUUID === 'function')
        ? self.crypto.randomUUID()
        : 'blocking-document-' + Date.now().toString(36) + '-' + Math.random().toString(36).slice(2);
      var selector = [
        'button[aria-label="Add to Bag"]',
        'button[aria-label="Add to Cart"]',
        'button[aria-label="أضف إلى عربة التسوق"]',
        'button[aria-label="أضف للسلة"]',
        '[role="button"][aria-label="Add to Bag"]',
        '[role="button"][aria-label="Add to Cart"]',
        '[data-testid="product-detail-add-to-bag"]'
      ].join(',');
      var blocked = new WeakSet();
      var observer = null;
      var stopped = false;
      var installed = false;

      function rootFingerprint() {
        return {
          path: location.pathname,
          readyState: document.readyState,
          app: !!document.getElementById('app'),
          sheinBranch: !!document.getElementById('shein-branch'),
          documentElementChildren: document.documentElement ? document.documentElement.childElementCount : 0,
          bodyChildren: document.body ? document.body.childElementCount : 0
        };
      }

      function reportOperation(operation, fields) {
        var handler = window.webkit && window.webkit.messageHandlers &&
          window.webkit.messageHandlers.otlobliCleanDiagnostics;
        if (!handler || typeof handler.postMessage !== 'function') return;
        try {
          handler.postMessage(Object.assign({
            protocolVersion: 1,
            kind: 'module-operation',
            module: 'blocking',
            operation: operation,
            documentId: documentId,
            at: Date.now()
          }, fields || {}));
        } catch (_) {}
      }

      function report(count) {
        var handler = window.webkit && window.webkit.messageHandlers &&
          window.webkit.messageHandlers.otlobliCleanBlocking;
        if (!handler || typeof handler.postMessage !== 'function') return;
        try {
          handler.postMessage({
            protocolVersion: 1,
            moduleVersion: '1.0.0',
            category: 'native-purchase-control',
            count: count,
            path: location.pathname
          });
        } catch (_) {}
      }

      function blockElement(node) {
        if (!node) return { matched: 0, changed: 0 };
        if (blocked.has(node)) return { matched: 1, changed: 0 };
        blocked.add(node);
        node.setAttribute('data-otlobli-clean-blocked', 'native-purchase-control');
        node.style.setProperty('display', 'none', 'important');
        return { matched: 1, changed: 1 };
      }

      function scanRoot(root) {
        var result = { matched: 0, changed: 0 };
        if (stopped || !root) return result;
        if (root.matches && root.matches(selector)) {
          var rootResult = blockElement(root);
          result.matched += rootResult.matched;
          result.changed += rootResult.changed;
        }
        var nodes = root.querySelectorAll ? root.querySelectorAll(selector) : [];
        for (var i = 0; i < nodes.length && i < 32; i += 1) {
          var nodeResult = blockElement(nodes[i]);
          result.matched += nodeResult.matched;
          result.changed += nodeResult.changed;
        }
        if (result.changed) report(result.changed);
        return result;
      }

      function install() {
        if (installed || stopped) return;
        installed = true;
        var before = rootFingerprint();
        var startedAt = performance.now();
        var initial = scanRoot(document.documentElement);
        reportOperation('install-scan', {
          durationMs: Math.round((performance.now() - startedAt) * 1000) / 1000,
          selectorCategory: 'native-purchase-control',
          elementsMatched: initial.matched,
          elementsChanged: initial.changed,
          rootBefore: before,
          rootAfter: rootFingerprint()
        });
        observer = new MutationObserver(function (records) {
          var callbackBefore = rootFingerprint();
          var callbackStartedAt = performance.now();
          var inspected = 0;
          var matched = 0;
          var changed = 0;
          for (var i = 0; i < records.length && inspected < 48; i += 1) {
            for (var j = 0; j < records[i].addedNodes.length && inspected < 48; j += 1) {
              var node = records[i].addedNodes[j];
              if (node && node.nodeType === 1) {
                var result = scanRoot(node);
                matched += result.matched;
                changed += result.changed;
              }
              inspected += 1;
            }
          }
          reportOperation('mutation-scan', {
            durationMs: Math.round((performance.now() - callbackStartedAt) * 1000) / 1000,
            selectorCategory: 'native-purchase-control',
            mutationRecordCount: records.length,
            addedNodesInspected: inspected,
            elementsMatched: matched,
            elementsChanged: changed,
            rootBefore: callbackBefore,
            rootAfter: rootFingerprint()
          });
        });
        observer.observe(document.documentElement, { childList: true, subtree: true });
      }

      function dispose() {
        var before = rootFingerprint();
        var startedAt = performance.now();
        stopped = true;
        if (observer) observer.disconnect();
        observer = null;
        reportOperation('dispose', {
          durationMs: Math.round((performance.now() - startedAt) * 1000) / 1000,
          selectorCategory: 'none',
          elementsMatched: 0,
          elementsChanged: 0,
          rootBefore: before,
          rootAfter: rootFingerprint()
        });
      }

      window.addEventListener('pagehide', dispose, { once: true, passive: true });
      window.__otlobliCleanBlocking = Object.freeze({ version: '1.0.0', dispose: dispose });
      if (document.documentElement) install();
      else document.addEventListener('DOMContentLoaded', install, { once: true });
    })();
    """#
}
