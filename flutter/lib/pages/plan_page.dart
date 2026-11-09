import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/date/week.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/plan/domain/entities/routine_entity.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../features/plan/presentation/cubit/plan_state.dart';
import '../widgets/bottom_sheet_pinned_title.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/gym_labels.dart';
import '../widgets/section_header.dart';
import 'home_shell.dart';

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});

  Future<void> _pickRoutineForDay(BuildContext context, int weekday) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PlanCubit>();
    final current = cubit.state.weeklyPlan.routineIdFor(weekday);
    final scheme = Theme.of(context).colorScheme;
    final result = await showModalBottomSheet<_DayChoice>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BottomSheetPinnedTitleScrollView(
        title: weekdayName(context, weekday),
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in cubit.state.routines)
              ListTile(
                leading: const Icon(Icons.list_alt_rounded),
                title: Text(r.title),
                subtitle: Text(
                  l10n.routineSummary(r.exercises.length, r.totalSets),
                ),
                trailing: current == r.id
                    ? Icon(Icons.check, color: scheme.primary)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(_DayChoice(r.id)),
              ),
            ListTile(
              leading: const Icon(Icons.hotel_outlined),
              title: Text(l10n.restDay),
              trailing: current == null
                  ? Icon(Icons.check, color: scheme.primary)
                  : null,
              onTap: () =>
                  Navigator.of(sheetContext).pop(const _DayChoice(null)),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.newRoutine),
              onTap: () =>
                  Navigator.of(sheetContext).pop(const _DayChoice.create()),
            ),
          ],
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    if (result.create) {
      context.push('/routine/new?weekday=$weekday');
      return;
    }
    await cubit.setDay(weekday: weekday, routineId: result.routineId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navPlan),
        actions: const [SettingsAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-routine',
        onPressed: () => context.push('/routine/new'),
        icon: const Icon(Icons.add),
        label: Text(l10n.newRoutine),
      ),
      body: BlocConsumer<PlanCubit, PlanState>(
        listener: (context, state) {
          if (state is PlanActionError) {
            showSnack(context, l10n.saveFailed);
          }
        },
        builder: (context, state) {
          if (state is PlanLoading || state is PlanInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PlanError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: l10n.loadError,
              action: FilledButton(
                onPressed: () => context.read<PlanCubit>().load(),
                child: Text(l10n.retry),
              ),
            );
          }
          final today = DateTime.now().weekday;
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              SectionHeader(l10n.weeklyPlan),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  l10n.weeklyPlanHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final day in weekdays)
                _DayTile(
                  weekday: day,
                  isToday: day == today,
                  routine: state.routineForWeekday(day),
                  onTap: () => _pickRoutineForDay(context, day),
                ),
              SectionHeader(l10n.routines),
              if (state.routines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(l10n.routinesEmpty),
                ),
              for (final r in state.routines) _RoutineTile(routine: r),
            ],
          );
        },
      ),
    );
  }
}

class _DayChoice {
  const _DayChoice(this.routineId) : create = false;
  const _DayChoice.create() : routineId = null, create = true;
  final String? routineId;
  final bool create;
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.weekday,
    required this.isToday,
    required this.routine,
    required this.onTap,
  });

  final int weekday;
  final bool isToday;
  final RoutineEntity? routine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final exercises = context.watch<ExercisesCubit>().state;
    final r = routine;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isToday
            ? scheme.primary
            : r == null
            ? scheme.surfaceContainerHighest
            : scheme.secondaryContainer,
        foregroundColor: isToday
            ? scheme.onPrimary
            : r == null
            ? scheme.onSurfaceVariant
            : scheme.onSecondaryContainer,
        child: Text(weekdayShort(context, weekday)),
      ),
      title: Text(
        r == null
            ? '${weekdayName(context, weekday)} · ${l10n.restDay}'
            : '${weekdayName(context, weekday)} · ${r.title}',
      ),
      subtitle: r == null
          ? null
          : Text(
              r.exercises.isEmpty
                  ? l10n.routineNoExercises
                  : r.exercises
                        .map(
                          (p) =>
                              '${p.sets}×${p.reps} ${exercises.byId(p.exerciseId)?.name ?? l10n.deletedExercise}',
                        )
                        .join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.edit_calendar_outlined),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.routine});

  final RoutineEntity routine;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final plan = context.watch<PlanCubit>().state.weeklyPlan;
    final days = [
      for (final d in weekdays)
        if (plan.routineIdFor(d) == routine.id) weekdayShort(context, d),
    ];
    return ListTile(
      leading: const Icon(Icons.list_alt_rounded),
      title: Text(routine.title),
      subtitle: Text(
        [
          l10n.routineSummary(routine.exercises.length, routine.totalSets),
          if (days.isNotEmpty) days.join(', '),
        ].join(' · '),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/routine/${routine.id}'),
    );
  }
}
