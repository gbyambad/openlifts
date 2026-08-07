import 'dart:ui' show PlatformDispatcher;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';
import 'package:openlifts/features/settings/domain/settings_repository.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(Ref ref) =>
    DriftSettingsRepository(ref.watch(appDatabaseProvider));

/// Reactive app settings.
final settingsProvider = StreamProvider<Setting>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// The active theme mode, defaulting to the brand's dark ground until settings
/// load. Watched by the root `MaterialApp`.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider).maybeWhen(
        data: (s) => s.themeMode,
        orElse: () => ThemeMode.dark,
      ),
);

/// The active UI language mode (`system`/`en`/`mn`), defaulting to `system`
/// until settings load.
final languageModeProvider = Provider<AppLanguage>(
  (ref) => ref.watch(settingsProvider).maybeWhen(
        data: (s) => s.languageMode,
        orElse: () => AppLanguage.system,
      ),
);

/// The [Locale] to hand `MaterialApp`; `null` means "follow the device
/// locale", matching `MaterialApp.locale`'s own contract.
final localeProvider = Provider<Locale?>((ref) {
  switch (ref.watch(languageModeProvider)) {
    case AppLanguage.system:
      return null;
    case AppLanguage.en:
      return const Locale('en');
    case AppLanguage.mn:
      return const Locale('mn');
  }
});

/// A concrete, always-supported [AppLocalizations] instance for
/// application-layer code (Riverpod providers) that builds user-facing
/// strings but has no `BuildContext` to call `AppLocalizations.of`.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final languageCode = switch (ref.watch(languageModeProvider)) {
    AppLanguage.en => 'en',
    AppLanguage.mn => 'mn',
    AppLanguage.system => _systemLanguageCode(),
  };
  return lookupAppLocalizations(Locale(languageCode));
});

String _systemLanguageCode() {
  final code = PlatformDispatcher.instance.locale.languageCode;
  return AppLocalizations.supportedLocales.any((l) => l.languageCode == code)
      ? code
      : 'en';
}

/// Edits to app settings.
///
/// Kept alive: the screen obtains this notifier with `ref.read(...notifier)`
/// (no listener), so an auto-dispose controller would be torn down before a
/// button's async `_save` completes — its `Ref` would then throw
/// `UnmountedRefException` mid-write and the tap would silently do nothing.
@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  void build() {}

  Future<void> setUnit(Unit unit) =>
      _save(SettingsCompanion(unit: Value(unit)));

  Future<void> setRest(int seconds) =>
      _save(SettingsCompanion(restTimerSeconds: Value(seconds)));

  Future<void> setBarWeight(double kg) =>
      _save(SettingsCompanion(barWeightKg: Value(kg)));

  Future<void> setThemeMode(ThemeMode mode) =>
      _save(SettingsCompanion(themeMode: Value(mode)));

  Future<void> setLanguageMode(AppLanguage mode) =>
      _save(SettingsCompanion(languageMode: Value(mode)));

  Future<void> _save(SettingsCompanion changes) =>
      ref.read(settingsRepositoryProvider).save(changes);
}
