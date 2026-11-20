import GymCore
import SwiftUI
import UIKit

struct ExercisesView: View {
  @Environment(AppModel.self) private var model
  @State private var query = ""
  @State private var showEditor = false

  var body: some View {
    Group {
      if model.loading && !model.loaded {
        ProgressView()
      } else if model.exercises.isEmpty {
        ContentUnavailableView {
          Label(L("exercisesEmptyTitle"), systemImage: "dumbbell")
        } description: {
          Text(L("exercisesEmptyBody"))
        } actions: {
          Button(L("newExercise")) { showEditor = true }.buttonStyle(.borderedProminent)
        }
      } else {
        list
      }
    }
    .navigationTitle(L("navExercises"))
    .searchable(text: $query, prompt: L("searchExercises"))
    .toolbar {
      SettingsToolbar()
      ToolbarItem(placement: .primaryAction) {
        Button(L("newExercise"), systemImage: "plus") { showEditor = true }
      }
    }
    .navigationDestination(for: String.self) { id in
      ExerciseDetailView(exerciseId: id)
    }
    .sheet(isPresented: $showEditor) {
      NavigationStack { ExerciseEditorView(exerciseId: nil) }
    }
    .refreshable { await model.reload() }
  }

  private var list: some View {
    List(filtered) { exercise in
      NavigationLink(value: exercise.id) {
        VStack(alignment: .leading, spacing: 2) {
          Text(exercise.name)
          Text(subtitle(exercise)).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
        }
      }
    }
  }

  private var filtered: [Exercise] {
    let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return model.exercises }
    return model.exercises.filter { $0.name.localizedCaseInsensitiveContains(text) }
  }

  private func subtitle(_ exercise: Exercise) -> String {
    let muscles = exercise.primaryMuscles.map(muscleLabel).joined(separator: ", ")
    return muscles.isEmpty ? equipmentLabel(exercise.equipment) : "\(equipmentLabel(exercise.equipment)) · \(muscles)"
  }
}

struct ExerciseDetailView: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  let exerciseId: String
  @State private var editing = false
  @State private var blocked: [String] = []
  @State private var confirmDelete = false

  private var exercise: Exercise? { model.exercise(exerciseId) }

  var body: some View {
    Group {
      if let exercise {
        List {
          Section {
            LabeledContent(L("equipment"), value: equipmentLabel(exercise.equipment))
            LabeledContent(L("loadTypeLabel"), value: exercise.loadType == .discs ? L("loadTypeDiscs") : L("loadTypeWeight"))
            if let notes = exercise.notes, !notes.isEmpty {
              Text(notes)
            }
          }
          if !exercise.primaryMuscles.isEmpty {
            Section(L("primaryMuscles")) {
              Text(exercise.primaryMuscles.map(muscleLabel).joined(separator: ", "))
            }
          }
          if !exercise.secondaryMuscles.isEmpty {
            Section(L("secondaryMuscles")) {
              Text(exercise.secondaryMuscles.map(muscleLabel).joined(separator: ", "))
            }
          }
          Section(L("usedInRoutines")) {
            let used = model.routinesUsing(exerciseId: exercise.id)
            if used.isEmpty {
              Text(L("notUsedInRoutines")).foregroundStyle(.secondary)
            } else {
              ForEach(used) { routine in Text(routine.title) }
            }
          }
          if !exercise.imagePaths.isEmpty {
            Section(L("referenceImages")) {
              ExercisePhotos(paths: exercise.imagePaths)
            }
          }
          Section {
            NavigationLink(L("viewProgress")) { ExerciseProgressView(exerciseId: exercise.id) }
          }
          Section {
            Button(L("delete"), role: .destructive) { askDelete(exercise) }
          }
        }
      } else {
        ContentUnavailableView(L("exerciseNotFound"), systemImage: "questionmark")
      }
    }
    .navigationTitle(exercise?.name ?? "")
    .toolbar {
      if exercise != nil {
        Button(L("edit")) { editing = true }
      }
    }
    .sheet(isPresented: $editing) {
      NavigationStack { ExerciseEditorView(exerciseId: exerciseId) }
    }
    .alert(L("exerciseInUseTitle"), isPresented: Binding(get: { !blocked.isEmpty }, set: { if !$0 { blocked = [] } })) {
      Button(L("ok"), role: .cancel) {}
    } message: {
      Text(L("exerciseInUseMessage", blocked.joined(separator: ", ")))
    }
    .confirmationDialog(L("deleteExerciseTitle"), isPresented: $confirmDelete, titleVisibility: .visible) {
      Button(L("delete"), role: .destructive) { Task { await remove() } }
      Button(L("cancel"), role: .cancel) {}
    } message: {
      Text(L("deleteExerciseMessage", exercise?.name ?? ""))
    }
  }

  private func askDelete(_ exercise: Exercise) {
    let used = model.routinesUsing(exerciseId: exercise.id)
    if used.isEmpty {
      confirmDelete = true
    } else {
      blocked = used.map(\.title)
    }
  }

  private func remove() async {
    guard let exercise else { return }
    if await model.deleteExercise(exercise) { dismiss() }
  }
}

