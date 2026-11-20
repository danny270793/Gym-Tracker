import GymCore
import LocalAuthentication
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
  case system, en, es
  var id: String { rawValue }
  var code: String? { self == .system ? nil : rawValue }
  var label: String {
    switch self {
    case .system: L("settingsLanguageSystem")
    case .en: L("settingsLanguageEnglish")
    case .es: L("settingsLanguageSpanish")
    }
  }
}

enum AppTheme: String, CaseIterable, Identifiable {
  case system, light, dark
  var id: String { rawValue }
  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
  var label: String {
    switch self {
    case .system: L("settingsThemeSystem")
    case .light: L("settingsThemeLight")
    case .dark: L("settingsThemeDark")
    }
  }
}

@MainActor @Observable
final class Preferences {
  private let defaults = UserDefaults.standard

  var language: AppLanguage {
    didSet {
      defaults.set(language.rawValue, forKey: "app_language_preference")
      L10n.apply(language)
    }
  }

  var theme: AppTheme {
    didSet { defaults.set(theme.rawValue, forKey: "app_theme_preference") }
  }

  var biometricUnlock: Bool {
    didSet { defaults.set(biometricUnlock, forKey: "app_biometric_unlock_enabled") }
  }

  /// Display preference only. Loads are stored in pounds.
  var weightUnit: WeightUnit {
    didSet { defaults.set(weightUnit.rawValue, forKey: "app_weight_unit") }
  }

  init() {
    language = AppLanguage(rawValue: defaults.string(forKey: "app_language_preference") ?? "") ?? .system
    theme = AppTheme(rawValue: defaults.string(forKey: "app_theme_preference") ?? "") ?? .system
    biometricUnlock = defaults.bool(forKey: "app_biometric_unlock_enabled")
    weightUnit = WeightUnit(rawValue: defaults.string(forKey: "app_weight_unit") ?? "") ?? .lb
    L10n.apply(language)
  }

  var biometricAvailable: Bool {
    LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
  }

  func authenticate(reason: String) async -> Bool {
    let context = LAContext()
    return (try? await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)) ?? false
  }
}
