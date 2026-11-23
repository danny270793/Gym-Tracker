import Foundation

/// One sleep session. A nap only has a start and an end; a night also has sleep stages and wake-ups.
public struct SleepEntry: Identifiable, Sendable, Codable, Equatable {
  public var id: String
  public var start: Date
  public var end: Date
  public var isNap: Bool
  /// Share of the session spent in deep sleep, 0-100.
  public var deepPercent: Double?
  /// Share of the session spent in REM sleep, 0-100.
  public var remPercent: Double?
  /// How many times you woke up.
  public var awakenings: Int?
  /// Total minutes spent awake during the session.
  public var awakeMinutes: Int?

  // Column names in `gym_sleep_entries` ("end" is a reserved word in SQL).
  enum CodingKeys: String, CodingKey {
    case id, isNap, deepPercent, remPercent, awakenings, awakeMinutes
    case start = "startAt"
    case end = "endAt"
  }

  public init(
    id: String = UUID().uuidString.lowercased(), start: Date, end: Date, isNap: Bool = false,
    deepPercent: Double? = nil, remPercent: Double? = nil, awakenings: Int? = nil, awakeMinutes: Int? = nil
  ) {
    self.id = id
    self.start = start
    self.end = end
    self.isNap = isNap
    self.deepPercent = isNap ? nil : deepPercent
    self.remPercent = isNap ? nil : remPercent
    self.awakenings = isNap ? nil : awakenings
    self.awakeMinutes = isNap ? nil : awakeMinutes
  }

  /// Time in bed, seconds.
  public var duration: TimeInterval { max(0, end.timeIntervalSince(start)) }

  /// Time actually asleep (without the time awake), seconds.
  public var asleep: TimeInterval { max(0, duration - Double(awakeMinutes ?? 0) * 60) }

  public var isValid: Bool {
    guard end > start, duration <= 24 * 3600 else { return false }
    if let deepPercent, !(0...100).contains(deepPercent) { return false }
    if let remPercent, !(0...100).contains(remPercent) { return false }
    if (deepPercent ?? 0) + (remPercent ?? 0) > 100 { return false }
    if let awakenings, awakenings < 0 { return false }
    if let awakeMinutes, awakeMinutes < 0 || Double(awakeMinutes) * 60 > duration { return false }
    return true
  }
}

/// Sessions that ended on `day`, most recent first.
public func sleepEntries(_ all: [SleepEntry], endingOn day: Date, calendar: Calendar = .current) -> [SleepEntry] {
  all.filter { isSameDay($0.end, day, calendar: calendar) }.sorted { $0.end > $1.end }
}

/// Total time asleep for the sessions that ended on `day` (night and naps), seconds.
public func totalSleep(_ all: [SleepEntry], endingOn day: Date, calendar: Calendar = .current) -> TimeInterval {
  sleepEntries(all, endingOn: day, calendar: calendar).reduce(0) { $0 + $1.asleep }
}
