import SwiftUI

/// Nutrition and sleep share one tab so the tab bar keeps five items (a sixth would
/// move a tab under "More", which nests a second navigation bar and shows two back buttons).
struct HealthView: View {
  private enum Section: String, CaseIterable, Identifiable {
    case nutrition, sleep
    var id: String { rawValue }
    var title: String { self == .nutrition ? L("navNutrition") : L("navSleep") }
  }

  @State private var section: Section = .nutrition

  var body: some View {
    Group {
      switch section {
      case .nutrition: NutritionView()
      case .sleep: SleepView()
      }
    }
    .safeAreaInset(edge: .top, spacing: 0) {
      Picker(L("navHealth"), selection: $section) {
        ForEach(Section.allCases) { Text($0.title).tag($0) }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.bottom, 8)
    }
  }
}
