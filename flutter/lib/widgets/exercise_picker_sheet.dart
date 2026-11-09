import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/exercises/presentation/cubit/exercises_state.dart';
import 'exercise_thumbnail.dart';
import 'gym_labels.dart';

/// Lets the user pick a saved exercise or create one. Resolves to its id.
Future<String?> showExercisePickerSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => _ExercisePickerBody(
        scrollController: controller,
        hostContext: context,
      ),
    ),
  );
}

class _ExercisePickerBody extends StatefulWidget {
  const _ExercisePickerBody({
    required this.scrollController,
    required this.hostContext,
  });

  final ScrollController scrollController;
  final BuildContext hostContext;

  @override
  State<_ExercisePickerBody> createState() => _ExercisePickerBodyState();
}

class _ExercisePickerBodyState extends State<_ExercisePickerBody> {
  String _query = '';

  bool _matches(AppLocalizations l10n, ExerciseEntity e) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return e.name.toLowerCase().contains(q) ||
        e.primaryMuscles.any(
          (m) => muscleLabel(l10n, m).toLowerCase().contains(q),
        );
  }

  Future<void> _createNew() async {
    final id = await context.push<String>('/exercise/new');
    if (id != null && mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return BlocBuilder<ExercisesCubit, ExercisesState>(
      builder: (context, state) {
        final items = state.exercises.where((e) => _matches(l10n, e)).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.pickExerciseTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _createNew,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.newExercise),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SearchBar(
                hintText: l10n.searchExercises,
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.exercises.isEmpty
                              ? l10n.exercisesEmptyTitle
                              : l10n.noResults,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final e = items[i];
                        return ListTile(
                          leading: ExerciseThumbnail.orNull(e, size: 40),
                          title: Text(e.name),
                          subtitle: ExerciseSummary(exercise: e),
                          onTap: () => Navigator.of(context).pop(e.id),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
