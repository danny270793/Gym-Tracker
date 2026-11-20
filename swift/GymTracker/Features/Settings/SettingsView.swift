import GymCore
import StoreKit
import SwiftUI

struct SettingsView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs
  @Environment(\.requestReview) private var requestReview
  @State private var confirmSignOut = false
  @State private var showEmail = false
  @State private var showPassword = false
  @State private var message: String?

  var body: some View {
    Form {
      Section(L("settingsProfileSection")) {
        LabeledContent(L("email"), value: model.repo?.email ?? "")
        Button(L("settingsChangeEmail")) { showEmail = true }
        Button {
          showPassword = true
        } label: {
          VStack(alignment: .leading) {
            Text(L("settingsChangePassword"))
            Text(L("settingsChangePasswordSubtitle")).font(.caption).foregroundStyle(.secondary)
          }
        }
      }
      Section(L("settingsSecuritySection")) {
        Toggle(isOn: biometricBinding) {
          VStack(alignment: .leading) {
            Text(L("settingsBiometricUnlockTitle"))
            Text(L(prefs.biometricAvailable ? "settingsBiometricUnlockSubtitle" : "settingsBiometricUnavailable"))
              .font(.caption).foregroundStyle(.secondary)
          }
        }
        .disabled(!prefs.biometricAvailable && !prefs.biometricUnlock)
      }
      Section(L("settingsAppearance")) {
        Picker(L("settingsLanguage"), selection: languageBinding) {
          ForEach(AppLanguage.allCases) { Text($0.label).tag($0) }
        }
        Picker(L("settingsTheme"), selection: themeBinding) {
          ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
        }
        Picker(L("settingsWeightUnit"), selection: unitBinding) {
          Text(L("settingsWeightUnitLb")).tag(WeightUnit.lb)
          Text(L("settingsWeightUnitKg")).tag(WeightUnit.kg)
        }
      }
      Section(L("settingsAboutSection")) {
        NavigationLink(L("settingsAboutApp")) { LegalView(kind: .about) }
        Button(L("rateApp")) { requestReview() }
        NavigationLink(L("settingsPrivacyPolicy")) { LegalView(kind: .privacy) }
        NavigationLink(L("settingsTermsOfUse")) { LegalView(kind: .terms) }
      }
      Section {
        Button(L("signOut"), role: .destructive) { confirmSignOut = true }
          .frame(maxWidth: .infinity)
      }
    }
    .navigationTitle(L("settings"))
    .confirmationDialog(L("signOut"), isPresented: $confirmSignOut) {
      Button(L("signOut"), role: .destructive) { Task { await model.signOut() } }
    }
    .sheet(isPresented: $showEmail) { EmailSheet { message = $0 } }
    .sheet(isPresented: $showPassword) { PasswordSheet { message = $0 } }
    .alert(L("settings"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
      Button(L("ok"), role: .cancel) {}
    } message: {
      Text(message ?? "")
    }
  }

  private var languageBinding: Binding<AppLanguage> {
    Binding(get: { prefs.language }, set: { prefs.language = $0 })
  }
  private var themeBinding: Binding<AppTheme> {
    Binding(get: { prefs.theme }, set: { prefs.theme = $0 })
  }
  private var unitBinding: Binding<WeightUnit> {
    Binding(get: { prefs.weightUnit }, set: { prefs.weightUnit = $0 })
  }
  private var biometricBinding: Binding<Bool> {
    Binding(
      get: { prefs.biometricUnlock },
      set: { enabled in
        Task {
          if !enabled {
            prefs.biometricUnlock = false
            return
          }
          guard prefs.biometricAvailable else {
            message = L("settingsBiometricUnavailable")
            return
          }
          if await prefs.authenticate(reason: L("settingsBiometricAuthReason")) {
            prefs.biometricUnlock = true
          }
        }
      }
    )
  }
}

private struct EmailSheet: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var onDone: (String) -> Void
  @State private var email = ""
  @State private var error: String?
  @State private var busy = false

  var body: some View {
    NavigationStack {
      Form {
        TextField(L("settingsNewEmailLabel"), text: $email)
          .textInputAutocapitalization(.never)
          .keyboardType(.emailAddress)
        if let error { Text(error).foregroundStyle(.red) }
      }
      .navigationTitle(L("settingsChangeEmailDialogTitle"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button(L("settingsChangeEmailSubmit")) { Task { await save() } }.disabled(busy)
        }
      }
    }
  }

  private func save() async {
    let next = email.trimmingCharacters(in: .whitespacesAndNewlines)
    guard next.contains("@"), next.contains(".") else {
      error = L("settingsChangeEmailInvalid")
      return
    }
    if next.caseInsensitiveCompare(model.repo?.email ?? "") == .orderedSame {
      error = L("settingsChangeEmailSameAsCurrent")
      return
    }
    busy = true
    defer { busy = false }
    do {
      try await model.repo?.updateEmail(next)
      onDone(L("settingsChangeEmailSuccess"))
      dismiss()
    } catch {
      self.error = L("unexpectedError")
    }
  }
}

private struct PasswordSheet: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var onDone: (String) -> Void
  @State private var password = ""
  @State private var confirm = ""
  @State private var error: String?
  @State private var busy = false

  var body: some View {
    NavigationStack {
      Form {
        SecureField(L("settingsNewPasswordLabel"), text: $password)
        SecureField(L("settingsConfirmNewPasswordLabel"), text: $confirm)
        Text(L("settingsChangePasswordSubtitle")).font(.footnote).foregroundStyle(.secondary)
        if let error { Text(error).foregroundStyle(.red) }
      }
      .navigationTitle(L("settingsChangePasswordDialogTitle"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
        ToolbarItem(placement: .confirmationAction) {
          Button(L("settingsChangePasswordSubmit")) { Task { await save() } }.disabled(busy)
        }
      }
    }
  }

  private func save() async {
    guard password.count >= 6 else {
      error = L("settingsPasswordTooShort")
      return
    }
    guard password == confirm else {
      error = L("settingsPasswordsDoNotMatch")
      return
    }
    busy = true
    defer { busy = false }
    do {
      try await model.repo?.updatePassword(password)
      onDone(L("settingsChangePasswordSuccess"))
      dismiss()
    } catch {
      self.error = L("unexpectedError")
    }
  }
}
