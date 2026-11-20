import Charts
import GymCore
import SwiftUI

struct DashboardView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs

  var body: some View {
    Group {
      if model.loading && !model.loaded {
        ProgressView()
      } else if model.loadError != nil, model.workouts.isEmpty {
        ContentUnavailableView {
          Label(L("loadError"), systemImage: "exclamationmark.triangle")
        } actions: {
          Button(L("retry")) { Task { await model.reload() } }
        }
      } else if model.workouts.isEmpty {
        ContentUnavailableView {
          Label(L("dashboardEmptyTitle"), systemImage: "chart.bar.xaxis")
        } description: {
          Text(L("dashboardEmptyBody"))
        }
      } else {
        dashboard
      }
    }
    .navigationTitle(L("navDashboard"))
    .toolbar { SettingsToolbar() }
    .refreshable { await model.reload() }
  }

  private var stats: DashboardStats {
    DashboardStatsCalculator()(
      workouts: model.workouts, exercises: model.exercises, weeklyPlan: model.plan, now: .now)
  }

  private var dashboard: some View {
    let stats = stats
    let unit = prefs.weightUnit
    return List {
      OfflineHeader()
      Section(L("dashboardThisWeek")) {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
          stat(
            L("dashboardWorkouts"),
            stats.plannedDaysPerWeek > 0 ? "\(stats.thisWeek.workouts)/\(stats.plannedDaysPerWeek)" : "\(stats.thisWeek.workouts)",
            stats.plannedDaysPerWeek > 0
              ? L("dashboardPlannedDays")
              : deltaCaption(Double(stats.thisWeek.workouts), Double(stats.lastWeek.workouts))
          )
          stat(L("dashboardVolume", unit.symbol), formatCompact(unit.fromLb(stats.thisWeek.volumeLb)), deltaCaption(stats.thisWeek.volumeLb, stats.lastWeek.volumeLb), up: stats.thisWeek.volumeLb >= stats.lastWeek.volumeLb)
          stat(L("dashboardReps"), formatInt(stats.thisWeek.reps), deltaCaption(Double(stats.thisWeek.reps), Double(stats.lastWeek.reps)), up: stats.thisWeek.reps >= stats.lastWeek.reps)
          stat(L("dashboardSets"), formatInt(stats.thisWeek.sets), deltaCaption(Double(stats.thisWeek.sets), Double(stats.lastWeek.sets)), up: stats.thisWeek.sets >= stats.lastWeek.sets)
          stat(L("dashboardStreak"), LP("dashboardStreakWeeks", stats.weekStreak), LP("dashboardTotalWorkouts", stats.totalWorkouts))
          stat(
            L("dashboardAvgDuration"),
            stats.averageDuration.map(formatDuration) ?? "—",
            L("dashboardLast30Days")
          )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .listRowBackground(Color.clear)
      }
      Section {
        Text(L("dashboardVolumeHint")).font(.footnote).foregroundStyle(.secondary)
        weekChart(stats.weeklyHistory.map { unit.fromLb($0.volumeLb) }, labels: stats.weeklyHistory.map(\.weekStart))
      } header: {
        Text(L("dashboardWeeklyVolume", unit.symbol))
      }
      Section(L("dashboardWeeklyReps")) {
        weekChart(stats.weeklyHistory.map { Double($0.reps) }, labels: stats.weeklyHistory.map(\.weekStart))
      }
      Section {
        Text(L("dashboardMuscleRepsHint")).font(.footnote).foregroundStyle(.secondary)
        if stats.muscleRepsThisWeek.isEmpty {
          Text(L("dashboardNoSetsThisWeek")).foregroundStyle(.secondary)
        } else {
          muscleBars(stats.muscleRepsThisWeek)
        }
      } header: {
        Text(L("dashboardMuscleReps"))
      }
      Section {
        Text(L("dashboardMuscleSetsHint")).font(.footnote).foregroundStyle(.secondary)
        if stats.muscleSetsThisWeek.isEmpty {
          Text(L("dashboardNoSetsThisWeek")).foregroundStyle(.secondary)
        } else {
          muscleBars(stats.muscleSetsThisWeek, fraction: true)
        }
      } header: {
        Text(L("dashboardMuscleSets"))
      }
      Section {
        Text(L("dashboardTrendsHint")).font(.footnote).foregroundStyle(.secondary)
        if stats.trends.isEmpty {
          Text(L("dashboardNoTrends")).foregroundStyle(.secondary)
        } else {
          ForEach(stats.trends.prefix(8)) { trend in
            HStack {
              Text(model.exercise(trend.exerciseId)?.name ?? L("deletedExercise"))
              Spacer()
              Text(L("dashboardE1rm", LoadText(type: .weight, unit: unit).format(trend.currentE1rm)))
                .foregroundStyle(.secondary)
              if let change = trend.change {
                Text("\(change > 0 ? "+" : "")\(Int((change * 100).rounded()))%")
                  .foregroundStyle(change >= 0 ? Color.green : Color.red)
              } else {
                Text(L("dashboardNew")).foregroundStyle(.secondary)
              }
            }
          }
        }
      } header: {
        Text(L("dashboardTrends"))
      }
      if !stats.personalRecords.isEmpty {
        Section(L("dashboardPersonalRecords")) {
          ForEach(stats.personalRecords.prefix(8)) { record in
            let load = LoadText(type: model.exercise(record.exerciseId)?.loadType ?? .weight, unit: unit)
            VStack(alignment: .leading, spacing: 2) {
              Text(model.exercise(record.exerciseId)?.name ?? L("deletedExercise"))
              Text("\(load.withSymbol(record.load)) × \(record.reps) · \(formatShortDate(record.date))")
                .font(.footnote).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }

  private func stat(_ title: String, _ value: String, _ caption: String, up: Bool? = nil) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(value).font(.title3.bold()).minimumScaleFactor(0.6).lineLimit(1)
      Text(caption)
        .font(.caption2)
        .foregroundStyle(up == nil || caption == L("dashboardNoPreviousWeek") ? .secondary : (up == true ? Color.green : Color.red))
        .lineLimit(2)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.fill.tertiary, in: .rect(cornerRadius: 14))
  }

  private func weekChart(_ values: [Double], labels: [Date]) -> some View {
    Chart {
      ForEach(Array(values.enumerated()), id: \.offset) { index, value in
        BarMark(
          x: .value("Week", formatShortDate(labels[index])),
          y: .value("Value", value)
        )
        .foregroundStyle(Color.accentColor.gradient)
      }
    }
    .frame(height: 160)
    .chartXAxis {
      AxisMarks { value in
        AxisValueLabel(orientation: .vertical)
      }
    }
  }

  private func muscleBars(_ entries: [MuscleValue], fraction: Bool = false) -> some View {
    let maxValue = entries.map(\.value).max() ?? 1
    return VStack(alignment: .leading, spacing: 8) {
      ForEach(entries) { entry in
        VStack(alignment: .leading, spacing: 2) {
          HStack {
            Text(muscleLabel(entry.muscle))
            Spacer()
            Text(fraction && entry.value != entry.value.rounded() ? String(format: "%.1f", entry.value) : formatInt(Int(entry.value.rounded())))
              .foregroundStyle(.secondary)
          }
          .font(.subheadline)
          GeometryReader { geo in
            Capsule().fill(Color.accentColor.gradient)
              .frame(width: max(4, geo.size.width * entry.value / max(maxValue, 0.01)))
          }
          .frame(height: 8)
        }
      }
    }
  }
}
