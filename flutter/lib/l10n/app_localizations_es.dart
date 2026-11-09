// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get addExercise => 'Agregar ejercicio';

  @override
  String get addSet => 'Serie';

  @override
  String get appTitle => 'Gym Tracker';

  @override
  String get autoSaved => 'Los cambios se guardan automáticamente';

  @override
  String get bestE1rm => 'Mejor 1RM est.';

  @override
  String get bestVolume => 'Mejor volumen por sesión';

  @override
  String get biometricLockBody => 'Usa Face ID o la huella para continuar.';

  @override
  String get biometricLockTitle => 'App bloqueada';

  @override
  String get biometricLockUnlockButton => 'Desbloquear';

  @override
  String get camera => 'Cámara';

  @override
  String get cancel => 'Cancelar';

  @override
  String get changeDate => 'Cambiar fecha';

  @override
  String get completeAll => 'Marcar todas';

  @override
  String get continueWorkout => 'Continuar';

  @override
  String get dashboardAvgDuration => 'Duración media';

  @override
  String dashboardE1rm(String value) {
    return '1RM est. $value';
  }

  @override
  String get dashboardEmptyBody =>
      'Registra tu primer entrenamiento y aquí verás tu progreso.';

  @override
  String get dashboardEmptyTitle => 'Aún no hay datos';

  @override
  String get dashboardLast30Days => 'últimos 30 días';

  @override
  String get dashboardMuscleSets => 'Series por músculo esta semana';

  @override
  String get dashboardMuscleSetsHint =>
      'Las series directas cuentan 1 y los músculos secundarios 0,5. Unas 10–20 series semanales por músculo es un objetivo común.';

  @override
  String get dashboardNew => 'Nuevo';

  @override
  String get dashboardNoPreviousWeek => 'nada la semana pasada';

  @override
  String get dashboardNoSetsThisWeek =>
      'Aún no hay series completadas esta semana.';

  @override
  String get dashboardNoTrends =>
      'Registra series con peso para ver tendencias.';

  @override
  String get dashboardPersonalRecords => 'Récords personales';

  @override
  String get dashboardPlannedDays => 'hechos / días planificados';

  @override
  String get dashboardReps => 'Repeticiones';

  @override
  String get dashboardSets => 'Series';

  @override
  String get dashboardStreak => 'Racha';

  @override
  String dashboardStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
    );
    return '$_temp0';
  }

  @override
  String get dashboardThisWeek => 'Esta semana';

  @override
  String dashboardTotalWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entrenamientos en total',
      one: '1 entrenamiento en total',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTrends => 'Tendencias de fuerza';

  @override
  String get dashboardTrendsHint =>
      'Mejor 1RM estimado de las últimas 4 semanas vs las 4 anteriores.';

  @override
  String dashboardVolume(String unit) {
    return 'Volumen ($unit)';
  }

  @override
  String dashboardVsLastWeek(String delta) {
    return '$delta vs semana pasada';
  }

  @override
  String get dashboardWeeklyReps => 'Repeticiones semanales';

  @override
  String dashboardWeeklyVolume(String unit) {
    return 'Volumen semanal ($unit)';
  }

  @override
  String get dashboardWorkouts => 'Entrenamientos';

  @override
  String get delete => 'Eliminar';

  @override
  String deleteExerciseMessage(String name) {
    return 'Se eliminarán \"$name\" y sus fotos. Los entrenamientos pasados conservan sus series.';
  }

  @override
  String get deleteExerciseTitle => '¿Eliminar ejercicio?';

  @override
  String deleteRoutineMessage(String name) {
    return '\"$name\" se quitará de tu plan semanal. Los entrenamientos pasados se conservan.';
  }

  @override
  String get deleteRoutineTitle => '¿Eliminar rutina?';

  @override
  String deleteWorkoutMessage(String name) {
    return 'Se eliminarán \"$name\" y todas sus series.';
  }

  @override
  String get deleteWorkoutTitle => '¿Eliminar entrenamiento?';

  @override
  String get deletedExercise => 'Ejercicio eliminado';

  @override
  String get edit => 'Editar';

  @override
  String get editExercise => 'Editar ejercicio';

  @override
  String get editRoutine => 'Editar rutina';

  @override
  String get email => 'Correo electrónico';

  @override
  String get emptyWorkoutHint =>
      'Empieza vacío y agrega ejercicios sobre la marcha';

  @override
  String get emptyWorkoutTitle => 'Entrenamiento';

  @override
  String get equipment => 'Equipo';

  @override
  String get equipmentBand => 'Banda';

  @override
  String get equipmentBarbell => 'Barra';

  @override
  String get equipmentBodyweight => 'Peso corporal';

  @override
  String get equipmentCable => 'Polea';

  @override
  String get equipmentDumbbell => 'Mancuerna';

  @override
  String get equipmentKettlebell => 'Pesa rusa';

  @override
  String get equipmentMachine => 'Máquina';

  @override
  String get equipmentOther => 'Otro';

  @override
  String get equipmentSmithMachine => 'Máquina Smith';

  @override
  String exerciseInUseMessage(String routines) {
    return 'Primero quítalo de estas rutinas: $routines.';
  }

  @override
  String get exerciseInUseTitle => 'Ejercicio en uso';

  @override
  String get exerciseNameHint => 'p. ej. Press inclinado con mancuernas';

  @override
  String get exerciseNameLabel => 'Nombre';

  @override
  String get exerciseNotFound => 'Ejercicio no encontrado';

  @override
  String get exerciseNotesHint => 'Posición, indicaciones, altura del asiento…';

  @override
  String get exerciseNotesLabel => 'Cómo hacerlo';

  @override
  String get exerciseRemoved => 'Ejercicio quitado';

  @override
  String get exercisesEmptyBody =>
      'Crea los ejercicios que haces, con los músculos que trabajan y fotos para recordar la técnica. Luego úsalos en tus rutinas.';

  @override
  String get exercisesEmptyTitle => 'Aún no hay ejercicios';

  @override
  String get exercisesInRoutine => 'Ejercicios';

  @override
  String get fieldRequired => 'Obligatorio';

  @override
  String get finish => 'Terminar';

  @override
  String get finishAsIs => 'Terminar así';

  @override
  String get finishWorkout => 'Terminar entrenamiento';

  @override
  String finishWorkoutPendingSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count series no están marcadas. Las series sin marcar no cuentan en tus estadísticas.',
      one: '1 serie no está marcada. Las series sin marcar no cuentan en tus estadísticas.',
    );
    return '$_temp0';
  }

  @override
  String get finishWorkoutTitle => '¿Terminar entrenamiento?';

  @override
  String get finished => 'Terminado';

  @override
  String get gallery => 'Galería';

  @override
  String get goToPlan => 'Armar plan';

  @override
  String get goToWorkouts => 'Ir a entrenos';

  @override
  String get heaviestSet => 'Serie más pesada';

  @override
  String get history => 'Historial';

  @override
  String get imageImportFailed => 'No se pudo agregar la imagen.';

  @override
  String get inProgress => 'En curso';

  @override
  String get lastSession => 'Última sesión';

  @override
  String lastTime(String sets) {
    return 'La última vez: $sets';
  }

  @override
  String get loadError => 'No se pudieron cargar tus datos';

  @override
  String get metricE1rm => '1RM';

  @override
  String get metricTopWeight => 'Máx.';

  @override
  String get metricVolume => 'Volumen';

  @override
  String get moveDown => 'Bajar';

  @override
  String get moveUp => 'Subir';

  @override
  String get muscleAbs => 'Abdomen';

  @override
  String get muscleAdductors => 'Aductores';

  @override
  String get muscleBiceps => 'Bíceps';

  @override
  String get muscleCalves => 'Pantorrillas';

  @override
  String get muscleChest => 'Pecho';

  @override
  String get muscleForearms => 'Antebrazos';

  @override
  String get muscleGlutes => 'Glúteos';

  @override
  String get muscleHamstrings => 'Isquiotibiales';

  @override
  String get muscleLats => 'Dorsales';

  @override
  String get muscleLowerBack => 'Zona lumbar';

  @override
  String get muscleObliques => 'Oblicuos';

  @override
  String get muscleQuads => 'Cuádriceps';

  @override
  String get muscleShoulders => 'Hombros';

  @override
  String get muscleTraps => 'Trapecios';

  @override
  String get muscleTriceps => 'Tríceps';

  @override
  String get muscleUpperBack => 'Espalda alta';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navExercises => 'Ejercicios';

  @override
  String get navPlan => 'Plan';

  @override
  String get navWorkouts => 'Entrenos';

  @override
  String get newExercise => 'Nuevo ejercicio';

  @override
  String get newRoutine => 'Nueva rutina';

  @override
  String get noPlanYet => 'Aún no hay plan';

  @override
  String get noPlanYetHint =>
      'Arma tu plan semanal para ver aquí el entrenamiento de hoy.';

  @override
  String get noResults => 'Sin resultados';

  @override
  String get notInPlan => 'Agregado hoy (fuera del plan)';

  @override
  String get notUsedInRoutines => 'Aún no se usa en ninguna rutina.';

  @override
  String get notes => 'Notas';

  @override
  String get ok => 'Aceptar';

  @override
  String get password => 'Contraseña';

  @override
  String get pickExerciseTitle => 'Agregar ejercicio';

  @override
  String plannedTarget(int sets, int reps, String weight) {
    return 'Plan: $sets×$reps$weight';
  }

  @override
  String get primaryMuscles => 'Músculos que trabaja directamente';

  @override
  String get primaryMusclesHint =>
      'Cada serie cuenta como una serie para estos músculos.';

  @override
  String get primaryMusclesRequired =>
      'Elige al menos un músculo que trabaje directamente.';

  @override
  String get progressEmptyBody =>
      'Completa series de este ejercicio para ver su progreso.';

  @override
  String get progressEmptyTitle => 'Aún no hay sesiones';

  @override
  String get progressSinceFirst => 'Desde la primera sesión';

  @override
  String get referenceImages => 'Imágenes de referencia';

  @override
  String get removeExercise => 'Quitar ejercicio';

  @override
  String get removeImage => 'Quitar imagen';

  @override
  String get removeSet => 'Serie';

  @override
  String get rename => 'Renombrar';

  @override
  String get reopenWorkout => 'Marcar como en curso';

  @override
  String get reps => 'Reps';

  @override
  String repsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '1 rep',
    );
    return '$_temp0';
  }

  @override
  String get restDay => 'Descanso';

  @override
  String get restDayHint =>
      'Nada planificado para hoy. Igual puedes empezar un entrenamiento.';

  @override
  String get retry => 'Reintentar';

  @override
  String get routineNoExercises => 'Sin ejercicios';

  @override
  String get routineNoExercisesHint =>
      'Agrega los ejercicios de este día, con series y repeticiones.';

  @override
  String routineSummary(int exercises, int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      exercises,
      locale: localeName,
      other: '$exercises ejercicios',
      one: '1 ejercicio',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets series',
      one: '1 serie',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get routineTitleHint => 'p. ej. Empuje';

  @override
  String get routineTitleLabel => 'Título';

  @override
  String get routines => 'Rutinas';

  @override
  String get routinesEmpty =>
      'Aún no hay rutinas. Crea una (p. ej. Empuje) y asígnala a días.';

  @override
  String get save => 'Guardar';

  @override
  String get searchExercises => 'Buscar ejercicios';

  @override
  String get secondaryMuscles => 'Músculos secundarios';

  @override
  String get secondaryMusclesHint =>
      'Músculos que ayudan. Cada serie cuenta como media serie.';

  @override
  String get sessions => 'Sesiones';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones',
      one: '1 sesión',
    );
    return '$_temp0';
  }

  @override
  String get sessionsTitle => 'Sesiones';

  @override
  String get setShort => 'Serie';

  @override
  String get sets => 'Series';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count series',
      one: '1 serie',
    );
    return '$_temp0';
  }

  @override
  String setsDone(int done, int total) {
    return '$done/$total series';
  }

  @override
  String get settings => 'Ajustes';

  @override
  String get settingsAboutApp => 'Acerca de';

  @override
  String get settingsAboutBulletDashboard =>
      'Panel con volumen y repeticiones semanales, series por músculo, tendencias de fuerza y récords personales.';

  @override
  String get settingsAboutBulletExercises =>
      'Ejercicios reutilizables con los músculos que trabajan, equipo, notas y fotos de referencia.';

  @override
  String get settingsAboutBulletLog =>
      'Registro diario que parte del plan: quita ejercicios, cambia series, repeticiones y peso, o agrega otros.';

  @override
  String get settingsAboutBulletPlan =>
      'Plan semanal: asigna una rutina (empuje, tirón, pierna…) a cada día, con series y repeticiones por ejercicio.';

  @override
  String get settingsAboutDataBody =>
      'El inicio de sesión y tus datos usan Supabase: tu plan, ejercicios, entrenamientos y fotos de referencia se guardan en tu cuenta y están disponibles en cualquier dispositivo donde inicies sesión. Se guarda en este dispositivo una copia de solo lectura de los últimos datos cargados para cuando no tengas conexión.';

  @override
  String get settingsAboutDataHeading => 'Tus datos';

  @override
  String get settingsAboutDeveloperGithub => 'GitHub';

  @override
  String get settingsAboutDeveloperHeading => 'Desarrollador';

  @override
  String get settingsAboutDeveloperLinkedin => 'LinkedIn';

  @override
  String get settingsAboutDeveloperWebsite => 'Sitio web';

  @override
  String get settingsAboutDeveloperYoutube => 'YouTube';

  @override
  String get settingsAboutFeaturesHeading => 'Qué puedes hacer';

  @override
  String get settingsAboutSection => 'Acerca de';

  @override
  String get settingsAboutTagline =>
      'Planifica tu semana, registra cada serie y mira tu progreso.';

  @override
  String get settingsAboutVersionLabel => 'Versión';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsBiometricAuthReason =>
      'Confirma para activar el desbloqueo biométrico.';

  @override
  String get settingsBiometricResumeReason => 'Autentícate para continuar.';

  @override
  String get settingsBiometricUnavailable =>
      'El desbloqueo biométrico no está disponible en este dispositivo.';

  @override
  String get settingsBiometricUnlockSubtitle =>
      'Usa la biometría para desbloquear la app.';

  @override
  String get settingsBiometricUnlockTitle => 'Face ID y huella dactilar';

  @override
  String get settingsChangeEmail => 'Cambiar correo';

  @override
  String get settingsChangeEmailDialogTitle => 'Cambiar correo';

  @override
  String get settingsChangeEmailInvalid => 'Introduce un correo válido.';

  @override
  String get settingsChangeEmailSameAsCurrent => 'Ese ya es tu correo.';

  @override
  String get settingsChangeEmailSubmit => 'Actualizar';

  @override
  String get settingsChangeEmailSuccess =>
      'Revisa tu correo nuevo para confirmar el cambio.';

  @override
  String get settingsChangePassword => 'Cambiar contraseña';

  @override
  String get settingsChangePasswordDialogTitle => 'Cambiar contraseña';

  @override
  String get settingsChangePasswordSubmit => 'Actualizar contraseña';

  @override
  String get settingsChangePasswordSubtitle =>
      'Actualiza la contraseña con la que inicias sesión.';

  @override
  String get settingsChangePasswordSuccess => 'Tu contraseña se actualizó.';

  @override
  String get settingsConfirmNewPasswordLabel => 'Confirmar contraseña';

  @override
  String get settingsDataSection => 'Datos';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageEnglish => 'Inglés';

  @override
  String get settingsLanguageSpanish => 'Español';

  @override
  String get settingsLanguageSystem => 'Predeterminado del sistema';

  @override
  String get settingsLocalData => 'Guardado en tu cuenta';

  @override
  String get settingsLocalDataSubtitle =>
      'El plan, los ejercicios, las fotos y los entrenamientos se guardan en Supabase. Los últimos datos cargados se pueden ver sin conexión; al cerrar sesión se borran de este dispositivo.';

  @override
  String get settingsNewEmailLabel => 'Correo nuevo';

  @override
  String get settingsNewPasswordLabel => 'Contraseña nueva';

  @override
  String get settingsPasswordTooShort => 'Usa al menos 6 caracteres.';

  @override
  String get settingsPasswordsDoNotMatch => 'Las contraseñas no coinciden.';

  @override
  String get settingsPrivacyDataBody =>
      'La autenticación la provee Supabase. Tu correo y credenciales los procesa Supabase; esta app no guarda tu contraseña.';

  @override
  String get settingsPrivacyDataTitle => 'Cuenta';

  @override
  String get settingsPrivacyInfraBody =>
      'Tu plan semanal, ejercicios, registros de entrenamiento y fotos de referencia se guardan en Supabase, asociados a tu cuenta y protegidos para que solo tú puedas leerlos. En este dispositivo se guarda una copia de los últimos datos cargados para verlos sin conexión, y se borra al cerrar sesión. La seguridad y los respaldos dependen de ese servicio. Usa una contraseña segura.';

  @override
  String get settingsPrivacyInfraTitle => 'Qué guardamos hoy — y después';

  @override
  String get settingsPrivacyNoticeBody =>
      'Este texto es un resumen orientativo, no asesoramiento legal. Antes de producción o de publicar en una tienda de apps, publica una política de privacidad acorde a tu jurisdicción, tu organización y cómo tratas los datos en la práctica.';

  @override
  String get settingsPrivacyNoticeTitle => 'Antes de publicar';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsPrivacySharingBody =>
      'No vendemos tu información personal ni usamos tus datos de entrenamiento para mostrarte anuncios. Aparte del servicio de inicio de sesión, esta app no envía tus datos a nadie.';

  @override
  String get settingsPrivacySharingTitle => 'Compartir y publicidad';

  @override
  String get settingsPrivacyTagline =>
      'Tu cuenta y tus datos de entrenamiento se guardan en Supabase.';

  @override
  String get settingsProfileSection => 'Perfil';

  @override
  String get settingsSecuritySection => 'Seguridad';

  @override
  String get settingsTermsAcceptanceBody =>
      'Al acceder o usar Gym Tracker, aceptas estos términos. Si no estás de acuerdo, no uses la app. El inicio de sesión y tus datos de entrenamiento los gestiona Supabase.';

  @override
  String get settingsTermsAcceptanceTitle => 'Aceptación';

  @override
  String get settingsTermsDisclaimerBody =>
      'Gym Tracker es una herramienta para organizar tu propio entrenamiento. Nada en la app es consejo médico, deportivo ni nutricional. Consulta a un profesional antes de empezar un programa y entrena bajo tu propio riesgo.';

  @override
  String get settingsTermsDisclaimerTitle => 'No es consejo médico';

  @override
  String get settingsTermsLiabilityBody =>
      'En la medida máxima permitida por la ley, los autores y colaboradores no serán responsables de daños indirectos, incidentales o consecuenciales, ni de pérdidas o decisiones que tomes basándote en la app. La app se ofrece «tal cual», sin garantías de ningún tipo.';

  @override
  String get settingsTermsLiabilityTitle => 'Limitación de responsabilidad';

  @override
  String get settingsTermsNoticeBody =>
      'Estos términos pueden actualizarse ocasionalmente. Si sigues usando la app tras publicarse cambios, ello implica que aceptas los términos actualizados. Este texto es un resumen orientativo, no asesoramiento legal. Antes de producción o de publicar en una tienda de apps, publica términos acordes a tu jurisdicción, tu organización y tu servicio.';

  @override
  String get settingsTermsNoticeTitle => 'Cambios y antes de publicar';

  @override
  String get settingsTermsOfUse => 'Términos de uso';

  @override
  String get settingsTermsResponsibilitiesBody =>
      'Eres responsable de proteger tu cuenta, credenciales y dispositivos.';

  @override
  String get settingsTermsResponsibilitiesTitle => 'Tus responsabilidades';

  @override
  String get settingsTermsTagline => 'Normas para usar esta app.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeSystem => 'Predeterminado del sistema';

  @override
  String get settingsWeightUnit => 'Unidad para totales';

  @override
  String get settingsWeightUnitKg => 'kg';

  @override
  String get settingsWeightUnitLb => 'lb';

  @override
  String get signIn => 'Iniciar sesión';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get startWorkout => 'Empezar';

  @override
  String get todayDone => 'Listo por hoy. ¡Buen trabajo!';

  @override
  String todayLabel(String day) {
    return 'Hoy · $day';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get unexpectedError => 'Ocurrió un error inesperado';

  @override
  String get usedInRoutines => 'Usado en rutinas';

  @override
  String get view => 'Ver';

  @override
  String get viewProgress => 'Ver progreso';

  @override
  String get weeklyPlan => 'Plan semanal';

  @override
  String get weeklyPlanHint =>
      'Toca un día para elegir su rutina. La misma rutina se puede usar en varios días.';

  @override
  String get workoutEmptyBody => 'Agrega los ejercicios que haces hoy.';

  @override
  String get workoutEmptyTitle => 'Sin ejercicios';

  @override
  String get workoutInProgress => 'Entrenamiento en curso';

  @override
  String get workoutNotFound => 'Entrenamiento no encontrado';

  @override
  String get workoutSaved => 'Entrenamiento guardado';

  @override
  String get workoutTitleLabel => 'Título del entrenamiento';

  @override
  String get workoutsEmpty => 'Aún no hay entrenamientos registrados.';

  @override
  String get yourStats => 'Tus estadísticas';

  @override
  String get discsShort => 'discos';

  @override
  String get loadTypeLabel => 'Carga';

  @override
  String get loadTypeWeight => 'Peso';

  @override
  String get loadTypeDiscs => 'Discos';

  @override
  String get loadTypeWeightHint =>
      'Las series se registran en esta unidad y cuentan en el volumen semanal.';

  @override
  String get loadTypeDiscsHint =>
      'Para poleas y máquinas: registra cuántos discos (placas). No cuenta en el volumen en lb/kg.';

  @override
  String get dashboardVolumeHint =>
      'El volumen solo cuenta ejercicios con peso; los de discos se siguen en su propio progreso.';

  @override
  String get saveFailed =>
      'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.';

  @override
  String get offlineBanner =>
      'Sin conexión: mostrando tus últimos datos sincronizados (solo lectura)';

  @override
  String get syncingLocalData => 'Subiendo tus datos a tu cuenta…';

  @override
  String get dashboardMuscleReps =>
      'Repeticiones por músculo principal esta semana';

  @override
  String get dashboardMuscleRepsHint =>
      'Repeticiones completadas de los ejercicios que trabajan cada músculo directamente.';

  @override
  String get openExercise => 'Abrir ejercicio';
}
