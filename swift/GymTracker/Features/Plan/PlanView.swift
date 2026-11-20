import GymCore
import SwiftUI

struct PlanView: View {
  @Environment(AppModel.self) private var model
  @State private var editor: RoutineRoute?
  @State private var dayPicker: WeekdayItem?

  var body: some View {
    Group {
      if model.loading && !model.loaded {
        ProgressView()
      } else if model.loadError != nil, !model.loaded {
        ContentUnavailableView {
          Label(L("loadError"), systemImage: "exclamationmark.triangle")
        } actions: {
          Button(L("retry")) { Task { await model.reload() } }
        }
      } else {
        list
      }
    }
    .navigationTitle(L("navPlan"))
    .toolbar {
      SettingsToolbar()
      ToolbarItem(placement: .primaryAction) {
        Button(L("newRoutine"), systemImage: "plus") { editor = RoutineRoute(id: nil, weekday: nil) }
      }
    }
    .navigationDestination(item: $editor) { route in
      RoutineEditorView(routineId: route.id, assignWeekday: route.weekday)
    }
    .sheet(item: $dayPicker) { item in
      DayPicker(weekday: item.weekday) { choice in
        dayPicker = nil
        switch choice {
        case .rest:
          Task { await model.setDay(weekday: item.weekday, routineId: nil) }
        case .routine(let id):
          Task { await model.setDay(weekday: item.weekday, routineId: id) }
        case .create:
          editor = RoutineRoute(id: nil, weekday: item.weekday)
        }
      }
    }
    .refreshable { await model.reload() }
  }

  private var list: some View {
    let today = weekdayMondayBased(.now)
    return List {
      OfflineHeader()
      Section {
        Text(L("weeklyPlanHint")).font(.footnote).foregroundStyle(.secondary)
        ForEach(weekdays, id: \.self) { day in
          let routine = model.plan.routineId(for: day).flatMap { model.routine($0) }
          Button {
            dayPicker = WeekdayItem(weekday: day)
          } label: {
            HStack {
              Text(weekdayShort(day))
                .font(.caption.bold())
                .frame(width: 36, height: 36)
                .background(day == today ? Color.accentColor : Color.secondary.opacity(0.15), in: .circle)
                .foregroundStyle(day == today ? Color.white : Color.primary)
              VStack(alignment: .leading) {
                Text(weekdayName(day))
                Text(routine?.title ?? L("restDay")).font(.footnote).foregroundStyle(.secondary)
              }
              Spacer()
              if let routine {
                Text(LP("routineSummary", routine.exercises.count, routine.totalSets))
                  .font(.caption).foregroundStyle(.secondary)
              }
            }
          }
          .buttonStyle(.plain)
        }
      } header: {
        Text(L("weeklyPlan"))
      }
      Section(L("routines")) {
        if model.routines.isEmpty {
          Text(L("routinesEmpty")).foregroundStyle(.secondary)
        }
        ForEach(model.routines) { routine in
          Button {
            editor = RoutineRoute(id: routine.id, weekday: nil)
          } label: {
            VStack(alignment: .leading) {
              Text(routine.title)
              Text(LP("routineSummary", routine.exercises.count, routine.totalSets))
                .font(.footnote).foregroundStyle(.secondary)
            }
          }
        }
      }
    }
  }
}

struct RoutineRoute: Identifiable, Hashable {
  var id: String { routineId ?? "new-\(weekday ?? 0)" }
  var routineId: String?
  var weekday: Int?

  init(id: String?, weekday: Int?) {
    routineId = id
    self.weekday = weekday
  }
}

private enum DayChoice {
  case rest
  case routine(String)
  case create
}

private struct DayPicker: View {
  @Environment(AppModel.self) private var model
  @Environment(\.dismiss) private var dismiss
  var weekday: Int
  var onPick: (DayChoice) -> Void

  var body: some View {
    NavigationStack {
      List {
        let current = model.plan.routineId(for: weekday)
        ForEach(model.routines) { routine in
          Button {
            onPick(.routine(routine.id))
            dismiss()
          } label: {
            HStack {
              Text(routine.title)
              Spacer()
              if current == routine.id { Image(systemName: "checkmark") }
            }
          }
        }
        Button {
          onPick(.rest)
          dismiss()
        } label: {
          HStack {
            Text(L("restDay"))
            Spacer()
            if current == nil { Image(systemName: "checkmark") }
          }
        }
        Button(L("newRoutine"), systemImage: "plus") {
          onPick(.create)
          dismiss()
        }
      }
      .navigationTitle(weekdayName(weekday))
      .toolbar { ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } } }
    }
    .presentationDetents([.medium, .large])
  }
}

struct WeekdayItem: Identifiable, Hashable {
  var weekday: Int
  var id: Int { weekday }
}
