import 'package:flutter/material.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/domain/entities/muscle_group.dart';
import 'gym_labels.dart';
import 'stored_image.dart';

/// First reference image of [exercise], or a dumbbell icon.
///
/// Lists use [ExerciseThumbnail.orNull] instead: the placeholder looks the
/// same on every row, so rows without a photo show no leading widget.
class ExerciseThumbnail extends StatelessWidget {
  const ExerciseThumbnail({super.key, required this.exercise, this.size = 48});

  final ExerciseEntity? exercise;
  final double size;

  /// A thumbnail when [exercise] has a photo, otherwise null.
  static Widget? orNull(ExerciseEntity? exercise, {double size = 48}) =>
      (exercise?.imagePaths.isEmpty ?? true)
      ? null
      : ExerciseThumbnail(exercise: exercise, size: size);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = exercise?.imagePaths.firstOrNull;
    final placeholder = Container(
      width: size,
      height: size,
      color: scheme.secondaryContainer,
      child: Icon(
        Icons.fitness_center_rounded,
        size: size * 0.5,
        color: scheme.onSecondaryContainer,
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: image == null
          ? placeholder
          : StoredImage(
              path: image,
              width: size,
              height: size,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
            ),
    );
  }
}

/// "Cable · **Triceps** · Shoulders": equipment, then the muscles trained
/// directly (emphasized), then the secondary muscles.
class ExerciseSummary extends StatelessWidget {
  const ExerciseSummary({super.key, required this.exercise});

  final ExerciseEntity exercise;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    String muscles(Iterable<MuscleGroup> list) =>
        list.map((m) => muscleLabel(l10n, m)).join(', ');
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: equipmentLabel(l10n, exercise.equipment)),
          if (exercise.primaryMuscles.isNotEmpty) ...[
            const TextSpan(text: ' · '),
            TextSpan(
              text: muscles(exercise.primaryMuscles),
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (exercise.secondaryMuscles.isNotEmpty) ...[
            const TextSpan(text: ' · '),
            TextSpan(text: muscles(exercise.secondaryMuscles)),
          ],
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
