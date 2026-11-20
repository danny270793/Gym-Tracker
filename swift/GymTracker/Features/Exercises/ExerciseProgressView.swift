import Charts
import GymCore
import SwiftUI

enum ProgressMetric: String, CaseIterable, Identifiable {
  case top, volume, reps, e1rm
  var id: String { rawValue }
  var label: String {
    switch self {
    case .e1rm: L("metricE1rm")
    case .top: L("metricTopWeight")
    case .volume: L("metricVolume")
    case .reps: L("reps")
    }
  }
}

struct ExerciseProgressView: View {
  @Environment(AppModel.self) private var model
  @Environment(Preferences.self) private var prefs
  let exerciseId: String
  @State private var metric: ProgressMetric = .top

  private var points: [ExerciseSessionPoint] {
    ExerciseProgress()(exerciseId: exerciseId, workouts: model.workouts)
  }

  var body: some View {
    let points = points
    let exercise = model.exercise(exerciseId)
    let load = LoadText(type: exercise?.loadType ?? .weight, unit: prefs.weightUnit)
    return List {
      if points.isEmpty {
        ContentUnavailableView {
          Label(L("progressEmptyTitle"), systemImage: "chart.xyaxis.line")
        } description: {
          Text(L("progressEmptyBody"))
        }
      } else {
        Section {
          Picker(L("metricE1rm"), selection: $metric) {
            ForEach(ProgressMetric.allCases) { item in Text(item.label).tag(item) }
          }
          .pickerStyle(.segmented)
          Chart(points) { point in
            LineMark(
              x: .value("Date", point.date),
              y: .value("Value", value(point))
            )
            .foregroundStyle(Color.accentColor)
            PointMark(
              x: .value("Date", point.date),
              y: .value("Value", value(point))
            )
          }
          .frame(height: 220)
          if let first = points.first, let last = points.last, metric == .e1rm, first.bestE1rm > 0 {
            let change = (last.bestE1rm - first.bestE1rm) / first.bestE1rm
            LabeledContent(L("progressSinceFirst"), value: "\(change >= 0 ? "+" : "")\(Int((change * 100).rounded()))%")
          }
          LabeledContent(L("bestE1rm"), value: load.withSymbol(points.map(\.bestE1rm).max() ?? 0))
          LabeledContent(L("bestVolume"), value: load.withSymbol(points.map(\.volume).max() ?? 0))
          LabeledContent(L("sessions"), value: LP("sessionsCount", points.count))
        }
        Section(L("sessionsTitle")) {
          ForEach(points.reversed()) { point in
            VStack(alignment: .leading) {
              Text(formatDay(point.date))
              Text("\(LP("setsCount", point.sets)) · \(LP("repsCount", point.reps)) · \(load.withSymbol(point.topLoad))")
                .font(.footnote).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .navigationTitle(exercise?.name ?? L("viewProgress"))
  }

  private func value(_ point: ExerciseSessionPoint) -> Double {
    switch metric {
    case .e1rm: point.bestE1rm
    case .top: point.topLoad
    case .volume: point.volume
    case .reps: Double(point.reps)
    }
  }
}
