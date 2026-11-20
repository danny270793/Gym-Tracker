import Foundation
import GymCore

/// On-device copy of a workout being edited. Edits land here immediately so nothing is lost;
/// Supabase only receives the workout when the user taps Save.
enum WorkoutDraftStore {
  private static func key(_ id: String) -> String { "workoutDraft.\(id)" }

  static func load(_ id: String) -> Workout? {
    guard let data = UserDefaults.standard.data(forKey: key(id)) else { return nil }
    return try? GymJSON.decode(Workout.self, from: data)
  }

  static func save(_ workout: Workout) {
    guard let data = try? GymJSON.encode(workout) else { return }
    UserDefaults.standard.set(data, forKey: key(workout.id))
  }

  static func clear(_ id: String) {
    UserDefaults.standard.removeObject(forKey: key(id))
  }
}
