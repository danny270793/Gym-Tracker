import Foundation
import GymCore
import GymData
import Testing

@Test func cacheRoundTripsExercisesAndKeepsEnvelope() async throws {
  let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
  let cache = OfflineCache(root: root)
  let exercise = Exercise(
    id: "x", name: "Press", primaryMuscles: [.chest], equipment: .dumbbell, createdAt: date(2026, 1, 1),
    updatedAt: date(2026, 1, 2))
  await cache.write([exercise], user: "user", name: OfflineCache.exercises)
  let loaded = await cache.read([Exercise].self, user: "user", name: OfflineCache.exercises)
  #expect(loaded == [exercise])

  let url = root.appendingPathComponent("users/user/cache_exercises.json")
  let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
  #expect(raw?["version"] as? Int == 1)

  let plan = WeeklyPlan(routineIdByWeekday: [1: "push"])
  await cache.write(plan, user: "user", name: OfflineCache.weeklyPlan)
  #expect(await cache.read(WeeklyPlan.self, user: "user", name: OfflineCache.weeklyPlan) == plan)

  await cache.clearCache(user: "user")
  #expect(await cache.read([Exercise].self, user: "user", name: OfflineCache.exercises) == nil)
  try? FileManager.default.removeItem(at: root)
}
