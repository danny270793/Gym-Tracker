import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get addSet;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym Tracker'**
  String get appTitle;

  /// No description provided for @autoSaved.
  ///
  /// In en, this message translates to:
  /// **'Changes are saved automatically'**
  String get autoSaved;

  /// No description provided for @bestE1rm.
  ///
  /// In en, this message translates to:
  /// **'Best est. 1RM'**
  String get bestE1rm;

  /// No description provided for @bestVolume.
  ///
  /// In en, this message translates to:
  /// **'Best session volume'**
  String get bestVolume;

  /// No description provided for @biometricLockBody.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID or fingerprint to continue.'**
  String get biometricLockBody;

  /// No description provided for @biometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'App locked'**
  String get biometricLockTitle;

  /// No description provided for @biometricLockUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get biometricLockUnlockButton;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDate;

  /// No description provided for @completeAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all done'**
  String get completeAll;

  /// No description provided for @continueWorkout.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueWorkout;

  /// No description provided for @dashboardAvgDuration.
  ///
  /// In en, this message translates to:
  /// **'Avg. duration'**
  String get dashboardAvgDuration;

  /// No description provided for @dashboardE1rm.
  ///
  /// In en, this message translates to:
  /// **'Est. 1RM {value}'**
  String dashboardE1rm(String value);

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Log your first workout and your progress will show up here.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardLast30Days.
  ///
  /// In en, this message translates to:
  /// **'last 30 days'**
  String get dashboardLast30Days;

  /// No description provided for @dashboardMuscleSets.
  ///
  /// In en, this message translates to:
  /// **'Sets per muscle this week'**
  String get dashboardMuscleSets;

  /// No description provided for @dashboardMuscleSetsHint.
  ///
  /// In en, this message translates to:
  /// **'Direct sets count 1, secondary muscles 0.5. Around 10–20 weekly sets per muscle is a common target.'**
  String get dashboardMuscleSetsHint;

  /// No description provided for @dashboardNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get dashboardNew;

  /// No description provided for @dashboardNoPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'nothing last week'**
  String get dashboardNoPreviousWeek;

  /// No description provided for @dashboardNoSetsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No completed sets this week yet.'**
  String get dashboardNoSetsThisWeek;

  /// No description provided for @dashboardNoTrends.
  ///
  /// In en, this message translates to:
  /// **'Log weighted sets to see trends.'**
  String get dashboardNoTrends;

  /// No description provided for @dashboardPersonalRecords.
  ///
  /// In en, this message translates to:
  /// **'Personal records'**
  String get dashboardPersonalRecords;

  /// No description provided for @dashboardPlannedDays.
  ///
  /// In en, this message translates to:
  /// **'done / planned days'**
  String get dashboardPlannedDays;

  /// No description provided for @dashboardReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get dashboardReps;

  /// No description provided for @dashboardSets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get dashboardSets;

  /// No description provided for @dashboardStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get dashboardStreak;

  /// No description provided for @dashboardStreakWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String dashboardStreakWeeks(int count);

  /// No description provided for @dashboardThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dashboardThisWeek;

  /// No description provided for @dashboardTotalWorkouts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 workout total} other{{count} workouts total}}'**
  String dashboardTotalWorkouts(int count);

  /// No description provided for @dashboardTrends.
  ///
  /// In en, this message translates to:
  /// **'Strength trends'**
  String get dashboardTrends;

  /// No description provided for @dashboardTrendsHint.
  ///
  /// In en, this message translates to:
  /// **'Best estimated 1RM in the last 4 weeks vs the 4 weeks before.'**
  String get dashboardTrendsHint;

  /// No description provided for @dashboardVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume ({unit})'**
  String dashboardVolume(String unit);

  /// No description provided for @dashboardVsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'{delta} vs last week'**
  String dashboardVsLastWeek(String delta);

  /// No description provided for @dashboardWeeklyReps.
  ///
  /// In en, this message translates to:
  /// **'Weekly reps'**
  String get dashboardWeeklyReps;

  /// No description provided for @dashboardWeeklyVolume.
  ///
  /// In en, this message translates to:
  /// **'Weekly volume ({unit})'**
  String dashboardWeeklyVolume(String unit);

  /// No description provided for @dashboardWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get dashboardWorkouts;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteExerciseMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its photos will be deleted. Past workouts keep their sets.'**
  String deleteExerciseMessage(String name);

  /// No description provided for @deleteExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise?'**
  String get deleteExerciseTitle;

  /// No description provided for @deleteRoutineMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from your weekly plan. Past workouts are kept.'**
  String deleteRoutineMessage(String name);

  /// No description provided for @deleteRoutineTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete routine?'**
  String get deleteRoutineTitle;

  /// No description provided for @deleteWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and all its sets will be deleted.'**
  String deleteWorkoutMessage(String name);

  /// No description provided for @deleteWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete workout?'**
  String get deleteWorkoutTitle;

  /// No description provided for @deletedExercise.
  ///
  /// In en, this message translates to:
  /// **'Deleted exercise'**
  String get deletedExercise;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editExercise.
  ///
  /// In en, this message translates to:
  /// **'Edit exercise'**
  String get editExercise;

  /// No description provided for @editRoutine.
  ///
  /// In en, this message translates to:
  /// **'Edit routine'**
  String get editRoutine;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emptyWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Start empty and add exercises as you go'**
  String get emptyWorkoutHint;

  /// No description provided for @emptyWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get emptyWorkoutTitle;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @equipmentBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get equipmentBand;

  /// No description provided for @equipmentBarbell.
  ///
  /// In en, this message translates to:
  /// **'Barbell'**
  String get equipmentBarbell;

  /// No description provided for @equipmentBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get equipmentBodyweight;

  /// No description provided for @equipmentCable.
  ///
  /// In en, this message translates to:
  /// **'Cable'**
  String get equipmentCable;

  /// No description provided for @equipmentDumbbell.
  ///
  /// In en, this message translates to:
  /// **'Dumbbell'**
  String get equipmentDumbbell;

  /// No description provided for @equipmentKettlebell.
  ///
  /// In en, this message translates to:
  /// **'Kettlebell'**
  String get equipmentKettlebell;

  /// No description provided for @equipmentMachine.
  ///
  /// In en, this message translates to:
  /// **'Machine'**
  String get equipmentMachine;

  /// No description provided for @equipmentOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get equipmentOther;

  /// No description provided for @equipmentSmithMachine.
  ///
  /// In en, this message translates to:
  /// **'Smith machine'**
  String get equipmentSmithMachine;

  /// No description provided for @exerciseInUseMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove it from these routines first: {routines}.'**
  String exerciseInUseMessage(String routines);

  /// No description provided for @exerciseInUseTitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise in use'**
  String get exerciseInUseTitle;

  /// No description provided for @exerciseNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Incline dumbbell press'**
  String get exerciseNameHint;

  /// No description provided for @exerciseNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get exerciseNameLabel;

  /// No description provided for @exerciseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found'**
  String get exerciseNotFound;

  /// No description provided for @exerciseNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Setup, cues, seat height…'**
  String get exerciseNotesHint;

  /// No description provided for @exerciseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'How to do it'**
  String get exerciseNotesLabel;

  /// No description provided for @exerciseRemoved.
  ///
  /// In en, this message translates to:
  /// **'Exercise removed'**
  String get exerciseRemoved;

  /// No description provided for @exercisesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Create the exercises you do, with the muscles they train and photos to remember the form. Then use them in your routines.'**
  String get exercisesEmptyBody;

  /// No description provided for @exercisesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet'**
  String get exercisesEmptyTitle;

  /// No description provided for @exercisesInRoutine.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesInRoutine;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @finishAsIs.
  ///
  /// In en, this message translates to:
  /// **'Finish as is'**
  String get finishAsIs;

  /// No description provided for @finishWorkout.
  ///
  /// In en, this message translates to:
  /// **'Finish workout'**
  String get finishWorkout;

  /// No description provided for @finishWorkoutPendingSets.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set is not checked. Unchecked sets don\'t count in your stats.} other{{count} sets are not checked. Unchecked sets don\'t count in your stats.}}'**
  String finishWorkoutPendingSets(int count);

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish workout?'**
  String get finishWorkoutTitle;

  /// No description provided for @finished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @goToPlan.
  ///
  /// In en, this message translates to:
  /// **'Set up plan'**
  String get goToPlan;

  /// No description provided for @goToWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Go to workouts'**
  String get goToWorkouts;

  /// No description provided for @heaviestSet.
  ///
  /// In en, this message translates to:
  /// **'Heaviest set'**
  String get heaviestSet;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @imageImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not add the image.'**
  String get imageImportFailed;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get inProgress;

  /// No description provided for @lastSession.
  ///
  /// In en, this message translates to:
  /// **'Last session'**
  String get lastSession;

  /// No description provided for @lastTime.
  ///
  /// In en, this message translates to:
  /// **'Last time: {sets}'**
  String lastTime(String sets);

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your data'**
  String get loadError;

  /// No description provided for @metricE1rm.
  ///
  /// In en, this message translates to:
  /// **'1RM'**
  String get metricE1rm;

  /// No description provided for @metricTopWeight.
  ///
  /// In en, this message translates to:
  /// **'Top'**
  String get metricTopWeight;

  /// No description provided for @metricVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get metricVolume;

  /// No description provided for @moveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get moveDown;

  /// No description provided for @moveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get moveUp;

  /// No description provided for @muscleAbs.
  ///
  /// In en, this message translates to:
  /// **'Abs'**
  String get muscleAbs;

  /// No description provided for @muscleAdductors.
  ///
  /// In en, this message translates to:
  /// **'Adductors'**
  String get muscleAdductors;

  /// No description provided for @muscleBiceps.
  ///
  /// In en, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleCalves.
  ///
  /// In en, this message translates to:
  /// **'Calves'**
  String get muscleCalves;

  /// No description provided for @muscleChest.
  ///
  /// In en, this message translates to:
  /// **'Chest'**
  String get muscleChest;

  /// No description provided for @muscleForearms.
  ///
  /// In en, this message translates to:
  /// **'Forearms'**
  String get muscleForearms;

  /// No description provided for @muscleGlutes.
  ///
  /// In en, this message translates to:
  /// **'Glutes'**
  String get muscleGlutes;

  /// No description provided for @muscleHamstrings.
  ///
  /// In en, this message translates to:
  /// **'Hamstrings'**
  String get muscleHamstrings;

  /// No description provided for @muscleLats.
  ///
  /// In en, this message translates to:
  /// **'Lats'**
  String get muscleLats;

  /// No description provided for @muscleLowerBack.
  ///
  /// In en, this message translates to:
  /// **'Lower back'**
  String get muscleLowerBack;

  /// No description provided for @muscleObliques.
  ///
  /// In en, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// No description provided for @muscleQuads.
  ///
  /// In en, this message translates to:
  /// **'Quads'**
  String get muscleQuads;

  /// No description provided for @muscleShoulders.
  ///
  /// In en, this message translates to:
  /// **'Shoulders'**
  String get muscleShoulders;

  /// No description provided for @muscleTraps.
  ///
  /// In en, this message translates to:
  /// **'Traps'**
  String get muscleTraps;

  /// No description provided for @muscleTriceps.
  ///
  /// In en, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleUpperBack.
  ///
  /// In en, this message translates to:
  /// **'Upper back'**
  String get muscleUpperBack;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navExercises.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get navExercises;

  /// No description provided for @navPlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get navPlan;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @newExercise.
  ///
  /// In en, this message translates to:
  /// **'New exercise'**
  String get newExercise;

  /// No description provided for @newRoutine.
  ///
  /// In en, this message translates to:
  /// **'New routine'**
  String get newRoutine;

  /// No description provided for @noPlanYet.
  ///
  /// In en, this message translates to:
  /// **'No plan yet'**
  String get noPlanYet;

  /// No description provided for @noPlanYetHint.
  ///
  /// In en, this message translates to:
  /// **'Set up your weekly plan to get today\'s workout here.'**
  String get noPlanYetHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @notInPlan.
  ///
  /// In en, this message translates to:
  /// **'Added today (not in plan)'**
  String get notInPlan;

  /// No description provided for @notUsedInRoutines.
  ///
  /// In en, this message translates to:
  /// **'Not used in any routine yet.'**
  String get notUsedInRoutines;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pickExerciseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get pickExerciseTitle;

  /// No description provided for @plannedTarget.
  ///
  /// In en, this message translates to:
  /// **'Plan: {sets}×{reps}{weight}'**
  String plannedTarget(int sets, int reps, String weight);

  /// No description provided for @primaryMuscles.
  ///
  /// In en, this message translates to:
  /// **'Muscles trained directly'**
  String get primaryMuscles;

  /// No description provided for @primaryMusclesHint.
  ///
  /// In en, this message translates to:
  /// **'Each set counts as one set for these muscles.'**
  String get primaryMusclesHint;

  /// No description provided for @primaryMusclesRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one muscle trained directly.'**
  String get primaryMusclesRequired;

  /// No description provided for @progressEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Complete sets of this exercise to see its progress.'**
  String get progressEmptyBody;

  /// No description provided for @progressEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions yet'**
  String get progressEmptyTitle;

  /// No description provided for @progressSinceFirst.
  ///
  /// In en, this message translates to:
  /// **'Since first session'**
  String get progressSinceFirst;

  /// No description provided for @referenceImages.
  ///
  /// In en, this message translates to:
  /// **'Reference images'**
  String get referenceImages;

  /// No description provided for @removeExercise.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get removeExercise;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get removeSet;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @reopenWorkout.
  ///
  /// In en, this message translates to:
  /// **'Mark as in progress'**
  String get reopenWorkout;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @repsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rep} other{{count} reps}}'**
  String repsCount(int count);

  /// No description provided for @restDay.
  ///
  /// In en, this message translates to:
  /// **'Rest day'**
  String get restDay;

  /// No description provided for @restDayHint.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned for today. You can still start a workout.'**
  String get restDayHint;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @routineNoExercises.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get routineNoExercises;

  /// No description provided for @routineNoExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Add the exercises for this day, with sets and reps.'**
  String get routineNoExercisesHint;

  /// No description provided for @routineSummary.
  ///
  /// In en, this message translates to:
  /// **'{exercises, plural, =1{1 exercise} other{{exercises} exercises}} · {sets, plural, =1{1 set} other{{sets} sets}}'**
  String routineSummary(int exercises, int sets);

  /// No description provided for @routineTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push'**
  String get routineTitleHint;

  /// No description provided for @routineTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get routineTitleLabel;

  /// No description provided for @routines.
  ///
  /// In en, this message translates to:
  /// **'Routines'**
  String get routines;

  /// No description provided for @routinesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No routines yet. Create one (e.g. Push) and assign it to days.'**
  String get routinesEmpty;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @searchExercises.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercises;

  /// No description provided for @secondaryMuscles.
  ///
  /// In en, this message translates to:
  /// **'Secondary muscles'**
  String get secondaryMuscles;

  /// No description provided for @secondaryMusclesHint.
  ///
  /// In en, this message translates to:
  /// **'Muscles that help. Each set counts as half a set.'**
  String get secondaryMusclesHint;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 session} other{{count} sessions}}'**
  String sessionsCount(int count);

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessionsTitle;

  /// No description provided for @setShort.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setShort;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @setsDone.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} sets'**
  String setsDone(int done, int total);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutApp;

  /// No description provided for @settingsAboutBulletDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard with weekly volume and reps, sets per muscle, strength trends and personal records.'**
  String get settingsAboutBulletDashboard;

  /// No description provided for @settingsAboutBulletExercises.
  ///
  /// In en, this message translates to:
  /// **'Reusable exercises with the muscles they train, equipment, notes and reference photos.'**
  String get settingsAboutBulletExercises;

  /// No description provided for @settingsAboutBulletLog.
  ///
  /// In en, this message translates to:
  /// **'Daily log that starts from the plan: drop exercises, change sets, reps and weight, or add new ones.'**
  String get settingsAboutBulletLog;

  /// No description provided for @settingsAboutBulletPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan: assign a routine (push, pull, legs…) to each day, with sets and reps for every exercise.'**
  String get settingsAboutBulletPlan;

  /// No description provided for @settingsAboutDataBody.
  ///
  /// In en, this message translates to:
  /// **'Sign-in and your data use Supabase: your plan, exercises, workouts and reference photos are stored in your account and available on any device where you sign in. A read-only copy of the last data loaded is kept on this device for when you\'re offline.'**
  String get settingsAboutDataBody;

  /// No description provided for @settingsAboutDataHeading.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsAboutDataHeading;

  /// No description provided for @settingsAboutDeveloperGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get settingsAboutDeveloperGithub;

  /// No description provided for @settingsAboutDeveloperHeading.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsAboutDeveloperHeading;

  /// No description provided for @settingsAboutDeveloperLinkedin.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get settingsAboutDeveloperLinkedin;

  /// No description provided for @settingsAboutDeveloperWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get settingsAboutDeveloperWebsite;

  /// No description provided for @settingsAboutDeveloperYoutube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get settingsAboutDeveloperYoutube;

  /// No description provided for @settingsAboutFeaturesHeading.
  ///
  /// In en, this message translates to:
  /// **'What you can do'**
  String get settingsAboutFeaturesHeading;

  /// No description provided for @settingsAboutSection.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutSection;

  /// No description provided for @settingsAboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Plan your week, log every set, see your progress.'**
  String get settingsAboutTagline;

  /// No description provided for @settingsAboutVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsAboutVersionLabel;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsBiometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm to enable biometric unlock.'**
  String get settingsBiometricAuthReason;

  /// No description provided for @settingsBiometricResumeReason.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to continue.'**
  String get settingsBiometricResumeReason;

  /// No description provided for @settingsBiometricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock is not available on this device.'**
  String get settingsBiometricUnavailable;

  /// No description provided for @settingsBiometricUnlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics to unlock the app.'**
  String get settingsBiometricUnlockSubtitle;

  /// No description provided for @settingsBiometricUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Face ID & fingerprint'**
  String get settingsBiometricUnlockTitle;

  /// No description provided for @settingsChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get settingsChangeEmail;

  /// No description provided for @settingsChangeEmailDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get settingsChangeEmailDialogTitle;

  /// No description provided for @settingsChangeEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get settingsChangeEmailInvalid;

  /// No description provided for @settingsChangeEmailSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'That is already your email.'**
  String get settingsChangeEmailSameAsCurrent;

  /// No description provided for @settingsChangeEmailSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get settingsChangeEmailSubmit;

  /// No description provided for @settingsChangeEmailSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check your new email to confirm the change.'**
  String get settingsChangeEmailSuccess;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePasswordDialogTitle;

  /// No description provided for @settingsChangePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get settingsChangePasswordSubmit;

  /// No description provided for @settingsChangePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates the password you use to sign in.'**
  String get settingsChangePasswordSubtitle;

  /// No description provided for @settingsChangePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password was updated.'**
  String get settingsChangePasswordSuccess;

  /// No description provided for @settingsConfirmNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get settingsConfirmNewPasswordLabel;

  /// No description provided for @settingsDataSection.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsDataSection;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get settingsLanguageSpanish;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsLocalData.
  ///
  /// In en, this message translates to:
  /// **'Saved in your account'**
  String get settingsLocalData;

  /// No description provided for @settingsLocalDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan, exercises, photos and workouts are stored in Supabase. The last data loaded stays readable offline; signing out removes it from this device.'**
  String get settingsLocalDataSubtitle;

  /// No description provided for @settingsNewEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'New email'**
  String get settingsNewEmailLabel;

  /// No description provided for @settingsNewPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get settingsNewPasswordLabel;

  /// No description provided for @settingsPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Use at least 6 characters.'**
  String get settingsPasswordTooShort;

  /// No description provided for @settingsPasswordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get settingsPasswordsDoNotMatch;

  /// No description provided for @settingsPrivacyDataBody.
  ///
  /// In en, this message translates to:
  /// **'Authentication is provided by Supabase. Your email and credentials are processed by Supabase; this app does not store your password.'**
  String get settingsPrivacyDataBody;

  /// No description provided for @settingsPrivacyDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsPrivacyDataTitle;

  /// No description provided for @settingsPrivacyInfraBody.
  ///
  /// In en, this message translates to:
  /// **'Your weekly plan, exercises, workout logs and reference photos are stored in Supabase, tied to your account and protected so only you can read them. A copy of the last data loaded is kept on this device to show it offline, and is deleted when you sign out. Security and backups depend on that service. Use a strong password.'**
  String get settingsPrivacyInfraBody;

  /// No description provided for @settingsPrivacyInfraTitle.
  ///
  /// In en, this message translates to:
  /// **'What we store today — and later'**
  String get settingsPrivacyInfraTitle;

  /// No description provided for @settingsPrivacyNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'This text is a simple placeholder, not legal advice. Before production or an app store release, publish a privacy policy that matches your jurisdiction, your organization, and how you actually process data.'**
  String get settingsPrivacyNoticeBody;

  /// No description provided for @settingsPrivacyNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you ship'**
  String get settingsPrivacyNoticeTitle;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsPrivacySharingBody.
  ///
  /// In en, this message translates to:
  /// **'We do not sell your personal information or use your training data to target ads. Apart from the sign-in service, this app does not send your data to anyone.'**
  String get settingsPrivacySharingBody;

  /// No description provided for @settingsPrivacySharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing and ads'**
  String get settingsPrivacySharingTitle;

  /// No description provided for @settingsPrivacyTagline.
  ///
  /// In en, this message translates to:
  /// **'Your account and training data are stored in Supabase.'**
  String get settingsPrivacyTagline;

  /// No description provided for @settingsProfileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get settingsProfileSection;

  /// No description provided for @settingsSecuritySection.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecuritySection;

  /// No description provided for @settingsTermsAcceptanceBody.
  ///
  /// In en, this message translates to:
  /// **'By accessing or using Gym Tracker, you agree to these terms. If you do not agree, do not use the app. Sign-in and your training data are handled by Supabase.'**
  String get settingsTermsAcceptanceBody;

  /// No description provided for @settingsTermsAcceptanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Acceptance'**
  String get settingsTermsAcceptanceTitle;

  /// No description provided for @settingsTermsDisclaimerBody.
  ///
  /// In en, this message translates to:
  /// **'Gym Tracker is a tool for organizing your own training. Nothing in the app is medical, fitness or nutrition advice. Consult a professional before starting a program, and train at your own risk.'**
  String get settingsTermsDisclaimerBody;

  /// No description provided for @settingsTermsDisclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Not medical advice'**
  String get settingsTermsDisclaimerTitle;

  /// No description provided for @settingsTermsLiabilityBody.
  ///
  /// In en, this message translates to:
  /// **'To the fullest extent permitted by law, the authors and contributors are not liable for any indirect, incidental, or consequential damages, or for losses or decisions you make based on the app. The app is provided as-is without warranties of any kind.'**
  String get settingsTermsLiabilityBody;

  /// No description provided for @settingsTermsLiabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Limitation of liability'**
  String get settingsTermsLiabilityTitle;

  /// No description provided for @settingsTermsNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'These terms may be updated from time to time. If you continue to use the app after changes are posted, that indicates your acceptance of the updated terms. This text is a simple placeholder, not legal advice. Before production or an app store release, publish terms that match your jurisdiction, your organization, and your service.'**
  String get settingsTermsNoticeBody;

  /// No description provided for @settingsTermsNoticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Changes and before you ship'**
  String get settingsTermsNoticeTitle;

  /// No description provided for @settingsTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get settingsTermsOfUse;

  /// No description provided for @settingsTermsResponsibilitiesBody.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for protecting your account, credentials and devices.'**
  String get settingsTermsResponsibilitiesBody;

  /// No description provided for @settingsTermsResponsibilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your responsibilities'**
  String get settingsTermsResponsibilitiesTitle;

  /// No description provided for @settingsTermsTagline.
  ///
  /// In en, this message translates to:
  /// **'Rules for using this app.'**
  String get settingsTermsTagline;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsWeightUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit for totals'**
  String get settingsWeightUnit;

  /// No description provided for @settingsWeightUnitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get settingsWeightUnitKg;

  /// No description provided for @settingsWeightUnitLb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get settingsWeightUnitLb;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @todayDone.
  ///
  /// In en, this message translates to:
  /// **'Done for today. Nice work!'**
  String get todayDone;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today · {day}'**
  String todayLabel(String day);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @unexpectedError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get unexpectedError;

  /// No description provided for @usedInRoutines.
  ///
  /// In en, this message translates to:
  /// **'Used in routines'**
  String get usedInRoutines;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @viewProgress.
  ///
  /// In en, this message translates to:
  /// **'View progress'**
  String get viewProgress;

  /// No description provided for @weeklyPlan.
  ///
  /// In en, this message translates to:
  /// **'Weekly plan'**
  String get weeklyPlan;

  /// No description provided for @weeklyPlanHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to choose its routine. The same routine can be used on several days.'**
  String get weeklyPlanHint;

  /// No description provided for @workoutEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the exercises you are doing today.'**
  String get workoutEmptyBody;

  /// No description provided for @workoutEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No exercises'**
  String get workoutEmptyTitle;

  /// No description provided for @workoutInProgress.
  ///
  /// In en, this message translates to:
  /// **'Workout in progress'**
  String get workoutInProgress;

  /// No description provided for @workoutNotFound.
  ///
  /// In en, this message translates to:
  /// **'Workout not found'**
  String get workoutNotFound;

  /// No description provided for @workoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved'**
  String get workoutSaved;

  /// No description provided for @workoutTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Workout title'**
  String get workoutTitleLabel;

  /// No description provided for @workoutsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged yet.'**
  String get workoutsEmpty;

  /// No description provided for @yourStats.
  ///
  /// In en, this message translates to:
  /// **'Your stats'**
  String get yourStats;

  /// No description provided for @discsShort.
  ///
  /// In en, this message translates to:
  /// **'discs'**
  String get discsShort;

  /// No description provided for @loadTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get loadTypeLabel;

  /// No description provided for @loadTypeWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get loadTypeWeight;

  /// No description provided for @loadTypeDiscs.
  ///
  /// In en, this message translates to:
  /// **'Discs'**
  String get loadTypeDiscs;

  /// No description provided for @loadTypeWeightHint.
  ///
  /// In en, this message translates to:
  /// **'Sets are logged in this unit and count toward weekly volume.'**
  String get loadTypeWeightHint;

  /// No description provided for @loadTypeDiscsHint.
  ///
  /// In en, this message translates to:
  /// **'For cable and machine stacks: log how many discs (plates). Not counted in lb/kg volume.'**
  String get loadTypeDiscsHint;

  /// No description provided for @dashboardVolumeHint.
  ///
  /// In en, this message translates to:
  /// **'Volume counts weight exercises only; disc exercises are tracked in their own progress.'**
  String get dashboardVolumeHint;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Check your connection and try again.'**
  String get saveFailed;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'Offline: showing your last synced data (read-only)'**
  String get offlineBanner;

  /// No description provided for @syncingLocalData.
  ///
  /// In en, this message translates to:
  /// **'Uploading your data to your account…'**
  String get syncingLocalData;

  /// No description provided for @dashboardMuscleReps.
  ///
  /// In en, this message translates to:
  /// **'Reps per main muscle this week'**
  String get dashboardMuscleReps;

  /// No description provided for @dashboardMuscleRepsHint.
  ///
  /// In en, this message translates to:
  /// **'Completed reps of the exercises that train each muscle directly.'**
  String get dashboardMuscleRepsHint;

  /// No description provided for @openExercise.
  ///
  /// In en, this message translates to:
  /// **'Open exercise'**
  String get openExercise;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
