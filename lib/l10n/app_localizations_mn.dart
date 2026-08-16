// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Mongolian (`mn`).
class AppLocalizationsMn extends AppLocalizations {
  AppLocalizationsMn([String locale = 'mn']) : super(locale);

  @override
  String get cancel => 'Цуцлах';

  @override
  String get startupFailed => 'Апп эхлэхэд алдаа гарлаа. Дахин эхлүүлнэ үү.';

  @override
  String get system => 'Систем';

  @override
  String get settingsTitle => 'Тохиргоо';

  @override
  String get settingsSectionPreferences => 'Тохиргоонууд';

  @override
  String get settingsUnits => 'Хэмжих нэгж';

  @override
  String get settingsDefaultRest => 'Стандарт амралт';

  @override
  String get settingsBarWeight => 'Штангийн жин';

  @override
  String get settingsSectionAppearance => 'Харагдац';

  @override
  String get settingsTheme => 'Загвар';

  @override
  String get themeLight => 'Цайвар';

  @override
  String get themeDark => 'Бараан';

  @override
  String get settingsLanguage => 'Хэл';

  @override
  String get settingsSectionYourData => 'Таны өгөгдөл';

  @override
  String get settingsBackupTitle => 'Өгөгдлөө нөөцлөх';

  @override
  String get settingsBackupSubtitle => 'Бүх өгөгдлийг файл болгон гаргаж авах';

  @override
  String get settingsRestoreTitle => 'Нөөцөөс сэргээх';

  @override
  String get settingsRestoreSubtitle => 'Бүх өгөгдлийг нөөц файлаар солих';

  @override
  String get navToday => 'Өнөөдөр';

  @override
  String get navHistory => 'Түүх';

  @override
  String get navProgress => 'Ахиц';

  @override
  String get navPrograms => 'Хөтөлбөр';

  @override
  String get navSettings => 'Тохиргоо';

  @override
  String errorGeneric(String error) {
    return 'Ямар нэг зүйл буруу боллоо.\n$error';
  }

  @override
  String get today => 'Өнөөдөр';

  @override
  String get tomorrow => 'Маргааш';

  @override
  String get weekdayMon => 'Да';

  @override
  String get weekdayTue => 'Мя';

  @override
  String get weekdayWed => 'Лх';

  @override
  String get weekdayThu => 'Пү';

  @override
  String get weekdayFri => 'Ба';

  @override
  String get weekdaySat => 'Бя';

  @override
  String get weekdaySun => 'Ня';

  @override
  String get monthJan => '1-р сар';

  @override
  String get monthFeb => '2-р сар';

  @override
  String get monthMar => '3-р сар';

  @override
  String get monthApr => '4-р сар';

  @override
  String get monthMay => '5-р сар';

  @override
  String get monthJun => '6-р сар';

  @override
  String get monthJul => '7-р сар';

  @override
  String get monthAug => '8-р сар';

  @override
  String get monthSep => '9-р сар';

  @override
  String get monthOct => '10-р сар';

  @override
  String get monthNov => '11-р сар';

  @override
  String get monthDec => '12-р сар';

  @override
  String scheduleTimesPerWeek(int count) {
    return 'долоо хоногт $count удаа';
  }

  @override
  String scheduleEveryNDays(int count) {
    return '$count өдөр тутам';
  }

  @override
  String get scheduleSetDays => 'тогтмол өдрүүд';

  @override
  String get setSchemeStraight => 'Шулуун сет';

  @override
  String get setSchemeTopBackoff => 'Дээд / Буурах сет';

  @override
  String get setSchemeRamp => 'Нэмэгдэх сет';

  @override
  String get save => 'Хадгалах';

