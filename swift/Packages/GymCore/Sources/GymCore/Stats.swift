import Foundation

/// Epley estimated one-rep max. `load` for a single, 0 for no load.
public func estimatedOneRepMax(_ load: Double, _ reps: Int) -> Double {
  if load <= 0 || reps <= 0 { return 0 }
  if reps == 1 { return load }
  return load * (1 + Double(reps) / 30)
}

public struct WeekSummary: Equatable, Sendable {
  public var weekStart: Date
  public var workouts: Int
  public var sets: Int
  public var reps: Int
  public var volumeLb: Double

  public init(weekStart: Date, workouts: Int = 0, sets: Int = 0, reps: Int = 0, volumeLb: Double = 0) {
    self.weekStart = weekStart
    self.workouts = workouts
    self.sets = sets
    self.reps = reps
    self.volumeLb = volumeLb
  }
}

public struct PersonalRecord: Equatable, Sendable, Identifiable {
  public var exerciseId: String
  public var e1rm: Double
  public var load: Double
  public var reps: Int
  public var date: Date
  public var id: String { exerciseId }

  public init(exerciseId: String, e1rm: Double, load: Double, reps: Int, date: Date) {
    self.exerciseId = exerciseId
    self.e1rm = e1rm
    self.load = load
    self.reps = reps
    self.date = date
  }
}

public struct ExerciseTrend: Equatable, Sendable, Identifiable {
  public var exerciseId: String
  public var currentE1rm: Double
  public var previousE1rm: Double?
  public var id: String { exerciseId }

  /// Fractional change (0.05 == +5%), or nil when there is no earlier data.
  public var change: Double? {
    guard let previousE1rm, previousE1rm > 0 else { return nil }
    return (currentE1rm - previousE1rm) / previousE1rm
  }

  public init(exerciseId: String, currentE1rm: Double, previousE1rm: Double? = nil) {
    self.exerciseId = exerciseId
    self.currentE1rm = currentE1rm
    self.previousE1rm = previousE1rm
  }
}

public struct MuscleValue: Equatable, Sendable, Identifiable {
  public var muscle: MuscleGroup
  public var value: Double
  public var id: MuscleGroup { muscle }
}

public struct DashboardStats: Equatable, Sendable {
  public var thisWeek: WeekSummary
  public var lastWeek: WeekSummary
  /// Oldest first, ending with this week.
  public var weeklyHistory: [WeekSummary]
  public var plannedDaysPerWeek: Int
  /// Consecutive weeks with at least one workout, ending this week (or last week).
  public var weekStreak: Int
  public var totalWorkouts: Int
  public var muscleSetsThisWeek: [MuscleValue]
  public var muscleRepsThisWeek: [MuscleValue]
  public var personalRecords: [PersonalRecord]
  public var trends: [ExerciseTrend]
  public var averageDuration: TimeInterval?

  public init(
    thisWeek: WeekSummary, lastWeek: WeekSummary, weeklyHistory: [WeekSummary],
    plannedDaysPerWeek: Int, weekStreak: Int, totalWorkouts: Int,
    muscleSetsThisWeek: [MuscleValue], muscleRepsThisWeek: [MuscleValue],
    personalRecords: [PersonalRecord], trends: [ExerciseTrend], averageDuration: TimeInterval?
  ) {
    self.thisWeek = thisWeek
    self.lastWeek = lastWeek
    self.weeklyHistory = weeklyHistory
    self.plannedDaysPerWeek = plannedDaysPerWeek
    self.weekStreak = weekStreak
    self.totalWorkouts = totalWorkouts
    self.muscleSetsThisWeek = muscleSetsThisWeek
    self.muscleRepsThisWeek = muscleRepsThisWeek
    self.personalRecords = personalRecords
    self.trends = trends
    self.averageDuration = averageDuration
  }
}

public struct ExerciseSessionPoint: Equatable, Sendable, Identifiable {
  public var date: Date
  public var workoutId: String
  public var sets: Int
  public var reps: Int
  public var topLoad: Double
  public var bestE1rm: Double
  public var volume: Double
  public var bestReps: Int
  public var id: String { workoutId }

