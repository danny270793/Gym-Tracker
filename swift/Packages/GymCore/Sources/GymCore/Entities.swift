import Foundation

/// A reusable exercise. Routines and workouts reference it by id.
public struct Exercise: Identifiable, Equatable, Sendable, Codable {
  public var id: String
  public var name: String
  /// Counted as one set each on the dashboard.
  public var primaryMuscles: [MuscleGroup]
  /// Counted as half a set each on the dashboard.
  public var secondaryMuscles: [MuscleGroup]
  public var equipment: Equipment
  public var loadType: LoadType
  public var notes: String?
  /// Object paths in the `gym-exercise-images` bucket (`<userId>/<uuid>.jpg`).
  public var imagePaths: [String]
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String,
    name: String,
    primaryMuscles: [MuscleGroup] = [],
    secondaryMuscles: [MuscleGroup] = [],
    equipment: Equipment = .other,
    loadType: LoadType = .weight,
    notes: String? = nil,
    imagePaths: [String] = [],
    createdAt: Date,
    updatedAt: Date
  ) {
    self.id = id
    self.name = name
    self.primaryMuscles = primaryMuscles
    self.secondaryMuscles = secondaryMuscles
    self.equipment = equipment
    self.loadType = loadType
    self.notes = notes
    self.imagePaths = imagePaths
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  enum CodingKeys: String, CodingKey {
    case id, name, primaryMuscles, secondaryMuscles, equipment, loadType, notes
    case imagePaths, imageNames, createdAt, updatedAt
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
    primaryMuscles = Self.muscles(try c.decodeIfPresent([String].self, forKey: .primaryMuscles))
    secondaryMuscles = Self.muscles(try c.decodeIfPresent([String].self, forKey: .secondaryMuscles))
    let equipmentRaw = try c.decodeIfPresent(String.self, forKey: .equipment)
    equipment = equipmentRaw.flatMap(Equipment.init(rawValue:)) ?? .other
    if let raw = try c.decodeIfPresent(String.self, forKey: .loadType), let parsed = LoadType(rawValue: raw) {
      loadType = parsed
    } else {
      loadType = LoadType.defaultFor(equipment)
    }
    notes = try c.decodeIfPresent(String.self, forKey: .notes)
    imagePaths =
      try c.decodeIfPresent([String].self, forKey: .imagePaths)
      ?? c.decodeIfPresent([String].self, forKey: .imageNames) ?? []
    createdAt = c.gymDate(.createdAt)
    updatedAt = c.gymDate(.updatedAt)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(name, forKey: .name)
    try c.encode(primaryMuscles.map(\.rawValue), forKey: .primaryMuscles)
    try c.encode(secondaryMuscles.map(\.rawValue), forKey: .secondaryMuscles)
    try c.encode(equipment.rawValue, forKey: .equipment)
    try c.encode(loadType.rawValue, forKey: .loadType)
    try c.encodeNullIfNil(notes, forKey: .notes)
    try c.encode(imagePaths, forKey: .imagePaths)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(updatedAt, forKey: .updatedAt)
  }

  private static func muscles(_ raw: [String]?) -> [MuscleGroup] {
    raw?.compactMap(MuscleGroup.init(rawValue:)) ?? []
  }
}

/// One line of a routine: "3x8 incline dumbbell press @ 50 lb".
public struct PlannedExercise: Equatable, Sendable, Codable {
  public var exerciseId: String
  public var sets: Int
  public var reps: Int
  /// Optional target load, in pounds (or discs).
  public var load: Double?
  public var notes: String?

  public init(exerciseId: String, sets: Int = 3, reps: Int = 8, load: Double? = nil, notes: String? = nil) {
    self.exerciseId = exerciseId
    self.sets = sets
    self.reps = reps
    self.load = load
    self.notes = notes
  }

  enum CodingKeys: String, CodingKey { case exerciseId, sets, reps, load, weightLb, notes }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    exerciseId = try c.decode(String.self, forKey: .exerciseId)
    sets = c.flexInt(.sets, default: 3)
    reps = c.flexInt(.reps, default: 8)
    load = c.flexDoubleIfPresent(.load) ?? c.flexDoubleIfPresent(.weightLb)
    notes = try c.decodeIfPresent(String.self, forKey: .notes)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(exerciseId, forKey: .exerciseId)
    try c.encode(sets, forKey: .sets)
    try c.encode(reps, forKey: .reps)
    try c.encodeNullIfNil(load, forKey: .load)
    try c.encodeNullIfNil(notes, forKey: .notes)
  }
}

