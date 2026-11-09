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

  bool _matches(ExerciseEntity e) {
    if (_muscle != null &&
        !e.primaryMuscles.contains(_muscle) &&
        !e.secondaryMuscles.contains(_muscle)) {
      return false;
    }
    return _query.isEmpty ||
        e.name.toLowerCase().contains(_query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navExercises),
        actions: const [SettingsAction()],
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: SearchBar(
                  hintText: l10n.searchExercises,
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
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
    );
  }
}
