import Foundation
import GymCore
import Testing

private let epoch = date(2026, 1, 1)

private func exercise(
  _ id: String, primary: [MuscleGroup] = [.chest], secondary: [MuscleGroup] = []
) -> Exercise {
  Exercise(
    id: id, name: id, primaryMuscles: primary, secondaryMuscles: secondary, equipment: .dumbbell,
    createdAt: epoch, updatedAt: epoch)
}

private func done(_ reps: Int, _ load: Double) -> WorkoutSet {
  WorkoutSet(reps: reps, load: load, completed: true)
}

private func workout(
  _ id: String, _ date: Date, _ sets: [String: [WorkoutSet]], finishedAt: Date? = nil
) -> Workout {
  Workout(
    id: id, date: date, title: id,
    exercises: sets.map { WorkoutExercise(id: "\(id)-\($0.key)", exerciseId: $0.key, sets: $0.value) },
    finishedAt: finishedAt, createdAt: date, updatedAt: date)
}

@Test func weekHelpersStartOnMonday() {
  let now = date(2026, 3, 11, 20)
  #expect(startOfWeek(now) == date(2026, 3, 9))
  #expect(startOfWeek(date(2026, 3, 15, 23)) == date(2026, 3, 9))
  #expect(addDays(date(2026, 3, 9), -7) == date(2026, 3, 2))
}

@Test func epley() {
  #expect(estimatedOneRepMax(100, 1) == 100)
  #expect(abs(estimatedOneRepMax(100, 10) - 133.33) < 0.01)
  #expect(estimatedOneRepMax(0, 10) == 0)
}

@Test func weeklyTotalsStreakMuscles() {
  let now = date(2026, 3, 11, 20)
  let workouts = [
    workout("w1", date(2026, 3, 9, 18), ["press": [done(8, 50), done(8, 50), WorkoutSet(reps: 8, load: 50)]], finishedAt: date(2026, 3, 9, 19)),
    workout("w0", date(2026, 3, 3, 18), ["press": [done(8, 45)]], finishedAt: date(2026, 3, 3, 19, 30)),
    workout("w-1", date(2026, 2, 24), ["press": [done(8, 40)]]),
    workout("w-3", date(2026, 2, 10), ["press": [done(8, 40)]]),
  ]
  let stats = DashboardStatsCalculator()(
    workouts: workouts,
    exercises: [exercise("press", primary: [.chest], secondary: [.triceps])],
    weeklyPlan: WeeklyPlan(routineIdByWeekday: [1: "a", 4: "b"]),
    now: now
  )
  #expect(stats.thisWeek.workouts == 1)
  #expect(stats.thisWeek.sets == 3)
  #expect(stats.thisWeek.reps == 24)
  #expect(stats.thisWeek.volumeLb == 1200)
  #expect(stats.lastWeek.volumeLb == 360)
  #expect(stats.weeklyHistory.count == 8)
  #expect(stats.weeklyHistory.last?.weekStart == date(2026, 3, 9))
  #expect(stats.weekStreak == 3)
  #expect(stats.totalWorkouts == 4)
  #expect(stats.plannedDaysPerWeek == 2)
  #expect(stats.muscleSetsThisWeek.map(\.muscle) == [.chest, .triceps])
  #expect(stats.muscleSetsThisWeek.map(\.value) == [3, 1.5])
  #expect(stats.averageDuration == 75.0 * 60)
  #expect(stats.personalRecords.count == 1)
  #expect(stats.personalRecords.first?.load == 50)
  let trend = stats.trends.first
  #expect(trend?.currentE1rm == estimatedOneRepMax(50, 8))
  #expect((trend?.change ?? 0) > 0)
}

@Test func streakCountsFromLastWeekWhenThisWeekIsEmpty() {
  let stats = DashboardStatsCalculator()(
    workouts: [workout("a", date(2026, 3, 3), ["x": [done(5, 100)]])],
    exercises: [],
    weeklyPlan: WeeklyPlan(),
    now: date(2026, 3, 11, 20)
  )
  #expect(stats.weekStreak == 1)
  #expect(stats.thisWeek.workouts == 0)
}

