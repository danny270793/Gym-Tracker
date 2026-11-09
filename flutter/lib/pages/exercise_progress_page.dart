import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/dashboard/domain/entities/dashboard_stats.dart';
import '../features/dashboard/domain/usecases/compute_exercise_progress_usecase.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';
import '../widgets/gym_labels.dart';
import '../widgets/load_display.dart';
import '../widgets/progress_line_chart.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_tile.dart';

enum _Metric { e1rm, topWeight, volume, reps }

/// Progress of one exercise across sessions.
class ExerciseProgressPage extends StatefulWidget {
  const ExerciseProgressPage({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  State<ExerciseProgressPage> createState() => _ExerciseProgressPageState();
}

class _ExerciseProgressPageState extends State<ExerciseProgressPage> {
  _Metric _metric = _Metric.e1rm;

  double _value(ExerciseSessionPoint p, LoadDisplay load) => switch (_metric) {
    _Metric.e1rm => load.toDisplay(p.bestE1rm),
    _Metric.topWeight => load.toDisplay(p.topLoad),
    _Metric.volume => load.toDisplay(p.volume),
    _Metric.reps => p.reps.toDouble(),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exercise = context.watch<ExercisesCubit>().state.byId(
      widget.exerciseId,
    );
    final workouts = context.watch<WorkoutsCubit>().state.workouts;
    final points = getIt<ComputeExerciseProgressUsecase>()(
      exerciseId: widget.exerciseId,
      workouts: workouts,
    );

    return Scaffold(
      appBar: AppBar(title: Text(exercise?.name ?? l10n.deletedExercise)),
      body: points.isEmpty
          ? EmptyState(
              icon: Icons.show_chart,
              title: l10n.progressEmptyTitle,
              message: l10n.progressEmptyBody,
            )
          : _body(
              context,
              l10n,
              theme,
              LoadDisplay.of(context, exercise),
              points,
            ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    LoadDisplay load,
    List<ExerciseSessionPoint> points,
  ) {
    String w(double v) => load.withSymbol(v);
    final first = points.first;
    final last = points.last;
    final best = points.reduce((a, b) => a.bestE1rm >= b.bestE1rm ? a : b);
    final heaviest = points.reduce((a, b) => a.topLoad >= b.topLoad ? a : b);
    final bestVolume = points.reduce((a, b) => a.volume >= b.volume ? a : b);
    final change = first.bestE1rm > 0
        ? (last.bestE1rm - first.bestE1rm) / first.bestE1rm
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SegmentedButton<_Metric>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(value: _Metric.e1rm, label: Text(l10n.metricE1rm)),
            ButtonSegment(
              value: _Metric.topWeight,
              label: Text(l10n.metricTopWeight),
            ),
            ButtonSegment(
              value: _Metric.volume,
              label: Text(l10n.metricVolume),
            ),
            ButtonSegment(value: _Metric.reps, label: Text(l10n.reps)),
          ],
          selected: {_metric},
          onSelectionChanged: (s) => setState(() => _metric = s.first),
        ),
        const SizedBox(height: 20),
        ProgressLineChart(
          dates: [for (final p in points) p.date],
          values: [for (final p in points) _value(p, load)],
          formatValue: (v) => _metric == _Metric.volume
              ? formatCompact(context, v)
              : WeightUnit.formatNumber(v),
          formatDate: (d) => formatShortDate(context, d),
        ),
        const SizedBox(height: 20),
        StatGrid(
          children: [
            StatTile(
              icon: Icons.emoji_events_outlined,
              label: l10n.bestE1rm,
              value: w(best.bestE1rm),
              caption: formatDay(context, best.date),
            ),
            StatTile(
              icon: Icons.trending_up_rounded,
              label: l10n.progressSinceFirst,
              value: change == null
                  ? '—'
                  : '${change >= 0 ? '+' : ''}${(change * 100).round()}%',
              caption: l10n.sessionsCount(points.length),
            ),
            StatTile(
              icon: Icons.fitness_center,
              label: l10n.heaviestSet,
              value: w(heaviest.topLoad),
              caption: formatDay(context, heaviest.date),
            ),
            StatTile(
              icon: Icons.scale_outlined,
              label: l10n.bestVolume,
              value:
                  '${formatCompact(context, load.toDisplay(bestVolume.volume))} ${load.symbol}',
              caption: formatDay(context, bestVolume.date),
            ),
          ],
        ),
        SectionHeader(
          l10n.sessionsTitle,
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 4),
        ),
        for (final p in points.reversed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(formatDay(context, p.date)),
            subtitle: Text(
              '${l10n.setsCount(p.sets)} · ${l10n.repsCount(p.reps)} · '
              '${formatCompact(context, load.toDisplay(p.volume))} ${load.symbol}',
            ),
            trailing: Text(
              w(p.topLoad),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => context.push('/workout/${p.workoutId}'),
          ),
      ],
    );
  }
}