struct ExercisePhotos: View {
  @Environment(AppModel.self) private var model
  var paths: [String]
  /// Shows a trailing placeholder tile with a spinner while a new photo is uploading.
  var uploading = false
  @State private var images: [String: URL] = [:]
  @State private var preview: PhotoPreview?

  var body: some View {
    if !paths.isEmpty || uploading {
      ScrollView(.horizontal) {
        HStack {
          ForEach(paths, id: \.self) { path in
            Group {
              if let ui = image(for: path) {
                Image(uiImage: ui).resizable().scaledToFill()
                  .contentShape(.rect)
                  .onTapGesture { preview = PhotoPreview(image: ui) }
              } else {
                ProgressView()
              }
            }
            .frame(width: 120, height: 120)
            .clipShape(.rect(cornerRadius: 12))
          }
          if uploading {
            ProgressView()
              .frame(width: 120, height: 120)
              .background(.quaternary, in: .rect(cornerRadius: 12))
          }
        }
      }
      .task(id: paths) { await load() }
      .fullScreenCover(item: $preview) { item in
        PhotoPreviewView(image: item.image)
      }
    }
  }

  private func image(for path: String) -> UIImage? {
    guard let url = images[path], let data = try? Data(contentsOf: url) else { return nil }
    return UIImage(data: data)
  }

  private func load() async {
    guard let repo = model.repo else { return }
    for path in paths where images[path] == nil {
      if let url = try? await repo.imageFile(path: path) {
        images[path] = url
      }
    }
  }
}

struct PhotoPreview: Identifiable {
  let id = UUID()
  let image: UIImage
}

/// Full-screen photo viewer: pinch to zoom, drag to pan, double-tap to toggle zoom.
struct PhotoPreviewView: View {
  @Environment(\.dismiss) private var dismiss
  let image: UIImage

  var body: some View {
    ZStack(alignment: .topTrailing) {
      Color.black.ignoresSafeArea()
      ZoomableImage(image: image).ignoresSafeArea()
      Button { dismiss() } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.title)
          .symbolRenderingMode(.palette)
          .foregroundStyle(.white, .black.opacity(0.5))
          .padding()
      }
      .accessibilityLabel(L("close"))
    }
  }
}

private struct ZoomableImage: UIViewRepresentable {
  let image: UIImage

  func makeUIView(context: Context) -> ZoomScrollView {
    let scroll = ZoomScrollView()
    scroll.delegate = context.coordinator
    scroll.minimumZoomScale = 1
    scroll.maximumZoomScale = 5
    scroll.showsHorizontalScrollIndicator = false
    scroll.showsVerticalScrollIndicator = false
    scroll.contentInsetAdjustmentBehavior = .never
    scroll.imageView.image = image
    scroll.addSubview(scroll.imageView)
    context.coordinator.imageView = scroll.imageView
    let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
    tap.numberOfTapsRequired = 2
    scroll.addGestureRecognizer(tap)
    return scroll
  }

  func updateUIView(_ uiView: ZoomScrollView, context: Context) {}

  func makeCoordinator() -> Coordinator { Coordinator() }

  final class ZoomScrollView: UIScrollView {
    let imageView = UIImageView()

    override init(frame: CGRect) {
      super.init(frame: frame)
      imageView.contentMode = .scaleAspectFit
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
      super.layoutSubviews()
      if zoomScale == 1 { imageView.frame = bounds }
    }
  }

  final class Coordinator: NSObject, UIScrollViewDelegate {
    weak var imageView: UIImageView?

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
      guard let scroll = gesture.view as? UIScrollView else { return }
      if scroll.zoomScale > 1 {
        scroll.setZoomScale(1, animated: true)
      } else {
        let point = gesture.location(in: imageView)
        let scale: CGFloat = 3
        let size = CGSize(width: scroll.bounds.width / scale, height: scroll.bounds.height / scale)
        scroll.zoom(
          to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height),
          animated: true)
      }
    }
  }
}
