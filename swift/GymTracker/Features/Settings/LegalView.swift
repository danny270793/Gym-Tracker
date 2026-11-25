import SwiftUI

enum LegalKind: String, Identifiable, Hashable {
  case about, privacy, terms
  var id: String { rawValue }
  var title: String {
    switch self {
    case .about: L("settingsAboutApp")
    case .privacy: L("settingsPrivacyPolicy")
    case .terms: L("settingsTermsOfUse")
    }
  }
}

struct LegalView: View {
  var kind: LegalKind

  private var version: String {
    let info = Bundle.main.infoDictionary
    return "\(info?["CFBundleShortVersionString"] as? String ?? "?") (\(info?["CFBundleVersion"] as? String ?? "?"))"
  }

  var body: some View {
    List {
      switch kind {
      case .about:
        Section {
          VStack(spacing: 10) {
            Image("AppIconImage").resizable().frame(width: 84, height: 84).clipShape(.rect(cornerRadius: 19))
            Text(L("appTitle")).font(.title2.bold())
            Text(L("settingsAboutTagline")).foregroundStyle(.secondary).multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity)
          .listRowBackground(Color.clear)
        }
        Section {
          LabeledContent(L("settingsAboutVersionLabel"), value: version)
        }
        Section {
          Label(L("settingsAboutBulletPlan"), systemImage: "calendar")
          Label(L("settingsAboutBulletLog"), systemImage: "figure.strengthtraining.traditional")
          Label(L("settingsAboutBulletExercises"), systemImage: "dumbbell")
          Label(L("settingsAboutBulletDashboard"), systemImage: "chart.bar.xaxis")
        } header: {
          Text(L("settingsAboutFeaturesHeading"))
        }
        Section {
          Text(L("settingsAboutDataBody"))
        } header: {
          Text(L("settingsAboutDataHeading"))
        }
        Section {
          LabeledContent("Danny Vaca", value: "danny270793@icloud.com")
          Link(L("settingsAboutDeveloperGithub"), destination: URL(string: "https://github.com/danny270793")!)
          Link(L("settingsAboutDeveloperWebsite"), destination: URL(string: "https://danny270793.github.io/")!)
          Link(L("settingsAboutDeveloperYoutube"), destination: URL(string: "https://www.youtube.com/channel/UC5MAQWU2s2VESTXaUo-ysgg")!)
          Link(L("settingsAboutDeveloperLinkedin"), destination: URL(string: "https://www.linkedin.com/in/danny270793/")!)
        } header: {
          Text(L("settingsAboutDeveloperHeading"))
        }
      case .privacy:
        Text(L("settingsPrivacyTagline")).font(.footnote).foregroundStyle(.secondary)
        section(L("settingsPrivacyDataTitle"), L("settingsPrivacyDataBody"))
        section(L("settingsPrivacyInfraTitle"), L("settingsPrivacyInfraBody"))
        section(L("settingsPrivacySharingTitle"), L("settingsPrivacySharingBody"))
        section(L("settingsPrivacyNoticeTitle"), L("settingsPrivacyNoticeBody"))
      case .terms:
        Text(L("settingsTermsTagline")).font(.footnote).foregroundStyle(.secondary)
        section(L("settingsTermsAcceptanceTitle"), L("settingsTermsAcceptanceBody"))
        section(L("settingsTermsResponsibilitiesTitle"), L("settingsTermsResponsibilitiesBody"))
        section(L("settingsTermsDisclaimerTitle"), L("settingsTermsDisclaimerBody"))
        section(L("settingsTermsLiabilityTitle"), L("settingsTermsLiabilityBody"))
        section(L("settingsTermsNoticeTitle"), L("settingsTermsNoticeBody"))
      }
    }
    .navigationTitle(kind.title)
  }

  private func section(_ title: String, _ body: String) -> some View {
    Section {
      Text(body)
    } header: {
      Text(title)
    }
  }
}
