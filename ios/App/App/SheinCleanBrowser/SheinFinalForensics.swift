import Foundation

struct SheinForensicScenario: Codable {
    static let schemaVersion = 1
    static let configurationFileName = "shein-final-forensics-scenario.json"

    let schemaVersion: Int
    let scenario: String
    let mode: String
    let containerIdentifier: String
    let runId: String
    let createdAt: String

    private static let expectedModes: [String: String] = [
        "A1": "RAW",
        "A2": "RAW",
        "A3": "RAW",
        "A4": "RAW_WITH_CACHE_GUARD",
        "B0": "RAW",
        "B1": "CAPTURE_ONLY",
        "B2": "BLOCKING_ONLY",
        "B3": "CAPTURE_AND_BLOCKING"
    ]

    var dataStoreIdentifier: UUID? {
        UUID(uuidString: containerIdentifier)
    }

    var dataStoreIdentity: String {
        dataStoreIdentifier?.uuidString.lowercased() ?? "invalid"
    }

    var runtimeFileName: String {
        "shein-final-forensics-\(runId.lowercased()).jsonl"
    }

    var expectedMode: SheinCleanBrowserMode? {
        SheinCleanBrowserMode.allCases.first { $0.wireName == mode }
    }

    static func load() throws -> SheinForensicScenario? {
        let fileManager = FileManager.default
        guard let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = documents.appendingPathComponent(configurationFileName, isDirectory: false)
        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let data = try Data(contentsOf: url, options: [.mappedIfSafe])
        let scenario = try JSONDecoder().decode(SheinForensicScenario.self, from: data)
        guard scenario.schemaVersion == schemaVersion else {
            throw SheinForensicScenarioError.invalidSchema
        }
        guard let expectedWireMode = expectedModes[scenario.scenario], expectedWireMode == scenario.mode else {
            throw SheinForensicScenarioError.invalidScenarioMode
        }
        guard scenario.dataStoreIdentifier != nil else {
            throw SheinForensicScenarioError.invalidContainerIdentifier
        }
        guard UUID(uuidString: scenario.runId) != nil else {
            throw SheinForensicScenarioError.invalidRunIdentifier
        }
        return scenario
    }
}

enum SheinForensicScenarioError: LocalizedError {
    case invalidSchema
    case invalidScenarioMode
    case invalidContainerIdentifier
    case invalidRunIdentifier

    var errorDescription: String? {
        switch self {
        case .invalidSchema: return "Unsupported SHEIN forensic scenario schema"
        case .invalidScenarioMode: return "The SHEIN forensic scenario and mode do not match"
        case .invalidContainerIdentifier: return "The SHEIN forensic container identifier is invalid"
        case .invalidRunIdentifier: return "The SHEIN forensic run identifier is invalid"
        }
    }
}

enum SheinFinalForensics {
    private static let writerQueue = DispatchQueue(label: "com.otlobli.shein.final-forensics.writer")
    private static var currentScenario: SheinForensicScenario?

    static func activate(_ scenario: SheinForensicScenario) {
        writerQueue.sync {
            currentScenario = scenario
        }
        record([
            "prefix": "[OTLOBLI_SHEIN_CLEAN]",
            "event": "forensic-scenario-activated",
            "at": Int64(Date().timeIntervalSince1970 * 1000),
            "scenario": scenario.scenario,
            "mode": scenario.mode,
            "runId": scenario.runId.lowercased(),
            "websiteDataContainer": scenario.dataStoreIdentity,
            "schemaVersion": scenario.schemaVersion
        ], scenario: scenario)
    }

    static func activeScenario() -> SheinForensicScenario? {
        writerQueue.sync { currentScenario }
    }

    static func record(_ payload: [String: Any], scenario explicitScenario: SheinForensicScenario? = nil) {
        writerQueue.async {
            guard let scenario = explicitScenario ?? currentScenario else { return }
            guard let documents = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first else { return }

            var safe = sanitizeDictionary(payload)
            safe["forensicScenario"] = scenario.scenario
            safe["forensicSchemaVersion"] = scenario.schemaVersion
            safe["runId"] = scenario.runId.lowercased()
            safe["mode"] = scenario.mode
            safe["websiteDataContainer"] = scenario.dataStoreIdentity
            guard JSONSerialization.isValidJSONObject(safe),
                  let data = try? JSONSerialization.data(withJSONObject: safe, options: [.sortedKeys]) else {
                return
            }

            let url = documents.appendingPathComponent(scenario.runtimeFileName, isDirectory: false)
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            guard let handle = try? FileHandle(forWritingTo: url) else { return }
            defer { try? handle.close() }
            do {
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
                try handle.write(contentsOf: Data([0x0A]))
                try handle.synchronize()
            } catch {
                return
            }
        }
    }

    private static func sanitizeDictionary(_ input: [String: Any]) -> [String: Any] {
        var output: [String: Any] = [:]
        for (key, value) in input {
            let lower = key.lowercased()
            if lower.contains("token") || lower.contains("cookie") ||
                lower.contains("authorization") || lower.contains("signature") ||
                lower.contains("address") || lower.contains("account") ||
                lower.contains("storagevalue") || lower.contains("query") {
                continue
            }
            output[key] = sanitizeValue(value)
        }
        return output
    }

    private static func sanitizeValue(_ value: Any) -> Any {
        if let text = value as? String {
            if text.contains("://"), let url = URL(string: text) {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.query = nil
                components?.fragment = nil
                return String((components?.url?.absoluteString ?? "").prefix(500))
            }
            return String(text.prefix(500))
        }
        if let dictionary = value as? [String: Any] {
            return sanitizeDictionary(dictionary)
        }
        if let array = value as? [Any] {
            return Array(array.prefix(80)).map(sanitizeValue)
        }
        if value is NSNumber || value is NSNull { return value }
        return String(String(describing: value).prefix(500))
    }
}
