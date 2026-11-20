import GymCore
import SwiftUI

struct RoutineEditorView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs
  @Environment(\.dismiss) private var dismiss

  var routineId: String?
  var assignWeekday: Int?

  @State private var title = ""
  @State private var notes = ""
  @State private var lines: [PlannedExercise] = []
  @State private var createdAt = Date.now
  @State private var showPicker = false
  @State private var confirmDelete = false

  var body: some View {
    Form {
      Section {
        TextField(L("routineTitleLabel"), text: $title, prompt: Text(L("routineTitleHint")))
        TextField(L("notes"), text: $notes, axis: .vertical)
      }
      if lines.isEmpty {
        Section(L("exercisesInRoutine")) {
          Text(L("routineNoExercisesHint")).foregroundStyle(.secondary)
        }
      }
      // Press and hold an exercise and drag it to reorder, as in a workout.
      ForEach(lines.indices, id: \.self) { index in
        lineSection(index)
      }
      .onMove { lines.move(fromOffsets: $0, toOffset: $1) }
      Section {
        Button(L("addExercise"), systemImage: "plus") { showPicker = true }
      }
      if routineId != nil {
        Section {
          Button(L("delete"), role: .destructive) { confirmDelete = true }
        }
      }
    }
    .navigationTitle(routineId == nil ? L("newRoutine") : L("editRoutine"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(L("save")) { Task { await save() } }.disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
    .sheet(isPresented: $showPicker) {
      ExercisePicker { id in lines.append(PlannedExercise(exerciseId: id)) }
    }
    .confirmationDialog(L("deleteRoutineTitle"), isPresented: $confirmDelete, titleVisibility: .visible) {
      Button(L("delete"), role: .destructive) { Task { await remove() } }
      Button(L("cancel"), role: .cancel) {}
    } message: {
      Text(L("deleteRoutineMessage", title))
    }
    .onAppear(perform: load)
  }

  private func lineSection(_ index: Int) -> some View {
    let exercise = model.exercise(lines[index].exerciseId)
    let discs = exercise?.loadType == .discs
    return Section {
      ColumnLabels(leading: [L("sets"), L("reps")], discs: discs)
      HStack(spacing: 10) {
        IntField(placeholder: L("sets"), value: clamped($lines[index].sets, 1...20))
        IntField(placeholder: L("reps"), value: clamped($lines[index].reps, 1...100))
        LoadEditor(
          pounds: Binding(
            get: { lines[index].load ?? 0 },
            set: { lines[index].load = $0 <= 0 ? nil : $0 }
          ),
          discs: discs,
          unit: prefs.weightUnit
        )
      }
    } header: {
      HStack {
        Text(exercise?.name ?? L("deletedExercise"))
        Spacer()
        Menu {
          Button(L("removeExercise"), systemImage: "trash", role: .destructive) { lines.remove(at: index) }
        } label: {
          Image(systemName: "ellipsis").frame(width: 32, height: 32)
        }
        .textCase(nil)
      }
    }
  }

  private func clamped(_ value: Binding<Int>, _ range: ClosedRange<Int>) -> Binding<Int> {
    Binding(
      get: { value.wrappedValue },
      set: { value.wrappedValue = min(max($0, range.lowerBound), range.upperBound) }
    )
  }

  private func load() {
    guard let routineId, let routine = model.routine(routineId) else { return }
    title = routine.title
    notes = routine.notes ?? ""
    lines = routine.exercises
    createdAt = routine.createdAt
  }

  private func save() async {
    let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    let routine = Routine(
      id: routineId ?? UUID().uuidString.lowercased(),
      title: trimmed,
      notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
      exercises: lines,
      createdAt: routineId == nil ? .now : createdAt,
      updatedAt: .now
    )
    guard await model.saveRoutine(routine) else { return }
    if routineId == nil, let assignWeekday {
      await model.setDay(weekday: assignWeekday, routineId: routine.id)
    }
    dismiss()
  }

  private func remove() async {
    guard let routineId else { return }
    if await model.deleteRoutine(id: routineId) { dismiss() }
  }
}

private extension String {
  var nilIfEmpty: String? { isEmpty ? nil : self }
}
