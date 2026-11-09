import 'package:flutter/widgets.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/domain/entities/load_type.dart';

/// Formats and parses a set's load for one exercise: pounds shown in the
/// user's lb/kg for weight exercises, a plain disc count for stack exercises.
class LoadDisplay {
  const LoadDisplay._(this.type, this.unit, this._discs);

  factory LoadDisplay.of(BuildContext context, ExerciseEntity? exercise) =>
      LoadDisplay._(
        exercise?.loadType ?? LoadType.weight,
        getIt<AppWeightUnitController>().unit,
        AppLocalizations.of(context)!.discsShort,
      );

  final LoadType type;
  final WeightUnit unit;
  final String _discs;

  bool get isDiscs => type == LoadType.discs;

  String get symbol => isDiscs ? _discs : unit.symbol;

  /// Stored value -> number shown to the user.
  double toDisplay(double stored) => isDiscs ? stored : unit.fromLb(stored);

  /// Number typed by the user -> stored value.
  double fromInput(double value) => isDiscs ? value : unit.toLb(value);

  String format(double stored) => WeightUnit.formatNumber(toDisplay(stored));

  String withSymbol(double stored) => '${format(stored)} $symbol';
}
