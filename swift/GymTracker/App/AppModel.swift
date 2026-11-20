import Foundation
import GymCore
import GymData
import SwiftUI

/// Signed-in data for every tab. Writes update the in-memory lists and Supabase.
@MainActor @Observable
final class AppModel {
  private(set) var repo: GymRepository?
  private(set) var isSignedIn = false
  private(set) var exercises: [Exercise] = []
  private(set) var routines: [Routine] = []
  private(set) var plan = WeeklyPlan()
  private(set) var workouts: [Workout] = []
  private(set) var fromCache = false
  private(set) var loading = false
  private(set) var loaded = false
  var loadError: String?
  var actionError: String?

  init() {
    repo = GymConfig.fromBundle().map { GymRepository(config: $0) }
    isSignedIn = repo?.hasSession ?? false
    if let repo {
      Task { await observeAuth(repo) }
    }
  }

  private func observeAuth(_ repo: GymRepository) async {
    for await (_, session) in repo.client.auth.authStateChanges {
      let signedIn = session != nil
      if signedIn != isSignedIn {
        isSignedIn = signedIn
        if !signedIn { clearLists() }
      }
    }
  }

  func exercise(_ id: String) -> Exercise? { exercises.first { $0.id == id } }
  func routine(_ id: String) -> Routine? { routines.first { $0.id == id } }
  func workout(_ id: String) -> Workout? { workouts.first { $0.id == id } }

  func routinesUsing(exerciseId: String) -> [Routine] {
    routines.filter { $0.exercises.contains { $0.exerciseId == exerciseId } }
  }

  func routineForToday(now: Date = .now) -> Routine? {
    guard let id = plan.routineId(for: weekdayMondayBased(now)) else { return nil }
    return routine(id)
  }

  func loadIfNeeded() async {
    guard isSignedIn, !loaded, !loading else { return }
    await reload()
  }

  func reload() async {
    guard let repo, isSignedIn else { return }
    loading = true
    defer { loading = false }
    if await repo.hasLegacyData() {
      do { _ = try await repo.migrateLegacyIfNeeded() } catch {
        GymLog.error("legacy upload failed", error)
      }
    }
    do {
      async let exerciseResult = repo.exercises()
      async let planResult = repo.plan()
      async let workoutResult = repo.workouts()
      let (exerciseServed, planServed, workoutServed) = try await (exerciseResult, planResult, workoutResult)
      exercises = exerciseServed.value.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      routines = planServed.value.routines.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
      plan = planServed.value.plan
      workouts = workoutServed.value
      fromCache = exerciseServed.fromCache || planServed.fromCache || workoutServed.fromCache
      loadError = nil
      loaded = true
    } catch {
      GymLog.error("load failed", error)
      if !loaded { loadError = L("loadError") }
    }
  }

  func signIn(email: String, password: String) async throws {
    guard let repo else { throw GymError.notConfigured }
    try await repo.signIn(email: email, password: password)
    isSignedIn = true
    loaded = false
    await reload()
  }

  func signOut() async {
    try? await repo?.signOut()
    isSignedIn = false
    clearLists()
  }

  private func clearLists() {
    exercises = []
    routines = []
    plan = WeeklyPlan()
    workouts = []
    fromCache = false
    loaded = false
    loadError = nil
  }

  @discardableResult
  func saveExercise(_ exercise: Exercise) async -> Bool {
    guard let repo else { return false }
    upsertExercise(exercise)
    do {
      _ = try await repo.saveExercise(exercise)
      return true
    } catch {
      GymLog.error("save exercise", error)
      actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func deleteExercise(_ exercise: Exercise) async -> Bool {
    guard let repo else { return false }
    exercises.removeAll { $0.id == exercise.id }
    do {
      try await repo.deleteExercise(exercise)
      return true
    } catch {
      GymLog.error("delete exercise", error)
      actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func saveRoutine(_ routine: Routine) async -> Bool {
    guard let repo else { return false }
    if let index = routines.firstIndex(where: { $0.id == routine.id }) {
      routines[index] = routine
    } else {
      routines.append(routine)
    }
    routines.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    do {
      _ = try await repo.saveRoutine(routine)
      return true
    } catch {
      GymLog.error("save routine", error)
      actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func deleteRoutine(id: String) async -> Bool {
    guard let repo else { return false }
    routines.removeAll { $0.id == id }
    plan = plan.withoutRoutine(id)
    do {
      plan = try await repo.deleteRoutine(id: id)
      return true
    } catch {
      GymLog.error("delete routine", error)
      actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func setDay(weekday: Int, routineId: String?) async -> Bool {
    guard let repo else { return false }
    plan = plan.withDay(weekday, routineId: routineId)
    do {
      plan = try await repo.setDay(weekday: weekday, routineId: routineId)
      return true
    } catch {
      GymLog.error("set day", error)
      actionError = L("saveFailed")
      return false
    }
  }

  func startWorkout(date: Date, title: String, routine: Routine?) async -> Workout? {
    let built = BuildWorkout()(date: date, title: title, routine: routine, history: workouts)
    guard await saveWorkout(built) else { return nil }
    return built
  }

  @discardableResult
  func saveWorkout(_ workout: Workout) async -> Bool {
    guard let repo else { return false }
    if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
      workouts[index] = workout
    } else {
      workouts.append(workout)
    }
    workouts.sort { $0.date > $1.date }
    do {
      _ = try await repo.saveWorkout(workout)
      return true
    } catch {
      GymLog.error("save workout", error)
      actionError = L("saveFailed")
      return false
    }
  }

  /// After a session, raises each planned load in the routine to the heaviest set logged for it.
  /// Loads are never lowered, and exercises without a planned load are left alone.
  func raisePlanLoads(from workout: Workout) async {
    guard let routineId = workout.routineId, var routine = routine(routineId) else { return }
    var changed = false
    for index in routine.exercises.indices {
      let planned = routine.exercises[index]
      guard let target = planned.load,
        let top = workout.exercises.filter({ $0.exerciseId == planned.exerciseId }).flatMap(\.sets).map(\.load).max(),
        top > target
      else { continue }
      routine.exercises[index].load = top
      changed = true
    }
    if changed {
      routine.updatedAt = .now
      await saveRoutine(routine)
    }
  }

  @discardableResult
  func deleteWorkout(id: String) async -> Bool {
    guard let repo else { return false }
    workouts.removeAll { $0.id == id }
    do {
      try await repo.deleteWorkout(id: id)
      return true
    } catch {
      GymLog.error("delete workout", error)
      actionError = L("saveFailed")
      return false
    }
  }

  private func upsertExercise(_ exercise: Exercise) {
    if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
      exercises[index] = exercise
    } else {
      exercises.append(exercise)
    }
    exercises.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
  }
}
