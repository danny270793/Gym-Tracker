import Foundation
import GymCore
import Supabase

public struct GymConfig: Sendable {
  public var url: URL
  public var anonKey: String

  public init(url: URL, anonKey: String) {
    self.url = url
    self.anonKey = anonKey
  }

  public static func fromBundle(_ bundle: Bundle = .main) -> GymConfig? {
    guard let path = bundle.path(forResource: "GymConfig", ofType: "plist"),
      let dict = NSDictionary(contentsOfFile: path) as? [String: String],
      let raw = dict["SUPABASE_URL"], let url = URL(string: raw),
      let key = dict["SUPABASE_ANON_KEY"], !key.isEmpty, !raw.contains("xxxx")
    else { return nil }
    return GymConfig(url: url, anonKey: key)
  }
}

public enum GymError: LocalizedError {
  case notSignedIn
  case notConfigured

  public var errorDescription: String? {
    switch self {
    case .notSignedIn: "Not signed in"
    case .notConfigured: "Danny Gym Tracker isn't configured"
    }
  }
}

/// Reads and writes the `gym_*` schema. Reads fall back to the on-device cache
/// when the network is down. Writes need a connection.
public final class GymRepository: Sendable {
  public let client: SupabaseClient
  let cache: OfflineCache
  private let saves = SaveQueue()

  static let imageBucket = "gym-exercise-images"
  static let legacyFiles = ["exercises", "routines", "weekly_plan", "workouts"]

  public init(config: GymConfig, cache: OfflineCache = .shared) {
    self.cache = cache
    client = SupabaseClient(
      supabaseURL: config.url,
      supabaseKey: config.anonKey,
      options: SupabaseClientOptions(
        db: .init(encoder: GymJSON.encoder, decoder: GymJSON.decoder),
        auth: .init(
          storage: KeychainLocalStorage(service: "io.github.danny270793.gymtracker.auth"),
          emitLocalSessionAsInitialSession: true
        )
      )
    )
  }

  public var userId: String? { client.auth.currentUser?.id.uuidString.lowercased() }
  public var email: String? { client.auth.currentUser?.email }
  public var hasSession: Bool { client.auth.currentSession != nil }

  func requireUser() throws -> String {
    guard let userId else { throw GymError.notSignedIn }
    return userId
  }

  // MARK: Session

  public func signIn(email: String, password: String) async throws {
    GymLog.debug("signIn")
    try await client.auth.signIn(email: email, password: password)
  }

  public func signOut() async throws {
    let uid = userId
    try await client.auth.signOut()
    if let uid { await cache.clearCache(user: uid) }
  }

  public func updateEmail(_ email: String) async throws {
    try await client.auth.update(user: UserAttributes(email: email))
  }

  public func updatePassword(_ password: String) async throws {
    try await client.auth.update(user: UserAttributes(password: password))
  }

  public func cacheEntries() async -> [CacheEntry] {
    guard let userId else { return [] }
    return await cache.entries(user: userId)
  }

  // MARK: Exercises

  public func exercises() async throws -> Served<[Exercise]> {
    let user = try requireUser()
    do {
      let rows: [Exercise] = try await client.from("gym_exercises").select()
        .is("deletedAt", value: nil).order("name").execute().value
      await cache.write(rows, user: user, name: OfflineCache.exercises)
      return Served(value: rows)
    } catch {
      if isOfflineError(error), let cached = await cache.read([Exercise].self, user: user, name: OfflineCache.exercises) {
        GymLog.debug("offline: \(cached.count) cached exercises")
        return Served(value: cached, fromCache: true)
      }
      throw error
    }
  }

  public func saveExercise(_ exercise: Exercise) async throws -> Exercise {
    let user = try requireUser()
    try await client.from("gym_exercises").upsert(ExerciseWrite(exercise: exercise, userId: user)).execute()
    var list = await cache.read([Exercise].self, user: user, name: OfflineCache.exercises) ?? []
    if let index = list.firstIndex(where: { $0.id == exercise.id }) {
      list[index] = exercise
    } else {
      list.append(exercise)
    }
    await cache.write(list, user: user, name: OfflineCache.exercises)
    return exercise
  }

