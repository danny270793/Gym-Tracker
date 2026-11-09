import 'package:flutter/widgets.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../features/exercises/domain/entities/equipment.dart';
import '../features/exercises/domain/entities/muscle_group.dart';

String muscleLabel(AppLocalizations l10n, MuscleGroup m) => switch (m) {
  MuscleGroup.chest => l10n.muscleChest,
  MuscleGroup.shoulders => l10n.muscleShoulders,
  MuscleGroup.triceps => l10n.muscleTriceps,
  MuscleGroup.biceps => l10n.muscleBiceps,
  MuscleGroup.forearms => l10n.muscleForearms,
  MuscleGroup.upperBack => l10n.muscleUpperBack,
  MuscleGroup.lats => l10n.muscleLats,
  MuscleGroup.traps => l10n.muscleTraps,
  MuscleGroup.lowerBack => l10n.muscleLowerBack,
  MuscleGroup.abs => l10n.muscleAbs,
  MuscleGroup.obliques => l10n.muscleObliques,
  MuscleGroup.glutes => l10n.muscleGlutes,
  MuscleGroup.quads => l10n.muscleQuads,
  MuscleGroup.hamstrings => l10n.muscleHamstrings,
  MuscleGroup.adductors => l10n.muscleAdductors,
  MuscleGroup.calves => l10n.muscleCalves,
};

String equipmentLabel(AppLocalizations l10n, Equipment e) => switch (e) {
  Equipment.barbell => l10n.equipmentBarbell,
  Equipment.dumbbell => l10n.equipmentDumbbell,
  Equipment.machine => l10n.equipmentMachine,
  Equipment.cable => l10n.equipmentCable,
  Equipment.smithMachine => l10n.equipmentSmithMachine,
  Equipment.kettlebell => l10n.equipmentKettlebell,
  Equipment.band => l10n.equipmentBand,
  Equipment.bodyweight => l10n.equipmentBodyweight,
  Equipment.other => l10n.equipmentOther,
};

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toLanguageTag();

String _capitalize(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// "Monday" for [DateTime.monday], in the app language.
String weekdayName(BuildContext context, int weekday) {
  // 2024-01-01 was a Monday.
  final date = DateTime(2024, 1, weekday);
  return _capitalize(DateFormat.EEEE(_locale(context)).format(date));
}

String weekdayShort(BuildContext context, int weekday) {
  final date = DateTime(2024, 1, weekday);
  return _capitalize(DateFormat.E(_locale(context)).format(date));
}

/// "Mon, Nov 8".
String formatDay(BuildContext context, DateTime d) =>
    _capitalize(DateFormat.MMMEd(_locale(context)).format(d));

/// "Nov 8".
String formatShortDate(BuildContext context, DateTime d) =>
    DateFormat.MMMd(_locale(context)).format(d);

/// 12,500 -> "12.5K".
String formatCompact(BuildContext context, num value) =>
    NumberFormat.compact(locale: _locale(context)).format(value);

String formatInt(BuildContext context, num value) =>
    NumberFormat.decimalPattern(_locale(context)).format(value);

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m.toString().padLeft(2, '0')}m' : '${m}m';
}
