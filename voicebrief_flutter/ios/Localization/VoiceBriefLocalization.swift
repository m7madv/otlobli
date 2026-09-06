import Foundation

enum VoiceBriefLocalization {
  private static let defaults = UserDefaults(suiteName: "group.app.voicebrief.mobile")
  private static let key = "VoiceBriefAppLanguage"
  private static let languages: Set<String> = ["ar", "en", "zh", "hi", "es", "fr", "bn", "pt", "ru", "ur", "id"]

  static func setLanguage(_ value: String?) {
    if let value, languages.contains(value) {
      defaults?.set(value, forKey: key)
    } else {
      defaults?.removeObject(forKey: key)
    }
  }

  static var language: String {
    if let chosen = defaults?.string(forKey: key), languages.contains(chosen) {
      return chosen
    }
    for tag in Locale.preferredLanguages {
      let normalized = tag.lowercased().replacingOccurrences(of: "_", with: "-")
      let parts = normalized.split(separator: "-").map(String.init)
      guard let code = parts.first, languages.contains(code) else { continue }
      if code == "zh", parts.contains("hant") || parts.contains("tw") || parts.contains("hk") || parts.contains("mo") { continue }
      return code
    }
    return "en"
  }

  static func text(_ key: String, fallback: String? = nil) -> String {
    let code = language == "zh" ? "zh-Hans" : language
    guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
          let bundle = Bundle(path: path) else { return fallback ?? key }
    return bundle.localizedString(forKey: key, value: fallback ?? key, table: "Localizable")
  }
}
