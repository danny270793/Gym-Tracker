import Foundation

/// Week helpers. Weeks start on Monday, matching the Flutter app (`DateTime.monday == 1`).

public func dateOnly(_ date: Date, calendar: Calendar = .current) -> Date {
  calendar.startOfDay(for: date)
}

/// Monday = 1 … Sunday = 7.
public func weekdayMondayBased(_ date: Date, calendar: Calendar = .current) -> Int {
  let weekday = calendar.component(.weekday, from: date)  // Sunday = 1 … Saturday = 7
  return weekday == 1 ? 7 : weekday - 1
}

public func startOfWeek(_ date: Date, calendar: Calendar = .current) -> Date {
  let day = dateOnly(date, calendar: calendar)
  return addDays(day, -(weekdayMondayBased(day, calendar: calendar) - 1), calendar: calendar)
}

/// Adds whole calendar days (DST-safe).
public func addDays(_ date: Date, _ days: Int, calendar: Calendar = .current) -> Date {
  calendar.date(byAdding: .day, value: days, to: dateOnly(date, calendar: calendar)) ?? date
}

public func isSameDay(_ a: Date, _ b: Date, calendar: Calendar = .current) -> Bool {
  calendar.isDate(a, inSameDayAs: b)
}

/// Monday…Sunday.
public let weekdays = [1, 2, 3, 4, 5, 6, 7]

public func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, calendar: Calendar = .current) -> Date {
  var parts = DateComponents()
  parts.year = year
  parts.month = month
  parts.day = day
  parts.hour = hour
  parts.minute = minute
  return calendar.date(from: parts) ?? .distantPast
}