public struct Routine: Identifiable, Equatable, Sendable, Codable {
  public var id: String
  public var title: String
  public var notes: String?
  public var exercises: [PlannedExercise]
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String, title: String, notes: String? = nil, exercises: [PlannedExercise] = [],
    createdAt: Date, updatedAt: Date
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.exercises = exercises
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public var totalSets: Int { exercises.reduce(0) { $0 + $1.sets } }

  enum CodingKeys: String, CodingKey { case id, title, notes, exercises, createdAt, updatedAt }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    notes = try c.decodeIfPresent(String.self, forKey: .notes)
    exercises = try c.decodeIfPresent([PlannedExercise].self, forKey: .exercises) ?? []
    createdAt = c.gymDate(.createdAt)
    updatedAt = c.gymDate(.updatedAt)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(title, forKey: .title)
    try c.encodeNullIfNil(notes, forKey: .notes)
    try c.encode(exercises, forKey: .exercises)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(updatedAt, forKey: .updatedAt)
  }
}

/// Which routine to do on each weekday (1 = Monday … 7 = Sunday). A missing day is rest.
public struct WeeklyPlan: Equatable, Sendable, Codable {
  public var routineIdByWeekday: [Int: String]

  public init(routineIdByWeekday: [Int: String] = [:]) {
    self.routineIdByWeekday = routineIdByWeekday
  }

  public func routineId(for weekday: Int) -> String? { routineIdByWeekday[weekday] }

  public var trainingDays: Int { routineIdByWeekday.count }

  public func withDay(_ weekday: Int, routineId: String?) -> WeeklyPlan {
    var next = routineIdByWeekday
    if let routineId { next[weekday] = routineId } else { next.removeValue(forKey: weekday) }
    return WeeklyPlan(routineIdByWeekday: next)
  }

  public func withoutRoutine(_ routineId: String) -> WeeklyPlan {
    WeeklyPlan(routineIdByWeekday: routineIdByWeekday.filter { $0.value != routineId })
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    let days = try c.decodeIfPresent([String: String].self, forKey: .days) ?? [:]
    var map: [Int: String] = [:]
    for (key, value) in days {
      if let day = Int(key), (1...7).contains(day) { map[day] = value }
    }
    routineIdByWeekday = map
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    let days = Dictionary(uniqueKeysWithValues: routineIdByWeekday.map { (String($0.key), $0.value) })
    try c.encode(days, forKey: .days)
  }

  enum CodingKeys: String, CodingKey { case days }
}

/// One logged set. Every set counts in stats; `completed` is kept only for the shared database column.
public struct WorkoutSet: Equatable, Sendable, Codable {
  public var reps: Int
  /// Pounds, or a disc count for stack exercises. 0 for bodyweight.
  public var load: Double
  public var completed: Bool

  public init(reps: Int = 0, load: Double = 0, completed: Bool = true) {
    self.reps = reps
    self.load = load
    self.completed = completed
  }

  public var volume: Double { Double(reps) * load }

  enum CodingKeys: String, CodingKey { case reps, load, weightLb, completed }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    reps = c.flexInt(.reps, default: 0)
    load = c.flexDoubleIfPresent(.load) ?? c.flexDouble(.weightLb, default: 0)
    completed = true
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(reps, forKey: .reps)
    try c.encode(load, forKey: .load)
    try c.encode(true, forKey: .completed)
  }
}

/// Snapshot of what the plan asked for, so later plan edits don't rewrite history.
public struct PlannedTarget: Equatable, Sendable, Codable {
  public var sets: Int
  public var reps: Int
  public var load: Double?

  public init(sets: Int, reps: Int, load: Double? = nil) {
    self.sets = sets
    self.reps = reps
    self.load = load
  }

