import Foundation
import GymCore
import Testing

@Test func mifflinStJeorTargets() {
  // 10*80 + 6.25*180 - 5*30 + 5 = 1780 kcal BMR; x1.55 = 2759 maintenance
  let profile = NutritionProfile(
    sex: .male, age: 30, weightKg: 80, heightCm: 180, activity: .moderate, goal: .maintain)
  let targets = NutritionCalculator.targets(for: profile)
  #expect(targets.bmr == 1780)
  #expect(targets.maintenance == 2759)
  #expect(targets.calories == 2759)
  #expect(targets.proteinGrams == 128)
}

@Test func goalChangesCaloriesAndProtein() {
  var profile = NutritionProfile(
    sex: .female, age: 28, weightKg: 60, heightCm: 165, activity: .light, goal: .lose)
  // 600 + 1031.25 - 140 - 161 = 1330.25 BMR; x1.375 = 1829.1 maintenance
  let cut = NutritionCalculator.targets(for: profile)
  #expect(cut.maintenance == 1829)
  #expect(cut.calories == 1463)
  #expect(cut.proteinGrams == 120)
  profile.goal = .gain
  let bulk = NutritionCalculator.targets(for: profile)
  #expect(bulk.calories == 2012)
  #expect(bulk.proteinGrams == 108)
}

@Test func profileValidation() {
  #expect(NutritionProfile().isValid)
  #expect(!NutritionProfile(age: 8).isValid)
  #expect(!NutritionProfile(weightKg: 5).isValid)
  #expect(!NutritionProfile(heightCm: 300).isValid)
}

@Test func dayTotalsAndFiltering() {
  let breakfast = FoodEntry(date: date(2026, 3, 11, 8), meal: .breakfast, proteinGrams: 30, calories: 450, details: "Eggs")
  let lunch = FoodEntry(date: date(2026, 3, 11, 13), meal: .lunch, proteinGrams: 45.5, calories: 700, details: "Chicken")
  let other = FoodEntry(date: date(2026, 3, 12, 9), meal: .breakfast, proteinGrams: 20, calories: 300, details: "Oats")
  let today = entries([lunch, other, breakfast], on: date(2026, 3, 11, 22))
  #expect(today.map(\.details) == ["Eggs", "Chicken"])
  let totals = DayTotals.of(today)
  #expect(totals.proteinGrams == 75.5)
  #expect(totals.calories == 1150)
}

@Test func suggestedMealByHour() {
  #expect(MealType.suggested(at: date(2026, 3, 11, 8)) == .breakfast)
  #expect(MealType.suggested(at: date(2026, 3, 11, 13)) == .lunch)
  #expect(MealType.suggested(at: date(2026, 3, 11, 19)) == .dinner)
  #expect(MealType.suggested(at: date(2026, 3, 11, 23)) == .snack)
}