  public func deleteExercise(_ exercise: Exercise) async throws {
    let user = try requireUser()
    let now = GymJSON.formatTimestamp(.now)
    try await client.from("gym_exercises").update(SoftDelete(deletedAt: now, updatedAt: now)).eq("id", value: exercise.id)
      .execute()
    var list = await cache.read([Exercise].self, user: user, name: OfflineCache.exercises) ?? []
    list.removeAll { $0.id == exercise.id }
    await cache.write(list, user: user, name: OfflineCache.exercises)
    await removeImages(exercise.imagePaths)
  }

  public func importImage(data: Data, fileExtension: String) async throws -> String {
    let user = try requireUser()
    let ext = fileExtension.isEmpty ? "jpg" : fileExtension.lowercased()
    let path = "\(user)/\(UUID().uuidString.lowercased()).\(ext)"
    try await client.storage.from(Self.imageBucket).upload(
      path, data: data, options: FileOptions(contentType: contentType(ext), upsert: true))
    let local = try await localImageURL(path, user: user)
    try data.write(to: local, options: .atomic)
    return path
  }

  public func removeImages(_ paths: [String]) async {
    guard !paths.isEmpty else { return }
    do {
      try await client.storage.from(Self.imageBucket).remove(paths: paths)
    } catch {
      GymLog.error("failed to remove images", error)
    }
    guard let user = userId else { return }
    for path in paths {
      let local = try? await localImageURL(path, user: user)
      if let local { try? FileManager.default.removeItem(at: local) }
    }
  }

  public func imageFile(path: String) async throws -> URL {
    let user = try requireUser()
    let local = try await localImageURL(path, user: user)
    if FileManager.default.fileExists(atPath: local.path) { return local }
    let data = try await client.storage.from(Self.imageBucket).download(path: path)
    try FileManager.default.createDirectory(at: local.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: local, options: .atomic)
    return local
  }

  private func localImageURL(_ path: String, user: String) async throws -> URL {
    let dir = await cache.imagesDirectory(user)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent((path as NSString).lastPathComponent)
  }

  // MARK: Plan

  public func plan() async throws -> Served<PlanSnapshot> {
    let user = try requireUser()
    do {
      let response = try await client.from("gym_routines").select("*, gym_routine_exercises(*)").is("deletedAt", value: nil)
        .execute()
      let routines = try routinesFromRows(response.data)
      let days: [PlanDayRow] = try await client.from("gym_weekly_plan").select().execute().value
      var map: [Int: String] = [:]
      for day in days { map[day.weekday] = day.routineId }
      let weekly = WeeklyPlan(routineIdByWeekday: map)
      await cache.write(routines, user: user, name: OfflineCache.routines)
      await cache.write(weekly, user: user, name: OfflineCache.weeklyPlan)
      return Served(value: PlanSnapshot(routines: routines, plan: weekly))
    } catch {
      if isOfflineError(error), let routines = await cache.read([Routine].self, user: user, name: OfflineCache.routines) {
        let weekly = await cache.read(WeeklyPlan.self, user: user, name: OfflineCache.weeklyPlan) ?? WeeklyPlan()
        return Served(value: PlanSnapshot(routines: routines, plan: weekly), fromCache: true)
      }
      throw error
    }
  }

  public func saveRoutine(_ routine: Routine) async throws -> Routine {
    let user = try requireUser()
    try await client.rpc("gym_save_routine", params: SaveRoutineParams(p_routine: routine)).execute()
    var list = await cache.read([Routine].self, user: user, name: OfflineCache.routines) ?? []
    if let index = list.firstIndex(where: { $0.id == routine.id }) { list[index] = routine } else { list.append(routine) }
    await cache.write(list, user: user, name: OfflineCache.routines)
    return routine
  }

  public func deleteRoutine(id: String) async throws -> WeeklyPlan {
    let user = try requireUser()
    try await client.rpc("gym_delete_routine", params: IdParams(p_id: id)).execute()
    var list = await cache.read([Routine].self, user: user, name: OfflineCache.routines) ?? []
    list.removeAll { $0.id == id }
    await cache.write(list, user: user, name: OfflineCache.routines)
    let plan = (await cache.read(WeeklyPlan.self, user: user, name: OfflineCache.weeklyPlan) ?? WeeklyPlan()).withoutRoutine(id)
    await cache.write(plan, user: user, name: OfflineCache.weeklyPlan)
    return plan
  }

