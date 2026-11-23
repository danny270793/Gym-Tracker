import Foundation

/// How a day measures up against a daily requirement.
public enum GoalStatus: Sendable, Equatable {
  /// The requirement was met.
  case reached
  /// The day is over (or has data) and the requirement was not met.
  case missed
  /// Today, and the requirement is not met yet.
  case inProgress
  /// A day that has not happened yet.
  case upcoming
  /// There is nothing to compare against (no daily goal set).
  case noTarget
}

public struct GoalStatuses: Sendable, Equatable {
  public var protein: GoalStatus
  public var calories: GoalStatus
  public var sleep: GoalStatus
}

/// One day of food and sleep next to the daily requirements.
public struct HealthDay: Identifiable, Sendable, Equatable {
  public var date: Date
  public var proteinGrams: Double
  public var calories: Double
  /// Time asleep, in seconds, for the sessions that ended that day (night and naps).
  public var sleepSeconds: TimeInterval
  public var entries: Int
  public var proteinTarget: Int?
  public var calorieTarget: Int?
  public var sleepTargetSeconds: TimeInterval
  public var status: GoalStatuses

  public var id: Date { date }

  public static func == (lhs: HealthDay, rhs: HealthDay) -> Bool {
    lhs.date == rhs.date && lhs.proteinGrams == rhs.proteinGrams && lhs.calories == rhs.calories
      && lhs.sleepSeconds == rhs.sleepSeconds && lhs.status == rhs.status
  }

  /// Every measurable requirement is met.
  public var allReached: Bool {
    let all = [status.protein, status.calories, status.sleep].filter { $0 != .noTarget }
    return !all.isEmpty && all.allSatisfy { $0 == .reached }
  }
}

public struct HealthWeek: Sendable {
  public var start: Date
  public var days: [HealthDay]

  /// Days (up to today) where each requirement was met, out of the days already counted.
  public func reachedCount(_ keyPath: KeyPath<HealthDay, GoalStatus>) -> (reached: Int, total: Int) {
    let counted = days.filter { [.reached, .missed].contains($0[keyPath: keyPath]) }
    return (counted.filter { $0[keyPath: keyPath] == .reached }.count, counted.count)
  }

  public func averageProtein() -> Double? { average(days.filter { $0.proteinGrams > 0 }.map(\.proteinGrams)) }
  public func averageCalories() -> Double? { average(days.filter { $0.calories > 0 }.map(\.calories)) }
  public func averageSleep() -> TimeInterval? { average(days.filter { $0.sleepSeconds > 0 }.map(\.sleepSeconds)) }

  private func average(_ values: [Double]) -> Double? {
    values.isEmpty ? nil : values.reduce(0, +) / Double(values.count)
  }
}

public enum HealthWeekCalculator {
  /// Calories count as met within this share of the daily target, either side.
  public static let calorieTolerance = 0.10
  public static let defaultSleepGoalHours = 8.0

  public static func week(
    startingAt weekStart: Date, food: [FoodEntry], sleep: [SleepEntry], targets: NutritionTargets?,
    sleepGoalHours: Double = defaultSleepGoalHours, now: Date = .now, calendar: Calendar = .current
  ) -> HealthWeek {
    let start = startOfWeek(weekStart, calendar: calendar)
    let today = dateOnly(now, calendar: calendar)
    let sleepTarget = sleepGoalHours * 3600
    let days = (0..<7).map { offset -> HealthDay in
      let day = addDays(start, offset, calendar: calendar)
      let dayFood = entries(food, on: day, calendar: calendar)
      let totals = DayTotals.of(dayFood)
      let slept = totalSleep(sleep, endingOn: day, calendar: calendar)
      func state(_ met: Bool?) -> GoalStatus {
        guard let met else { return .noTarget }
        if day > today { return .upcoming }
        if met { return .reached }
        return day == today ? .inProgress : .missed
      }
      let proteinMet = targets.map { totals.proteinGrams >= Double($0.proteinGrams) }
      let caloriesMet = targets.map { target -> Bool in
        let goal = Double(target.calories)
        return totals.calories >= goal * (1 - calorieTolerance) && totals.calories <= goal * (1 + calorieTolerance)
      }
      // Today's calories can still be "short"; they only become a miss once the day is over,
      // and going over the range is a miss right away.
      var caloriesStatus = state(caloriesMet)
      if day == today, let target = targets, totals.calories > Double(target.calories) * (1 + calorieTolerance) {
        caloriesStatus = .missed
      }
      return HealthDay(
        date: day, proteinGrams: totals.proteinGrams, calories: totals.calories, sleepSeconds: slept,
        entries: dayFood.count, proteinTarget: targets?.proteinGrams, calorieTarget: targets?.calories,
        sleepTargetSeconds: sleepTarget,
        status: GoalStatuses(protein: state(proteinMet), calories: caloriesStatus, sleep: state(slept >= sleepTarget)))
    }
    return HealthWeek(start: start, days: days)
  }
}
