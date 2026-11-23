import GymCore
import SwiftUI

struct SleepView: View {
  @Environment(AppModel.self) private var model
  @Environment(SleepStore.self) private var store
  @State private var editing: SleepEntry?

  /// Days that have sessions, most recent first.
  private var days: [Date] {
    var seen: [Date] = []
    for entry in store.entries.sorted(by: { $0.end > $1.end }) {
      let day = dateOnly(entry.end)
      if !seen.contains(day) { seen.append(day) }
    }
    return seen
  }

  var body: some View {
    List {
      if store.entries.isEmpty {
        ContentUnavailableView {
          Label(L("sleepEmptyTitle"), systemImage: "bed.double")
        } description: {
          Text(L("sleepEmptyBody"))
        } actions: {
          Button(L("sleepAdd")) { editing = newEntry(nap: false) }.buttonStyle(.borderedProminent)
        }
        .listRowBackground(Color.clear)
      }
      ForEach(days, id: \.self) { day in
        Section {
          ForEach(sleepEntries(store.entries, endingOn: day)) { entry in
            Button { editing = entry } label: { SleepRow(entry: entry) }
              .buttonStyle(.plain)
          }
          .onDelete { offsets in
            let list = sleepEntries(store.entries, endingOn: day)
            for index in offsets { Task { await store.delete(list[index], model: model) } }
          }
        } header: {
          HStack {
            Text(dayTitle(day))
            Spacer()
            Text(L("sleepTotal", duration(totalSleep(store.entries, endingOn: day))))
          }
        }
      }
    }
    .navigationTitle(L("navSleep"))
    .toolbar {
      SettingsToolbar()
      ToolbarItem(placement: .primaryAction) {
        Menu {
          Button(L("sleepAddNight"), systemImage: "moon.stars") { editing = newEntry(nap: false) }
          Button(L("sleepAddNap"), systemImage: "sun.haze") { editing = newEntry(nap: true) }
        } label: {
          Image(systemName: "plus")
        }
        .accessibilityLabel(L("sleepAdd"))
      }
    }
    .task { await store.load(model: model) }
    .refreshable { await store.load(model: model) }
    .sheet(item: $editing) { entry in
      NavigationStack { SleepEditor(entry: entry, isNew: !store.entries.contains { $0.id == entry.id }) }
    }
  }

  private func newEntry(nap: Bool) -> SleepEntry {
    let end = Date.now
    return SleepEntry(start: end.addingTimeInterval(nap ? -1800 : -8 * 3600), end: end, isNap: nap)
  }

  private func dayTitle(_ day: Date) -> String {
    if isSameDay(day, .now) { return L("today") }
    if isSameDay(day, addDays(.now, -1)) { return L("yesterday") }
    return day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
  }
}

/// `7h 30m`, `45m`.
func duration(_ seconds: TimeInterval) -> String {
  let minutes = Int((seconds / 60).rounded())
  return minutes >= 60 ? "\(minutes / 60)h \(minutes % 60)m" : "\(minutes)m"
}

private struct SleepRow: View {
  let entry: SleepEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Label(entry.isNap ? L("sleepNap") : L("sleepNight"), systemImage: entry.isNap ? "sun.haze" : "moon.stars")
          .font(.headline)
        Spacer()
        Text(duration(entry.asleep)).monospacedDigit()
      }
      Text("\(entry.start.formatted(date: .omitted, time: .shortened)) – \(entry.end.formatted(date: .omitted, time: .shortened))")
        .font(.footnote).foregroundStyle(.secondary)
      if !entry.isNap {
        let parts = details
        if !parts.isEmpty {
          Text(parts.joined(separator: " · ")).font(.footnote).foregroundStyle(.secondary)
        }
      }
    }
    .contentShape(.rect)
  }

  private var details: [String] {
    var parts: [String] = []
    if let deep = entry.deepPercent { parts.append(L("sleepDeepValue", WeightUnit.formatNumber(deep))) }
    if let rem = entry.remPercent { parts.append(L("sleepRemValue", WeightUnit.formatNumber(rem))) }
    if let count = entry.awakenings { parts.append(L("sleepAwakeningsValue", count)) }
    if let minutes = entry.awakeMinutes { parts.append(L("sleepAwakeValue", minutes)) }
    return parts
  }
}