  public init(
    date: Date, workoutId: String, sets: Int, reps: Int, topLoad: Double, bestE1rm: Double, volume: Double,
    bestReps: Int
  ) {
    self.date = date
    self.workoutId = workoutId
    self.sets = sets
    self.reps = reps
    self.topLoad = topLoad
    self.bestE1rm = bestE1rm
    self.volume = volume
    self.bestReps = bestReps
  }
}

public struct DashboardStatsCalculator: Sendable {
  public static let historyWeeks = 8
  public init() {}

  public func callAsFunction(
    workouts: [Workout], exercises: [Exercise], weeklyPlan: WeeklyPlan, now: Date
  ) -> DashboardStats {
    let thisWeekStart = startOfWeek(now)
    let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    let isWeight: (String) -> Bool = { byId[$0]?.loadType != .discs }
    var weekly: [Date: WeekAcc] = [:]
    for workout in workouts where workout.completedSetCount > 0 {
      weekly[startOfWeek(workout.date), default: WeekAcc()].add(workout, isWeight)
    }
    func summary(_ start: Date) -> WeekSummary {
      weekly[start]?.toSummary(start) ?? WeekSummary(weekStart: start)
    }
    let history = (0..<Self.historyWeeks).reversed().map { summary(addDays(thisWeekStart, -7 * $0)) }
    let thisWeekWorkouts = workouts.filter { !$0.date.isBefore(thisWeekStart) }
    return DashboardStats(
      thisWeek: summary(thisWeekStart),
      lastWeek: summary(addDays(thisWeekStart, -7)),
      weeklyHistory: history,
      plannedDaysPerWeek: weeklyPlan.trainingDays,
      weekStreak: Self.weekStreak(Set(weekly.keys), thisWeekStart),
      totalWorkouts: workouts.filter { $0.completedSetCount > 0 }.count,
      muscleSetsThisWeek: Self.muscleSets(thisWeekWorkouts, byId),
      muscleRepsThisWeek: Self.muscleReps(thisWeekWorkouts, byId),
      personalRecords: Self.personalRecords(workouts),
      trends: Self.trends(workouts, now),
      averageDuration: Self.averageDuration(workouts, now)
    )
  }

  static func weekStreak(_ active: Set<Date>, _ thisWeekStart: Date) -> Int {
    var cursor = active.contains(thisWeekStart) ? thisWeekStart : addDays(thisWeekStart, -7)
    var streak = 0
    while active.contains(cursor) {
      streak += 1
      cursor = addDays(cursor, -7)
    }
    return streak
  }

  static func muscleSets(_ workouts: [Workout], _ byId: [String: Exercise]) -> [MuscleValue] {
    var sets: [MuscleGroup: Double] = [:]
    for workout in workouts {
      for entry in workout.exercises {
        guard let exercise = byId[entry.exerciseId] else { continue }
        let n = Double(entry.completedSets.count)
        if n == 0 { continue }
        for muscle in exercise.primaryMuscles { sets[muscle, default: 0] += n }
        for muscle in exercise.secondaryMuscles { sets[muscle, default: 0] += n * 0.5 }
      }
    }
    return sets.map { MuscleValue(muscle: $0.key, value: $0.value) }.sorted { $0.value > $1.value }
  }

  static func muscleReps(_ workouts: [Workout], _ byId: [String: Exercise]) -> [MuscleValue] {
    var reps: [MuscleGroup: Int] = [:]
    for workout in workouts {
      for entry in workout.exercises {
        guard let exercise = byId[entry.exerciseId] else { continue }
        let n = entry.completedSets.reduce(0) { $0 + $1.reps }
        if n == 0 { continue }
        for muscle in exercise.primaryMuscles { reps[muscle, default: 0] += n }
      }
    }
    return reps.map { MuscleValue(muscle: $0.key, value: Double($0.value)) }.sorted { $0.value > $1.value }
  }

  public static func personalRecords(_ workouts: [Workout]) -> [PersonalRecord] {
    var best: [String: PersonalRecord] = [:]
    for workout in workouts {
      for entry in workout.exercises {
        for set in entry.completedSets {
          let e1rm = estimatedOneRepMax(set.load, set.reps)
          if e1rm <= 0 { continue }
          if let current = best[entry.exerciseId] {
            let better = e1rm > current.e1rm || (e1rm == current.e1rm && workout.date < current.date)
            if !better { continue }
          }
          best[entry.exerciseId] = PersonalRecord(
            exerciseId: entry.exerciseId, e1rm: e1rm, load: set.load, reps: set.reps, date: workout.date)
        }
      }
    }
    return best.values.sorted { $0.date > $1.date }
  }

