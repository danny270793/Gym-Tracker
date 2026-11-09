import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../core/di/injection.dart';
import '../core/units/app_weight_unit_controller.dart';
import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/workouts/domain/entities/workout_entity.dart';
import '../features/workouts/domain/usecases/build_workout_usecase.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';
import '../features/workouts/presentation/cubit/workouts_state.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/exercise_thumbnail.dart';
import '../widgets/gym_labels.dart';
import '../widgets/load_display.dart';
import '../features/exercises/domain/entities/load_type.dart';
import '../widgets/section_header.dart';

/// Logs one training day. Starts from the plan; everything is editable.
/// Changes are saved automatically (debounced) while the page is open.
class WorkoutSessionPage extends StatefulWidget {
  const WorkoutSessionPage({super.key, required this.workoutId});

  final String workoutId;

  @override
  State<WorkoutSessionPage> createState() => _WorkoutSessionPageState();
}

class _WorkoutSessionPageState extends State<WorkoutSessionPage> {
  WorkoutEntity? _workout;
  Timer? _saveTimer;
  late final WorkoutsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<WorkoutsCubit>();
    _workout = _cubit.state.byId(widget.workoutId);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      final w = _workout;
      if (w != null) unawaited(_cubit.save(w));
    }
    super.dispose();
  }

  void _update(WorkoutEntity next, {bool immediate = false}) {
    setState(() => _workout = next);
    _saveTimer?.cancel();
    if (immediate) {
      unawaited(_cubit.save(next));
    } else {
      _saveTimer = Timer(const Duration(milliseconds: 500), () {
        unawaited(_cubit.save(next));
      });
    }
  }

  void _updateExercise(WorkoutExercise row, {bool immediate = false}) {
    final w = _workout!;
    _update(
      w.copyWith(
        exercises: [for (final e in w.exercises) e.id == row.id ? row : e],
      ),
      immediate: immediate,
    );
  }

  List<WorkoutEntity> get _history =>
      _cubit.state.workouts.where((w) => w.id != widget.workoutId).toList();

  Future<void> _addExercise() async {
    final id = await showExercisePickerSheet(context);
    if (id == null || !mounted) return;
    final row = getIt<BuildWorkoutUsecase>().adHocEntry(id, _history);
    final w = _workout!;
    _update(w.copyWith(exercises: [...w.exercises, row]), immediate: true);
  }

  void _removeExercise(WorkoutExercise row) {
    final w = _workout!;
    final index = w.exercises.indexWhere((e) => e.id == row.id);
    _update(
      w.copyWith(exercises: w.exercises.where((e) => e.id != row.id).toList()),
      immediate: true,
    );
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.exerciseRemoved),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () {
              final current = _workout!;
              final list = [...current.exercises];
              list.insert(index.clamp(0, list.length), row);
              _update(current.copyWith(exercises: list), immediate: true);
            },
          ),
        ),
      );
  }

  void _move(WorkoutExercise row, int delta) {
    final w = _workout!;
    final list = [...w.exercises];
    final i = list.indexWhere((e) => e.id == row.id);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= list.length) return;
    list.removeAt(i);
    list.insert(j, row);
    _update(w.copyWith(exercises: list), immediate: true);
  }

  Future<void> _editTitle() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _workout!.title);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workoutTitleLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.trim().isEmpty || !mounted) return;
    _update(_workout!.copyWith(title: next.trim()), immediate: true);
  }

  Future<void> _editDate() async {
    final w = _workout!;
    final picked = await showDatePicker(
      context: context,
      initialDate: w.date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    _update(
      w.copyWith(
        date: DateTime(
          picked.year,
          picked.month,
          picked.day,
          w.date.hour,
          w.date.minute,
        ),
      ),
      immediate: true,
    );
  }

  Future<void> _finish() async {
    final l10n = AppLocalizations.of(context)!;
    final w = _workout!;
    final pending = w.totalSetCount - w.completedSetCount;
    if (pending > 0) {
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.finishWorkoutTitle),
          content: Text(l10n.finishWorkoutPendingSets(pending)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('keep'),
              child: Text(l10n.finishAsIs),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop('complete'),
              child: Text(l10n.completeAll),
            ),
          ],
        ),
      );
      if (choice == null || !mounted) return;
      if (choice == 'complete') {
        _update(
          w.copyWith(
            exercises: [
              for (final e in w.exercises)
                e.copyWith(
                  sets: [for (final s in e.sets) s.copyWith(completed: true)],
                ),
            ],
          ),
          immediate: true,
        );
      }
    }
    _update(
      _workout!.copyWith(finishedAt: () => DateTime.now()),
      immediate: true,
    );
    if (!mounted) return;
    showSnack(context, l10n.workoutSaved);
    context.pop();
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmDelete(
      context,
      title: l10n.deleteWorkoutTitle,
      message: l10n.deleteWorkoutMessage(_workout!.title),
    );
    if (!ok || !mounted) return;
    _saveTimer?.cancel();
    final deleted = await _cubit.delete(id: widget.workoutId);
    if (!mounted) return;
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
    final w = _workout;
    if (w == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.search_off, title: l10n.workoutNotFound),
      );
    }
    final exercises = context.watch<ExercisesCubit>().state;
    final unit = getIt<AppWeightUnitController>().unit;

    return BlocListener<WorkoutsCubit, WorkoutsState>(
      listener: (context, state) {
        if (state is WorkoutsActionError) showSnack(context, l10n.saveFailed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            onTap: _editTitle,
            child: Text(w.title, overflow: TextOverflow.ellipsis),
          ),
          actions: [
            if (!w.isFinished)
              TextButton(onPressed: _finish, child: Text(l10n.finish)),
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'title':
                    _editTitle();
                  case 'date':
                    _editDate();
                  case 'reopen':
                    _update(
                      w.copyWith(finishedAt: () => null),
                      immediate: true,
                    );
                  case 'delete':
                    _delete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'title', child: Text(l10n.rename)),
                PopupMenuItem(value: 'date', child: Text(l10n.changeDate)),
                if (w.isFinished)
                  PopupMenuItem(
                    value: 'reopen',
                    child: Text(l10n.reopenWorkout),
                  ),
                PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add-exercise',
          onPressed: _addExercise,
          icon: const Icon(Icons.add),
          label: Text(l10n.addExercise),
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(formatDay(context, w.date)),
                    onPressed: _editDate,
                  ),
                  Chip(
                    label: Text(
                      '${l10n.setsDone(w.completedSetCount, w.totalSetCount)} · '
                      '${formatCompact(context, unit.fromLb(w.weightVolumeLb((id) => exercises.byId(id)?.loadType != LoadType.discs)))} ${unit.symbol}',
                    ),
                  ),
                  if (w.isFinished)
                    Chip(
                      avatar: const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(l10n.finished),
                    ),
                ],
              ),
            ),
            if (w.exercises.isEmpty)
              EmptyState(
                icon: Icons.playlist_add,
                title: l10n.workoutEmptyTitle,
                message: l10n.workoutEmptyBody,
              ),
            for (var i = 0; i < w.exercises.length; i++)
              _ExerciseCard(
                key: ValueKey(w.exercises[i].id),
                row: w.exercises[i],
                exercise: exercises.byId(w.exercises[i].exerciseId),
                load: LoadDisplay.of(
                  context,
                  exercises.byId(w.exercises[i].exerciseId),
                ),
                lastSets: BuildWorkoutUsecase.lastSets(
                  w.exercises[i].exerciseId,
                  _history,
                ),
                isFirst: i == 0,
                isLast: i == w.exercises.length - 1,
                onChanged: _updateExercise,
                onRemove: () => _removeExercise(w.exercises[i]),
                onMove: (d) => _move(w.exercises[i], d),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextFormField(
                initialValue: w.notes,
                minLines: 2,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _update(
                  _workout!.copyWith(notes: () => v.trim().isEmpty ? null : v),
                ),
              ),
            ),
            if (!w.isFinished)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: FilledButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.flag_outlined),
                  label: Text(l10n.finishWorkout),
                ),
              ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.autoSaved,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    super.key,
    required this.row,
    required this.exercise,
    required this.load,
    required this.lastSets,
    required this.isFirst,
    required this.isLast,
    required this.onChanged,
    required this.onRemove,
    required this.onMove,
  });

  final WorkoutExercise row;
  final ExerciseEntity? exercise;
  final LoadDisplay load;
  final List<WorkoutSet> lastSets;
  final bool isFirst;
  final bool isLast;
  final void Function(WorkoutExercise row, {bool immediate}) onChanged;
  final VoidCallback onRemove;
  final void Function(int delta) onMove;

  String _set(WorkoutSet s) =>
      s.load > 0 ? '${load.format(s.load)}×${s.reps}' : '${s.reps}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final planned = row.planned;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (ExerciseThumbnail.orNull(exercise, size: 44)
                    case final thumb?) ...[
                  thumb,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: exercise == null
                        ? null
                        : () => context.push('/exercise/${exercise!.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise?.name ?? l10n.deletedExercise,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (exercise != null)
                          Text(
                            equipmentLabel(l10n, exercise!.equipment),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          planned == null
                              ? l10n.notInPlan
                              : l10n.plannedTarget(
                                  planned.sets,
                                  planned.reps,
                                  planned.load == null
                                      ? ''
                                      : ' @ ${load.format(planned.load!)} ${load.symbol}',
                                ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                        if (lastSets.isNotEmpty)
                          Text(
                            l10n.lastTime(lastSets.map(_set).join(', ')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'up':
                        onMove(-1);
                      case 'down':
                        onMove(1);
                      case 'remove':
                        onRemove();
                    }
                  },
                  itemBuilder: (_) => [
                    if (!isFirst)
                      PopupMenuItem(value: 'up', child: Text(l10n.moveUp)),
                    if (!isLast)
                      PopupMenuItem(value: 'down', child: Text(l10n.moveDown)),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(l10n.removeExercise),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      l10n.setShort,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      load.symbol,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.reps,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            for (var i = 0; i < row.sets.length; i++)
              _SetRow(
                key: ValueKey('${row.id}-$i-${load.symbol}'),
                index: i,
                set: row.sets[i],
                load: load,
                onChanged: (s, {immediate = false}) {
                  final sets = [...row.sets];
                  sets[i] = s;
                  onChanged(row.copyWith(sets: sets), immediate: immediate);
                },
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    final last = row.sets.lastOrNull;
                    onChanged(
                      row.copyWith(
                        sets: [
                          ...row.sets,
                          (last ?? WorkoutSet(reps: planned?.reps ?? 8))
                              .copyWith(completed: false),
                        ],
                      ),
                      immediate: true,
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.addSet),
                ),
                if (row.sets.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => onChanged(
                      row.copyWith(
                        sets: row.sets.sublist(0, row.sets.length - 1),
                      ),
                      immediate: true,
                    ),
                    icon: const Icon(Icons.remove, size: 18),
                    label: Text(l10n.removeSet),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({
    super.key,
    required this.index,
    required this.set,
    required this.load,
    required this.onChanged,
  });

  final int index;
  final WorkoutSet set;
  final LoadDisplay load;
  final void Function(WorkoutSet set, {bool immediate}) onChanged;

  InputDecoration _decoration(ColorScheme scheme) => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: set.completed
        ? scheme.primaryContainer.withValues(alpha: 0.5)
        : scheme.surfaceContainerHighest,
    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: set.load > 0 ? load.format(set.load) : '',
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: _decoration(scheme).copyWith(hintText: '0'),
              onChanged: (v) {
                final parsed = double.tryParse(v.replaceAll(',', '.')) ?? 0;
                onChanged(set.copyWith(load: load.fromInput(parsed)));
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: '${set.reps}',
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration(scheme),
              onChanged: (v) =>
                  onChanged(set.copyWith(reps: int.tryParse(v) ?? 0)),
            ),
          ),
          IconButton(
            isSelected: set.completed,
            icon: const Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: scheme.primary),
            onPressed: () {
              HapticFeedback.selectionClick();
              onChanged(
                set.copyWith(completed: !set.completed),
                immediate: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
