import Foundation

/// Builds a new, unsaved workout from a routine (or an empty one).
///
/// Each planned exercise gets its planned sets and reps. The load is the plan's
/// target, otherwise the heaviest completed load from the most recent session.
public struct BuildWorkout: Sendable {
  public init() {}

  public func callAsFunction(
    date: Date, title: String, routine: Routine?, history: [Workout], now: Date = .now
  ) -> Workout {
    Workout(
      id: UUID().uuidString.lowercased(),
      date: date,
      routineId: routine?.id,
      title: title,
      exercises: (routine?.exercises ?? []).map { entryFor($0, history) },
      createdAt: now,
      updatedAt: now
    )
  }

  public func entryFor(_ planned: PlannedExercise, _ history: [Workout]) -> WorkoutExercise {
    let weight = planned.load ?? Self.lastLoad(planned.exerciseId, history) ?? 0
    return WorkoutExercise(
      id: UUID().uuidString.lowercased(),
      exerciseId: planned.exerciseId,
      planned: PlannedTarget(sets: planned.sets, reps: planned.reps, load: planned.load),
      sets: (0..<planned.sets).map { _ in WorkoutSet(reps: planned.reps, load: weight) }
    )
  }

  /// A row for an exercise added during the workout (not in the plan).
  public func adHocEntry(_ exerciseId: String, _ history: [Workout]) -> WorkoutExercise {
    let last = Self.lastSets(exerciseId, history)
    let sets =
      last.isEmpty
      ? [WorkoutSet(reps: 8), WorkoutSet(reps: 8), WorkoutSet(reps: 8)]
      : last.map { WorkoutSet(reps: $0.reps, load: $0.load) }
    return WorkoutExercise(id: UUID().uuidString.lowercased(), exerciseId: exerciseId, sets: sets)
  }

  /// Heaviest completed load in the latest session that did `exerciseId`.
  public static func lastLoad(_ exerciseId: String, _ history: [Workout]) -> Double? {
    let sets = lastSets(exerciseId, history)
    return sets.map(\.load).max()
  }

  /// Completed sets from the latest session that did `exerciseId`.
  public static func lastSets(_ exerciseId: String, _ history: [Workout]) -> [WorkoutSet] {
    for workout in history.sorted(by: { $0.date > $1.date }) {
      let sets = workout.exercises.filter { $0.exerciseId == exerciseId }.flatMap(\.completedSets)
      if !sets.isEmpty { return sets }
    }
    return []
  }
}