struct SleepEditor: View {
  @Environment(AppModel.self) private var model
  @Environment(SleepStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let entry: SleepEntry
  let isNew: Bool

  @State private var isNap = false
  @State private var start = Date.now
  @State private var end = Date.now
  @State private var deep = ""
  @State private var rem = ""
  @State private var awakenings = ""
  @State private var awakeMinutes = ""
  @State private var saving = false

  private var built: SleepEntry {
    SleepEntry(
      id: entry.id, start: start, end: end, isNap: isNap,
      deepPercent: parseNumber(deep), remPercent: parseNumber(rem),
      awakenings: Int(awakenings), awakeMinutes: Int(awakeMinutes))
  }

  /// Text that is filled in but not a valid number.
  private var hasBadInput: Bool {
    (!deep.isEmpty && parseNumber(deep) == nil) || (!rem.isEmpty && parseNumber(rem) == nil)
      || (!awakenings.isEmpty && Int(awakenings) == nil) || (!awakeMinutes.isEmpty && Int(awakeMinutes) == nil)
  }

  var body: some View {
    Form {
      Section {
        Picker(L("sleepType"), selection: $isNap) {
          Text(L("sleepNight")).tag(false)
          Text(L("sleepNap")).tag(true)
        }
        .pickerStyle(.segmented)
        DatePicker(L("sleepStart"), selection: $start)
        DatePicker(L("sleepEnd"), selection: $end)
        LabeledContent(L("sleepDuration"), value: duration(max(0, end.timeIntervalSince(start))))
      }
      if !isNap {
        Section(L("sleepQuality")) {
          field(L("sleepDeep"), text: $deep, suffix: "%", keyboard: .decimalPad)
          field(L("sleepRem"), text: $rem, suffix: "%", keyboard: .decimalPad)
          field(L("sleepTimesAwake"), text: $awakenings, suffix: L("unitTimes"), keyboard: .numberPad)
          field(L("sleepTimeAwake"), text: $awakeMinutes, suffix: L("unitMin"), keyboard: .numberPad)
        }
      }
      if !built.isValid || hasBadInput {
        Section { Text(L("sleepInvalid")).foregroundStyle(.red).font(.footnote) }
      }
      if !isNew {
        Section {
          Button(L("delete"), role: .destructive) {
            Task { if await store.delete(entry, model: model) { dismiss() } }
          }
        }
      }
    }
    .navigationTitle(isNew ? L("sleepAdd") : L("sleepEdit"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
      ToolbarItem(placement: .confirmationAction) {
        Button(L("save")) {
          Task {
            saving = true
            defer { saving = false }
            if await store.save(built, model: model) { dismiss() }
          }
        }
        .disabled(!built.isValid || hasBadInput || saving)
      }
    }
    .onAppear {
      isNap = entry.isNap
      start = entry.start
      end = entry.end
      deep = entry.deepPercent.map(WeightUnit.formatNumber) ?? ""
      rem = entry.remPercent.map(WeightUnit.formatNumber) ?? ""
      awakenings = entry.awakenings.map(String.init) ?? ""
      awakeMinutes = entry.awakeMinutes.map(String.init) ?? ""
    }
  }

  private func field(_ title: String, text: Binding<String>, suffix: String, keyboard: UIKeyboardType) -> some View {
    HStack {
      Text(title)
      TextField("—", text: text).keyboardType(keyboard).multilineTextAlignment(.trailing)
      Text(suffix).foregroundStyle(.secondary)
    }
  }
}
