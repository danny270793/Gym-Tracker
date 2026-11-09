// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addExercise => 'Add exercise';

  @override
  String get addSet => 'Set';

  @override
  String get appTitle => 'Gym Tracker';

  @override
  String get autoSaved => 'Changes are saved automatically';

  @override
  String get bestE1rm => 'Best est. 1RM';

  @override
  String get bestVolume => 'Best session volume';

  @override
  String get biometricLockBody => 'Use Face ID or fingerprint to continue.';

  @override
  String get biometricLockTitle => 'App locked';

  @override
  String get biometricLockUnlockButton => 'Unlock';

  @override
  String get camera => 'Camera';

  @override
  String get cancel => 'Cancel';

  @override
  String get changeDate => 'Change date';

  @override
  String get completeAll => 'Mark all done';

  @override
  String get continueWorkout => 'Continue';

  @override
  String get dashboardAvgDuration => 'Avg. duration';

  @override
  String dashboardE1rm(String value) {
    return 'Est. 1RM $value';
  }

  @override
  String get dashboardEmptyBody =>
      'Log your first workout and your progress will show up here.';

  @override
  String get dashboardEmptyTitle => 'No data yet';

  @override
  String get dashboardLast30Days => 'last 30 days';

  @override
  String get dashboardMuscleSets => 'Sets per muscle this week';

  @override
  String get dashboardMuscleSetsHint =>
      'Direct sets count 1, secondary muscles 0.5. Around 10–20 weekly sets per muscle is a common target.';

  @override
  String get dashboardNew => 'New';

  @override
  String get dashboardNoPreviousWeek => 'nothing last week';

  @override
  String get dashboardNoSetsThisWeek => 'No completed sets this week yet.';

  @override
  String get dashboardNoTrends => 'Log weighted sets to see trends.';

  @override
  String get dashboardPersonalRecords => 'Personal records';

  @override
  String get dashboardPlannedDays => 'done / planned days';

  @override
  String get dashboardReps => 'Reps';

  @override
  String get dashboardSets => 'Sets';

  @override
  String get dashboardStreak => 'Streak';

  @override
  String dashboardStreakWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get dashboardThisWeek => 'This week';

  @override
  String dashboardTotalWorkouts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workouts total',
      one: '1 workout total',
    );
    return '$_temp0';
  }

  @override
  String get dashboardTrends => 'Strength trends';

  @override
  String get dashboardTrendsHint =>
      'Best estimated 1RM in the last 4 weeks vs the 4 weeks before.';

  @override
  String dashboardVolume(String unit) {
    return 'Volume ($unit)';
  }

  @override
  String dashboardVsLastWeek(String delta) {
    return '$delta vs last week';
  }

  @override
  String get dashboardWeeklyReps => 'Weekly reps';

  @override
  String dashboardWeeklyVolume(String unit) {
    return 'Weekly volume ($unit)';
  }

  @override
  String get dashboardWorkouts => 'Workouts';

  @override
  String get delete => 'Delete';

  @override
  String deleteExerciseMessage(String name) {
    return '\"$name\" and its photos will be deleted. Past workouts keep their sets.';
  }

  @override
  String get deleteExerciseTitle => 'Delete exercise?';

  @override
  String deleteRoutineMessage(String name) {
    return '\"$name\" will be removed from your weekly plan. Past workouts are kept.';
  }

  @override
  String get deleteRoutineTitle => 'Delete routine?';

  @override
  String deleteWorkoutMessage(String name) {
    return '\"$name\" and all its sets will be deleted.';
  }

  @override
  String get deleteWorkoutTitle => 'Delete workout?';

  @override
  String get deletedExercise => 'Deleted exercise';

  @override
  String get edit => 'Edit';

  @override
  String get editExercise => 'Edit exercise';

  @override
  String get editRoutine => 'Edit routine';

  @override
  String get email => 'Email';

  @override
  String get emptyWorkoutHint => 'Start empty and add exercises as you go';

  @override
  String get emptyWorkoutTitle => 'Workout';

  @override
  String get equipment => 'Equipment';

  @override
  String get equipmentBand => 'Band';

  @override
  String get equipmentBarbell => 'Barbell';

  @override
  String get equipmentBodyweight => 'Bodyweight';

  @override
  String get equipmentCable => 'Cable';

  @override
  String get equipmentDumbbell => 'Dumbbell';

  @override
  String get equipmentKettlebell => 'Kettlebell';

  @override
  String get equipmentMachine => 'Machine';

  @override
  String get equipmentOther => 'Other';

  @override
  String get equipmentSmithMachine => 'Smith machine';

  @override
  String exerciseInUseMessage(String routines) {
    return 'Remove it from these routines first: $routines.';
  }

  @override
  String get exerciseInUseTitle => 'Exercise in use';

  @override
  String get exerciseNameHint => 'e.g. Incline dumbbell press';

  @override
  String get exerciseNameLabel => 'Name';

  @override
  String get exerciseNotFound => 'Exercise not found';

  @override
  String get exerciseNotesHint => 'Setup, cues, seat height…';

  @override
  String get exerciseNotesLabel => 'How to do it';

  @override
  String get exerciseRemoved => 'Exercise removed';

  @override
  String get exercisesEmptyBody =>
      'Create the exercises you do, with the muscles they train and photos to remember the form. Then use them in your routines.';

  @override
  String get exercisesEmptyTitle => 'No exercises yet';

  @override
  String get exercisesInRoutine => 'Exercises';

  @override
  String get fieldRequired => 'Required';

  @override
  String get finish => 'Finish';

  @override
  String get finishAsIs => 'Finish as is';

  @override
  String get finishWorkout => 'Finish workout';

  @override
  String finishWorkoutPendingSets(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count sets are not checked. Unchecked sets don\'t count in your stats.',
      one: '1 set is not checked. Unchecked sets don\'t count in your stats.',
    );
    return '$_temp0';
  }

  @override
  String get finishWorkoutTitle => 'Finish workout?';

  @override
  String get finished => 'Finished';

  @override
  String get gallery => 'Gallery';

  @override
  String get goToPlan => 'Set up plan';

  @override
  String get goToWorkouts => 'Go to workouts';

  @override
  String get heaviestSet => 'Heaviest set';

  @override
  String get history => 'History';

  @override
  String get imageImportFailed => 'Could not add the image.';

  @override
  String get inProgress => 'In progress';

  @override
  String get lastSession => 'Last session';

  @override
  String lastTime(String sets) {
    return 'Last time: $sets';
  }

  @override
  String get loadError => 'Could not load your data';

  @override
  String get metricE1rm => '1RM';

  @override
  String get metricTopWeight => 'Top';

  @override
  String get metricVolume => 'Volume';

  @override
  String get moveDown => 'Move down';

  @override
  String get moveUp => 'Move up';

  @override
  String get muscleAbs => 'Abs';

  @override
  String get muscleAdductors => 'Adductors';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleCalves => 'Calves';

  @override
  String get muscleChest => 'Chest';

  @override
  String get muscleForearms => 'Forearms';

  @override
  String get muscleGlutes => 'Glutes';

  @override
  String get muscleHamstrings => 'Hamstrings';

  @override
  String get muscleLats => 'Lats';

  @override
  String get muscleLowerBack => 'Lower back';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get muscleQuads => 'Quads';

  @override
  String get muscleShoulders => 'Shoulders';

  @override
  String get muscleTraps => 'Traps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleUpperBack => 'Upper back';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navExercises => 'Exercises';

  @override
  String get navPlan => 'Plan';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get newExercise => 'New exercise';

  @override
  String get newRoutine => 'New routine';

  @override
  String get noPlanYet => 'No plan yet';

  @override
  String get noPlanYetHint =>
      'Set up your weekly plan to get today\'s workout here.';

  @override
  String get noResults => 'No results';

  @override
  String get notInPlan => 'Added today (not in plan)';

  @override
  String get notUsedInRoutines => 'Not used in any routine yet.';

  @override
  String get notes => 'Notes';

  @override
  String get ok => 'OK';

  @override
  String get password => 'Password';

  @override
  String get pickExerciseTitle => 'Add exercise';

  @override
  String plannedTarget(int sets, int reps, String weight) {
    return 'Plan: $sets×$reps$weight';
  }

  @override
  String get primaryMuscles => 'Muscles trained directly';

  @override
  String get primaryMusclesHint =>
      'Each set counts as one set for these muscles.';

  @override
  String get primaryMusclesRequired =>
      'Pick at least one muscle trained directly.';

  @override
  String get progressEmptyBody =>
      'Complete sets of this exercise to see its progress.';

  @override
  String get progressEmptyTitle => 'No sessions yet';

  @override
  String get progressSinceFirst => 'Since first session';

  @override
  String get referenceImages => 'Reference images';

  @override
  String get removeExercise => 'Remove exercise';

  @override
  String get removeImage => 'Remove image';

  @override
  String get removeSet => 'Set';

  @override
  String get rename => 'Rename';

  @override
  String get reopenWorkout => 'Mark as in progress';

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
  String get restDay => 'Rest day';

  @override
  String get restDayHint =>
      'Nothing planned for today. You can still start a workout.';

  @override
  String get retry => 'Retry';

  @override
  String get routineNoExercises => 'No exercises';

  @override
  String get routineNoExercisesHint =>
      'Add the exercises for this day, with sets and reps.';

  @override
  String routineSummary(int exercises, int sets) {
    String _temp0 = intl.Intl.pluralLogic(
      exercises,
      locale: localeName,
      other: '$exercises exercises',
      one: '1 exercise',
    );
    String _temp1 = intl.Intl.pluralLogic(
      sets,
      locale: localeName,
      other: '$sets sets',
      one: '1 set',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get routineTitleHint => 'e.g. Push';

  @override
  String get routineTitleLabel => 'Title';

  @override
  String get routines => 'Routines';

  @override
  String get routinesEmpty =>
      'No routines yet. Create one (e.g. Push) and assign it to days.';

  @override
  String get save => 'Save';

  @override
  String get searchExercises => 'Search exercises';

  @override
  String get secondaryMuscles => 'Secondary muscles';

  @override
  String get secondaryMusclesHint =>
      'Muscles that help. Each set counts as half a set.';

  @override
  String get sessions => 'Sessions';

  @override
  String sessionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sessions',
      one: '1 session',
    );
    return '$_temp0';
  }

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get setShort => 'Set';

  @override
  String get sets => 'Sets';

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String setsDone(int done, int total) {
    return '$done/$total sets';
  }

  @override
  String get settings => 'Settings';

  @override
  String get settingsAboutApp => 'About';

  @override
  String get settingsAboutBulletDashboard =>
      'Dashboard with weekly volume and reps, sets per muscle, strength trends and personal records.';

  @override
  String get settingsAboutBulletExercises =>
      'Reusable exercises with the muscles they train, equipment, notes and reference photos.';

  @override
  String get settingsAboutBulletLog =>
      'Daily log that starts from the plan: drop exercises, change sets, reps and weight, or add new ones.';

  @override
  String get settingsAboutBulletPlan =>
      'Weekly plan: assign a routine (push, pull, legs…) to each day, with sets and reps for every exercise.';

  @override
  String get settingsAboutDataBody =>
      'Sign-in and your data use Supabase: your plan, exercises, workouts and reference photos are stored in your account and available on any device where you sign in. A read-only copy of the last data loaded is kept on this device for when you\'re offline.';

  @override
  String get settingsAboutDataHeading => 'Your data';

  @override
  String get settingsAboutDeveloperGithub => 'GitHub';

  @override
  String get settingsAboutDeveloperHeading => 'Developer';

  @override
  String get settingsAboutDeveloperLinkedin => 'LinkedIn';

  @override
  String get settingsAboutDeveloperWebsite => 'Website';

  @override
  String get settingsAboutDeveloperYoutube => 'YouTube';

  @override
  String get settingsAboutFeaturesHeading => 'What you can do';

  @override
  String get settingsAboutSection => 'About';

  @override
  String get settingsAboutTagline =>
      'Plan your week, log every set, see your progress.';

  @override
  String get settingsAboutVersionLabel => 'Version';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsBiometricAuthReason =>
      'Confirm to enable biometric unlock.';

  @override
  String get settingsBiometricResumeReason => 'Authenticate to continue.';

  @override
  String get settingsBiometricUnavailable =>
      'Biometric unlock is not available on this device.';

  @override
  String get settingsBiometricUnlockSubtitle =>
      'Use biometrics to unlock the app.';

  @override
  String get settingsBiometricUnlockTitle => 'Face ID & fingerprint';

  @override
  String get settingsChangeEmail => 'Change email';

  @override
  String get settingsChangeEmailDialogTitle => 'Change email';

  @override
  String get settingsChangeEmailInvalid => 'Enter a valid email address.';

  @override
  String get settingsChangeEmailSameAsCurrent => 'That is already your email.';

  @override
  String get settingsChangeEmailSubmit => 'Update';

  @override
  String get settingsChangeEmailSuccess =>
      'Check your new email to confirm the change.';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordDialogTitle => 'Change password';

  @override
  String get settingsChangePasswordSubmit => 'Update password';

  @override
  String get settingsChangePasswordSubtitle =>
      'Updates the password you use to sign in.';

  @override
  String get settingsChangePasswordSuccess => 'Your password was updated.';

  @override
  String get settingsConfirmNewPasswordLabel => 'Confirm new password';

  @override
  String get settingsDataSection => 'Data';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageSpanish => 'Spanish';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsLocalData => 'Saved in your account';

  @override
  String get settingsLocalDataSubtitle =>
      'Plan, exercises, photos and workouts are stored in Supabase. The last data loaded stays readable offline; signing out removes it from this device.';

  @override
  String get settingsNewEmailLabel => 'New email';

  @override
  String get settingsNewPasswordLabel => 'New password';

  @override
  String get settingsPasswordTooShort => 'Use at least 6 characters.';

  @override
  String get settingsPasswordsDoNotMatch => 'Passwords do not match.';

  @override
  String get settingsPrivacyDataBody =>
      'Authentication is provided by Supabase. Your email and credentials are processed by Supabase; this app does not store your password.';

  @override
  String get settingsPrivacyDataTitle => 'Account';

  @override
  String get settingsPrivacyInfraBody =>
      'Your weekly plan, exercises, workout logs and reference photos are stored in Supabase, tied to your account and protected so only you can read them. A copy of the last data loaded is kept on this device to show it offline, and is deleted when you sign out. Security and backups depend on that service. Use a strong password.';

  @override
  String get settingsPrivacyInfraTitle => 'What we store today — and later';

  @override
  String get settingsPrivacyNoticeBody =>
      'This text is a simple placeholder, not legal advice. Before production or an app store release, publish a privacy policy that matches your jurisdiction, your organization, and how you actually process data.';

  @override
  String get settingsPrivacyNoticeTitle => 'Before you ship';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsPrivacySharingBody =>
      'We do not sell your personal information or use your training data to target ads. Apart from the sign-in service, this app does not send your data to anyone.';

  @override
  String get settingsPrivacySharingTitle => 'Sharing and ads';

  @override
  String get settingsPrivacyTagline =>
      'Your account and training data are stored in Supabase.';

  @override
  String get settingsProfileSection => 'Profile';

  @override
  String get settingsSecuritySection => 'Security';

  @override
  String get settingsTermsAcceptanceBody =>
      'By accessing or using Gym Tracker, you agree to these terms. If you do not agree, do not use the app. Sign-in and your training data are handled by Supabase.';

  @override
  String get settingsTermsAcceptanceTitle => 'Acceptance';

  @override
  String get settingsTermsDisclaimerBody =>
      'Gym Tracker is a tool for organizing your own training. Nothing in the app is medical, fitness or nutrition advice. Consult a professional before starting a program, and train at your own risk.';

  @override
  String get settingsTermsDisclaimerTitle => 'Not medical advice';

  @override
  String get settingsTermsLiabilityBody =>
      'To the fullest extent permitted by law, the authors and contributors are not liable for any indirect, incidental, or consequential damages, or for losses or decisions you make based on the app. The app is provided as-is without warranties of any kind.';

  @override
  String get settingsTermsLiabilityTitle => 'Limitation of liability';

  @override
  String get settingsTermsNoticeBody =>
      'These terms may be updated from time to time. If you continue to use the app after changes are posted, that indicates your acceptance of the updated terms. This text is a simple placeholder, not legal advice. Before production or an app store release, publish terms that match your jurisdiction, your organization, and your service.';

  @override
  String get settingsTermsNoticeTitle => 'Changes and before you ship';

  @override
  String get settingsTermsOfUse => 'Terms of use';

  @override
  String get settingsTermsResponsibilitiesBody =>
      'You are responsible for protecting your account, credentials and devices.';

  @override
  String get settingsTermsResponsibilitiesTitle => 'Your responsibilities';

  @override
  String get settingsTermsTagline => 'Rules for using this app.';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsWeightUnit => 'Unit for totals';

  @override
  String get settingsWeightUnitKg => 'kg';

  @override
  String get settingsWeightUnitLb => 'lb';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get todayDone => 'Done for today. Nice work!';

  @override
  String todayLabel(String day) {
    return 'Today · $day';
  }

  @override
  String get undo => 'Undo';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get usedInRoutines => 'Used in routines';

  @override
  String get view => 'View';

  @override
  String get viewProgress => 'View progress';

  @override
  String get weeklyPlan => 'Weekly plan';

  @override
  String get weeklyPlanHint =>
      'Tap a day to choose its routine. The same routine can be used on several days.';

  @override
  String get workoutEmptyBody => 'Add the exercises you are doing today.';

  @override
  String get workoutEmptyTitle => 'No exercises';

  @override
  String get workoutInProgress => 'Workout in progress';

  @override
  String get workoutNotFound => 'Workout not found';

  @override
  String get workoutSaved => 'Workout saved';

  @override
  String get workoutTitleLabel => 'Workout title';

  @override
  String get workoutsEmpty => 'No workouts logged yet.';

  @override
  String get yourStats => 'Your stats';

  @override
  String get discsShort => 'discs';

  @override
  String get loadTypeLabel => 'Load';

  @override
  String get loadTypeWeight => 'Weight';

  @override
  String get loadTypeDiscs => 'Discs';

  @override
  String get loadTypeWeightHint =>
      'Sets are logged in this unit and count toward weekly volume.';

  @override
  String get loadTypeDiscsHint =>
      'For cable and machine stacks: log how many discs (plates). Not counted in lb/kg volume.';

  @override
  String get dashboardVolumeHint =>
      'Volume counts weight exercises only; disc exercises are tracked in their own progress.';

  @override
  String get saveFailed =>
      'Couldn\'t save. Check your connection and try again.';

  @override
  String get offlineBanner =>
      'Offline: showing your last synced data (read-only)';

  @override
  String get syncingLocalData => 'Uploading your data to your account…';

  @override
  String get dashboardMuscleReps => 'Reps per main muscle this week';

  @override
  String get dashboardMuscleRepsHint =>
      'Completed reps of the exercises that train each muscle directly.';

  @override
  String get openExercise => 'Open exercise';
}
