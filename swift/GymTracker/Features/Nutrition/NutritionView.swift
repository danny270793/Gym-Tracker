import GymCore
import SwiftUI

struct NutritionView: View {
  @Environment(AppModel.self) private var model
  @Environment(NutritionStore.self) private var store
  @State private var day = Date.now
  @State private var editing: FoodEntry?
  @State private var showProfile = false

  private var dayEntries: [FoodEntry] { store.entries(on: day) }
  private var totals: DayTotals { DayTotals.of(dayEntries) }

  var body: some View {
    List {
      Section { dayPicker }
      Section {
        if let targets = store.targets {
          IntakeRow(
            title: L("protein"), unit: L("unitGrams"), eaten: totals.proteinGrams,
            target: Double(targets.proteinGrams), tint: .blue)
          IntakeRow(
            title: L("calories"), unit: L("unitKcal"), eaten: totals.calories,
            target: Double(targets.calories), tint: .orange)
        } else {
          TotalsRow(totals: totals)
          Button(L("nutritionSetGoals"), systemImage: "target") { showProfile = true }
        }
      } header: {
        Text(L("nutritionToday"))
      } footer: {
        if store.targets == nil { Text(L("nutritionSetGoalsHint")) }
      }
      Section(L("nutritionFoodLog")) {
        if dayEntries.isEmpty {
          Text(L("nutritionEmpty")).foregroundStyle(.secondary)
        }
        ForEach(dayEntries) { entry in
          Button { editing = entry } label: { FoodRow(entry: entry) }
            .buttonStyle(.plain)
        }
        .onDelete { offsets in
          let list = dayEntries
          for index in offsets { Task { await store.delete(list[index], model: model) } }
        }
        Button(L("nutritionAddFood"), systemImage: "plus.circle.fill") {
          editing = FoodEntry(date: entryDate(), meal: .suggested(at: .now), proteinGrams: 0, calories: 0, details: "")
        }
      }
    }
    .navigationTitle(L("navNutrition"))
    .toolbar {
      SettingsToolbar()
      ToolbarItem(placement: .primaryAction) {
        Button(L("nutritionGoals"), systemImage: "target") { showProfile = true }
      }
    }
    .task { await store.load(model: model) }
    .refreshable { await store.load(model: model) }
    .sheet(item: $editing) { entry in
      NavigationStack { FoodEntryEditor(entry: entry, isNew: !store.entries.contains { $0.id == entry.id }) }
    }
    .sheet(isPresented: $showProfile) {
      NavigationStack { NutritionProfileView() }
    }
  }

  private var dayPicker: some View {
    HStack {
      Button(L("previousDay"), systemImage: "chevron.left") { day = addDays(day, -1) }
        .labelStyle(.iconOnly)
      Spacer()
      Text(dayTitle).font(.headline)
      Spacer()
      Button(L("nextDay"), systemImage: "chevron.right") { day = addDays(day, 1) }
        .labelStyle(.iconOnly)
        .disabled(isSameDay(day, .now))
    }
    .buttonStyle(.borderless)
  }

  private var dayTitle: String {
    if isSameDay(day, .now) { return L("today") }
    if isSameDay(day, addDays(.now, -1)) { return L("yesterday") }
    return day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
  }

  /// A new entry belongs to the day on screen, at the current time of day.
  private func entryDate() -> Date {
    guard !isSameDay(day, .now) else { return .now }
    let time = Calendar.current.dateComponents([.hour, .minute], from: .now)
    return Calendar.current.date(bySettingHour: time.hour ?? 12, minute: time.minute ?? 0, second: 0, of: day) ?? day
  }
}

private struct IntakeRow: View {
  let title: String
  let unit: String
  let eaten: Double
  let target: Double
  let tint: Color

  private var remaining: Double { target - eaten }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .firstTextBaseline) {
        Text(title).font(.headline)
        Spacer()
        Text("\(Int(eaten.rounded())) / \(Int(target.rounded())) \(unit)").monospacedDigit()
      }
      ProgressView(value: min(eaten, target), total: max(target, 1)).tint(remaining < 0 ? .red : tint)
      Text(
        remaining >= 0
          ? L("nutritionRemaining", Int(remaining.rounded()), unit)
          : L("nutritionOver", Int((-remaining).rounded()), unit)
      )
      .font(.footnote).foregroundStyle(.secondary)
    }
    .padding(.vertical, 2)
  }
}

