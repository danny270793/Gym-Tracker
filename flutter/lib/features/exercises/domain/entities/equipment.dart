enum Equipment {
  barbell,
  dumbbell,
  machine,
  cable,
  smithMachine,
  kettlebell,
  band,
  bodyweight,
  other;

  static Equipment fromStorage(Object? raw) {
    for (final e in values) {
      if (e.name == raw) return e;
    }
    return Equipment.other;
  }
}