  static func trends(_ workouts: [Workout], _ now: Date) -> [ExerciseTrend] {
    let today = dateOnly(now)
    let currentStart = addDays(today, -27)
    let previousStart = addDays(today, -55)
    var current: [String: Double] = [:]
    var previous: [String: Double] = [:]
    for workout in workouts {
      let day = dateOnly(workout.date)
      if day < previousStart || day > today { continue }
      let isPrevious = day < currentStart
      for entry in workout.exercises {
        for set in entry.completedSets {
          let e1rm = estimatedOneRepMax(set.load, set.reps)
          if isPrevious {
            if e1rm > previous[entry.exerciseId, default: 0] { previous[entry.exerciseId] = e1rm }
          } else if e1rm > current[entry.exerciseId, default: 0] {
            current[entry.exerciseId] = e1rm
          }
        }
      }
    }
    return current.compactMap { id, value -> ExerciseTrend? in
      guard value > 0 else { return nil }
      return ExerciseTrend(exerciseId: id, currentE1rm: value, previousE1rm: previous[id])
    }
    .sorted { a, b in
      switch (a.change, b.change) {
      case let (ca?, cb?) where ca != cb:
        return ca > cb
      case (_?, _?):
        return a.exerciseId < b.exerciseId
      case (nil, nil):
        return a.currentE1rm == b.currentE1rm
          ? a.exerciseId < b.exerciseId : a.currentE1rm > b.currentE1rm
      case (nil, _):
        return false
      case (_, nil):
        return true
      }
    }
  }

  static func averageDuration(_ workouts: [Workout], _ now: Date) -> TimeInterval? {
    let since = now.addingTimeInterval(-30 * 24 * 60 * 60)
    let durations = workouts.compactMap { workout -> TimeInterval? in
      guard let finished = workout.finishedAt, workout.date > since else { return nil }
      let duration = finished.timeIntervalSince(workout.date)
      guard duration > 0, duration < 6 * 60 * 60 else { return nil }
      return duration
    }
    guard !durations.isEmpty else { return nil }
    let total = durations.reduce(0, +)
    return TimeInterval(Int(total) / durations.count)
  }
}

private struct WeekAcc {
  var workouts = 0
  var sets = 0
  var reps = 0
  var volume = 0.0

  mutating func add(_ workout: Workout, _ isWeight: (String) -> Bool) {
    workouts += 1
    sets += workout.completedSetCount
    reps += workout.completedReps
    volume += workout.weightVolumeLb(isWeight)
  }

  func toSummary(_ start: Date) -> WeekSummary {
    WeekSummary(weekStart: start, workouts: workouts, sets: sets, reps: reps, volumeLb: volume)
  }
}

public struct ExerciseProgress: Sendable {
  public init() {}

  /// Per-session history of one exercise, oldest first.
  public func callAsFunction(exerciseId: String, workouts: [Workout]) -> [ExerciseSessionPoint] {
    var points: [ExerciseSessionPoint] = []
    for workout in workouts {
      let sets = workout.exercises.filter { $0.exerciseId == exerciseId }.flatMap(\.completedSets)
      if sets.isEmpty { continue }
      var top = 0.0, e1rm = 0.0, volume = 0.0, reps = 0, bestReps = 0
      for set in sets {
        if set.load > top { top = set.load }
        let est = estimatedOneRepMax(set.load, set.reps)
        if est > e1rm { e1rm = est }
        if set.reps > bestReps { bestReps = set.reps }
        volume += set.volume
        reps += set.reps
      }
      points.append(
        ExerciseSessionPoint(
          date: workout.date, workoutId: workout.id, sets: sets.count, reps: reps, topLoad: top, bestE1rm: e1rm,
          volume: volume, bestReps: bestReps))
    }
    return points.sorted { $0.date < $1.date }
  }
}

private extension Date {
  func isBefore(_ other: Date) -> Bool { self < other }
}
