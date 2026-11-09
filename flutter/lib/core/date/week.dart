/// Week helpers. Weeks start on Monday ([DateTime.monday] == 1).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime startOfWeek(DateTime d) {
  final day = dateOnly(d);
  return DateTime(
    day.year,
    day.month,
    day.day - (day.weekday - DateTime.monday),
  );
}

/// Adds whole calendar days (DST-safe, unlike adding a [Duration]).
DateTime addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// The seven weekdays in display order: Monday..Sunday.
const List<int> weekdays = [
  DateTime.monday,
  DateTime.tuesday,
  DateTime.wednesday,
  DateTime.thursday,
  DateTime.friday,
  DateTime.saturday,
  DateTime.sunday,
];
