import GymCore
import PhotosUI
import SwiftUI
import UIKit

struct ExerciseEditorView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var exerciseId: String?

  @State private var name = ""
  @State private var notes = ""
  @State private var equipment: Equipment = .dumbbell
  @State private var loadType: LoadType = .weight
  @State private var loadTouched = false
  @State private var primary: Set<MuscleGroup> = []
  @State private var secondary: Set<MuscleGroup> = []
  @State private var imagePaths: [String] = []
  @State private var createdAt = Date.now
  @State private var pickerItem: PhotosPickerItem?
  @State private var showCamera = false
  @State private var error: String?
  @State private var uploads = 0

  private var isUploading: Bool { uploads > 0 }

  var body: some View {
    Form {
      Section {
        TextField(L("exerciseNameLabel"), text: $name, prompt: Text(L("exerciseNameHint")))
        TextField(L("exerciseNotesLabel"), text: $notes, prompt: Text(L("exerciseNotesHint")), axis: .vertical)
      }
      Section {
        Picker(L("equipment"), selection: $equipment) {
          ForEach(Equipment.allCases, id: \.self) { item in
            Text(equipmentLabel(item)).tag(item)
          }
        }
        .onChange(of: equipment) { _, newValue in
          if !loadTouched { loadType = LoadType.defaultFor(newValue) }
        }
        Picker(L("loadTypeLabel"), selection: $loadType) {
          Text(L("loadTypeWeight")).tag(LoadType.weight)
          Text(L("loadTypeDiscs")).tag(LoadType.discs)
        }
        .onChange(of: loadType) { _, _ in loadTouched = true }
        Text(loadType == .discs ? L("loadTypeDiscsHint") : L("loadTypeWeightHint"))
          .font(.footnote).foregroundStyle(.secondary)
      }
      muscleSection(L("primaryMuscles"), hint: L("primaryMusclesHint"), selection: $primary)
      muscleSection(L("secondaryMuscles"), hint: L("secondaryMusclesHint"), selection: $secondary)
      Section(L("referenceImages")) {
        ExercisePhotos(paths: imagePaths, uploading: isUploading)
        PhotosPicker(selection: $pickerItem, matching: .images) {
          Label(L("gallery"), systemImage: "photo")
        }
        .disabled(isUploading)
        Button(L("camera"), systemImage: "camera") { showCamera = true }
          .disabled(isUploading)
        if let error { Text(error).foregroundStyle(.red).font(.footnote) }
      }
    }
    .navigationTitle(exerciseId == nil ? L("newExercise") : L("editExercise"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
      ToolbarItem(placement: .confirmationAction) {
        Button(L("save")) { Task { await save() } }
          .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || primary.isEmpty || isUploading)
      }
    }
    .onAppear(perform: load)
    .onChange(of: pickerItem) { _, item in
      guard let item else { return }
      Task { await importPhoto(item) }
    }
    .sheet(isPresented: $showCamera) {
      CameraPicker { data in Task { await importData(data, ext: "jpg") } }
    }
  }

  private func muscleSection(_ title: String, hint: String, selection: Binding<Set<MuscleGroup>>) -> some View {
    Section {
      Text(hint).font(.footnote).foregroundStyle(.secondary)
      ForEach(MuscleGroup.allCases, id: \.self) { muscle in
        Button {
          if selection.wrappedValue.contains(muscle) {
            selection.wrappedValue.remove(muscle)
          } else {
            selection.wrappedValue.insert(muscle)
          }
        } label: {
          HStack {
            Text(muscleLabel(muscle))
            Spacer()
            if selection.wrappedValue.contains(muscle) { Image(systemName: "checkmark") }
          }
        }
        .buttonStyle(.plain)
      }
    } header: {
      Text(title)
    }
  }

  private func load() {
    guard let exerciseId, let exercise = model.exercise(exerciseId) else { return }
    name = exercise.name
    notes = exercise.notes ?? ""
    equipment = exercise.equipment
    loadType = exercise.loadType
    loadTouched = true
    primary = Set(exercise.primaryMuscles)
    secondary = Set(exercise.secondaryMuscles)
    imagePaths = exercise.imagePaths
    createdAt = exercise.createdAt
  }

  private func importPhoto(_ item: PhotosPickerItem) async {
    defer { pickerItem = nil }
    uploads += 1
    defer { uploads -= 1 }
    guard let data = try? await item.loadTransferable(type: Data.self) else {
      error = L("imageImportFailed")
      return
    }
    await importData(data, ext: "jpg")
  }

  private func importData(_ data: Data, ext: String) async {
    guard let repo = model.repo else { return }
    uploads += 1
    defer { uploads -= 1 }
    do {
      let path = try await repo.importImage(data: data, fileExtension: ext)
      imagePaths.append(path)
      error = nil
    } catch {
      self.error = L("imageImportFailed")
    }
  }

  private func save() async {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, !primary.isEmpty else { return }
    let exercise = Exercise(
      id: exerciseId ?? UUID().uuidString.lowercased(),
      name: trimmed,
      primaryMuscles: MuscleGroup.allCases.filter { primary.contains($0) },
      secondaryMuscles: MuscleGroup.allCases.filter { secondary.contains($0) },
      equipment: equipment,
      loadType: loadType,
      notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
      imagePaths: imagePaths,
      createdAt: exerciseId == nil ? .now : createdAt,
      updatedAt: .now
    )
    if await model.saveExercise(exercise) { dismiss() }
  }
}

private extension String {
  var nilIfEmpty: String? { isEmpty ? nil : self }
}

struct CameraPicker: UIViewControllerRepresentable {
  var onImage: (Data) -> Void
  @Environment(\.dismiss) private var dismiss

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator(self) }

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let parent: CameraPicker
    init(_ parent: CameraPicker) { self.parent = parent }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.85) {
        parent.onImage(data)
      }
      parent.dismiss()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
  }
}