private struct TotalsRow: View {
  let totals: DayTotals

  var body: some View {
    HStack {
      Label("\(Int(totals.proteinGrams.rounded())) \(L("unitGrams"))", systemImage: "fork.knife")
      Spacer()
      Label("\(Int(totals.calories.rounded())) \(L("unitKcal"))", systemImage: "flame")
    }
    .monospacedDigit()
  }
}

private struct FoodRow: View {
  let entry: FoodEntry

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 2) {
        Text(entry.details.isEmpty ? mealLabel(entry.meal) : entry.details)
        Text("\(mealLabel(entry.meal)) · \(entry.date.formatted(date: .omitted, time: .shortened))")
          .font(.footnote).foregroundStyle(.secondary)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 2) {
        Text("\(WeightUnit.formatNumber(entry.proteinGrams)) \(L("unitGrams"))")
        Text("\(WeightUnit.formatNumber(entry.calories)) \(L("unitKcal"))")
          .font(.footnote).foregroundStyle(.secondary)
      }
      .monospacedDigit()
    }
    .contentShape(.rect)
  }
}

func mealLabel(_ meal: MealType) -> String {
  switch meal {
  case .breakfast: L("mealBreakfast")
  case .lunch: L("mealLunch")
  case .dinner: L("mealDinner")
  case .snack: L("mealSnack")
  }
}

/// Accepts `12.5` and `12,5`.
func parseNumber(_ text: String) -> Double? {
  Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}

struct FoodEntryEditor: View {
  @Environment(AppModel.self) private var model
  @Environment(NutritionStore.self) private var store
  @Environment(\.dismiss) private var dismiss
  let entry: FoodEntry
  let isNew: Bool

  @State private var protein = ""
  @State private var calories = ""
  @State private var details = ""
  @State private var meal: MealType = .snack
  @State private var date = Date.now
  @State private var saving = false
  @FocusState private var focus: Field?

  private enum Field { case protein, calories, details }

  private var parsed: (protein: Double, calories: Double)? {
    let p = protein.isEmpty ? 0 : parseNumber(protein)
    let c = calories.isEmpty ? 0 : parseNumber(calories)
    guard let p, let c, p >= 0, c >= 0, p > 0 || c > 0 else { return nil }
    return (p, c)
  }

  var body: some View {
    Form {
      Section {
        HStack {
          Text(L("protein"))
          TextField("0", text: $protein)
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).focused($focus, equals: .protein)
          Text(L("unitGrams")).foregroundStyle(.secondary)
        }
        HStack {
          Text(L("calories"))
          TextField("0", text: $calories)
            .keyboardType(.decimalPad).multilineTextAlignment(.trailing).focused($focus, equals: .calories)
          Text(L("unitKcal")).foregroundStyle(.secondary)
        }
        TextField(L("foodDescriptionLabel"), text: $details, prompt: Text(L("foodDescriptionHint")), axis: .vertical)
          .focused($focus, equals: .details)
      }
      Section {
        Picker(L("meal"), selection: $meal) {
          ForEach(MealType.allCases, id: \.self) { Text(mealLabel($0)).tag($0) }
        }
        DatePicker(L("time"), selection: $date)
      }
      if !isNew {
        Section {
          Button(L("delete"), role: .destructive) {
            Task { if await store.delete(entry, model: model) { dismiss() } }
          }
        }
      }
    }
    .navigationTitle(isNew ? L("nutritionAddFood") : L("nutritionEditFood"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
      ToolbarItem(placement: .confirmationAction) { Button(L("save")) { Task { await save() } }.disabled(parsed == nil || saving) }
    }
    .onAppear {
      protein = entry.proteinGrams > 0 ? WeightUnit.formatNumber(entry.proteinGrams) : ""
      calories = entry.calories > 0 ? WeightUnit.formatNumber(entry.calories) : ""
      details = entry.details
      meal = entry.meal
      date = entry.date
      if isNew { focus = .protein }
    }
  }

  private func save() async {
    guard let parsed else { return }
    saving = true
    defer { saving = false }
    let saved = await store.save(
      FoodEntry(
        id: entry.id, date: date, meal: meal, proteinGrams: parsed.protein, calories: parsed.calories,
        details: details.trimmingCharacters(in: .whitespacesAndNewlines)),
      model: model)
    if saved { dismiss() }
  }
}
