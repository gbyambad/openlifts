import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_mn.dart';

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
    Locale('mn')
  ];

  /// Generic cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Shown if the app's startup seeding fails
  ///
  /// In en, this message translates to:
  /// **'Startup failed. Please restart.'**
  String get startupFailed;

  /// Generic 'follow system default' option, used for both theme and language pickers
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get settingsUnits;

  /// No description provided for @settingsDefaultRest.
  ///
  /// In en, this message translates to:
  /// **'Default rest'**
  String get settingsDefaultRest;

  /// No description provided for @settingsBarWeight.
  ///
  /// In en, this message translates to:
  /// **'Bar weight'**
  String get settingsBarWeight;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsSectionYourData.
  ///
  /// In en, this message translates to:
  /// **'Your data'**
  String get settingsSectionYourData;

  /// No description provided for @settingsBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up my data'**
  String get settingsBackupTitle;

  /// No description provided for @settingsBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export everything to a file you keep'**
  String get settingsBackupSubtitle;

  /// No description provided for @settingsRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get settingsRestoreTitle;

  /// No description provided for @settingsRestoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data with a backup file'**
  String get settingsRestoreSubtitle;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @navPrograms.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get navPrograms;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Generic error state shown when an AsyncValue fails to load
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\n{error}'**
  String errorGeneric(String error);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @scheduleTimesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{count}×/week'**
  String scheduleTimesPerWeek(int count);

  /// No description provided for @scheduleEveryNDays.
  ///
  /// In en, this message translates to:
  /// **'every {count} days'**
  String scheduleEveryNDays(int count);

  /// No description provided for @scheduleSetDays.
  ///
  /// In en, this message translates to:
  /// **'set days'**
  String get scheduleSetDays;

  /// No description provided for @setSchemeStraight.
  ///
  /// In en, this message translates to:
  /// **'Straight sets'**
  String get setSchemeStraight;

  /// No description provided for @setSchemeTopBackoff.
  ///
  /// In en, this message translates to:
  /// **'Top / Back-off'**
  String get setSchemeTopBackoff;

  /// No description provided for @setSchemeRamp.
  ///
  /// In en, this message translates to:
  /// **'Ramp'**
  String get setSchemeRamp;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @setSchemeSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — sets & reps'**
  String setSchemeSheetTitle(String name);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} set} other {{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @repsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} rep} other {{count} reps}}'**
  String repsCount(int count);

  /// No description provided for @duplicateProgramName.
  ///
  /// In en, this message translates to:
  /// **'{name} (Copy)'**
  String duplicateProgramName(String name);

  /// No description provided for @todayEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No active program yet.\nPick one in the Programs tab.'**
  String get todayEmptyMessage;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get startWorkout;

  /// No description provided for @welcomeBackTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBackTitle;

  /// No description provided for @welcomeBackMessage.
  ///
  /// In en, this message translates to:
  /// **'{weeks, plural, one {It\'s been about 1 week. Ease back in with lighter weights to rebuild form and avoid soreness.} other {It\'s been about {weeks} weeks. Ease back in with lighter weights to rebuild form and avoid soreness.}}'**
  String welcomeBackMessage(int weeks);

  /// No description provided for @deload.
  ///
  /// In en, this message translates to:
  /// **'Deload'**
  String get deload;

  /// No description provided for @keepWeights.
  ///
  /// In en, this message translates to:
  /// **'Keep weights'**
  String get keepWeights;

  /// No description provided for @applyDeload.
  ///
  /// In en, this message translates to:
  /// **'Apply deload'**
  String get applyDeload;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get historyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet.\nFinished workouts show up here.'**
  String get historyEmptyMessage;

  /// No description provided for @historyVolume.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit} vol'**
  String historyVolume(String value, String unit);

  /// No description provided for @couldNotLoadExercises.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load exercises.'**
  String get couldNotLoadExercises;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No workouts logged yet.\nFinish a workout to see your progress.'**
  String get progressEmptyMessage;

  /// No description provided for @bodyweightChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bodyweightChartTitle;

  /// No description provided for @logMoreToSeeTrend.
  ///
  /// In en, this message translates to:
  /// **'Log one more session to see a trend.'**
  String get logMoreToSeeTrend;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @programsWeightsTab.
  ///
  /// In en, this message translates to:
  /// **'Weights'**
  String get programsWeightsTab;

  /// No description provided for @programsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No programs yet.\nTap Create to build one.'**
  String get programsEmptyMessage;

  /// No description provided for @programsSectionMine.
  ///
  /// In en, this message translates to:
  /// **'My programs'**
  String get programsSectionMine;

  /// No description provided for @programsSectionTemplates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get programsSectionTemplates;

  /// No description provided for @scheduleUpdateCta.
  ///
  /// In en, this message translates to:
  /// **'Update schedule'**
  String get scheduleUpdateCta;

  /// No description provided for @scheduleUseCta.
  ///
  /// In en, this message translates to:
  /// **'Use this program'**
  String get scheduleUseCta;

  /// No description provided for @scheduleUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Schedule updated'**
  String get scheduleUpdatedMessage;

  /// No description provided for @programNowActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now active'**
  String programNowActiveMessage(String name);

  /// No description provided for @currentProgramLabel.
  ///
  /// In en, this message translates to:
  /// **'Current program'**
  String get currentProgramLabel;

  /// No description provided for @nextWorkoutLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {next}'**
  String nextWorkoutLabel(String next);

  /// No description provided for @detailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsTooltip;

  /// No description provided for @noActiveProgramBanner.
  ///
  /// In en, this message translates to:
  /// **'No active program. Pick one below to start training.'**
  String get noActiveProgramBanner;

  /// No description provided for @duplicateAndCustomize.
  ///
  /// In en, this message translates to:
  /// **'Duplicate & customize'**
  String get duplicateAndCustomize;

  /// No description provided for @deleteProgramConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteProgramConfirmTitle(String name);

  /// No description provided for @deleteProgramConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes the program. It cannot be undone.'**
  String get deleteProgramConfirmMessage;

  /// No description provided for @setsRepsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sets & reps'**
  String get setsRepsTooltip;

  /// No description provided for @programNotFound.
  ///
  /// In en, this message translates to:
  /// **'Program not found.'**
  String get programNotFound;

  /// No description provided for @trainingDays.
  ///
  /// In en, this message translates to:
  /// **'Training days'**
  String get trainingDays;

  /// No description provided for @pickTrainingDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Pick the days you train. Workouts rotate across them.'**
  String get pickTrainingDaysHint;

  /// No description provided for @workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// No description provided for @newProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get newProgramTitle;

  /// No description provided for @editProgramTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit program'**
  String get editProgramTitle;

  /// No description provided for @programNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Program name'**
  String get programNameLabel;

  /// No description provided for @addWorkoutDay.
  ///
  /// In en, this message translates to:
  /// **'Add workout day'**
  String get addWorkoutDay;

  /// No description provided for @programSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Program saved'**
  String get programSavedMessage;

  /// No description provided for @renameDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename day'**
  String get renameDayTooltip;

  /// No description provided for @removeDayTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove day'**
  String get removeDayTooltip;

  /// No description provided for @noExercisesYet.
  ///
  /// In en, this message translates to:
  /// **'No exercises yet.'**
  String get noExercisesYet;

  /// No description provided for @removeExerciseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove exercise'**
  String get removeExerciseTooltip;

  /// No description provided for @addExercise.
  ///
  /// In en, this message translates to:
  /// **'Add exercise'**
  String get addExercise;

  /// No description provided for @searchExercisesHint.
  ///
  /// In en, this message translates to:
  /// **'Search exercises'**
  String get searchExercisesHint;

  /// No description provided for @noMatchingExercises.
  ///
  /// In en, this message translates to:
  /// **'No matching exercises.'**
  String get noMatchingExercises;

  /// No description provided for @couldNotStartWorkout.
  ///
  /// In en, this message translates to:
  /// **'Could not start workout.\n{error}'**
  String couldNotStartWorkout(String error);

  /// No description provided for @leaveWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave workout?'**
  String get leaveWorkoutTitle;

  /// No description provided for @leaveWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Your logged sets will be discarded — finish the workout to save them.'**
  String get leaveWorkoutMessage;

  /// No description provided for @keepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get keepGoing;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @finishWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish workout?'**
  String get finishWorkoutTitle;

  /// No description provided for @finishWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {{count} set is not logged. Only logged sets are saved.} other {{count} sets are not logged. Only logged sets are saved.}}'**
  String finishWorkoutMessage(int count);

  /// No description provided for @switchWorkoutTooltip.
  ///
  /// In en, this message translates to:
  /// **'Switch workout'**
  String get switchWorkoutTooltip;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @workoutTab.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get workoutTab;

  /// No description provided for @warmupTab.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get warmupTab;

  /// No description provided for @allSetsLogged.
  ///
  /// In en, this message translates to:
  /// **'All sets logged'**
  String get allSetsLogged;

  /// No description provided for @setsProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} sets'**
  String setsProgress(int done, int total);

  /// No description provided for @restLabel.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get restLabel;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @logBodyWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Log body weight'**
  String get logBodyWeightTitle;

  /// No description provided for @howToPerform.
  ///
  /// In en, this message translates to:
  /// **'How to perform'**
  String get howToPerform;

  /// No description provided for @noInstructionsYet.
  ///
  /// In en, this message translates to:
  /// **'No instructions for this exercise yet.'**
  String get noInstructionsYet;

  /// No description provided for @bodyWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Body weight'**
  String get bodyWeightLabel;

  /// No description provided for @logAction.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logAction;

  /// No description provided for @noWarmupNeeded.
  ///
  /// In en, this message translates to:
  /// **'No warmup needed — start with the working weight.'**
  String get noWarmupNeeded;

  /// No description provided for @emptyBarLabel.
  ///
  /// In en, this message translates to:
  /// **'empty bar'**
  String get emptyBarLabel;

  /// No description provided for @perSideLabel.
  ///
  /// In en, this message translates to:
  /// **'{value} {unit}/side'**
  String perSideLabel(String value, String unit);

  /// No description provided for @setOfLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {current} of {total}'**
  String setOfLabel(int current, int total);

  /// No description provided for @tapToTypeHint.
  ///
  /// In en, this message translates to:
  /// **'{unit} · tap to type'**
  String tapToTypeHint(String unit);

  /// No description provided for @deloadPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Deload {percent}%'**
  String deloadPercentLabel(String percent);

  /// No description provided for @removeSetButton.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSetButton;

  /// No description provided for @addSetButton.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSetButton;

  /// No description provided for @evenOutAllSets.
  ///
  /// In en, this message translates to:
  /// **'Even out all sets'**
  String get evenOutAllSets;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @setColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get setColumnHeader;

  /// No description provided for @repsColumnHeader.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get repsColumnHeader;

  /// No description provided for @niceWork.
  ///
  /// In en, this message translates to:
  /// **'Nice work!'**
  String get niceWork;

  /// No description provided for @dayCompleteLabel.
  ///
  /// In en, this message translates to:
  /// **'{dayName} complete'**
  String dayCompleteLabel(String dayName);

  /// No description provided for @setsLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets logged'**
  String get setsLoggedLabel;

  /// No description provided for @totalVolumeLabel.
  ///
  /// In en, this message translates to:
  /// **'Total volume'**
  String get totalVolumeLabel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @exerciseNotFound.
  ///
  /// In en, this message translates to:
  /// **'Exercise not found.'**
  String get exerciseNotFound;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @noInstructionsYetShort.
  ///
  /// In en, this message translates to:
  /// **'No instructions yet.'**
  String get noInstructionsYetShort;

  /// No description provided for @recentTopSets.
  ///
  /// In en, this message translates to:
  /// **'Recent top sets'**
  String get recentTopSets;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @couldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Could not read file: {error}'**
  String couldNotReadFile(String error);

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from backup?'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This replaces all current data with the backup. Your current data is saved to a safety file first, but this cannot be undone in the app.'**
  String get restoreConfirmMessage;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @backupRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup restored'**
  String get backupRestoredMessage;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);
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
      <String>['en', 'mn'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'mn':
      return AppLocalizationsMn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