  public func setDay(weekday: Int, routineId: String?) async throws -> WeeklyPlan {
    let user = try requireUser()
    if let routineId {
      try await client.from("gym_weekly_plan").upsert(
        PlanDayWrite(userId: user, weekday: weekday, routineId: routineId, updatedAt: .now),
        onConflict: "userId,weekday"
      ).execute()
    } else {
      try await client.from("gym_weekly_plan").delete().eq("weekday", value: weekday).execute()
    }
    let days: [PlanDayRow] = try await client.from("gym_weekly_plan").select().execute().value
    var map: [Int: String] = [:]
    for day in days { map[day.weekday] = day.routineId }
    let plan = WeeklyPlan(routineIdByWeekday: map)
    await cache.write(plan, user: user, name: OfflineCache.weeklyPlan)
    return plan
  }

  // MARK: Workouts

  public func workouts() async throws -> Served<[Workout]> {
    let user = try requireUser()
    do {
      let response = try await client.from("gym_workouts")
        .select("*, gym_workout_exercises(*, gym_workout_sets(*))")
        .is("deletedAt", value: nil)
        .order("date", ascending: false)
        .execute()
      let list = try workoutsFromRows(response.data).sorted { $0.date > $1.date }
      await cache.write(list, user: user, name: OfflineCache.workouts)
      return Served(value: list)
    } catch {
      if isOfflineError(error), let cached = await cache.read([Workout].self, user: user, name: OfflineCache.workouts) {
        return Served(value: cached.sorted { $0.date > $1.date }, fromCache: true)
      }
      throw error
    }
  }

  public func saveWorkout(_ workout: Workout) async throws -> Workout {
    let user = try requireUser()
    return try await saves.run { [client, cache] in
      try await client.rpc("gym_save_workout", params: SaveWorkoutParams(p_workout: workout)).execute()
      var list = await cache.read([Workout].self, user: user, name: OfflineCache.workouts) ?? []
      if let index = list.firstIndex(where: { $0.id == workout.id }) { list[index] = workout } else { list.append(workout) }
      list.sort { $0.date > $1.date }
      await cache.write(list, user: user, name: OfflineCache.workouts)
      return workout
    }
  }

  public func deleteWorkout(id: String) async throws {
    let user = try requireUser()
    try await saves.run { [client, cache] in
      let now = GymJSON.formatTimestamp(.now)
      try await client.from("gym_workouts").update(SoftDelete(deletedAt: now, updatedAt: now)).eq("id", value: id).execute()
      var list = await cache.read([Workout].self, user: user, name: OfflineCache.workouts) ?? []
      list.removeAll { $0.id == id }
      await cache.write(list, user: user, name: OfflineCache.workouts)
    }
  }

  // MARK: Nutrition

  public func nutritionProfile() async throws -> Served<NutritionProfile?> {
    let user = try requireUser()
    do {
      let rows: [NutritionProfile] = try await client.from("gym_nutrition_profiles").select().execute().value
      await cache.write(rows, user: user, name: OfflineCache.nutritionProfile)
      return Served(value: rows.first)
    } catch {
      if isOfflineError(error),
        let cached = await cache.read([NutritionProfile].self, user: user, name: OfflineCache.nutritionProfile)
      {
        return Served(value: cached.first, fromCache: true)
      }
      throw error
    }
  }

  public func saveNutritionProfile(_ profile: NutritionProfile) async throws {
    let user = try requireUser()
    try await client.from("gym_nutrition_profiles").upsert(
      UserRow(value: profile, userId: user, updatedAt: .now), onConflict: "userId"
    ).execute()
    await cache.write([profile], user: user, name: OfflineCache.nutritionProfile)
  }

  public func foodEntries() async throws -> Served<[FoodEntry]> {
    let user = try requireUser()
    do {
      let rows: [FoodEntry] = try await client.from("gym_food_entries").select()
        .is("deletedAt", value: nil).order("date", ascending: false).execute().value
      await cache.write(rows, user: user, name: OfflineCache.foodEntries)
      return Served(value: rows)
    } catch {
      if isOfflineError(error), let cached = await cache.read([FoodEntry].self, user: user, name: OfflineCache.foodEntries) {
        return Served(value: cached, fromCache: true)
      }
      throw error
    }
  }

