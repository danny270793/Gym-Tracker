/// Muscles an exercise can train. Stored by [name] in JSON, so renaming a value
/// is a data migration; adding one is not.
enum MuscleGroup {
  chest,
  shoulders,
  triceps,
  biceps,
  forearms,
  upperBack,
  lats,
  traps,
  lowerBack,
  abs,
  obliques,
  glutes,
  quads,
  hamstrings,
  adductors,
  calves;

  static MuscleGroup? fromStorage(Object? raw) {
    for (final m in values) {
      if (m.name == raw) return m;
    }
    return null;
  }
}
