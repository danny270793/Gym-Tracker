import Foundation
import GymCore
import GymData

/// The sleep log, stored in Supabase (`gym_sleep_entries`) with an offline read copy.
/// Writes need a connection.
@MainActor @Observable
final class SleepStore {
  private(set) var entries: [SleepEntry] = []
  private(set) var fromCache = false
  private var userId: String?

  func load(model: AppModel) async {
    guard let repo = model.repo, let user = repo.userId else { return }
    if user != userId {
      userId = user
      entries = []
    }
    do {
      let served = try await repo.sleepEntries()
      entries = served.value
      fromCache = served.fromCache
    } catch {
      GymLog.error("load sleep", error)
    }
  }

  @discardableResult
  func save(_ entry: SleepEntry, model: AppModel) async -> Bool {
    guard let repo = model.repo else { return false }
    do {
      try await repo.saveSleepEntry(entry)
      if let index = entries.firstIndex(where: { $0.id == entry.id }) { entries[index] = entry } else { entries.append(entry) }
      return true
    } catch {
      GymLog.error("save sleep entry", error)
      model.actionError = L("saveFailed")
      return false
    }
  }

  @discardableResult
  func delete(_ entry: SleepEntry, model: AppModel) async -> Bool {
    guard let repo = model.repo else { return false }
    do {
      try await repo.deleteSleepEntry(id: entry.id)
      entries.removeAll { $0.id == entry.id }
      return true
    } catch {
      GymLog.error("delete sleep entry", error)
      model.actionError = L("saveFailed")
      return false
    }
  }
}
