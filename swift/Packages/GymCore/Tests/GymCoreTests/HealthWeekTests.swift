import Foundation
import GymCore
import Testing

// Wed 11 Mar 2026; the week starts Mon 9 Mar.
private let now = date(2026, 3, 11, 20)
private let targets = NutritionTargets(bmr: 1700, maintenance: 2500, calories: 2500, proteinGrams: 150)

private func food(_ day: Int, protein: Double, calories: Double) -> FoodEntry {
  FoodEntry(date: date(2026, 3, day, 12), meal: .lunch, proteinGrams: protein, calories: calories, details: "")
}

private func night(_ startDay: Int, hours: Double) -> SleepEntry {
  let start = date(2026, 3, startDay, 23)
  return SleepEntry(start: start, end: start.addingTimeInterval(hours * 3600))
}

@Test func monToSunWithStatuses() {
  let week = HealthWeekCalculator.week(
    startingAt: now,
    food: [
      food(9, protein: 160, calories: 2450),  // reached both
      food(10, protein: 90, calories: 1500),  // missed both
    ],
    sleep: [night(8, hours: 8), night(9, hours: 6)],
    targets: targets, now: now)
  #expect(week.start == date(2026, 3, 9))
  #expect(week.days.count == 7)
  let mon = week.days[0]
  #expect(mon.status.protein == .reached)
  #expect(mon.status.calories == .reached)
  #expect(mon.status.sleep == .reached)
  #expect(mon.allReached)
  let tue = week.days[1]
  #expect(tue.status.protein == .missed)
  #expect(tue.status.calories == .missed)
  #expect(tue.status.sleep == .missed)
  // Wednesday is today with nothing logged: still in progress.
  #expect(week.days[2].status.protein == .inProgress)
  #expect(week.days[2].status.sleep == .inProgress)
  // Thursday onward has not happened.
  #expect(week.days[3].status.protein == .upcoming)
}

@Test func overTheCalorieRangeIsAMissEvenToday() {
  let week = HealthWeekCalculator.week(
    startingAt: now, food: [food(11, protein: 100, calories: 3200)], sleep: [], targets: targets, now: now)
  #expect(week.days[2].status.calories == .missed)
  #expect(week.days[2].status.protein == .inProgress)
}

@Test func noTargetsMeansNoGoalStatusButSleepStillCounts() {
  let week = HealthWeekCalculator.week(
    startingAt: now, food: [food(9, protein: 100, calories: 1800)], sleep: [night(8, hours: 9)], targets: nil, now: now)
  #expect(week.days[0].status.protein == .noTarget)
  #expect(week.days[0].status.calories == .noTarget)
  #expect(week.days[0].status.sleep == .reached)
  #expect(week.days[0].allReached)
}

@Test func summaryCountsAndAverages() {
  let week = HealthWeekCalculator.week(
    startingAt: now,
    food: [food(9, protein: 160, calories: 2500), food(10, protein: 80, calories: 2000)],
    sleep: [night(8, hours: 8), night(9, hours: 6)], targets: targets, now: now)
  let protein = week.reachedCount(\.status.protein)
  #expect(protein.reached == 1)
  #expect(protein.total == 2)  // Mon + Tue are over; Wed is still in progress
  #expect(week.averageProtein() == 120.0)
  #expect(week.averageSleep() == 25_200.0)
}

@Test func customSleepGoal() {
  let week = HealthWeekCalculator.week(
    startingAt: now, food: [], sleep: [night(8, hours: 7)], targets: nil, sleepGoalHours: 7, now: now)
  #expect(week.days[0].status.sleep == .reached)
}
