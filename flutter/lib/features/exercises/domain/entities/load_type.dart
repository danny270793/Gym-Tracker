import 'equipment.dart';

/// What the number in a set means for an exercise.
enum LoadType {
  /// Pounds (shown in lb or kg). Counts toward weekly volume.
  weight,

  /// Plates on a cable/machine stack: a plain count, never converted, and
  /// kept out of the pound-based volume totals.
  discs;

  static LoadType defaultFor(Equipment equipment) => switch (equipment) {
    Equipment.cable || Equipment.machine => LoadType.discs,
    _ => LoadType.weight,
  };

  static LoadType? fromStorage(Object? raw) {
    for (final t in values) {
      if (t.name == raw) return t;
    }
    return null;
  }
}
