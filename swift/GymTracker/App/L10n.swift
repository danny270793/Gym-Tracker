import Foundation
import GymCore

/// Looks up strings in the String Catalog, honoring the in-app language override.
enum L10n {
  nonisolated(unsafe) static var bundle: Bundle = .main
  nonisolated(unsafe) static var locale: Locale = .current

  static func apply(_ language: AppLanguage) {
    if let code = language.code, let path = Bundle.main.path(forResource: code, ofType: "lproj"),
      let localized = Bundle(path: path)
    {
      bundle = localized
      locale = Locale(identifier: code)
    } else {
      bundle = .main
      locale = .current
    }
  }
}

func L(_ key: String, _ args: Any...) -> String {
  let format = L10n.bundle.localizedString(forKey: key, value: key, table: nil)
  guard !args.isEmpty else { return format }
  return String(format: format, locale: L10n.locale, arguments: args.map { "\($0)" as NSString })
}

/// Plural string. `counts` follow the placeholder order in the English catalog.
/// Singular branches live at `key#one` and `key#one.other`.
func LP(_ key: String, _ counts: Int...) -> String {
  let tags = counts.map { $0 == 1 ? "one" : "other" }
  let variant = tags.contains("one") ? "\(key)#\(tags.joined(separator: "."))" : key
  var format = L10n.bundle.localizedString(forKey: variant, value: "", table: nil)
  if format.isEmpty {
    format = L10n.bundle.localizedString(forKey: key, value: key, table: nil)
  }
  guard !counts.isEmpty else { return format }
  return String(format: format, locale: L10n.locale, arguments: counts.map { "\($0)" as NSString })
}