  public func saveFoodEntry(_ entry: FoodEntry) async throws {
    let user = try requireUser()
    try await client.from("gym_food_entries").upsert(
      UserRow(value: entry, userId: user, updatedAt: .now, clearsDeletedAt: true)
    ).execute()
    var list = await cache.read([FoodEntry].self, user: user, name: OfflineCache.foodEntries) ?? []
    if let index = list.firstIndex(where: { $0.id == entry.id }) { list[index] = entry } else { list.append(entry) }
    await cache.write(list, user: user, name: OfflineCache.foodEntries)
  }

  public func deleteFoodEntry(id: String) async throws {
    let user = try requireUser()
    let now = GymJSON.formatTimestamp(.now)
    try await client.from("gym_food_entries").update(SoftDelete(deletedAt: now, updatedAt: now)).eq("id", value: id)
      .execute()
    var list = await cache.read([FoodEntry].self, user: user, name: OfflineCache.foodEntries) ?? []
    list.removeAll { $0.id == id }
    await cache.write(list, user: user, name: OfflineCache.foodEntries)
  }

  // MARK: Sleep

  public func sleepEntries() async throws -> Served<[SleepEntry]> {
    let user = try requireUser()
    do {
      let rows: [SleepEntry] = try await client.from("gym_sleep_entries").select()
        .is("deletedAt", value: nil).order("endAt", ascending: false).execute().value
      await cache.write(rows, user: user, name: OfflineCache.sleepEntries)
      return Served(value: rows)
    } catch {
      if isOfflineError(error), let cached = await cache.read([SleepEntry].self, user: user, name: OfflineCache.sleepEntries) {
        return Served(value: cached, fromCache: true)
      }
      throw error
    }
  }

  public func saveSleepEntry(_ entry: SleepEntry) async throws {
    let user = try requireUser()
    try await client.from("gym_sleep_entries").upsert(SleepWrite(entry: entry, userId: user)).execute()
    var list = await cache.read([SleepEntry].self, user: user, name: OfflineCache.sleepEntries) ?? []
    if let index = list.firstIndex(where: { $0.id == entry.id }) { list[index] = entry } else { list.append(entry) }
    await cache.write(list, user: user, name: OfflineCache.sleepEntries)
  }

  public func deleteSleepEntry(id: String) async throws {
    let user = try requireUser()
    let now = GymJSON.formatTimestamp(.now)
    try await client.from("gym_sleep_entries").update(SoftDelete(deletedAt: now, updatedAt: now)).eq("id", value: id)
      .execute()
    var list = await cache.read([SleepEntry].self, user: user, name: OfflineCache.sleepEntries) ?? []
    list.removeAll { $0.id == id }
    await cache.write(list, user: user, name: OfflineCache.sleepEntries)
  }

  // MARK: Legacy device-only data

  public func hasLegacyData() async -> Bool {
    guard let userId else { return false }
    for name in Self.legacyFiles {
      if await cache.legacyFileExists(user: userId, name: name) { return true }
    }
    return false
  }

