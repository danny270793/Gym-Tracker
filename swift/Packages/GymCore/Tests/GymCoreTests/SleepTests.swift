import Foundation
import GymCore
import Testing

@Test func nightDurationAndAsleep() {
  let night = SleepEntry(
    start: date(2026, 3, 10, 23), end: date(2026, 3, 11, 7), deepPercent: 20, remPercent: 25,
    awakenings: 2, awakeMinutes: 30)
  #expect(night.duration == 8 * 3600)
  #expect(night.asleep == 7.5 * 3600)
  #expect(night.isValid)
}

@Test func napDropsNightFields() {
  let nap = SleepEntry(
    start: date(2026, 3, 11, 14), end: date(2026, 3, 11, 14, 30), isNap: true,
    deepPercent: 20, remPercent: 10, awakenings: 1, awakeMinutes: 5)
  #expect(nap.deepPercent == nil && nap.remPercent == nil)
  #expect(nap.awakenings == nil && nap.awakeMinutes == nil)
  #expect(nap.asleep == 1800)
}

@Test func sleepValidation() {
  let start = date(2026, 3, 10, 23)
  let end = date(2026, 3, 11, 7)
  #expect(!SleepEntry(start: end, end: start).isValid)
  #expect(!SleepEntry(start: start, end: end, deepPercent: 70, remPercent: 40).isValid)
  #expect(!SleepEntry(start: start, end: end, deepPercent: 120).isValid)
  #expect(!SleepEntry(start: start, end: end, awakeMinutes: 600).isValid)
}

@Test func sleepGroupedByWakeUpDay() {
  let night = SleepEntry(start: date(2026, 3, 10, 23), end: date(2026, 3, 11, 7))
  let nap = SleepEntry(start: date(2026, 3, 11, 14), end: date(2026, 3, 11, 14, 30), isNap: true)
  let older = SleepEntry(start: date(2026, 3, 9, 23), end: date(2026, 3, 10, 6))
  let day = sleepEntries([night, older, nap], endingOn: date(2026, 3, 11, 20))
  #expect(day.map(\.id) == [nap.id, night.id])
  #expect(totalSleep([night, older, nap], endingOn: date(2026, 3, 11)) == 8.5 * 3600)
}
