import Foundation

enum SheinCleanBrowserMode: Int, CaseIterable {
    case raw = 0
    case rawWithCacheGuard = 1
    case captureOnly = 2
    case blockingOnly = 3
    case captureAndBlocking = 4
    case legacyControl = 5

    static let diagnosticVersion = "2026.08.21-v86.205-clean-room-selector-single-flight-v1"

    var wireName: String {
        switch self {
        case .raw: return "RAW"
        case .rawWithCacheGuard: return "RAW_WITH_CACHE_GUARD"
        case .captureOnly: return "CAPTURE_ONLY"
        case .blockingOnly: return "BLOCKING_ONLY"
        case .captureAndBlocking: return "CAPTURE_AND_BLOCKING"
        case .legacyControl: return "LEGACY_BROWSER_CONTROL"
        }
    }

    var title: String {
        switch self {
        case .raw: return "RAW"
        case .rawWithCacheGuard: return "RAW + CACHE GUARD"
        case .captureOnly: return "CAPTURE ONLY"
        case .blockingOnly: return "BLOCKING ONLY"
        case .captureAndBlocking: return "CAPTURE + BLOCKING"
        case .legacyControl: return "LEGACY CONTROL"
        }
    }

    var summary: String {
        switch self {
        case .raw:
            return "Guest SHEIN in one WKWebView with passive diagnostics only."
        case .rawWithCacheGuard:
            return "RAW plus the exact native raw/XHR JavaScript-prefetch rule."
        case .captureOnly:
            return "RAW plus the new on-demand product snapshot module."
        case .blockingOnly:
            return "RAW plus exact semantic blocking of SHEIN purchase controls."
        case .captureAndBlocking:
            return "The independent clean capture and blocking modules together."
        case .legacyControl:
            return "The current OtlobliSheinBrowser implementation, unchanged."
        }
    }

    var usesCleanController: Bool { self != .legacyControl }
    var usesCacheGuard: Bool { self == .rawWithCacheGuard }
    var usesCapture: Bool { self == .captureOnly || self == .captureAndBlocking }
    var usesBlocking: Bool { self == .blockingOnly || self == .captureAndBlocking }

    // Capture and Blocking deliberately use unguarded RAW in this first IPA.
    // The cache guard cannot become their foundation until physical evidence
    // proves that RAW needs it and that the guard works on the target device.
    var foundationName: String {
        usesCleanController ? "RAW (unguarded)" : "legacy-owned"
    }

    var browserImplementation: String {
        usesCleanController ? "SheinCleanBrowserViewController" : "OtlobliSheinBrowserPlugin"
    }

    var contentRuleIdentity: String {
        if usesCacheGuard { return SheinCleanBrowserContentRule.identifier }
        if self == .legacyControl { return "legacy-owned"
        }
        return "absent"
    }

    var dataStoreIdentifier: UUID? {
        switch self {
        case .raw:
            return UUID(uuidString: "720B1500-0A4B-4A00-9000-000000000000")
        case .rawWithCacheGuard:
            return UUID(uuidString: "720B1500-0A4B-4A00-9000-000000000001")
        case .captureOnly:
            return UUID(uuidString: "720B1500-0A4B-4A00-9000-000000000002")
        case .blockingOnly:
            return UUID(uuidString: "720B1500-0A4B-4A00-9000-000000000003")
        case .captureAndBlocking:
            return UUID(uuidString: "720B1500-0A4B-4A00-9000-000000000004")
        case .legacyControl:
            return nil
        }
    }

    var dataStoreIdentity: String {
        dataStoreIdentifier?.uuidString.lowercased() ?? "WKWebsiteDataStore.default (legacy)"
    }
}

enum SheinCleanBrowserContentRule {
    static let identifier = "com.otlobli.shein.clean.raw-js-prefetch-block.v1"
    static let json = #"""
    [
      {
        "trigger": {
          "url-filter": "^https://sheinm\\.ltwebstatic\\.com/pwa_dist/assets/.*\\.js",
          "url-filter-is-case-sensitive": true,
          "resource-type": ["raw"]
        },
        "action": {
          "type": "block"
        }
      }
    ]
    """#
}
