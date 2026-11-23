import Foundation

public enum Sex: String, CaseIterable, Sendable, Codable {
  case male, female
}

public enum ActivityLevel: String, CaseIterable, Sendable, Codable {
  /// Desk job, little exercise.
  case sedentary
  /// Training 1-3 days a week.
  case light
  /// Training 3-5 days a week.
  case moderate
  /// Training 6-7 days a week.
  case high
  /// Hard daily training or a physical job.
  case extreme

  public var factor: Double {
    switch self {
    case .sedentary: 1.2
    case .light: 1.375
    case .moderate: 1.55
    case .high: 1.725
    case .extreme: 1.9
    }
  }
}

public enum NutritionGoal: String, CaseIterable, Sendable, Codable {
  case lose, maintain, gain

  /// Share added to (or taken off) maintenance calories.
  public var calorieAdjustment: Double {
    switch self {
    case .lose: -0.20
    case .maintain: 0
    case .gain: 0.10
    }
  }

  /// Grams of protein per kg of body weight (within the 1.6-2.2 g/kg range used for lifters).
  public var proteinPerKg: Double {
    switch self {
    case .lose: 2.0
    case .maintain: 1.6
    case .gain: 1.8
    }
  }
}

/// What the daily estimate is based on. Weight is kept in kg, height in cm.
public struct NutritionProfile: Sendable, Codable, Equatable {
  public var sex: Sex
  public var age: Int
  public var weightKg: Double
  public var heightCm: Double
  public var activity: ActivityLevel
  public var goal: NutritionGoal

  public init(
    sex: Sex = .male, age: Int = 30, weightKg: Double = 75, heightCm: Double = 175,
    activity: ActivityLevel = .moderate, goal: NutritionGoal = .maintain
  ) {
    self.sex = sex
    self.age = age
    self.weightKg = weightKg
    self.heightCm = heightCm
    self.activity = activity
    self.goal = goal
  }

  public static let ageRange = 14...100
  public static let weightKgRange = 30.0...300.0
  public static let heightCmRange = 120.0...230.0

  public var isValid: Bool {
    Self.ageRange.contains(age) && Self.weightKgRange.contains(weightKg)
      && Self.heightCmRange.contains(heightCm)
  }
}

public struct NutritionTargets: Sendable, Equatable {
  /// Basal metabolic rate (Mifflin-St Jeor), kcal.
  public var bmr: Int
  /// Calories to keep the current weight, kcal.
  public var maintenance: Int
  /// Daily calories for the goal, kcal.
  public var calories: Int
  /// Daily protein, grams.
  public var proteinGrams: Int
}

public enum NutritionCalculator {
  public static func targets(for profile: NutritionProfile) -> NutritionTargets {
    var bmr = 10 * profile.weightKg + 6.25 * profile.heightCm - 5 * Double(profile.age)
    bmr += profile.sex == .male ? 5 : -161
    let maintenance = bmr * profile.activity.factor
    let calories = maintenance * (1 + profile.goal.calorieAdjustment)
    return NutritionTargets(
      bmr: Int(bmr.rounded()),
      maintenance: Int(maintenance.rounded()),
      calories: Int(calories.rounded()),
      proteinGrams: Int((profile.weightKg * profile.goal.proteinPerKg).rounded()))
  }
}

public enum MealType: String, CaseIterable, Sendable, Codable {
  case breakfast, lunch, dinner, snack

  /// A sensible default for the time of day.
  public static func suggested(at date: Date, calendar: Calendar = .current) -> MealType {
    switch calendar.component(.hour, from: date) {
    case 4..<11: .breakfast
    case 11..<16: .lunch
    case 16..<22: .dinner
    default: .snack
    }
  }
}

public struct FoodEntry: Identifiable, Sendable, Codable, Equatable {
  public var id: String
  public var date: Date
  public var meal: MealType
  public var proteinGrams: Double
  public var calories: Double
  public var details: String

  public init(
    id: String = UUID().uuidString.lowercased(), date: Date = .now, meal: MealType,
    proteinGrams: Double, calories: Double, details: String
  ) {
    self.id = id
    self.date = date
    self.meal = meal
    self.proteinGrams = proteinGrams
    self.calories = calories
    self.details = details
  }
}

public struct DayTotals: Sendable, Equatable {
  public var proteinGrams: Double
  public var calories: Double

  public init(proteinGrams: Double = 0, calories: Double = 0) {
    self.proteinGrams = proteinGrams
    self.calories = calories
  }

  public static func of(_ entries: [FoodEntry]) -> DayTotals {
    DayTotals(
      proteinGrams: entries.reduce(0) { $0 + $1.proteinGrams },
      calories: entries.reduce(0) { $0 + $1.calories })
  }
}

/// Entries logged on `day`, oldest first.
public func entries(_ all: [FoodEntry], on day: Date, calendar: Calendar = .current) -> [FoodEntry] {
  all.filter { isSameDay($0.date, day, calendar: calendar) }.sorted { $0.date < $1.date }
}