@Test func exerciseProgressOldestFirst() {
  let points = ExerciseProgress()(
    exerciseId: "press",
    workouts: [
      workout("b", date(2026, 3, 9), ["press": [done(8, 50), done(6, 55)]]),
      workout("a", date(2026, 3, 2), ["press": [done(8, 45)], "other": [done(1, 300)]]),
    ]
  )
  #expect(points.map(\.workoutId) == ["a", "b"])
  #expect(points.last?.topLoad == 55)
  #expect(points.last?.volume == 8 * 50 + 6.0 * 55)
  #expect(points.last?.sets == 2)
}

@Test func weightUnitConvertsAndFormats() {
  #expect(WeightUnit.lb.format(135) == "135")
  #expect(WeightUnit.kg.format(135) == "61.2")
  #expect(abs(WeightUnit.kg.toLb(WeightUnit.kg.fromLb(225)) - 225) < 1e-9)
  #expect(WeightUnit.kg.format(66) == "29.9")
  let reported = WeightUnit.kg.toLb(50)
  #expect(abs(reported - 110.23) < 0.01)
  #expect(WeightUnit.lb.format(reported) == "110.2")
}

@Test func discExercisesAreLeftOutOfVolume() {
  var pushdown = exercise("pushdown")
  pushdown.loadType = .discs
  let stats = DashboardStatsCalculator()(
    workouts: [workout("w", date(2026, 3, 10), ["press": [done(8, 50)], "pushdown": [done(10, 6)]])],
    exercises: [exercise("press"), pushdown],
    weeklyPlan: WeeklyPlan(),
    now: date(2026, 3, 11, 20)
  )
  #expect(stats.thisWeek.volumeLb == 400)
  #expect(stats.thisWeek.reps == 18)
  #expect(stats.thisWeek.sets == 2)
}

@Test func repsPerMainMuscleIgnoreSecondary() {
  let stats = DashboardStatsCalculator()(
    workouts: [
      workout("w", date(2026, 3, 10), ["press": [done(8, 50), done(6, 50)], "curl": [done(10, 20)]])
    ],
    exercises: [
      exercise("press", primary: [.chest], secondary: [.triceps]),
      exercise("curl", primary: [.biceps]),
    ],
    weeklyPlan: WeeklyPlan(),
    now: date(2026, 3, 11, 20)
  )
  #expect(stats.muscleRepsThisWeek.map(\.muscle) == [.chest, .biceps])
  #expect(stats.muscleRepsThisWeek.map { Int($0.value) } == [14, 10])
  #expect(stats.thisWeek.volumeLb == 14 * 50 + 10 * 20)
}

@Test func exerciseRoundTripsThroughJSON() throws {
  let exercise = Exercise(
    id: "x", name: "Incline dumbbell press", primaryMuscles: [.chest],
    secondaryMuscles: [.shoulders, .triceps], equipment: .dumbbell, notes: "Bench at 30°",
    imagePaths: ["a.jpg"], createdAt: date(2026, 1, 1), updatedAt: date(2026, 1, 2))
  let decoded = try GymJSON.decode(Exercise.self, from: GymJSON.encode(exercise))
  #expect(decoded == exercise)
}

@Test func exerciseJSONToleratesUnknownFields() throws {
  let raw = #"{"id":"x","primaryMuscles":["chest","notAMuscle"],"equipment":"spaceship"}"#
  let exercise = try GymJSON.decode(Exercise.self, from: Data(raw.utf8))
  #expect(exercise.name == "")
  #expect(exercise.primaryMuscles == [.chest])
  #expect(exercise.equipment == .other)
  #expect(exercise.imagePaths.isEmpty)
}

