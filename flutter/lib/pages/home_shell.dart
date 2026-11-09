import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_tracker/l10n/app_localizations.dart';

import '../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../features/plan/presentation/cubit/plan_cubit.dart';
import '../features/workouts/presentation/cubit/workouts_cubit.dart';

/// Bottom navigation for the four main tabs. Each tab keeps its own stack.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _OfflineBanner(),
          NavigationBar(
            selectedIndex: shell.currentIndex,
            onDestinationSelected: (i) =>
                shell.goBranch(i, initialLocation: i == shell.currentIndex),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.insights_outlined),
                selectedIcon: const Icon(Icons.insights),
                label: l10n.navDashboard,
              ),
              NavigationDestination(
                icon: const Icon(Icons.event_note_outlined),
                selectedIcon: const Icon(Icons.event_note),
                label: l10n.navWorkouts,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_view_week_outlined),
                selectedIcon: const Icon(Icons.calendar_view_week),
                label: l10n.navPlan,
              ),
              NavigationDestination(
                icon: const Icon(Icons.fitness_center_outlined),
                selectedIcon: const Icon(Icons.fitness_center),
                label: l10n.navExercises,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shown while any list is the offline copy of the last successful read.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    final offline =
        context.select((ExercisesCubit c) => c.state.fromCache) ||
        context.select((PlanCubit c) => c.state.fromCache) ||
        context.select((WorkoutsCubit c) => c.state.fromCache);
    if (!offline) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.cloud_off, color: scheme.onTertiaryContainer),
        title: Text(
          l10n.offlineBanner,
          style: TextStyle(color: scheme.onTertiaryContainer),
        ),
        trailing: TextButton(
          onPressed: () {
            context.read<ExercisesCubit>().load();
            context.read<PlanCubit>().load();
            context.read<WorkoutsCubit>().load();
          },
          child: Text(l10n.retry),
        ),
      ),
    );
  }
}

/// App bar action that opens Settings; shared by the tab pages.
class SettingsAction extends StatelessWidget {
  const SettingsAction({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.settings_outlined),
    tooltip: AppLocalizations.of(context)!.settings,
    onPressed: () => context.push('/settings'),
  );
}
