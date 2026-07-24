import 'package:flutter/material.dart';

/// Named, app-wide text roles — one place to tune the size and weight of a
/// *kind* of text (a card title, a data number, a tab label) instead of
/// scattering `copyWith(fontSize:/fontWeight:)` across widgets.
///
/// Colour is deliberately left to the call site (taken from the colour scheme),
/// so these roles are theme-invariant. That's why this is a plain helper
/// derived from the ambient [TextTheme] rather than a [ThemeExtension] like
/// `SemanticColors` — whose values genuinely differ light vs dark.
@immutable
class AppTextStyles {
  const AppTextStyles({
    required this.screenTitle,
    required this.cardTitle,
    required this.sectionHeader,
    required this.tabLabel,
    required this.tabLabelMuted,
    required this.appBarAction,
    required this.heroNumber,
    required this.dataNumber,
    required this.tableRow,
    required this.tableRowStrong,
    required this.setWeight,
    required this.metric,
    required this.buttonLabel,
  });

  /// Derives every role from a base [TextTheme], so roles inherit the app's
  /// font family, letter-spacing, and baseline sizes.
  factory AppTextStyles.fromTextTheme(TextTheme t) => AppTextStyles(
        screenTitle: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        cardTitle:
            t.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
        sectionHeader: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        tabLabel: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        tabLabelMuted: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        appBarAction:
            t.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
        heroNumber: t.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        dataNumber:
            t.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
        tableRow: t.titleMedium,
        tableRowStrong: t.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        setWeight: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        metric: t.bodyLarge,
        buttonLabel:
            t.bodyMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
      );

  /// The roles derived from the theme in scope.
  factory AppTextStyles.of(BuildContext context) =>
      AppTextStyles.fromTextTheme(Theme.of(context).textTheme);

  /// Prominent surface title, e.g. the lift name atop the weights sheet.
  final TextStyle? screenTitle;

  /// The title of an exercise or program card.
  final TextStyle? cardTitle;

  /// A list-section header, e.g. "Templates".
  final TextStyle? sectionHeader;

  /// The selected tab label.
  final TextStyle? tabLabel;

  /// The unselected tab label (same size, a touch lighter).
  final TextStyle? tabLabelMuted;

  /// An emphasised app-bar text action, e.g. "Finish".
  final TextStyle? appBarAction;

  /// The single large, editable number — the weights sheet's working weight.
  final TextStyle? heroNumber;

  /// A number you read and act on at a glance, e.g. the reps in a set circle.
  final TextStyle? dataNumber;

  /// A data-table row cell.
  final TextStyle? tableRow;

  /// A data-table row cell that carries the primary value (the weight column).
  final TextStyle? tableRowStrong;

  /// A per-set weight shown beneath a set circle.
  final TextStyle? setWeight;

  /// A supporting metric line, e.g. "23.75 kg / side".
  final TextStyle? metric;

  /// A button label sized for comfortable tapping.
  final TextStyle? buttonLabel;
}
