import GymCore
import SwiftUI

/// Dashboard card: Monday to Sunday with a mark for each day's protein, calories and sleep.
struct HealthWeekCard: View {
  @Environment(AppModel.self) private var model
  @Environment(NutritionStore.self) private var nutrition
  @Environment(SleepStore.self) private var sleep
  @Environment(Preferences.self) private var prefs

  private var week: HealthWeek {
    HealthWeekCalculator.week(
      startingAt: .now, food: nutrition.entries, sleep: sleep.entries, targets: nutrition.targets,
      sleepGoalHours: prefs.sleepGoalHours)
  }

  var body: some View {
    let week = week
    NavigationLink {
      HealthWeekView()
    } label: {
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 0) {
          Text("").frame(width: 70, alignment: .leading)
          ForEach(week.days) { day in
            Text(weekdayInitial(day.date)).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
              .frame(maxWidth: .infinity)
          }
        }
        metricRow(L("protein"), \.status.protein, week)
        metricRow(L("calories"), \.status.calories, week)
        metricRow(L("sleepShort"), \.status.sleep, week)
        Text(summary(week)).font(.footnote).foregroundStyle(.secondary)
      }
      .padding(.vertical, 4)
    }
    .task {
      await nutrition.load(model: model)
      await sleep.load(model: model)
    }
  }

  private func metricRow(_ title: String, _ key: KeyPath<HealthDay, GoalStatus>, _ week: HealthWeek) -> some View {
    HStack(spacing: 0) {
      Text(title).font(.subheadline).frame(width: 70, alignment: .leading)
      ForEach(week.days) { day in
        StatusMark(status: day[keyPath: key]).frame(maxWidth: .infinity)
      }
    }
  }

  private func summary(_ week: HealthWeek) -> String {
    let protein = week.reachedCount(\.status.protein)
    let calories = week.reachedCount(\.status.calories)
    let sleep = week.reachedCount(\.status.sleep)
    return L("healthWeekSummary", "\(protein.reached)/\(protein.total)", "\(calories.reached)/\(calories.total)", "\(sleep.reached)/\(sleep.total)")
  }
}

/// ✓ reached, ✗ missed, ◌ today so far, – not yet / no goal.
struct StatusMark: View {
  let status: GoalStatus

  var body: some View {
    switch status {
    case .reached: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
    case .missed: Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
    case .inProgress: Image(systemName: "circle.dotted").foregroundStyle(.orange)
    case .upcoming, .noTarget: Image(systemName: "minus").foregroundStyle(.tertiary)
    }
  }
}

/// A week at a time: each day against the protein, calorie and sleep requirements.
struct HealthWeekView: View {
  @Environment(AppModel.self) private var model
  @Environment(NutritionStore.self) private var nutrition
  @Environment(SleepStore.self) private var sleep
  @Environment(Preferences.self) private var prefs
  @State private var weekStart = startOfWeek(.now)
  @State private var showProfile = false

  private var week: HealthWeek {
    HealthWeekCalculator.week(
      startingAt: weekStart, food: nutrition.entries, sleep: sleep.entries, targets: nutrition.targets,
      sleepGoalHours: prefs.sleepGoalHours)
  }

