import 'package:equatable/equatable.dart';

/// Which routine to do on each weekday ([DateTime.monday]..[DateTime.sunday]).
/// A missing weekday is a rest day.
class WeeklyPlanEntity extends Equatable {
  final Map<int, String> routineIdByWeekday;

  const WeeklyPlanEntity({this.routineIdByWeekday = const {}});

  String? routineIdFor(int weekday) => routineIdByWeekday[weekday];

  /// Number of training days per week.
  int get trainingDays => routineIdByWeekday.length;

  WeeklyPlanEntity withDay(int weekday, String? routineId) {
    final next = Map<int, String>.of(routineIdByWeekday);
    if (routineId == null) {
      next.remove(weekday);
    } else {
      next[weekday] = routineId;
    }
    return WeeklyPlanEntity(routineIdByWeekday: next);
  }

  /// Clears every day that points at [routineId] (e.g. after deleting it).
  WeeklyPlanEntity withoutRoutine(String routineId) => WeeklyPlanEntity(
    routineIdByWeekday: {
      for (final e in routineIdByWeekday.entries)
        if (e.value != routineId) e.key: e.value,
    },
  );

  factory WeeklyPlanEntity.fromJson(Map<String, dynamic> json) {
    final days = json['days'];
    final map = <int, String>{};
    if (days is Map) {
      for (final e in days.entries) {
        final day = int.tryParse('${e.key}');
        if (day != null && day >= 1 && day <= 7 && e.value is String) {
          map[day] = e.value as String;
        }
      }
    }
    return WeeklyPlanEntity(routineIdByWeekday: map);
  }

  Map<String, dynamic> toJson() => {
    'days': {for (final e in routineIdByWeekday.entries) '${e.key}': e.value},
  };

  @override
  List<Object?> get props => [routineIdByWeekday];
}