@Test func routineAndPlanRoundTrip() throws {
  let routine = Routine(
    id: "push", title: "Push",
    exercises: [
      PlannedExercise(exerciseId: "a", sets: 3, reps: 8, load: 50),
      PlannedExercise(exerciseId: "b", sets: 3, reps: 8),
    ],
    createdAt: date(2026, 1, 1), updatedAt: date(2026, 1, 1))
  #expect(try GymJSON.decode(Routine.self, from: GymJSON.encode(routine)) == routine)
  let plan = WeeklyPlan(routineIdByWeekday: [1: "push", 4: "push"])
  #expect(try GymJSON.decode(WeeklyPlan.self, from: GymJSON.encode(plan)) == plan)
  #expect(plan.trainingDays == 2)
  #expect(plan.withoutRoutine("push").trainingDays == 0)
  #expect(plan.withDay(1, routineId: nil).routineId(for: 1) == nil)
}

@Test func workoutRoundTripCountsCompletedSets() throws {
  let session = workout(
    "w", date(2026, 3, 2, 18),
    ["a": [done(8, 50), done(8, 50), WorkoutSet(reps: 8, load: 50)]])
  #expect(try GymJSON.decode(Workout.self, from: GymJSON.encode(session)) == session)
  #expect(session.totalSetCount == 3)
  #expect(session.completedSetCount == 3)
  #expect(session.completedReps == 24)
  #expect(session.weightVolumeLb { _ in true } == 1200)
  #expect(session.weightVolumeLb { _ in false } == 0)
}

@Test func loadTypeDefaultsFromEquipment() throws {
  func old(_ equipment: String) throws -> Exercise {
    try GymJSON.decode(Exercise.self, from: Data(#"{"id":"x","equipment":"\#(equipment)"}"#.utf8))
  }
  #expect(try old("cable").loadType == .discs)
  #expect(try old("machine").loadType == .discs)
  #expect(try old("dumbbell").loadType == .weight)
  let explicit = try GymJSON.decode(
    Exercise.self, from: Data(#"{"id":"x","equipment":"cable","loadType":"weight"}"#.utf8))
  #expect(explicit.loadType == .weight)
}

@Test func oldWeightLbKeyStillLoads() throws {
  let set = try GymJSON.decode(WorkoutSet.self, from: Data(#"{"reps":8,"weightLb":50,"completed":true}"#.utf8))
  #expect(set.load == 50)
}

@Test func buildWorkoutPrefillsLastSession() {
  let routine = Routine(
    id: "push", title: "Push",
    exercises: [
      PlannedExercise(exerciseId: "incline", sets: 3, reps: 8),
      PlannedExercise(exerciseId: "ohp", sets: 2, reps: 10, load: 40),
    ],
    createdAt: epoch, updatedAt: epoch)
  let history = [
    workout("old", date(2026, 3, 1), ["incline": [done(8, 45)]]),
    workout("recent", date(2026, 3, 5), ["incline": [done(8, 50), done(6, 55)]]),
  ]
  let built = BuildWorkout()(date: date(2026, 3, 9), title: "Push", routine: routine, history: history)
  #expect(built.routineId == "push")
  #expect(built.exercises.count == 2)
  let incline = built.exercises[0]
  #expect(incline.sets.count == 3)
  #expect(incline.sets.allSatisfy { $0.reps == 8 && $0.load == 55 })
  #expect(incline.planned == PlannedTarget(sets: 3, reps: 8))
  #expect(built.exercises[1].sets.map(\.load) == [40, 40])
}

@Test func emptyWorkoutWithoutRoutine() {
  let built = BuildWorkout()(date: date(2026, 1, 1), title: "Workout", routine: nil, history: [])
  #expect(built.routineId == nil)
  #expect(built.exercises.isEmpty)
}

@Test func adHocEntryCopiesLastSets() {
  let history = [workout("w", date(2026, 3, 5), ["curl": [done(12, 25), done(10, 25)]])]
  let builder = BuildWorkout()
  let row = builder.adHocEntry("curl", history)
  #expect(row.planned == nil)
  #expect(row.sets == [WorkoutSet(reps: 12, load: 25), WorkoutSet(reps: 10, load: 25)])
  #expect(builder.adHocEntry("new", history).sets.count == 3)
}
