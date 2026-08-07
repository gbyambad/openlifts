import 'package:openlifts/l10n/app_localizations.dart';

/// Short day-of-week label. Index with `DateTime.weekday` (1 = Mon … 7 = Sun).
String weekdayShort(AppLocalizations loc, int weekday) => [
      loc.weekdayMon,
      loc.weekdayTue,
      loc.weekdayWed,
      loc.weekdayThu,
      loc.weekdayFri,
      loc.weekdaySat,
      loc.weekdaySun,
    ][weekday - 1];

/// Short month label. Index with `DateTime.month` (1 = Jan … 12 = Dec).
String monthShort(AppLocalizations loc, int month) => [
      loc.monthJan,
      loc.monthFeb,
      loc.monthMar,
      loc.monthApr,
      loc.monthMay,
      loc.monthJun,
      loc.monthJul,
      loc.monthAug,
      loc.monthSep,
      loc.monthOct,
      loc.monthNov,
      loc.monthDec,
    ][month - 1];