  var body: some View {
    let week = week
    List {
      Section { weekPicker }
      Section {
        summaryRow(L("protein"), week.reachedCount(\.status.protein), average: week.averageProtein().map { "\(Int($0.rounded())) \(L("unitGrams"))" })
        summaryRow(L("calories"), week.reachedCount(\.status.calories), average: week.averageCalories().map { "\(Int($0.rounded())) \(L("unitKcal"))" })
        summaryRow(L("sleepShort"), week.reachedCount(\.status.sleep), average: week.averageSleep().map(duration))
      } header: {
        Text(L("healthDaysReached"))
      } footer: {
        Text(L("healthRulesNote"))
      }
      if nutrition.targets == nil {
        Section {
          Button(L("nutritionSetGoals"), systemImage: "target") { showProfile = true }
        } footer: {
          Text(L("nutritionSetGoalsHint"))
        }
      }
      Section(L("healthDays")) {
        ForEach(week.days) { day in DayRow(day: day) }
      }
      Section {
        Stepper(value: Bindable(prefs).sleepGoalHours, in: 5...10, step: 0.5) {
          LabeledContent(L("healthSleepGoal"), value: duration(prefs.sleepGoalHours * 3600))
        }
      } footer: {
        Text(L("healthSleepGoalHint"))
      }
    }
    .navigationTitle(L("healthWeekTitle"))
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await nutrition.load(model: model)
      await sleep.load(model: model)
    }
    .refreshable {
      await nutrition.load(model: model)
      await sleep.load(model: model)
    }
    .sheet(isPresented: $showProfile) {
      NavigationStack { NutritionProfileView() }
    }
  }

  private var weekPicker: some View {
    HStack {
      Button(L("previousWeek"), systemImage: "chevron.left") { weekStart = addDays(weekStart, -7) }
        .labelStyle(.iconOnly)
      Spacer()
      VStack(spacing: 2) {
        Text(rangeTitle).font(.headline)
        if isSameDay(weekStart, startOfWeek(.now)) { Text(L("thisWeek")).font(.caption).foregroundStyle(.secondary) }
      }
      Spacer()
      Button(L("nextWeek"), systemImage: "chevron.right") { weekStart = addDays(weekStart, 7) }
        .labelStyle(.iconOnly)
        .disabled(weekStart >= startOfWeek(.now))
    }
    .buttonStyle(.borderless)
  }

  private var rangeTitle: String {
    let end = addDays(weekStart, 6)
    return "\(weekStart.formatted(.dateTime.day().month(.abbreviated))) – \(end.formatted(.dateTime.day().month(.abbreviated)))"
  }

  private func summaryRow(_ title: String, _ count: (reached: Int, total: Int), average: String?) -> some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
        if let average { Text(L("healthAverage", average)).font(.footnote).foregroundStyle(.secondary) }
      }
      Spacer()
      Text("\(count.reached)/\(count.total)")
        .font(.title3.bold()).monospacedDigit()
        .foregroundStyle(count.total == 0 ? Color.secondary : (count.reached == count.total ? Color.green : (count.reached * 2 >= count.total ? Color.orange : Color.red)))
    }
  }
}

private struct DayRow: View {
  let day: HealthDay

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(day.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))).font(.headline)
        if isSameDay(day.date, .now) { Text(L("today")).font(.caption).foregroundStyle(.secondary) }
        Spacer()
        if day.allReached { Image(systemName: "star.fill").foregroundStyle(.yellow) }
      }
      metric(
        L("protein"), day.status.protein, value: day.proteinGrams, target: day.proteinTarget.map(Double.init),
        unit: L("unitGrams"), tint: .blue)
      metric(
        L("calories"), day.status.calories, value: day.calories, target: day.calorieTarget.map(Double.init),
        unit: L("unitKcal"), tint: .orange)
      HStack {
        StatusMark(status: day.status.sleep)
        Text(L("sleepShort"))
        Spacer()
        Text("\(duration(day.sleepSeconds)) / \(duration(day.sleepTargetSeconds))")
          .monospacedDigit().foregroundStyle(.secondary)
      }
      .font(.subheadline)
      if day.status.sleep != .upcoming {
        ProgressView(value: min(day.sleepSeconds, day.sleepTargetSeconds), total: max(day.sleepTargetSeconds, 1))
          .tint(.indigo)
      }
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func metric(_ title: String, _ status: GoalStatus, value: Double, target: Double?, unit: String, tint: Color) -> some View {
    HStack {
      StatusMark(status: status)
      Text(title)
      Spacer()
      Text(target.map { "\(Int(value.rounded())) / \(Int($0.rounded())) \(unit)" } ?? "\(Int(value.rounded())) \(unit)")
        .monospacedDigit().foregroundStyle(.secondary)
    }
    .font(.subheadline)
    if let target, status != .upcoming {
      ProgressView(value: min(value, target), total: max(target, 1)).tint(status == .missed ? .red : tint)
    }
  }
}

private func weekdayInitial(_ date: Date) -> String {
  String(date.formatted(.dateTime.weekday(.narrow)))
}
