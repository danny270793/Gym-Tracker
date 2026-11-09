import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_session_notifier.dart';
import '../locale/app_locale_controller.dart';
import '../security/app_biometric_unlock_controller.dart';
import '../storage/legacy_local_data_migrator.dart';
import '../storage/local_json_store.dart';
import '../theme/app_theme_controller.dart';
import '../units/app_weight_unit_controller.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_usecase.dart';
import '../../features/auth/domain/usecases/sign_out_usecase.dart';
import '../../features/auth/domain/usecases/update_email_usecase.dart';
import '../../features/auth/domain/usecases/update_password_usecase.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';
import '../../features/auth/presentation/cubit/settings_cubit.dart';
import '../../features/dashboard/domain/usecases/compute_dashboard_stats_usecase.dart';
import '../../features/dashboard/domain/usecases/compute_exercise_progress_usecase.dart';
import '../../features/exercises/data/datasources/exercises_remote_datasource.dart';
import '../../features/exercises/data/repositories/exercises_repository_impl.dart';
import '../../features/exercises/domain/repositories/exercises_repository.dart';
import '../../features/exercises/domain/usecases/delete_exercise_usecase.dart';
import '../../features/exercises/domain/usecases/get_exercises_usecase.dart';
import '../../features/exercises/domain/usecases/manage_exercise_images_usecase.dart';
import '../../features/exercises/domain/usecases/save_exercise_usecase.dart';
import '../../features/exercises/presentation/cubit/exercises_cubit.dart';
import '../../features/plan/data/datasources/plan_remote_datasource.dart';
import '../../features/plan/data/repositories/plan_repository_impl.dart';
import '../../features/plan/domain/repositories/plan_repository.dart';
import '../../features/plan/domain/usecases/delete_routine_usecase.dart';
import '../../features/plan/domain/usecases/get_plan_usecase.dart';
import '../../features/plan/domain/usecases/save_routine_usecase.dart';
import '../../features/plan/domain/usecases/set_plan_day_usecase.dart';
import '../../features/plan/presentation/cubit/plan_cubit.dart';
import '../../features/workouts/data/datasources/workouts_remote_datasource.dart';
import '../../features/workouts/data/repositories/workouts_repository_impl.dart';
import '../../features/workouts/domain/repositories/workouts_repository.dart';
import '../../features/workouts/domain/usecases/build_workout_usecase.dart';
import '../../features/workouts/domain/usecases/delete_workout_usecase.dart';
import '../../features/workouts/domain/usecases/get_workouts_usecase.dart';
import '../../features/workouts/domain/usecases/save_workout_usecase.dart';
import '../../features/workouts/presentation/cubit/workouts_cubit.dart';

final getIt = GetIt.instance;

/// [store] is opened in `main` (it needs the app documents directory).
void setupDi({required LocalJsonStore store}) {
  getIt.registerLazySingleton<AppLocaleController>(AppLocaleController.new);
  getIt.registerLazySingleton<AppThemeController>(AppThemeController.new);
  getIt.registerLazySingleton<AppWeightUnitController>(
    AppWeightUnitController.new,
  );
  getIt.registerLazySingleton<AppBiometricUnlockController>(
    AppBiometricUnlockController.new,
  );

  getIt.registerSingleton<LocalJsonStore>(store);
  getIt.registerLazySingleton<AuthSessionNotifier>(
    () => AuthSessionNotifier(Supabase.instance.client),
  );
  getIt.registerLazySingleton<CurrentUser>(() => getIt<AuthSessionNotifier>());

  // auth
  getIt.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthSupabaseDatasource(Supabase.instance.client),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<AuthRemoteDatasource>(), getIt(), getIt()),
  );
  getIt.registerFactory<SignInUsecase>(() => SignInUsecase(getIt()));
  getIt.registerFactory<SignOutUsecase>(() => SignOutUsecase(getIt()));
  getIt.registerFactory<UpdateEmailUsecase>(() => UpdateEmailUsecase(getIt()));
  getIt.registerFactory<UpdatePasswordUsecase>(
    () => UpdatePasswordUsecase(getIt()),
  );
  getIt.registerFactory<LoginBloc>(() => LoginBloc(signIn: getIt()));
  getIt.registerFactory<SettingsCubit>(() => SettingsCubit(signOut: getIt()));

  // exercises
  getIt.registerLazySingleton<ExercisesRemoteDatasource>(
    () => ExercisesSupabaseDatasource(Supabase.instance.client),
  );
  getIt.registerLazySingleton<ExercisesRepository>(
    () => ExercisesRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<GetExercisesUsecase>(
    () => GetExercisesUsecase(getIt()),
  );
  getIt.registerFactory<SaveExerciseUsecase>(
    () => SaveExerciseUsecase(getIt()),
  );
  getIt.registerFactory<DeleteExerciseUsecase>(
    () => DeleteExerciseUsecase(getIt()),
  );
  getIt.registerFactory<ManageExerciseImagesUsecase>(
    () => ManageExerciseImagesUsecase(getIt()),
  );
  getIt.registerFactory<ExercisesCubit>(
    () => ExercisesCubit(
      getExercises: getIt(),
      saveExercise: getIt(),
      deleteExercise: getIt(),
      images: getIt(),
    ),
  );

  // plan
  getIt.registerLazySingleton<PlanRemoteDatasource>(
    () => PlanSupabaseDatasource(Supabase.instance.client),
  );
  getIt.registerLazySingleton<PlanRepository>(
    () => PlanRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<GetPlanUsecase>(() => GetPlanUsecase(getIt()));
  getIt.registerFactory<SaveRoutineUsecase>(() => SaveRoutineUsecase(getIt()));
  getIt.registerFactory<DeleteRoutineUsecase>(
    () => DeleteRoutineUsecase(getIt()),
  );
  getIt.registerFactory<SetPlanDayUsecase>(() => SetPlanDayUsecase(getIt()));
  getIt.registerFactory<PlanCubit>(
    () => PlanCubit(
      getPlan: getIt(),
      saveRoutine: getIt(),
      deleteRoutine: getIt(),
      setPlanDay: getIt(),
    ),
  );

  // workouts
  getIt.registerLazySingleton<WorkoutsRemoteDatasource>(
    () => WorkoutsSupabaseDatasource(Supabase.instance.client),
  );
  getIt.registerLazySingleton<WorkoutsRepository>(
    () => WorkoutsRepositoryImpl(getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<GetWorkoutsUsecase>(() => GetWorkoutsUsecase(getIt()));
  getIt.registerFactory<SaveWorkoutUsecase>(() => SaveWorkoutUsecase(getIt()));
  getIt.registerFactory<DeleteWorkoutUsecase>(
    () => DeleteWorkoutUsecase(getIt()),
  );
  getIt.registerFactory<BuildWorkoutUsecase>(BuildWorkoutUsecase.new);
  getIt.registerFactory<WorkoutsCubit>(
    () => WorkoutsCubit(
      getWorkouts: getIt(),
      saveWorkout: getIt(),
      deleteWorkout: getIt(),
      buildWorkout: getIt(),
    ),
  );

  getIt.registerFactory<LegacyLocalDataMigrator>(
    () => LegacyLocalDataMigrator(
      store: getIt(),
      user: getIt(),
      exercises: getIt(),
      plan: getIt(),
      workouts: getIt(),
    ),
  );

  // dashboard
  getIt.registerFactory<ComputeDashboardStatsUsecase>(
    ComputeDashboardStatsUsecase.new,
  );
  getIt.registerFactory<ComputeExerciseProgressUsecase>(
    ComputeExerciseProgressUsecase.new,
  );
}
