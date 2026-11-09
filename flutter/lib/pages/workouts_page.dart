import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/date/week.dart';
import '../core/di/injection.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/exercises/domain/entities/load_type.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/plan/domain/entities/routine_entity.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../features/workouts/domain/entities/workout_entity.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';
import '../features/workouts/presentation/cubit/workouts_state.dart';
import '../widgets/bottom_sheet_pinned_title.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gym_labels.dart';
import '../widgets/section_header.dart';
import 'home_shell.dart';

/// Starts a workout from [routine] (or empty) on [date] and opens it.
Future<void> startWorkout(
  BuildContext context, {
  RoutineEntity? routine,
  DateTime? date,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final saved = await context.read<WorkoutsCubit>().start(
    date: date ?? DateTime.now(),
    title: routine?.title ?? l10n.emptyWorkoutTitle,
    routine: routine,
  );
  if (!context.mounted) return;
  if (saved == null) {
    showSnack(context, l10n.saveFailed);
    return;
  }
  context.push('/workout/${saved.id}');
}

/// Routine chooser: every routine plus "empty workout".
Future<void> showStartWorkoutSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final routines = context.read<PlanCubit>().state.routines;
  final choice = await showModalBottomSheet<_StartChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => BottomSheetPinnedTitleScrollView(
      title: l10n.startWorkout,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in routines)
            ListTile(
              leading: const Icon(Icons.list_alt_rounded),
              title: Text(r.title),
              subtitle: Text(
                l10n.routineSummary(r.exercises.length, r.totalSets),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_StartChoice(r)),
            ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline_rounded),
            title: Text(l10n.emptyWorkoutTitle),
            subtitle: Text(l10n.emptyWorkoutHint),
            onTap: () =>
                Navigator.of(sheetContext).pop(const _StartChoice(null)),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return;
  await startWorkout(context, routine: choice.routine);
}

class _StartChoice {
  const _StartChoice(this.routine);
  final RoutineEntity? routine;
}

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navWorkouts),
        actions: const [SettingsAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'start-workout',
        onPressed: () => showStartWorkoutSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.startWorkout),
      ),
      body: BlocBuilder<WorkoutsCubit, WorkoutsState>(
        builder: (context, state) {
          if (state is WorkoutsLoading || state is WorkoutsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is WorkoutsError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.loadError,
              action: FilledButton(
                onPressed: () => context.read<WorkoutsCubit>().load(),
                child: Text(l10n.retry),
              ),
            );
          }
          final workouts = state.workouts;
          return ListenableBuilder(
            listenable: getIt<AppWeightUnitController>(),
            builder: (context, _) => ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const _TodayCard(),
                SectionHeader(l10n.history),
                if (workouts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(l10n.workoutsEmpty),
                  ),
                for (final w in workouts) _WorkoutTile(workout: w),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final plan = context.watch<PlanCubit>().state;
    final workouts = context.watch<WorkoutsCubit>().state.workouts;
    final routine = plan.routineForWeekday(now.weekday);
    final todays = workouts.where((w) => isSameDay(w.date, now)).toList();
    final inProgress = todays.where((w) => !w.isFinished).firstOrNull;
    final doneToday = todays.where((w) => w.isFinished).firstOrNull;

    final String title;
    final String subtitle;
    Widget? action;
    if (inProgress != null) {
      title = inProgress.title;
      subtitle = l10n.workoutInProgress;
      action = FilledButton.icon(
        onPressed: () => context.push('/workout/${inProgress.id}'),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.continueWorkout),
      );
    } else if (doneToday != null) {
      title = doneToday.title;
      subtitle = l10n.todayDone;
      action = OutlinedButton(
        onPressed: () => context.push('/workout/${doneToday.id}'),
        child: Text(l10n.view),
      );
    } else if (routine != null) {
      title = routine.title;
      subtitle = l10n.routineSummary(
        routine.exercises.length,
        routine.totalSets,
      );
      action = FilledButton.icon(
        onPressed: () => startWorkout(context, routine: routine),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.startWorkout),
      );
    } else {
      title = plan.weeklyPlan.trainingDays == 0 ? l10n.noPlanYet : l10n.restDay;
      subtitle = plan.weeklyPlan.trainingDays == 0
          ? l10n.noPlanYetHint
          : l10n.restDayHint;
      action = plan.weeklyPlan.trainingDays == 0
          ? OutlinedButton(
              onPressed: () => context.go('/plan'),
              child: Text(l10n.goToPlan),
            )
          : null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        elevation: 0,
        color: scheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayLabel(weekdayName(context, now.weekday)),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 12), action],
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.workout});

  final WorkoutEntity workout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final unit = getIt<AppWeightUnitController>().unit;
    final exercises = context.watch<ExercisesCubit>().state;
    return Dismissible(
      key: ValueKey('workout-${workout.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: scheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        final ok = await confirmDelete(
          context,
          title: l10n.deleteWorkoutTitle,
          message: l10n.deleteWorkoutMessage(workout.title),
        );
        if (!ok || !context.mounted) return false;
        return context.read<WorkoutsCubit>().delete(id: workout.id);
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: workout.isFinished
              ? scheme.secondaryContainer
              : scheme.tertiaryContainer,
          child: Text(
            weekdayShort(context, workout.date.weekday),
            style: TextStyle(
              fontSize: 12,
              color: workout.isFinished
                  ? scheme.onSecondaryContainer
                  : scheme.onTertiaryContainer,
            ),
          ),
        ),
        title: Text(workout.title),
        subtitle: Text(
          [
            formatDay(context, workout.date),
            l10n.setsCount(workout.completedSetCount),
            '${formatCompact(context, unit.fromLb(workout.weightVolumeLb((id) => exercises.byId(id)?.loadType != LoadType.discs)))} ${unit.symbol}',
          ].join(' · '),
        ),
        trailing: workout.isFinished
            ? const Icon(Icons.chevron_right)
            : Chip(
                label: Text(l10n.inProgress),
                visualDensity: VisualDensity.compact,
              ),
        onTap: () => context.push('/workout/${workout.id}'),
      ),
    );
  }
}
