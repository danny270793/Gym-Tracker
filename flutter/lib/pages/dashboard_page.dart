import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/dashboard/domain/entities/dashboard_stats.dart';
import '../features/dashboard/domain/usecases/compute_dashboard_stats_usecase.dart';
import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/domain/entities/muscle_group.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/exercises/presentation/cubit/exercises_state.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../features/plan/presentation/cubit/plan_state.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';
import '../features/workouts/presentation/cubit/workouts_state.dart';
import '../widgets/exercise_thumbnail.dart';
import '../widgets/gym_labels.dart';
import '../widgets/load_display.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';
import '../widgets/weekly_bar_chart.dart';
import 'home_shell.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navDashboard),
        actions: const [SettingsAction()],
      ),
      body: ListenableBuilder(
        listenable: getIt<AppWeightUnitController>(),
        builder: (context, _) {
          final workouts = context.watch<WorkoutsCubit>().state;
          final exercises = context.watch<ExercisesCubit>().state;
          final plan = context.watch<PlanCubit>().state;
          if (workouts is WorkoutsLoading ||
              workouts is WorkoutsInitial ||
              exercises is ExercisesLoading ||
              plan is PlanLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (workouts.workouts.isEmpty) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: l10n.dashboardEmptyTitle,
              message: l10n.dashboardEmptyBody,
              action: FilledButton.icon(
                onPressed: () => context.go('/workouts'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.goToWorkouts),
              ),
            );
          }
          final stats = getIt<ComputeDashboardStatsUsecase>()(
            workouts: workouts.workouts,
            exercises: exercises.exercises,
            weeklyPlan: plan.weeklyPlan,
            now: DateTime.now(),
          );
          return _DashboardBody(
            stats: stats,
            exercises: exercises,
            unit: getIt<AppWeightUnitController>().unit,
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.stats,
    required this.exercises,
    required this.unit,
  });

  final DashboardStats stats;
  final ExercisesState exercises;
  final WeightUnit unit;

  String _delta(AppLocalizations l10n, num current, num previous) {
    if (previous <= 0) return l10n.dashboardNoPreviousWeek;
    final pct = ((current - previous) / previous * 100).round();
    final sign = pct > 0 ? '+' : '';
    return l10n.dashboardVsLastWeek('$sign$pct%');
  }

  Color? _deltaColor(ColorScheme scheme, num current, num previous) {
    if (previous <= 0 || current == previous) return null;
    return current > previous ? Colors.green.shade600 : scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final week = stats.thisWeek;
    final last = stats.lastWeek;
    String vol(double lb) => formatCompact(context, unit.fromLb(lb));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SectionHeader(
          l10n.dashboardThisWeek,
          padding: const EdgeInsets.only(bottom: 10),
        ),
        StatGrid(
          children: [
            StatTile(
              icon: Icons.event_available_outlined,
              label: l10n.dashboardWorkouts,
              value: stats.plannedDaysPerWeek > 0
                  ? '${week.workouts}/${stats.plannedDaysPerWeek}'
                  : '${week.workouts}',
              caption: stats.plannedDaysPerWeek > 0
                  ? l10n.dashboardPlannedDays
                  : _delta(l10n, week.workouts, last.workouts),
            ),
            StatTile(
              icon: Icons.scale_outlined,
              label: l10n.dashboardVolume(unit.symbol),
              value: vol(week.volumeLb),
              caption: _delta(l10n, week.volumeLb, last.volumeLb),
              captionColor: _deltaColor(scheme, week.volumeLb, last.volumeLb),
            ),
            StatTile(
              icon: Icons.repeat_rounded,
              label: l10n.dashboardReps,
              value: formatInt(context, week.reps),
              caption: _delta(l10n, week.reps, last.reps),
              captionColor: _deltaColor(scheme, week.reps, last.reps),
            ),
            StatTile(
              icon: Icons.format_list_numbered_rounded,
              label: l10n.dashboardSets,
              value: formatInt(context, week.sets),
              caption: _delta(l10n, week.sets, last.sets),
              captionColor: _deltaColor(scheme, week.sets, last.sets),
            ),
            StatTile(
              icon: Icons.local_fire_department_outlined,
              label: l10n.dashboardStreak,
              value: l10n.dashboardStreakWeeks(stats.weekStreak),
              caption: l10n.dashboardTotalWorkouts(stats.totalWorkouts),
            ),
            StatTile(
              icon: Icons.timer_outlined,
              label: l10n.dashboardAvgDuration,
              value: stats.averageDuration == null
                  ? '—'
                  : formatDuration(stats.averageDuration!),
              caption: l10n.dashboardLast30Days,
            ),
          ],
        ),
        SectionHeader(
          l10n.dashboardWeeklyVolume(unit.symbol),
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            l10n.dashboardVolumeHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        WeeklyBarChart(
          values: [
            for (final w in stats.weeklyHistory) unit.fromLb(w.volumeLb),
          ],
          bottomLabels: [
            for (final w in stats.weeklyHistory)
              formatShortDate(context, w.weekStart),
          ],
          formatValue: (v) => formatCompact(context, v),
        ),
        SectionHeader(
          l10n.dashboardWeeklyReps,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 12),
        ),
        WeeklyBarChart(
          height: 140,
          values: [for (final w in stats.weeklyHistory) w.reps.toDouble()],
          bottomLabels: [
            for (final w in stats.weeklyHistory)
              formatShortDate(context, w.weekStart),
          ],
          formatValue: (v) => formatCompact(context, v),
        ),
        SectionHeader(
          l10n.dashboardMuscleSets,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
        ),
        Text(
          l10n.dashboardMuscleSetsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        if (stats.muscleSetsThisWeek.isEmpty)
          Text(l10n.dashboardNoSetsThisWeek)
        else
          _MuscleBars(entries: stats.muscleSetsThisWeek),
        SectionHeader(
          l10n.dashboardTrends,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
        ),
        Text(
          l10n.dashboardTrendsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        if (stats.trends.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.dashboardNoTrends),
          ),
        for (final t in stats.trends.take(8))
          _ExerciseRow(
            exercise: exercises.byId(t.exerciseId),
            subtitle: l10n.dashboardE1rm(
              LoadDisplay.of(
                context,
                exercises.byId(t.exerciseId),
              ).withSymbol(t.currentE1rm),
            ),
            trailing: _ChangeBadge(change: t.change),
          ),
        SectionHeader(
          l10n.dashboardPersonalRecords,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
        ),
        for (final pr in stats.personalRecords.take(10))
          _ExerciseRow(
            exercise: exercises.byId(pr.exerciseId),
            subtitle:
                '${LoadDisplay.of(context, exercises.byId(pr.exerciseId)).withSymbol(pr.load)} × ${pr.reps} · '
                '${formatDay(context, pr.date)}',
            trailing: Text(
              LoadDisplay.of(
                context,
                exercises.byId(pr.exerciseId),
              ).withSymbol(pr.e1rm),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _MuscleBars extends StatelessWidget {
  const _MuscleBars({required this.entries});

  final List<MapEntry<MuscleGroup, double>> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = entries.first.value;
    return Column(
      children: [
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    muscleLabel(l10n, e.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: max <= 0 ? 0 : e.value / max,
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    e.value == e.value.truncateToDouble()
                        ? e.value.toInt().toString()
                        : e.value.toStringAsFixed(1),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.subtitle,
    required this.trailing,
  });

  final ExerciseEntity? exercise;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ExerciseThumbnail.orNull(exercise, size: 40),
      title: Text(exercise?.name ?? l10n.deletedExercise),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: exercise == null
          ? null
          : () => context.push('/exercise/${exercise!.id}/progress'),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.change});

  final double? change;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final c = change;
    if (c == null) {
      return Chip(
        label: Text(l10n.dashboardNew),
        visualDensity: VisualDensity.compact,
      );
    }
    final pct = (c * 100).round();
    final up = pct > 0;
    final color = pct == 0
        ? scheme.onSurfaceVariant
        : up
        ? Colors.green.shade600
        : scheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          pct == 0
              ? Icons.trending_flat_rounded
              : up
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${up ? '+' : ''}$pct%',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
