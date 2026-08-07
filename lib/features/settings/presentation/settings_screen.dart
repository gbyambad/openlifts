import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/backup/presentation/backup_actions.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';

/// Settings, grouped into cards: workout preferences, appearance, and data.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsProvider);
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.settingsTitle)),
      body: AsyncView(
        value: async,
        data: (s) {
          final ctrl = ref.read(settingsControllerProvider.notifier);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SectionHeader(loc.settingsSectionPreferences),
              _Card(
                children: [
                  ListTile(
                    title: Text(loc.settingsUnits),
                    trailing: SegmentedButton<Unit>(
                      segments: const [
                        ButtonSegment(value: Unit.kg, label: Text('kg')),
                        ButtonSegment(value: Unit.lb, label: Text('lb')),
                      ],
                      selected: {s.unit},
                      showSelectedIcon: false,
                      onSelectionChanged: (sel) => ctrl.setUnit(sel.first),
                    ),
                  ),
                  const _Line(),
                  ListTile(
                    title: Text(loc.settingsDefaultRest),
                    trailing: _MenuValue<int>(
                      value: _mmss(s.restTimerSeconds),
                      selected: s.restTimerSeconds,
                      items: const [90, 120, 180, 300],
                      labelOf: _mmss,
                      onSelected: ctrl.setRest,
                    ),
                  ),
                  const _Line(),
                  ListTile(
                    title: Text(loc.settingsBarWeight),
                    trailing: _MenuValue<double>(
                      value: '${s.barWeightKg.toStringAsFixed(0)} kg',
                      selected: s.barWeightKg,
                      items: const [20, 15, 10, 7],
                      labelOf: (kg) => '${kg.toStringAsFixed(0)} kg',
                      onSelected: ctrl.setBarWeight,
                    ),
                  ),
                ],
              ),
              _SectionHeader(loc.settingsSectionAppearance),
              _Card(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loc.settingsTheme,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: [
                              ButtonSegment(
                                value: ThemeMode.system,
                                label: Text(loc.system),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                label: Text(loc.themeLight),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                label: Text(loc.themeDark),
                              ),
                            ],
                            selected: {s.themeMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (sel) =>
                                ctrl.setThemeMode(sel.first),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          loc.settingsLanguage,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<AppLanguage>(
                            segments: [
                              ButtonSegment(
                                value: AppLanguage.system,
                                label: Text(loc.system),
                              ),
                              const ButtonSegment(
                                value: AppLanguage.mn,
                                label: Text('Монгол'),
                              ),
                              const ButtonSegment(
                                value: AppLanguage.en,
                                label: Text('English'),
                              ),
                            ],
                            selected: {s.languageMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (sel) =>
                                ctrl.setLanguageMode(sel.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _SectionHeader(loc.settingsSectionYourData),
              _Card(
                children: [
                  ListTile(
                    leading: const Icon(Icons.upload_file_outlined),
                    title: Text(loc.settingsBackupTitle),
                    subtitle: Text(loc.settingsBackupSubtitle),
                    onTap: () => exportBackup(context, ref),
                  ),
                  const _Line(),
                  ListTile(
                    leading: const Icon(Icons.download_outlined),
                    title: Text(loc.settingsRestoreTitle),
                    subtitle: Text(loc.settingsRestoreSubtitle),
                    onTap: () => importBackup(context, ref),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An uppercase, tracked section label above a settings card.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// A rounded surface grouping related settings rows.
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 16);
}

/// A trailing "value + menu" control: shows the current value in the accent
/// colour and opens a menu of choices on tap.
class _MenuValue<T> extends StatelessWidget {
  const _MenuValue({
    required this.value,
    required this.selected,
    required this.items,
    required this.labelOf,
    required this.onSelected,
  });

  final String value;
  final T selected;
  final List<T> items;
  final String Function(T) labelOf;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          CheckedPopupMenuItem(
            value: item,
            checked: item == selected,
            child: Text(labelOf(item)),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: theme.colorScheme.primary),
          ),
          Icon(
            Icons.arrow_drop_down,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

String _mmss(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
