import GymCore
import SwiftUI

private struct ExerciseRoute: Hashable, Identifiable { let id: String }

struct WorkoutSessionView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs
  @Environment(\.dismiss) private var dismiss
  let workoutId: String

  @State private var workout: Workout?
  @State private var dirty = false
  @State private var saving = false
  @State private var detail: ExerciseRoute?
  @State private var showAdd = false
  @State private var showFinish = false
  @State private var showRename = false
  @State private var titleDraft = ""
  @State private var removed: (index: Int, row: WorkoutExercise)?

  var body: some View {
    Group {
      if let workout {
        session(workout)
      } else {
        ContentUnavailableView(L("loadError"), systemImage: "questionmark")
      }
    }
    .navigationTitle(workout?.title ?? "")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        Button(workout?.title ?? "") { beginRename() }.font(.headline).lineLimit(1)
      }
      ToolbarItem(placement: .primaryAction) {
        Button(L("save")) { Task { await save() } }
          .disabled(!dirty || saving)
      }
      ToolbarItem(placement: .primaryAction) {
        Menu {
          if workout?.isFinished == true {
            Button(L("reopenWorkout")) { reopen() }
          } else {
            Button(L("finishWorkout")) { showFinish = true }
          }
          Button(L("delete"), role: .destructive) { Task { await deleteWorkout() } }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
    .sheet(isPresented: $showAdd) {
      ExercisePicker { id in addExercise(id) }
    }
    .alert(L("workoutTitleLabel"), isPresented: $showRename) {
      TextField(L("workoutTitleLabel"), text: $titleDraft)
      Button(L("save")) { applyTitle() }
      Button(L("cancel"), role: .cancel) {}
    }
    .confirmationDialog(L("finishWorkoutTitle"), isPresented: $showFinish, titleVisibility: .visible) {
      finishActions
    }
    .navigationDestination(item: $detail) { ExerciseDetailView(exerciseId: $0.id) }
    .onAppear { loadWorkout() }
  }

  /// Prefers the on-device draft, which holds edits that were never saved to Supabase.
  private func loadWorkout() {
    guard workout == nil else { return }
    if let draft = WorkoutDraftStore.load(workoutId) {
      workout = draft
      dirty = true
    } else {
      workout = model.workout(workoutId)
    }
  }

  @ViewBuilder
  private var finishActions: some View {
    Button(L("finish")) { finish() }
    Button(L("cancel"), role: .cancel) {}
  }

  private func session(_ workout: Workout) -> some View {
    List {
      Section {
        DatePicker(L("changeDate"), selection: dateBinding, displayedComponents: .date)
        if workout.isFinished {
          Text(L("finished")).foregroundStyle(.secondary)
        }
      }
      // Press and hold an exercise and drag it to another spot to reorder.
      ForEach(workout.exercises) { row in
        exerciseSection(row)
      }
      .onMove { moveExercises(from: $0, to: $1) }
      Section {
        Button(L("addExercise"), systemImage: "plus") { showAdd = true }
      }
      if let removed {
        Section {
          Button(L("undo")) { undo(removed) }
            .buttonStyle(.bordered)
        } header: {
          Text(L("exerciseRemoved"))
        }
      }
    }
  }

  private func exerciseSection(_ row: WorkoutExercise) -> some View {
    let exercise = model.exercise(row.exerciseId)
    let load = LoadText(type: exercise?.loadType ?? .weight, unit: prefs.weightUnit)
    return Section {
      if !row.sets.isEmpty {
        ColumnLabels(leading: [L("reps")], discs: load.isDiscs, reservesRemoveButton: true)
      }
      ForEach(Array(row.sets.enumerated()), id: \.offset) { setIndex, set in
        setRow(row: row, index: setIndex, set: set, discs: load.isDiscs)
      }
      Button(L("addSet"), systemImage: "plus") { addSet(row) }
    } header: {
      HStack {
        Text(exercise?.name ?? L("deletedExercise"))
        Spacer()
        Button(L("seeMore")) { detail = ExerciseRoute(id: row.exerciseId) }
          .font(.footnote)
          .textCase(nil)
        Menu {
          Button(L("removeExercise"), systemImage: "trash", role: .destructive) { remove(row) }
        } label: {
          Image(systemName: "ellipsis").frame(width: 32, height: 32)
        }
        .textCase(nil)
      }
    }
  }

  private func setRow(row: WorkoutExercise, index: Int, set: WorkoutSet, discs: Bool) -> some View {
    HStack(spacing: 10) {
      IntField(placeholder: L("reps"), value: setBinding(row, index, \.reps))
      LoadEditor(pounds: setBinding(row, index, \.load), discs: discs, unit: prefs.weightUnit)
      Button(role: .destructive) {
        removeSet(row, index)
      } label: {
        Image(systemName: "minus.circle")
      }
      .buttonStyle(.plain)
    }
  }

  private func setBinding(_ row: WorkoutExercise, _ index: Int, _ keyPath: WritableKeyPath<WorkoutSet, Int>) -> Binding<Int> {
    Binding(
      get: { workout?.exercises.first { $0.id == row.id }?.sets[safe: index]?[keyPath: keyPath] ?? 0 },
      set: { newValue in updateSet(row, index) { $0[keyPath: keyPath] = newValue } }
    )
  }

  private func setBinding(_ row: WorkoutExercise, _ index: Int, _ keyPath: WritableKeyPath<WorkoutSet, Double>) -> Binding<Double> {
    Binding(
      get: { workout?.exercises.first { $0.id == row.id }?.sets[safe: index]?[keyPath: keyPath] ?? 0 },
      set: { newValue in updateSet(row, index) { $0[keyPath: keyPath] = newValue } }
    )
  }

  private func mutate(_ body: (inout Workout) -> Void) {
    guard var current = workout else { return }
    body(&current)
    current.updatedAt = .now
    workout = current
    dirty = true
    WorkoutDraftStore.save(current)
  }

  private func updateSet(_ row: WorkoutExercise, _ index: Int, _ body: (inout WorkoutSet) -> Void) {
    mutate { workout in
      guard let entry = workout.exercises.firstIndex(where: { $0.id == row.id }),
        workout.exercises[entry].sets.indices.contains(index)
      else { return }
      body(&workout.exercises[entry].sets[index])
    }
  }

  private func addSet(_ row: WorkoutExercise) {
    mutate { workout in
      guard let entry = workout.exercises.firstIndex(where: { $0.id == row.id }) else { return }
      let previous = workout.exercises[entry].sets.last ?? WorkoutSet(reps: 8)
      workout.exercises[entry].sets.append(WorkoutSet(reps: previous.reps, load: previous.load))
    }
  }

  private func removeSet(_ row: WorkoutExercise, _ index: Int) {
    mutate { workout in
      guard let entry = workout.exercises.firstIndex(where: { $0.id == row.id }) else { return }
      guard workout.exercises[entry].sets.indices.contains(index) else { return }
      workout.exercises[entry].sets.remove(at: index)
    }
  }

  private func moveExercises(from source: IndexSet, to destination: Int) {
    mutate { workout in
      workout.exercises.move(fromOffsets: source, toOffset: destination)
    }
  }

  private func remove(_ row: WorkoutExercise) {
    mutate { workout in
      guard let index = workout.exercises.firstIndex(where: { $0.id == row.id }) else { return }
      removed = (index, workout.exercises.remove(at: index))
    }
  }

  private func undo(_ item: (index: Int, row: WorkoutExercise)) {
    mutate { workout in
      let index = min(item.index, workout.exercises.count)
      workout.exercises.insert(item.row, at: index)
    }
    removed = nil
  }

  private var dateBinding: Binding<Date> {
    Binding(
      get: { workout?.date ?? .now },
      set: { newDate in
        mutate { current in
          let calendar = Calendar.current
          let time = calendar.dateComponents([.hour, .minute], from: current.date)
          var parts = calendar.dateComponents([.year, .month, .day], from: newDate)
          parts.hour = time.hour
          parts.minute = time.minute
          current.date = calendar.date(from: parts) ?? newDate
        }
      }
    )
  }

  private func addExercise(_ id: String) {
    let row = BuildWorkout().adHocEntry(id, model.workouts.filter { $0.id != workoutId })
    mutate { $0.exercises.append(row) }
  }

  private func beginRename() {
    titleDraft = workout?.title ?? ""
    showRename = true
  }

  private func applyTitle() {
    let title = titleDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !title.isEmpty else { return }
    mutate { $0.title = title }
  }

  private func finish() {
    mutate { workout in
      workout.finishedAt = .now
    }
    Task { await save() }
  }

  private func reopen() {
    mutate { $0.finishedAt = nil }
  }

  private func deleteWorkout() async {
    if await model.deleteWorkout(id: workoutId) {
      WorkoutDraftStore.clear(workoutId)
      dismiss()
    }
  }

  /// The only place a session reaches Supabase. The local draft is cleared once the upload succeeds.
  private func save() async {
    guard let workout, !saving else { return }
    saving = true
    defer { saving = false }
    guard await model.saveWorkout(workout) else { return }
    await model.raisePlanLoads(from: workout)
    WorkoutDraftStore.clear(workoutId)
    dirty = false
    dismiss()
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
