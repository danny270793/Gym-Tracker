import Foundation
import GymCore
import GymData

/// Daily protein goal inputs and the food log, stored in Supabase (`gym_nutrition_profiles`,
/// `gym_food_entries`) with an offline read copy. Writes need a connection.
@MainActor @Observable
final class NutritionStore {
  private(set) var profile: NutritionProfile?
  private(set) var entries: [FoodEntry] = []
  private(set) var fromCache = false
  private var userId: String?

  var targets: NutritionTargets? { profile.map(NutritionCalculator.targets(for:)) }

  func entries(on day: Date) -> [FoodEntry] { GymCore.entries(entries, on: day) }

  func load(model: AppModel) async {
    guard let repo = model.repo, let user = repo.userId else { return }
    if user != userId {
      userId = user
      profile = nil
      entries = []
    }
    do {
      async let profileResult = repo.nutritionProfile()
      async let entriesResult = repo.foodEntries()
      let (served, list) = try await (profileResult, entriesResult)
      profile = served.value
      entries = list.value
      fromCache = served.fromCache || list.fromCache
    } catch {
      GymLog.error("load nutrition", error)
    }
  }

  @discardableResult
  func saveProfile(_ profile: NutritionProfile, model: AppModel) async -> Bool {
    guard let repo = model.repo else { return false }
    do {
      try await repo.saveNutritionProfile(profile)
      self.profile = profile
      return true
    } catch {
      GymLog.error("save nutrition profile", error)
      model.actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func save(_ entry: FoodEntry, model: AppModel) async -> Bool {
    guard let repo = model.repo else { return false }
    do {
      try await repo.saveFoodEntry(entry)
      if let index = entries.firstIndex(where: { $0.id == entry.id }) { entries[index] = entry } else { entries.append(entry) }
      return true
    } catch {
      GymLog.error("save food entry", error)
      model.actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func delete(_ entry: FoodEntry, model: AppModel) async -> Bool {
    guard let repo = model.repo else { return false }
    do {
      try await repo.deleteFoodEntry(id: entry.id)
      entries.removeAll { $0.id == entry.id }
      return true
    } catch {
      GymLog.error("delete food entry", error)
      model.actionError = L("saveFailed")
      return false
    }
  }
}