  /// Uploads `exercises.json`, `routines.json`, `weekly_plan.json`, `workouts.json`
  /// left by the device-only first version. A failed run is retried next launch.
  public func migrateLegacyIfNeeded() async throws -> Bool {
    guard await hasLegacyData(), let user = userId else { return false }
    GymLog.debug("uploading on-device data")
    let exerciseRows = await legacyList(user: user, name: "exercises")
    var exercises: [Exercise] = []
    for row in exerciseRows {
      var exercise = try decodeObject(Exercise.self, row)
      var paths: [String] = []
      for name in exercise.imagePaths {
        if name.contains("/") {
          paths.append(name)
          continue
        }
        let local = await cache.imagesDirectory(user).appendingPathComponent((name as NSString).lastPathComponent)
        guard FileManager.default.fileExists(atPath: local.path), let data = try? Data(contentsOf: local) else { continue }
        let ext = local.pathExtension.isEmpty ? "jpg" : local.pathExtension
        let path = "\(user)/\((name as NSString).lastPathComponent)"
        try await client.storage.from(Self.imageBucket).upload(
          path, data: data, options: FileOptions(contentType: contentType(ext), upsert: true))
        paths.append(path)
      }
      exercise.imagePaths = paths
      _ = try await saveExercise(exercise)
      exercises.append(exercise)
    }
    let exerciseIds = Set(exercises.map(\.id))

    let routineRows = await legacyList(user: user, name: "routines")
    var routines: [Routine] = []
    for row in routineRows {
      var routine = try decodeObject(Routine.self, row)
      routine.exercises = routine.exercises.filter { exerciseIds.contains($0.exerciseId) }
      if routine.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { routine.title = "—" }
      _ = try await saveRoutine(routine)
      routines.append(routine)
    }
    let routineIds = Set(routines.map(\.id))
    if let raw = await legacyObject(user: user, name: "weekly_plan"),
      let plan = try? decodeObject(WeeklyPlan.self, raw)
    {
      for (day, routineId) in plan.routineIdByWeekday where routineIds.contains(routineId) {
        _ = try await setDay(weekday: day, routineId: routineId)
      }
    }

    for row in await legacyList(user: user, name: "workouts") {
      var workout = try decodeObject(Workout.self, row)
      if let routineId = workout.routineId, !routineIds.contains(routineId) { workout.routineId = nil }
      workout.exercises = workout.exercises.filter { exerciseIds.contains($0.exerciseId) }
      _ = try await saveWorkout(workout)
    }

    for name in Self.legacyFiles {
      await cache.markMigrated(user: user, name: name)
    }
    return true
  }

  private func legacyList(user: String, name: String) async -> [[String: Any]] {
    guard let raw = await legacyObject(user: user, name: name) else { return [] }
    if let list = raw as? [[String: Any]] { return list }
    if let list = raw as? [Any] { return list.compactMap { $0 as? [String: Any] } }
    return []
  }

  private func legacyObject(user: String, name: String) async -> Any? {
    guard let data = await cache.readLegacyData(user: user, name: name) else { return nil }
    let object = try? JSONSerialization.jsonObject(with: data)
    if let wrapped = object as? [String: Any], wrapped["data"] != nil { return wrapped["data"] }
    return object
  }
}

// MARK: - Rows

private struct ExerciseWrite: Encodable {
  var id: String
  var name: String
  var primaryMuscles: [String]
  var secondaryMuscles: [String]
  var equipment: String
  var loadType: String
  var notes: String?
  var imagePaths: [String]
  var createdAt: Date
  var updatedAt: Date
  var userId: String
  var deletedAt: String?

  init(exercise: Exercise, userId: String) {
    id = exercise.id
    name = exercise.name
    primaryMuscles = exercise.primaryMuscles.map(\.rawValue)
    secondaryMuscles = exercise.secondaryMuscles.map(\.rawValue)
    equipment = exercise.equipment.rawValue
    loadType = exercise.loadType.rawValue
    notes = exercise.notes
    imagePaths = exercise.imagePaths
    createdAt = exercise.createdAt
    updatedAt = exercise.updatedAt
    self.userId = userId
    deletedAt = nil
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id, forKey: .id)
    try c.encode(name, forKey: .name)
    try c.encode(primaryMuscles, forKey: .primaryMuscles)
    try c.encode(secondaryMuscles, forKey: .secondaryMuscles)
    try c.encode(equipment, forKey: .equipment)
    try c.encode(loadType, forKey: .loadType)
    try c.encodeNullIfNil(notes, forKey: .notes)
    try c.encode(imagePaths, forKey: .imagePaths)
    try c.encode(createdAt, forKey: .createdAt)
    try c.encode(updatedAt, forKey: .updatedAt)
    try c.encode(userId, forKey: .userId)
    try c.encodeNil(forKey: .deletedAt)
  }

  enum CodingKeys: String, CodingKey {
    case id, name, primaryMuscles, secondaryMuscles, equipment, loadType, notes
    case imagePaths, createdAt, updatedAt, userId, deletedAt
  }
}

private struct SoftDelete: Encodable {
  var deletedAt: String
  var updatedAt: String
}

/// A value written together with the owner id and timestamps (and, for soft-deleted tables, a cleared `deletedAt`).
private struct UserRow<Value: Encodable>: Encodable {
  var value: Value
  var userId: String
  var updatedAt: Date
  var clearsDeletedAt = false

