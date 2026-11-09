import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/logger/app_logger.dart';
import '../../domain/entities/routine_entity.dart';
import '../../domain/usecases/delete_routine_usecase.dart';
import '../../domain/usecases/get_plan_usecase.dart';
import '../../domain/usecases/save_routine_usecase.dart';
import '../../domain/usecases/set_plan_day_usecase.dart';
import 'plan_state.dart';

class PlanCubit extends Cubit<PlanState> {
  final GetPlanUsecase _getPlan;
  final SaveRoutineUsecase _saveRoutine;
  final DeleteRoutineUsecase _deleteRoutine;
  final SetPlanDayUsecase _setPlanDay;

  static const _uuid = Uuid();

  PlanCubit({
    required GetPlanUsecase getPlan,
    required SaveRoutineUsecase saveRoutine,
    required DeleteRoutineUsecase deleteRoutine,
    required SetPlanDayUsecase setPlanDay,
  }) : _getPlan = getPlan,
       _saveRoutine = saveRoutine,
       _deleteRoutine = deleteRoutine,
       _setPlanDay = setPlanDay,
       super(const PlanInitial());

  /// Saves can finish after the cubit is closed (e.g. a page's debounced save
  /// right after sign-out recreated the per-user cubits).
  @override
  void emit(PlanState state) {
    if (!isClosed) super.emit(state);
  }

  static List<RoutineEntity> _sorted(Iterable<RoutineEntity> list) =>
      list.toList()..sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );

  Future<void> load() async {
    AppLogger.debug('loading plan');
    emit(const PlanLoading());
    try {
      final result = await _getPlan();
      final (routines, plan) = result.value;
      AppLogger.info('plan loaded: ${routines.length} routines');
      emit(PlanLoaded(_sorted(routines), plan, fromCache: result.fromCache));
    } catch (e, s) {
      AppLogger.error('failed to load plan', e, s);
      emit(const PlanError());
    }
  }

  /// Creates when [id] is null, otherwise updates. Returns null on failure.
  Future<RoutineEntity?> saveRoutine({
    String? id,
    required String title,
    String? notes,
    required List<PlannedExercise> exercises,
  }) async {
    final now = DateTime.now();
    final existing = state.routineById(id);
    final routine = RoutineEntity(
      id: id ?? _uuid.v4(),
      title: title.trim(),
      notes: (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
      exercises: exercises,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      final saved = await _saveRoutine(routine);
      AppLogger.info('routine saved: ${saved.id}');
      emit(
        PlanLoaded(
          _sorted([...state.routines.where((r) => r.id != saved.id), saved]),
          state.weeklyPlan,
        ),
      );
      return saved;
    } catch (e, s) {
      AppLogger.error('failed to save routine', e, s);
      emit(
        PlanActionError(
          state.routines,
          state.weeklyPlan,
          fromCache: state.fromCache,
        ),
      );
      return null;
    }
  }

  Future<bool> deleteRoutine({required String id}) async {
    try {
      final plan = await _deleteRoutine(id: id);
      AppLogger.info('routine deleted: $id');
      emit(PlanLoaded(state.routines.where((r) => r.id != id).toList(), plan));
      return true;
    } catch (e, s) {
      AppLogger.error('failed to delete routine', e, s);
      emit(
        PlanActionError(
          state.routines,
          state.weeklyPlan,
          fromCache: state.fromCache,
        ),
      );
      return false;
    }
  }

  Future<void> setDay({
    required int weekday,
    required String? routineId,
  }) async {
    try {
      final plan = await _setPlanDay(weekday: weekday, routineId: routineId);
      AppLogger.info('plan day $weekday -> $routineId');
      emit(PlanLoaded(state.routines, plan));
    } catch (e, s) {
      AppLogger.error('failed to set plan day', e, s);
      emit(
        PlanActionError(
          state.routines,
          state.weeklyPlan,
          fromCache: state.fromCache,
        ),
      );
    }
  }
}
