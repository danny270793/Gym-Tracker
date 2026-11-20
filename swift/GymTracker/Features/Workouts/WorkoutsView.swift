import GymCore
import SwiftUI

struct WorkoutsView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs
  @State private var showStart = false

  var body: some View {
    Group {
      if model.loading && !model.loaded {
        ProgressView()
      } else if let loadError = model.loadError, model.workouts.isEmpty {
        ContentUnavailableView {
          Label(loadError, systemImage: "exclamationmark.triangle")
        } actions: {
          Button(L("retry")) { Task { await model.reload() } }
        }
      } else {
        list
      }
    }
    .navigationTitle(L("navWorkouts"))
    .toolbar {
      SettingsToolbar()
      ToolbarItem(placement: .primaryAction) {
        Button(L("startWorkout"), systemImage: "plus") { showStart = true }
      }
    }
    .sheet(isPresented: $showStart) { StartWorkoutSheet() }
    .refreshable { await model.reload() }
  }

  private var list: some View {
    List {
      OfflineHeader()
      Section { TodayCard() }
      Section(L("history")) {
        if model.workouts.isEmpty {
          Text(L("workoutsEmpty")).foregroundStyle(.secondary)
        }
        ForEach(model.workouts) { workout in
          NavigationLink(value: workout.id) {
            WorkoutRow(workout: workout, unit: prefs.weightUnit)
          }
        }
        .onDelete { offsets in
          for index in offsets {
            let id = model.workouts[index].id
            Task { await model.deleteWorkout(id: id) }
          }
        }
      }
    }
    .navigationDestination(for: String.self) { id in
      WorkoutSessionView(workoutId: id)
    }
  }
}

private struct TodayCard: View {
  @Environment(AppModel.self) private var model

  var body: some View {
    card(Date.now)
  }

  private func card(_ now: Date) -> some View {
    let todays = model.workouts.filter { isSameDay($0.date, now) }
    let inProgress = todays.first { !$0.isFinished }
    let done = todays.first { $0.isFinished }
    let routine = model.routineForToday(now: now)
    return VStack(alignment: .leading, spacing: 8) {
      Text(L("todayLabel", formatDay(now))).font(.subheadline).foregroundStyle(.secondary)
      todayBody(inProgress: inProgress, done: done, routine: routine)
    }
    .padding(.vertical, 4)
  }

  @ViewBuilder
  private func todayBody(inProgress: Workout?, done: Workout?, routine: Routine?) -> some View {
    if let inProgress {
      Text(inProgress.title).font(.title3.bold())
      Text(L("workoutInProgress")).foregroundStyle(.secondary)
      NavigationLink(value: inProgress.id) { Text(L("continueWorkout")) }.buttonStyle(.borderedProminent)
    } else if let done {
      Text(done.title).font(.title3.bold())
      Text(L("todayDone")).foregroundStyle(.secondary)
      NavigationLink(value: done.id) { Text(L("view")) }.buttonStyle(.bordered)
    } else if let routine {
      Text(routine.title).font(.title3.bold())
      Text(LP("routineSummary", routine.exercises.count, routine.totalSets)).foregroundStyle(.secondary)
      Button(L("startWorkout")) { Task { _ = await model.startWorkout(date: .now, title: routine.title, routine: routine) } }
        .buttonStyle(.borderedProminent)
    } else {
      Text(L("noPlanYet")).font(.title3.bold())
      Text(L("restDayHint")).foregroundStyle(.secondary)
      Button(L("startWorkout")) { Task { _ = await model.startWorkout(date: .now, title: L("emptyWorkoutTitle"), routine: nil) } }
        .buttonStyle(.borderedProminent)
    }
  }
}

private struct WorkoutRow: View {
  var workout: Workout
  var unit: WeightUnit
  @Environment(AppModel.self) private var model

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack {
        Text(workout.title)
        Spacer()
        if !workout.isFinished {
          Text(L("inProgress")).font(.caption).foregroundStyle(.orange)
        }
      }
      Text(formatDay(workout.date)).font(.footnote).foregroundStyle(.secondary)
      Text(summary).font(.footnote).foregroundStyle(.secondary)
    }
  }

  private var summary: String {
    let isWeight: (String) -> Bool = { model.exercise($0)?.loadType != .discs }
    let volume = workout.weightVolumeLb(isWeight)
    return "\(L("setsCount", workout.totalSetCount)) · \(LoadText(type: .weight, unit: unit).withSymbol(volume))"
  }
}

private struct StartWorkoutSheet: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        ForEach(model.routines) { routine in
          Button {
            Task {
              _ = await model.startWorkout(date: .now, title: routine.title, routine: routine)
              dismiss()
            }
          } label: {
            VStack(alignment: .leading) {
              Text(routine.title)
              Text(LP("routineSummary", routine.exercises.count, routine.totalSets))
                .font(.footnote).foregroundStyle(.secondary)
            }
          }
        }
        Button {
          Task {
            _ = await model.startWorkout(date: .now, title: L("emptyWorkoutTitle"), routine: nil)
            dismiss()
          }
        } label: {
          VStack(alignment: .leading) {
            Text(L("emptyWorkoutTitle"))
            Text(L("emptyWorkoutHint")).font(.footnote).foregroundStyle(.secondary)
          }
        }
      }
      .navigationTitle(L("startWorkout"))
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } } }
    }
    .presentationDetents([.medium, .large])
  }
}