  @override
  String setSchemeSheetTitle(String name) {
    return '$name — сет ба давталт';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count сет',
    );
    return '$_temp0';
  }

  @override
  String repsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count давталт',
    );
    return '$_temp0';
  }

  @override
  String duplicateProgramName(String name) {
    return '$name (Хуулбар)';
  }

  @override
  String get todayEmptyMessage =>
      'Идэвхтэй хөтөлбөр алга байна.\nХөтөлбөр таб-аас нэгийг сонгоно уу.';

  @override
  String get startWorkout => 'Дасгал эхлүүлэх';

  @override
  String get welcomeBackTitle => 'Тавтай морил';

  @override
  String welcomeBackMessage(int weeks) {
    String _temp0 = intl.Intl.pluralLogic(
      weeks,
      locale: localeName,
      other:
          'Ойролцоогоор $weeks долоо хоног завсарлажээ. Дасгалын хэлбэрээ сэргээж, булчингийн өвдөлтөөс сэргийлэхийн тулд хөнгөн жингээр эхлээрэй.',
    );
    return '$_temp0';
  }

  @override
  String get deload => 'Ачааллыг бууруулах';

  @override
  String get keepWeights => 'Жинг хэвээр үлдээх';

  @override
  String get applyDeload => 'Ачааллыг бууруулж хэрэглэх';

  @override
  String get historyTitle => 'Түүх';

  @override
  String get historyEmptyMessage =>
      'Одоогоор дасгал алга.\nДуусгасан дасгалууд энд харагдана.';

  @override
  String historyVolume(String value, String unit) {
    return '$value $unit эзэлхүүн';
  }

  @override
  String get couldNotLoadExercises => 'Дасгалуудыг ачаалж чадсангүй.';

  @override
  String get progressTitle => 'Ахиц';

  @override
  String get progressEmptyMessage =>
      'Одоогоор дасгал бүртгэгдээгүй байна.\nАхицаа харахын тулд дасгал хийж дуусгана уу.';

  @override
  String get bodyweightChartTitle => 'Биеийн жин';

  @override
  String get logMoreToSeeTrend =>
      'Чиг хандлагыг харахын тулд өөр нэг удаагийн бичлэг хийнэ үү.';

  @override
  String get progressRangeOneMonth => '1 сар';

  @override
  String get progressRangeThreeMonths => '3 сар';

  @override
  String get progressRangeSixMonths => '6 сар';

  @override
  String get progressRangeOneYear => '1 жил';

  @override
  String get progressRangeAll => 'Бүгд';

  @override
  String get progressRangeEmptyMessage => 'Энэ хугацаанд бүртгэл алга байна.';

  @override
  String get progressOverallTitle => 'Ерөнхий';

  @override
  String get progressStatStrength => 'Хүч чадал';

  @override
  String get progressChartsTitle => 'График';

  @override
  String get progressChartVolume => 'Дасгалын хэмжээ';

  @override
  String get progressRecordsTitle => 'Хувийн дээд амжилт';

  @override
  String get create => 'Үүсгэх';

  @override
  String get edit => 'Засах';

  @override
  String get delete => 'Устгах';

  @override
  String get start => 'Эхлүүлэх';

  @override
  String get schedule => 'Хуваарь';

  @override
  String get programsWeightsTab => 'Жин';

  @override
  String get programsEmptyMessage =>
      'Одоогоор хөтөлбөр алга.\nҮүсгэхийн тулд Үүсгэх дээр дарна уу.';

  @override
  String get programsSectionMine => 'Миний хөтөлбөрүүд';

  @override
  String get programsSectionTemplates => 'Загварууд';

  @override
  String get scheduleUpdateCta => 'Хуваарь шинэчлэх';

  @override
  String get scheduleUseCta => 'Энэ хөтөлбөрийг ашиглах';

  @override
  String get scheduleUpdatedMessage => 'Хуваарь шинэчлэгдлээ';

  @override
  String programNowActiveMessage(String name) {
    return '$name одоо идэвхтэй боллоо';
  }

  @override
  String get currentProgramLabel => 'Идэвхтэй хөтөлбөр';

  @override
  String nextWorkoutLabel(String next) {
    return 'Дараагийн: $next';
  }

  @override
  String get detailsTooltip => 'Дэлгэрэнгүй';

  @override
  String get noActiveProgramBanner =>
      'Идэвхтэй хөтөлбөр алга. Дасгал хийж эхлэхийн тулд доороос сонгоно уу.';

  @override
  String get duplicateAndCustomize => 'Хуулж, өөрчлөх';

  @override
  String deleteProgramConfirmTitle(String name) {
    return '\"$name\"-г устгах уу?';
  }

  @override
  String get deleteProgramConfirmMessage =>
      'Энэ нь хөтөлбөрийг устгана. Буцаах боломжгүй.';

  @override
  String get setsRepsTooltip => 'Сет ба давталт';

  @override
  String get programNotFound => 'Хөтөлбөр олдсонгүй.';

  @override
  String get trainingDays => 'Дасгалын өдрүүд';

  @override
  String get pickTrainingDaysHint =>
      'Дасгал хийх өдрүүдээ сонгоно уу. Дасгалууд эдгээр өдрүүдээр эргэлдэнэ.';

  @override
  String get workoutsLabel => 'Дасгалууд';

  @override
  String get newProgramTitle => 'Шинэ хөтөлбөр';

  @override
  String get editProgramTitle => 'Хөтөлбөр засах';

  @override
  String get programNameLabel => 'Хөтөлбөрийн нэр';

  @override
  String get addWorkoutDay => 'Дасгалын өдөр нэмэх';

  @override
  String get programSavedMessage => 'Хөтөлбөр хадгалагдлаа';

  @override
  String get renameDayTooltip => 'Өдрийн нэр солих';

  @override
  String get removeDayTooltip => 'Өдөр устгах';

  @override
  String get noExercisesYet => 'Одоогоор дасгал алга.';

  @override
  String get removeExerciseTooltip => 'Дасгал устгах';

  @override
  String get addExercise => 'Дасгал нэмэх';

  @override
  String get searchExercisesHint => 'Дасгал хайх';

  @override
  String get noMatchingExercises => 'Тохирох дасгал олдсонгүй.';

  @override
  String couldNotStartWorkout(String error) {
    return 'Дасгал эхлүүлж чадсангүй.\n$error';
  }

  @override
  String get leaveWorkoutTitle => 'Дасгалаас гарах уу?';

  @override
  String get leaveWorkoutMessage =>
      'Бүртгэсэн сетүүд хадгалагдахгүй — дасгалыг хадгалахын тулд дуусгана уу.';

  @override
  String get keepGoing => 'Үргэлжлүүлэх';

  @override
  String get leave => 'Гарах';

  @override
  String get finishWorkoutTitle => 'Дасгалыг дуусгах уу?';

  @override
  String finishWorkoutMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count сет бүртгэгдээгүй байна. Зөвхөн бүртгэсэн сетүүд хадгалагдана.',
    );
    return '$_temp0';
  }

  @override
  String get switchWorkoutTooltip => 'Дасгал солих';

  @override
  String get finish => 'Дуусгах';

  @override
  String get workoutTab => 'Дасгал';

  @override
  String get warmupTab => 'Урьдчилан дулаацуулах';

  @override
  String get allSetsLogged => 'Бүх сет бүртгэгдлээ';

  @override
  String setsProgress(int done, int total) {
    return '$done / $total сет';
  }

  @override
  String get restLabel => 'Амралт';

  @override
  String get skip => 'Алгасах';

  @override
  String get logBodyWeightTitle => 'Биеийн жин бүртгэх';

  @override
  String get howToPerform => 'Хэрхэн хийх';

  @override
  String get noInstructionsYet => 'Энэ дасгалын зааварчилгаа одоохондоо алга.';

  @override
  String get bodyWeightLabel => 'Биеийн жин';

  @override
  String get logAction => 'Бүртгэх';

  @override
  String get noWarmupNeeded =>
      'Урьдчилан дулаацуулах шаардлагагүй — ажлын жингээр эхэл.';

  @override
  String get emptyBarLabel => 'хоосон штанга';

  @override
  String perSideLabel(String value, String unit) {
    return '$value $unit/тал';
  }

  @override
  String setOfLabel(int current, int total) {
    return '$total-н $current-р сет';
  }

  @override
  String tapToTypeHint(String unit) {
    return '$unit · бичихийн тулд дарна уу';
  }

  @override
  String deloadPercentLabel(String percent) {
    return '$percent%-иар бууруулах';
  }

  @override
  String get removeSetButton => 'Сет хасах';

  @override
  String get addSetButton => 'Сет нэмэх';

  @override
  String get evenOutAllSets => 'Бүх сетийг тэгшитгэх';

  @override
  String get close => 'Хаах';

  @override
  String get setColumnHeader => 'Сет';

  @override
  String get repsColumnHeader => 'Давталт';

  @override
  String get niceWork => 'Сайн ажиллалаа!';

  @override
  String dayCompleteLabel(String dayName) {
    return '$dayName дуусгалаа';
  }

  @override
  String get setsLoggedLabel => 'Бүртгэсэн сет';

  @override
  String get totalVolumeLabel => 'Нийт ачаалал';

  @override
  String get done => 'Дууслаа';

  @override
  String get exerciseNotFound => 'Дасгал олдсонгүй.';

  @override
  String get currentLabel => 'Одоогийн';

  @override
  String get noInstructionsYetShort => 'Зааварчилгаа алга.';

  @override
  String get recentTopSets => 'Сүүлийн үеийн дээд сетүүд';

  @override
  String exportFailed(String error) {
    return 'Экспорт амжилтгүй боллоо: $error';
  }

  @override
  String couldNotReadFile(String error) {
    return 'Файлыг унших боломжгүй байна: $error';
  }

  @override
  String get restoreConfirmTitle => 'Нөөцөөс сэргээх үү?';

  @override
  String get restoreConfirmMessage =>
      'Энэ нь бүх одоогийн өгөгдлийг нөөц файлаар солино. Таны одоогийн өгөгдөл эхлээд нөөц файлд хадгалагдах ч апп дотор буцаах боломжгүй.';

  @override
  String get replace => 'Солих';

  @override
  String get backupRestoredMessage => 'Нөөц сэргээгдлээ';

  @override
  String restoreFailed(String error) {
    return 'Сэргээхэд алдаа гарлаа: $error';
  }
}
