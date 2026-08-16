// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get startupFailed => 'Startup failed. Please restart.';

  @override
  String get system => 'System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsUnits => 'Units';

  @override
  String get settingsDefaultRest => 'Default rest';

  @override
  String get settingsBarWeight => 'Bar weight';

  @override
  String get settingsSectionAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsSectionYourData => 'Your data';

  @override
  String get settingsBackupTitle => 'Back up my data';

  @override
  String get settingsBackupSubtitle => 'Export everything to a file you keep';

  @override
  String get settingsRestoreTitle => 'Restore from backup';

  @override
  String get settingsRestoreSubtitle => 'Replace all data with a backup file';

  @override
  String get navToday => 'Today';

  @override
  String get navHistory => 'History';

  @override
  String get navProgress => 'Progress';

  @override
  String get navPrograms => 'Programs';

  @override
  String get navSettings => 'Settings';

  @override
  String errorGeneric(String error) {
    return 'Something went wrong.\n$error';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String scheduleTimesPerWeek(int count) {
    return '$count×/week';
  }

  @override
  String scheduleEveryNDays(int count) {
    return 'every $count days';
  }

  @override
  String get scheduleSetDays => 'set days';

  @override
  String get setSchemeStraight => 'Straight sets';

  @override
  String get setSchemeTopBackoff => 'Top / Back-off';

  @override
  String get setSchemeRamp => 'Ramp';

  @override
  String get save => 'Save';

  @override
  String setSchemeSheetTitle(String name) {
    return '$name — sets & reps';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '$count set',
    );
    return '$_temp0';
  }

  @override
  String repsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reps',
      one: '$count rep',
    );
    return '$_temp0';
  }

  @override
  String duplicateProgramName(String name) {
    return '$name (Copy)';
  }

  @override
  String get todayEmptyMessage =>
      'No active program yet.\nPick one in the Programs tab.';

  @override
  String get startWorkout => 'Start workout';

  @override
  String get welcomeBackTitle => 'Welcome back';

  @override
  String welcomeBackMessage(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other:
          'It\'s been about $weeks weeks. Ease back in with lighter weights to rebuild form and avoid soreness.',
      one:
          'It\'s been about 1 week. Ease back in with lighter weights to rebuild form and avoid soreness.',
    );
    return '$_temp0';
  }

  @override
  String get deload => 'Deload';

  @override
  String get keepWeights => 'Keep weights';

  @override
  String get applyDeload => 'Apply deload';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyMessage =>
      'No workouts yet.\nFinished workouts show up here.';

  @override
  String historyVolume(String value, String unit) {
    return '$value $unit vol';
  }

  @override
  String get couldNotLoadExercises => 'Couldn\'t load exercises.';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressEmptyMessage =>
      'No workouts logged yet.\nFinish a workout to see your progress.';

  @override
  String get bodyweightChartTitle => 'Bodyweight';

  @override
  String get logMoreToSeeTrend => 'Log one more session to see a trend.';

  @override
  String get progressRangeOneMonth => '1M';

  @override
  String get progressRangeThreeMonths => '3M';

  @override
  String get progressRangeSixMonths => '6M';

  @override
  String get progressRangeOneYear => '1Y';

  @override
  String get progressRangeAll => 'ALL';

  @override
  String get progressRangeEmptyMessage => 'No data in this range yet.';

  @override
  String get progressOverallTitle => 'Overall';

  @override
  String get progressStatStrength => 'Strength';

  @override
  String get progressChartsTitle => 'Charts';

  @override
  String get progressChartVolume => 'Training Volume';

  @override
  String get progressRecordsTitle => 'Personal Records';

  @override
  String get create => 'Create';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get start => 'Start';

  @override
  String get schedule => 'Schedule';

  @override
  String get programsWeightsTab => 'Weights';

  @override
  String get programsEmptyMessage =>
      'No programs yet.\nTap Create to build one.';

  @override
  String get programsSectionMine => 'My programs';

  @override
  String get programsSectionTemplates => 'Templates';

  @override
  String get scheduleUpdateCta => 'Update schedule';

  @override
  String get scheduleUseCta => 'Use this program';

  @override
  String get scheduleUpdatedMessage => 'Schedule updated';

  @override
  String programNowActiveMessage(String name) {
    return '$name is now active';
  }

  @override
  String get currentProgramLabel => 'Current program';

  @override
  String nextWorkoutLabel(String next) {
    return 'Next: $next';
  }

  @override
  String get detailsTooltip => 'Details';

  @override
  String get noActiveProgramBanner =>
      'No active program. Pick one below to start training.';

  @override
  String get duplicateAndCustomize => 'Duplicate & customize';

  @override
  String deleteProgramConfirmTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteProgramConfirmMessage =>
      'This removes the program. It cannot be undone.';

  @override
  String get setsRepsTooltip => 'Sets & reps';

  @override
  String get programNotFound => 'Program not found.';

  @override
  String get trainingDays => 'Training days';

  @override
  String get pickTrainingDaysHint =>
      'Pick the days you train. Workouts rotate across them.';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get newProgramTitle => 'New program';

  @override
  String get editProgramTitle => 'Edit program';

  @override
  String get programNameLabel => 'Program name';

  @override
  String get addWorkoutDay => 'Add workout day';

  @override
  String get programSavedMessage => 'Program saved';

  @override
  String get renameDayTooltip => 'Rename day';

  @override
  String get removeDayTooltip => 'Remove day';

  @override
  String get noExercisesYet => 'No exercises yet.';

  @override
  String get removeExerciseTooltip => 'Remove exercise';

  @override
  String get addExercise => 'Add exercise';

  @override
  String get searchExercisesHint => 'Search exercises';

  @override
  String get noMatchingExercises => 'No matching exercises.';

  @override
  String couldNotStartWorkout(String error) {
    return 'Could not start workout.\n$error';
  }

  @override
  String get leaveWorkoutTitle => 'Leave workout?';

  @override
  String get leaveWorkoutMessage =>
      'Your logged sets will be discarded — finish the workout to save them.';

  @override
  String get keepGoing => 'Keep going';

  @override
  String get leave => 'Leave';

  @override
  String get finishWorkoutTitle => 'Finish workout?';

  @override
  String finishWorkoutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets are not logged. Only logged sets are saved.',
      one: '$count set is not logged. Only logged sets are saved.',
    );
    return '$_temp0';
  }

  @override
  String get switchWorkoutTooltip => 'Switch workout';

  @override
  String get finish => 'Finish';

  @override
  String get workoutTab => 'Workout';

  @override
  String get warmupTab => 'Warmup';

  @override
  String get allSetsLogged => 'All sets logged';

  @override
  String setsProgress(int done, int total) {
    return '$done / $total sets';
  }

  @override
  String get restLabel => 'Rest';

  @override
  String get skip => 'Skip';

  @override
  String get logBodyWeightTitle => 'Log body weight';

  @override
  String get howToPerform => 'How to perform';

  @override
  String get noInstructionsYet => 'No instructions for this exercise yet.';

  @override
  String get bodyWeightLabel => 'Body weight';

  @override
  String get logAction => 'Log';

  @override
  String get noWarmupNeeded =>
      'No warmup needed — start with the working weight.';

  @override
  String get emptyBarLabel => 'empty bar';

  @override
  String perSideLabel(String value, String unit) {
    return '$value $unit/side';
  }

  @override
  String setOfLabel(int current, int total) {
    return 'Set $current of $total';
  }

  @override
  String tapToTypeHint(String unit) {
    return '$unit · tap to type';
  }

  @override
  String deloadPercentLabel(String percent) {
    return 'Deload $percent%';
  }

  @override
  String get removeSetButton => 'Remove set';

  @override
  String get addSetButton => 'Add set';

  @override
  String get evenOutAllSets => 'Even out all sets';

  @override
  String get close => 'Close';

  @override
  String get setColumnHeader => 'Set';

  @override
  String get repsColumnHeader => 'Reps';

  @override
  String get niceWork => 'Nice work!';

  @override
  String dayCompleteLabel(String dayName) {
    return '$dayName complete';
  }

  @override
  String get setsLoggedLabel => 'Sets logged';

  @override
  String get totalVolumeLabel => 'Total volume';

  @override
  String get done => 'Done';

  @override
  String get exerciseNotFound => 'Exercise not found.';

  @override
  String get currentLabel => 'Current';

  @override
  String get noInstructionsYetShort => 'No instructions yet.';

  @override
  String get recentTopSets => 'Recent top sets';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String couldNotReadFile(String error) {
    return 'Could not read file: $error';
  }

  @override
  String get restoreConfirmTitle => 'Restore from backup?';

  @override
  String get restoreConfirmMessage =>
      'This replaces all current data with the backup. Your current data is saved to a safety file first, but this cannot be undone in the app.';

  @override
  String get replace => 'Replace';

  @override
  String get backupRestoredMessage => 'Backup restored';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }
}
