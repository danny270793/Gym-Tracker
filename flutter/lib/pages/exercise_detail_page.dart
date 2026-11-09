import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/dashboard/domain/usecases/compute_dashboard_stats_usecase.dart';
import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../features/workouts/domain/usecases/build_workout_usecase.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gym_labels.dart';
import '../widgets/stored_image.dart';
import '../widgets/load_display.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

class ExerciseDetailPage extends StatelessWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});

  final String exerciseId;

  Future<void> _delete(BuildContext context, ExerciseEntity exercise) async {
    final l10n = AppLocalizations.of(context)!;
    final usedBy = context
        .read<PlanCubit>()
        .state
        .routines
        .where((r) => r.exercises.any((p) => p.exerciseId == exercise.id))
        .map((r) => r.title)
        .toList();
    if (usedBy.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.exerciseInUseTitle),
          content: Text(l10n.exerciseInUseMessage(usedBy.join(', '))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.ok),
            ),
          ],
        ),
      );
      return;
    }
    final ok = await confirmDelete(
      context,
      title: l10n.deleteExerciseTitle,
      message: l10n.deleteExerciseMessage(exercise.name),
    );
    if (!ok || !context.mounted) return;
    final deleted = await context.read<ExercisesCubit>().delete(
      id: exercise.id,
    );
    if (!context.mounted) return;
    if (deleted) {
      context.pop();
    } else {
      showSnack(context, l10n.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cubit = context.watch<ExercisesCubit>();
    final exercise = cubit.state.byId(exerciseId);
    if (exercise == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off, title: l10n.exerciseNotFound),
      );
    }
    final load = LoadDisplay.of(context, exercise);
    final workouts = context.watch<WorkoutsCubit>().state.workouts;
    final pr = ComputeDashboardStatsUsecase.personalRecords(workouts)
        .where((p) => p.exerciseId == exerciseId)
        .firstOrNull;
    final lastSets = BuildWorkoutUsecase.lastSets(exerciseId, workouts);
    final sessions = workouts
        .where((w) => w.exercises.any((e) => e.exerciseId == exerciseId))
        .length;
    final routines = context
        .watch<PlanCubit>()
        .state
        .routines
        .where((r) => r.exercises.any((p) => p.exerciseId == exerciseId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/exercise/$exerciseId/edit'),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, exercise),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (exercise.imagePaths.isNotEmpty)
            SizedBox(
              height: 280,
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                children: [
                  for (final name in exercise.imagePaths)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: GestureDetector(
                        onTap: () => _openImage(context, cubit, name),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: StoredImage(path: name),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.handyman_outlined, size: 18),
                  label: Text(equipmentLabel(l10n, exercise.equipment)),
                ),
                for (final m in exercise.primaryMuscles)
                  Chip(
                    backgroundColor: scheme.primaryContainer,
                    label: Text(muscleLabel(l10n, m)),
                  ),
                for (final m in exercise.secondaryMuscles)
                  Chip(label: Text(muscleLabel(l10n, m))),
              ],
            ),
          ),
          if (exercise.notes != null) ...[
            SectionHeader(l10n.exerciseNotesLabel),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SelectableText(
                exercise.notes!,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
              ),
            ),
          ],
          SectionHeader(l10n.yourStats),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: StatGrid(
              children: [
                StatTile(
                  icon: Icons.emoji_events_outlined,
                  label: l10n.bestE1rm,
                  value: pr == null ? '—' : load.withSymbol(pr.e1rm),
                  caption: pr == null
                      ? null
                      : '${load.format(pr.load)} × ${pr.reps}',
                ),
                StatTile(
                  icon: Icons.history,
                  label: l10n.lastSession,
                  value: lastSets.isEmpty
                      ? '—'
                      : load.withSymbol(
                          lastSets
                              .map((s) => s.load)
                              .reduce((a, b) => a > b ? a : b),
                        ),
                  caption: lastSets.isEmpty
                      ? null
                      : lastSets.map((s) => '${s.reps}').join(' / '),
                ),
                StatTile(
                  icon: Icons.event_repeat_outlined,
                  label: l10n.sessions,
                  value: '$sessions',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: OutlinedButton.icon(
              onPressed: sessions == 0
                  ? null
                  : () => context.push('/exercise/$exerciseId/progress'),
              icon: const Icon(Icons.show_chart),
              label: Text(l10n.viewProgress),
            ),
          ),
          SectionHeader(l10n.usedInRoutines),
          if (routines.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.notUsedInRoutines),
            ),
          for (final r in routines)
            ListTile(
              leading: const Icon(Icons.list_alt_rounded),
              title: Text(r.title),
              subtitle: Text(
                r.exercises
                    .where((p) => p.exerciseId == exerciseId)
                    .map((p) => '${p.sets}×${p.reps}')
                    .join(', '),
              ),
              onTap: () => context.push('/routine/${r.id}'),
            ),
        ],
      ),
    );
  }

  void _openImage(BuildContext context, ExercisesCubit cubit, String name) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              maxScale: 5,
              child: StoredImage(path: name, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
