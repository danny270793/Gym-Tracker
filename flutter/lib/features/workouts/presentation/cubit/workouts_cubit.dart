import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/logger/app_logger.dart';
import '../../../plan/domain/entities/routine_entity.dart';
import '../../domain/entities/workout_entity.dart';
import '../../domain/usecases/build_workout_usecase.dart';
import '../../domain/usecases/delete_workout_usecase.dart';
import '../../domain/usecases/get_workouts_usecase.dart';
import '../../domain/usecases/save_workout_usecase.dart';
import 'workouts_state.dart';

class WorkoutsCubit extends Cubit<WorkoutsState> {
  final GetWorkoutsUsecase _getWorkouts;
  final SaveWorkoutUsecase _saveWorkout;
  final DeleteWorkoutUsecase _deleteWorkout;
  final BuildWorkoutUsecase _buildWorkout;

  WorkoutsCubit({
    required GetWorkoutsUsecase getWorkouts,
    required SaveWorkoutUsecase saveWorkout,
    required DeleteWorkoutUsecase deleteWorkout,
    required BuildWorkoutUsecase buildWorkout,
  }) : _getWorkouts = getWorkouts,
       _saveWorkout = saveWorkout,
       _deleteWorkout = deleteWorkout,
       _buildWorkout = buildWorkout,
       super(const WorkoutsInitial());

  /// Saves can finish after the cubit is closed (e.g. a page's debounced save
  /// right after sign-out recreated the per-user cubits).
  @override
  void emit(WorkoutsState state) {
    if (!isClosed) super.emit(state);
  }

  BuildWorkoutUsecase get builder => _buildWorkout;

  static List<WorkoutEntity> _sorted(Iterable<WorkoutEntity> list) =>
      list.toList()..sort((a, b) => b.date.compareTo(a.date));

  Future<void> load() async {
    AppLogger.debug('loading workouts');
    emit(const WorkoutsLoading());
    try {
      final result = await _getWorkouts();
      AppLogger.info('workouts loaded: ${result.value.length}');
      emit(WorkoutsLoaded(_sorted(result.value), fromCache: result.fromCache));
    } catch (e, s) {
      AppLogger.error('failed to load workouts', e, s);
      emit(const WorkoutsError());
    }
  }

  /// Creates and stores a workout prefilled from [routine]. Returns null on failure.
  Future<WorkoutEntity?> start({
    required DateTime date,
    required String title,
    RoutineEntity? routine,
  }) {
    final workout = _buildWorkout(
      date: date,
      title: title,
      routine: routine,
      history: state.workouts,
    );
    return save(workout);
  }

  Future<WorkoutEntity?> save(WorkoutEntity workout) async {
    final current = state.workouts;
    try {
      final saved = await _saveWorkout(workout);
      emit(
        WorkoutsLoaded(
          _sorted([...current.where((w) => w.id != saved.id), saved]),
        ),
      );
      return saved;
    } catch (e, s) {
      AppLogger.error('failed to save workout', e, s);
      emit(WorkoutsActionError(current, fromCache: state.fromCache));
      return null;
    }
  }

  Future<bool> delete({required String id}) async {
    final current = state.workouts;
    try {
      await _deleteWorkout(id: id);
      AppLogger.info('workout deleted: $id');
      emit(WorkoutsLoaded(current.where((w) => w.id != id).toList()));
      return true;
    } catch (e, s) {
      AppLogger.error('failed to delete workout', e, s);
      emit(WorkoutsActionError(current, fromCache: state.fromCache));
      return false;
    }
  }
}