  private struct Key: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(_ name: String) { stringValue = name }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
  }

  func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
    var c = encoder.container(keyedBy: Key.self)
    try c.encode(userId, forKey: Key("userId"))
    try c.encode(updatedAt, forKey: Key("updatedAt"))
    if clearsDeletedAt { try c.encodeNil(forKey: Key("deletedAt")) }
  }
}

/// Explicit nulls so turning a night into a nap clears the night-only columns.
private struct SleepWrite: Encodable {
  var entry: SleepEntry
  var userId: String

  enum CodingKeys: String, CodingKey {
    case id, userId, startAt, endAt, isNap, deepPercent, remPercent, awakenings, awakeMinutes
    case updatedAt, deletedAt
  }

  init(entry: SleepEntry, userId: String) {
    self.entry = entry
    self.userId = userId
  }

  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(entry.id, forKey: .id)
    try c.encode(userId, forKey: .userId)
    try c.encode(entry.start, forKey: .startAt)
    try c.encode(entry.end, forKey: .endAt)
    try c.encode(entry.isNap, forKey: .isNap)
    try c.encodeNullIfNil(entry.deepPercent, forKey: .deepPercent)
    try c.encodeNullIfNil(entry.remPercent, forKey: .remPercent)
    if let awakenings = entry.awakenings { try c.encode(awakenings, forKey: .awakenings) } else { try c.encodeNil(forKey: .awakenings) }
    if let minutes = entry.awakeMinutes { try c.encode(minutes, forKey: .awakeMinutes) } else { try c.encodeNil(forKey: .awakeMinutes) }
    try c.encode(Date.now, forKey: .updatedAt)
    try c.encodeNil(forKey: .deletedAt)
  }
}

private struct PlanDayRow: Decodable {
  var weekday: Int
  var routineId: String
}

private struct PlanDayWrite: Encodable {
  var userId: String
  var weekday: Int
  var routineId: String
  var updatedAt: Date
}

private struct SaveRoutineParams: Encodable {
  var p_routine: Routine
}

private struct SaveWorkoutParams: Encodable {
  var p_workout: Workout
}

private struct IdParams: Encodable {
  var p_id: String
}

private func contentType(_ ext: String) -> String {
  switch ext.lowercased() {
  case "png": "image/png"
  case "webp": "image/webp"
  case "heic", "heif": "image/heic"
  default: "image/jpeg"
  }
}

private func routinesFromRows(_ data: Data) throws -> [Routine] {
  let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
  return try rows.map { row in
    var copy = row
    let children = (row["gym_routine_exercises"] as? [[String: Any]] ?? []).sorted {
      jsonInt($0["position"]) < jsonInt($1["position"])
    }
    copy["exercises"] = children
    return try decodeObject(Routine.self, copy)
  }
}

private func workoutsFromRows(_ data: Data) throws -> [Workout] {
  let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
  return try rows.map { row in
    var copy = row
    let exercises = (row["gym_workout_exercises"] as? [[String: Any]] ?? []).sorted {
      jsonInt($0["position"]) < jsonInt($1["position"])
    }
    copy["exercises"] = exercises.map { entry -> [String: Any] in
      var exercise = entry
      let sets = (entry["gym_workout_sets"] as? [[String: Any]] ?? []).sorted {
        jsonInt($0["position"]) < jsonInt($1["position"])
      }
      exercise["sets"] = sets
      if entry["plannedSets"] == nil || entry["plannedSets"] is NSNull {
        exercise["planned"] = NSNull()
      } else {
        exercise["planned"] = [
          "sets": entry["plannedSets"] ?? NSNull(),
          "reps": entry["plannedReps"] ?? NSNull(),
          "load": entry["plannedLoad"] ?? NSNull(),
        ]
      }
      return exercise
    }
    return try decodeObject(Workout.self, copy)
  }
}

private func jsonInt(_ value: Any?) -> Int {
  if let number = value as? NSNumber { return number.intValue }
  if let string = value as? String, let int = Int(string) { return int }
  return 0
}

private func decodeObject<T: Decodable>(_ type: T.Type, _ object: Any) throws -> T {
  let data = try JSONSerialization.data(withJSONObject: object)
  return try GymJSON.decode(type, from: data)
}
