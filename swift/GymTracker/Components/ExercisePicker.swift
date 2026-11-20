import GymCore
import SwiftUI

/// Searchable list of exercises, shown as a sheet. Picks one and dismisses itself.
struct ExercisePicker: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""
  var onPick: (String) -> Void

  var body: some View {
    NavigationStack {
      List(filtered) { exercise in
        Button(exercise.name) {
          onPick(exercise.id)
          dismiss()
        }
        .foregroundStyle(.primary)
      }
      .searchable(text: $query, prompt: L("searchExercises"))
      .overlay {
        if filtered.isEmpty { ContentUnavailableView(L("noResults"), systemImage: "magnifyingglass") }
      }
      .navigationTitle(L("pickExerciseTitle"))
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } } }
    }
  }

  private var filtered: [Exercise] {
    let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return model.exercises }
    return model.exercises.filter { $0.name.localizedCaseInsensitiveContains(text) }
  }
}
