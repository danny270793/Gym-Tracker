import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/exercises/domain/entities/exercise_entity.dart';
import '../features/exercises/domain/entities/muscle_group.dart';
import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/exercises/presentation/cubit/exercises_state.dart';
import '../widgets/exercise_thumbnail.dart';
import '../widgets/gym_labels.dart';
import '../widgets/section_header.dart';
import 'home_shell.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  String _query = '';
  MuscleGroup? _muscle;

  /// Search lives in the app bar and only opens on demand.
  bool _searching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch() => setState(() => _searching = true);

  void _closeSearch() => setState(() {
    _searching = false;
    _query = '';
    _searchController.clear();
  });

  bool _matches(ExerciseEntity e) {
    // Chips filter by the muscles trained directly, not secondary ones.
    if (_muscle != null && !e.primaryMuscles.contains(_muscle)) return false;
    return _query.isEmpty ||
        e.name.toLowerCase().contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      // Back closes the search first, like other Android apps.
      canPop: !_searching,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _searching) _closeSearch();
      },
      child: Scaffold(
        appBar: _searching
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  onPressed: _closeSearch,
                ),
                title: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: l10n.searchExercises,
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                actions: [
                  if (_query.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      onPressed: () => setState(() {
                        _query = '';
                        _searchController.clear();
                      }),
                    ),
                ],
              )
            : AppBar(
                title: Text(l10n.navExercises),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    tooltip: l10n.searchExercises,
                    onPressed: _openSearch,
                  ),
                  const SettingsAction(),
                ],
              ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'new-exercise',
          onPressed: () => context.push('/exercise/new'),
          icon: const Icon(Icons.add),
          label: Text(l10n.newExercise),
        ),
        body: BlocBuilder<ExercisesCubit, ExercisesState>(
          builder: (context, state) {
            if (state is ExercisesLoading || state is ExercisesInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ExercisesError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: l10n.loadError,
                action: FilledButton(
                  onPressed: () => context.read<ExercisesCubit>().load(),
                  child: Text(l10n.retry),
                ),
              );
            }
            if (state.exercises.isEmpty) {
              return EmptyState(
                icon: Icons.fitness_center_outlined,
                title: l10n.exercisesEmptyTitle,
                message: l10n.exercisesEmptyBody,
              );
            }
            final used = <MuscleGroup>{
              for (final e in state.exercises) ...e.primaryMuscles,
            };
            final items = state.exercises.where(_matches).toList();
            return Column(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      for (final m in MuscleGroup.values.where(used.contains))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(muscleLabel(l10n, m)),
                            selected: _muscle == m,
                            onSelected: (sel) =>
                                setState(() => _muscle = sel ? m : null),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? Center(child: Text(l10n.noResults))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final e = items[i];
                            return ListTile(
                              leading: ExerciseThumbnail.orNull(e),
                              title: Text(e.name),
                              subtitle: ExerciseSummary(exercise: e),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/exercise/${e.id}'),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
