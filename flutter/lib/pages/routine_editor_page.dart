import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/plan/domain/entities/routine_entity.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/exercise_picker_sheet.dart';
import '../widgets/exercise_thumbnail.dart';
import '../widgets/load_display.dart';
import '../widgets/section_header.dart';
import 'workouts_page.dart';

/// Creates or edits a routine (a reusable day: title + planned exercises).
class RoutineEditorPage extends StatefulWidget {
  const RoutineEditorPage({super.key, this.routineId, this.assignToWeekday});

  final String? routineId;

  /// When creating from the weekly plan, assign the new routine to this day.
  final int? assignToWeekday;

  @override
  State<RoutineEditorPage> createState() => _RoutineEditorPageState();
}

class _RoutineEditorPageState extends State<RoutineEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _notes;
  late List<PlannedExercise> _items;

  /// Stable keys for list rows (exercise ids can repeat).
  late List<int> _keys;
  int _nextKey = 0;
  bool _saving = false;
  RoutineEntity? _existing;

  @override
  void initState() {
    super.initState();
    _existing = context.read<PlanCubit>().state.routineById(widget.routineId);
    _title = TextEditingController(text: _existing?.title ?? '');
    _notes = TextEditingController(text: _existing?.notes ?? '');
    _items = [...?_existing?.exercises];
    _keys = [for (final _ in _items) _nextKey++];
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _addExercise() async {
    final id = await showExercisePickerSheet(context);
    if (id == null || !mounted) return;
    setState(() {
      _items.add(PlannedExercise(exerciseId: id));
      _keys.add(_nextKey++);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final cubit = context.read<PlanCubit>();
    final saved = await cubit.saveRoutine(
      id: widget.routineId,
      title: _title.text,
      notes: _notes.text,
      exercises: _items,
    );
    if (!mounted) return;
    if (saved == null) {
      setState(() => _saving = false);
      showSnack(context, l10n.saveFailed);
      return;
    }
    final day = widget.assignToWeekday;
    if (day != null) await cubit.setDay(weekday: day, routineId: saved.id);
    if (mounted) context.pop(saved.id);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await confirmDelete(
      context,
      title: l10n.deleteRoutineTitle,
      message: l10n.deleteRoutineMessage(_existing!.title),
    );
    if (!ok || !mounted) return;
    final deleted = await context.read<PlanCubit>().deleteRoutine(
      id: _existing!.id,
    );
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
    final exercises = context.watch<ExercisesCubit>().state;
    final isNew = _existing == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? l10n.newRoutine : l10n.editRoutine),
        actions: [
          if (!isNew)
            IconButton(
              tooltip: l10n.startWorkout,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => startWorkout(context, routine: _existing),
            ),
          if (!isNew)
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          TextButton(onPressed: _saving ? null : _save, child: Text(l10n.save)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'routine-add-exercise',
        onPressed: _addExercise,
        icon: const Icon(Icons.add),
        label: Text(l10n.addExercise),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextFormField(
                controller: _title,
                autofocus: isNew,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.routineTitleLabel,
                  hintText: l10n.routineTitleHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.fieldRequired : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextFormField(
                controller: _notes,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.notes,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            SectionHeader(l10n.exercisesInRoutine),
            if (_items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(l10n.routineNoExercisesHint),
              ),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) => setState(() {
                _items.insert(to, _items.removeAt(from));
                _keys.insert(to, _keys.removeAt(from));
              }),
              children: [
                for (var i = 0; i < _items.length; i++)
                  _PlannedRow(
                    key: ValueKey(_keys[i]),
                    index: i,
                    item: _items[i],
                    name:
                        exercises.byId(_items[i].exerciseId)?.name ??
                        l10n.deletedExercise,
                    thumbnail: ExerciseThumbnail.orNull(
                      exercises.byId(_items[i].exerciseId),
                      size: 40,
                    ),
                    load: LoadDisplay.of(
                      context,
                      exercises.byId(_items[i].exerciseId),
                    ),
                    onChanged: (next) => setState(() => _items[i] = next),
                    onRemove: () => setState(() {
                      _items.removeAt(i);
                      _keys.removeAt(i);
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannedRow extends StatelessWidget {
  const _PlannedRow({
    super.key,
    required this.index,
    required this.item,
    required this.name,
    required this.thumbnail,
    required this.load,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final PlannedExercise item;
  final String name;
  final Widget? thumbnail;
  final LoadDisplay load;
  final ValueChanged<PlannedExercise> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
        child: Column(
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator),
                  ),
                ),
                if (thumbnail != null) ...[
                  thumbnail!,
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.removeExercise,
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _Stepper(
                      label: l10n.sets,
                      value: item.sets,
                      min: 1,
                      onChanged: (v) => onChanged(item.copyWith(sets: v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Stepper(
                      label: l10n.reps,
                      value: item.reps,
                      min: 1,
                      onChanged: (v) => onChanged(item.copyWith(reps: v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: TextFormField(
                      key: ValueKey('w-${load.symbol}'),
                      initialValue: item.load == null
                          ? ''
                          : load.format(item.load!),
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: load.symbol,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final parsed = double.tryParse(v.replaceAll(',', '.'));
                        onChanged(
                          item.copyWith(
                            load: () => parsed == null || parsed <= 0
                                ? null
                                : load.fromInput(parsed),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + 1),
            ),
          ],
        ),
      ],
    );
  }
}
