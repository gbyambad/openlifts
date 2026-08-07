import 'package:flutter/material.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// Wraps [home] in a [MaterialApp] with localization wired up and pinned to
/// English — widgets under test call `AppLocalizations.of(context)!`, which
/// needs the delegate registered, and pinning the locale keeps `find.text`
/// assertions independent of the host machine's locale.
Widget wrapWithLocalizations(Widget home) => MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
