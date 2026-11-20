import SwiftUI

struct MainTabView: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    TabView {
      Tab(L("navDashboard"), systemImage: "chart.bar.xaxis") {
        NavigationStack { DashboardView() }
      }
      Tab(L("navWorkouts"), systemImage: "figure.strengthtraining.traditional") {
        NavigationStack { WorkoutsView() }
      }
      Tab(L("navPlan"), systemImage: "calendar") {
        NavigationStack { PlanView() }
      }
      Tab(L("navExercises"), systemImage: "dumbbell") {
        NavigationStack { ExercisesView() }
      }
    }
    .tabBarMinimizeBehavior(.onScrollDown)
    .tabViewStyle(.sidebarAdaptable)
    .task { await model.loadIfNeeded() }
  }
}

struct SettingsToolbar: ToolbarContent {
  var body: some ToolbarContent {
    ToolbarItem(placement: .automatic) {
      NavigationLink {
        SettingsView()
      } label: {
        Image(systemName: "gearshape")
      }
      .accessibilityLabel(L("settings"))
    }
  }
}

struct OfflineHeader: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    if model.fromCache {
      Label(L("offlineBanner"), systemImage: "icloud.slash")
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.tertiary.opacity(0.25))
    }
  }
}