  enum CodingKeys: String, CodingKey { case sets, reps, load, weightLb }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    sets = c.flexInt(.sets, default: 0)
    reps = c.flexInt(.reps, default: 0)
    load = c.flexDoubleIfPresent(.load) ?? c.flexDoubleIfPresent(.weightLb)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(sets, forKey: .sets)
    try c.encode(reps, forKey: .reps)
    try c.encodeNullIfNil(load, forKey: .load)
  }
}

public struct WorkoutExercise: Identifiable, Equatable, Sendable, Codable {
  public var id: String
  public var exerciseId: String
  /// Nil when the exercise was added during the workout.
  public var planned: PlannedTarget?
  public var sets: [WorkoutSet]
  public var notes: String?

  public init(
    id: String, exerciseId: String, planned: PlannedTarget? = nil, sets: [WorkoutSet] = [], notes: String? = nil
  ) {
    self.id = id
    self.exerciseId = exerciseId
    self.planned = planned
    self.sets = sets
    self.notes = notes
  }

  public var completedSets: [WorkoutSet] { sets }

  enum CodingKeys: String, CodingKey { case id, exerciseId, planned, sets, notes }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    exerciseId = try c.decode(String.self, forKey: .exerciseId)
    planned = try c.decodeIfPresent(PlannedTarget.self, forKey: .planned)
    sets = try c.decodeIfPresent([WorkoutSet].self, forKey: .sets) ?? []
    notes = try c.decodeIfPresent(String.self, forKey: .notes)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(exerciseId, forKey: .exerciseId)
    if let planned { try c.encode(planned, forKey: .planned) } else { try c.encodeNil(forKey: .planned) }
    try c.encode(sets, forKey: .sets)
    try c.encodeNullIfNil(notes, forKey: .notes)
  }
}

public struct Workout: Identifiable, Equatable, Sendable, Codable {
  public var id: String
  /// Local date and start time of the session.
  public var date: Date
  public var routineId: String?
  public var title: String
  public var exercises: [WorkoutExercise]
  public var notes: String?
  /// Nil while the workout is in progress.
  public var finishedAt: Date?
  public var createdAt: Date
  public var updatedAt: Date

  public init(
    id: String, date: Date, routineId: String? = nil, title: String,
    exercises: [WorkoutExercise] = [], notes: String? = nil, finishedAt: Date? = nil,
    createdAt: Date, updatedAt: Date
  ) {
    self.id = id
    self.date = date
    self.routineId = routineId
    self.title = title
    self.exercises = exercises
    self.notes = notes
    self.finishedAt = finishedAt
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  public var isFinished: Bool { finishedAt != nil }
  public var completedSetCount: Int { exercises.reduce(0) { $0 + $1.completedSets.count } }
  public var totalSetCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
  public var completedReps: Int {
    exercises.reduce(0) { sum, entry in sum + entry.completedSets.reduce(0) { $0 + $1.reps } }
  }

  /// Completed reps × pounds for exercises where `isWeight` is true.
  public func weightVolumeLb(_ isWeight: (String) -> Bool) -> Double {
    exercises.filter { isWeight($0.exerciseId) }.reduce(0) { sum, entry in
      sum + entry.completedSets.reduce(0) { $0 + $1.volume }
    }
  }

  enum CodingKeys: String, CodingKey {
    case id, date, routineId, title, exercises, notes, finishedAt, createdAt, updatedAt
  }

  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id = try c.decode(String.self, forKey: .id)
    date = c.gymDate(.date)
    routineId = try c.decodeIfPresent(String.self, forKey: .routineId)
    title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
    exercises = try c.decodeIfPresent([WorkoutExercise].self, forKey: .exercises) ?? []
    notes = try c.decodeIfPresent(String.self, forKey: .notes)
    finishedAt = c.gymDateIfPresent(.finishedAt)
    createdAt = c.gymDate(.createdAt)
    updatedAt = c.gymDate(.updatedAt)
  }

  public func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(date, forKey: .date)
    try c.encodeNullIfNil(routineId, forKey: .routineId)
    try c.encode(title, forKey: .title)
    try c.encode(exercises, forKey: .exercises)
    try c.encodeNullIfNil(notes, forKey: .notes)
    try c.encodeNullIfNil(finishedAt, forKey: .finishedAt)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(updatedAt, forKey: .updatedAt)
  }
}
