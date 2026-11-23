import GymCore
import SwiftUI

/// Asks for the data needed to estimate daily calories and protein.
struct NutritionProfileView: View {
  @Environment(AppModel.self) private var model
  @Environment(NutritionStore.self) private var store
  @Environment(Preferences.self) private var prefs
  @Environment(\.dismiss) private var dismiss

  @State private var sex: Sex = .male
  @State private var age = ""
  @State private var weight = ""
  @State private var height = ""
  @State private var activity: ActivityLevel = .moderate
  @State private var goal: NutritionGoal = .maintain
  @State private var saving = false

  private var unit: WeightUnit { prefs.weightUnit }

  private var profile: NutritionProfile? {
    guard let age = Int(age), let weight = parseNumber(weight), let height = parseNumber(height) else { return nil }
    let value = NutritionProfile(
      sex: sex, age: age, weightKg: unit == .kg ? weight : weight * WeightUnit.kgPerLb, heightCm: height,
      activity: activity, goal: goal)
    return value.isValid ? value : nil
  }

  var body: some View {
    Form {
      Section {
        Picker(L("sex"), selection: $sex) {
          Text(L("sexMale")).tag(Sex.male)
          Text(L("sexFemale")).tag(Sex.female)
        }
        field(L("age"), text: $age, suffix: L("unitYears"), keyboard: .numberPad)
        field(L("bodyWeight"), text: $weight, suffix: unit.symbol, keyboard: .decimalPad)
        field(L("height"), text: $height, suffix: L("unitCm"), keyboard: .decimalPad)
      } header: {
        Text(L("nutritionAboutYou"))
      }
      Section {
        Picker(L("activityLevel"), selection: $activity) {
          ForEach(ActivityLevel.allCases, id: \.self) { Text(activityLabel($0)).tag($0) }
        }
        Picker(L("goal"), selection: $goal) {
          ForEach(NutritionGoal.allCases, id: \.self) { Text(goalLabel($0)).tag($0) }
        }
      } footer: {
        Text(activityHint(activity))
      }
      if let profile {
        let targets = NutritionCalculator.targets(for: profile)
        Section {
          LabeledContent(L("protein"), value: "\(targets.proteinGrams) \(L("unitGrams"))")
          LabeledContent(L("calories"), value: "\(targets.calories) \(L("unitKcal"))")
          LabeledContent(L("nutritionMaintenance"), value: "\(targets.maintenance) \(L("unitKcal"))")
        } header: {
          Text(L("nutritionYourDay"))
        } footer: {
          Text(L("nutritionEstimateNote", String(format: "%.1f", goal.proteinPerKg)))
        }
      }
    }
    .navigationTitle(L("nutritionGoals"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .cancellationAction) { Button(L("cancel")) { dismiss() } }
      ToolbarItem(placement: .confirmationAction) {
        Button(L("save")) {
          guard let profile else { return }
          Task {
            saving = true
            defer { saving = false }
            if await store.saveProfile(profile, model: model) { dismiss() }
          }
        }
        .disabled(profile == nil || saving)
      }
    }
    .onAppear(perform: load)
  }

  private func field(_ title: String, text: Binding<String>, suffix: String, keyboard: UIKeyboardType) -> some View {
    HStack {
      Text(title)
      TextField("0", text: text).keyboardType(keyboard).multilineTextAlignment(.trailing)
      Text(suffix).foregroundStyle(.secondary)
    }
  }

  private func load() {
    guard let saved = store.profile else { return }
    sex = saved.sex
    age = String(saved.age)
    weight = WeightUnit.formatNumber(unit == .kg ? saved.weightKg : saved.weightKg / WeightUnit.kgPerLb)
    height = WeightUnit.formatNumber(saved.heightCm)
    activity = saved.activity
    goal = saved.goal
  }
}

private func activityLabel(_ level: ActivityLevel) -> String {
  switch level {
  case .sedentary: L("activitySedentary")
  case .light: L("activityLight")
  case .moderate: L("activityModerate")
  case .high: L("activityHigh")
  case .extreme: L("activityExtreme")
  }
}

private func activityHint(_ level: ActivityLevel) -> String {
  switch level {
  case .sedentary: L("activitySedentaryHint")
  case .light: L("activityLightHint")
  case .moderate: L("activityModerateHint")
  case .high: L("activityHighHint")
  case .extreme: L("activityExtremeHint")
  }
}

private func goalLabel(_ goal: NutritionGoal) -> String {
  switch goal {
  case .lose: L("goalLose")
  case .maintain: L("goalMaintain")
  case .gain: L("goalGain")
  }
}
