import 'package:flutter/material.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/theme/app_text_styles.dart';
import 'package:openlifts/core/units/loadable.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/plate_bar.dart';

/// One row in the weights sheet: a set's weight and its rep target.
typedef WeightsSheetSet = ({double weightKg, int reps});

/// The single surface for editing a lift's working weights — opened by tapping
/// the header weight. Shows a compact plate diagram, a set·reps·kg table, and a
/// weight control for the selected row: type an exact weight or nudge it ±2.5
/// kg. StrongLifts-style: one deliberate place to dial weights.
///
/// The callbacks are the source of truth; the sheet mirrors each edit into a
/// local copy only so the table redraws while it is open:
/// - [onRowWeight] recalculates the selected set and the ones after it
///   (scheme-aware, via [recalcFromEditedSet]); editing the top set also
///   resyncs the anchor and warmup ramp.
/// - [onApplyAll] backs the "Even out all sets" action: re-resolves every set
///   from the implied anchor, undoing any per-set drift.
/// - [onAddSet] / [onRemoveLast] grow or shrink the set list (never below one).
/// - [onDeload] drops the whole lift by [deloadPercent] (loadable-rounded).
Future<void> showWeightsSheet(
  BuildContext context, {
  required String liftName,
  required List<WeightsSheetSet> sets,
  required List<SetGroupSpec> setGroups,
  required Unit unit,
  required double barKg,
  required double deloadPercent,
  required void Function(int setIndex, double kg) onRowWeight,
  required void Function(double anchorKg) onApplyAll,
  required VoidCallback onAddSet,
  required VoidCallback onRemoveLast,
  required VoidCallback onDeload,
}) {
  // A lift always has at least one working set; guard anyway so a malformed
  // prescription can't crash the sheet on the first weights[selected] read.
  if (sets.isEmpty) return Future<void>.value();

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _WeightsSheetBody(
      liftName: liftName,
      sets: sets,
      setGroups: setGroups,
      unit: unit,
      barKg: barKg,
      deloadPercent: deloadPercent,
      onRowWeight: onRowWeight,
      onApplyAll: onApplyAll,
      onAddSet: onAddSet,
      onRemoveLast: onRemoveLast,
      onDeload: onDeload,
    ),
  );
}

class _WeightsSheetBody extends StatefulWidget {
  const _WeightsSheetBody({
    required this.liftName,
    required this.sets,
    required this.setGroups,
    required this.unit,
    required this.barKg,
    required this.deloadPercent,
    required this.onRowWeight,
    required this.onApplyAll,
    required this.onAddSet,
    required this.onRemoveLast,
    required this.onDeload,
  });

  final String liftName;
  final List<WeightsSheetSet> sets;
  final List<SetGroupSpec> setGroups;
  final Unit unit;
  final double barKg;
  final double deloadPercent;
  final void Function(int setIndex, double kg) onRowWeight;
  final void Function(double anchorKg) onApplyAll;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveLast;
  final VoidCallback onDeload;

  @override
  State<_WeightsSheetBody> createState() => _WeightsSheetBodyState();
}

class _WeightsSheetBodyState extends State<_WeightsSheetBody> {
  late final List<double> _weights;
  late final List<int> _reps;
  int _selected = 0;

  // The weight field doubles as the display and the tap-to-type input; its text
  // stays in sync with [_weights] whenever the field is not being edited.
  late final TextEditingController _weightCtrl;
  final FocusNode _weightFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weights = [for (final s in widget.sets) s.weightKg];
    _reps = [for (final s in widget.sets) s.reps];
    _weightCtrl = TextEditingController(text: _fieldText());
    _weightFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _weightFocus
      ..removeListener(_onFocusChange)
      ..dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  String _fieldText() =>
      formatWeight(displayWeight(_weights[_selected], widget.unit));

  void _onFocusChange() {
    if (_weightFocus.hasFocus) {
      // Preselect the value so the first keystroke replaces it wholesale.
      _weightCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _weightCtrl.text.length,
      );
    } else {
      _commitField();
    }
    setState(() {}); // repaint the focus affordance
  }

  /// Refresh the field to the selected weight when it isn't being edited.
  void _syncField() {
    if (!_weightFocus.hasFocus) _weightCtrl.text = _fieldText();
  }

  double _toKg(double display) =>
      widget.unit == Unit.kg ? display : lbToKg(display);

  void _editSelected(double kg) {
    final next = recalcFromEditedSet(
      groups: widget.setGroups,
      currentWeights: _weights,
      editedIndex: _selected,
      editedWeight: kg,
    );
    setState(() => _weights.setAll(0, next));
    widget.onRowWeight(_selected, kg);
    _syncField();
  }

  /// Parse the typed weight and apply it; revert the field on invalid input.
  void _commitField() {
    final parsed = double.tryParse(_weightCtrl.text.trim());
    if (parsed == null || parsed < 0) {
      _weightCtrl.text = _fieldText();
      return;
    }
    _editSelected(_toKg(parsed));
    _weightCtrl.text = _fieldText();
  }

  void _select(int i) {
    _weightFocus.unfocus(); // commits any in-progress edit via the listener
    setState(() => _selected = i);
    _syncField();
  }

  void _deload() {
    _weightFocus.unfocus();
    // Derive the anchor from the top set (matching the controller's deload),
    // drop it, snap to loadable, and re-resolve every set locally so the sheet
    // reflects the change without closing.
    final factors = anchorFactors(widget.setGroups);
    final topFactor = factors.isNotEmpty ? factors[0] : 1.0;
    final anchor = topFactor == 0 ? _weights[0] : _weights[0] / topFactor;
    final deloaded =
        roundToLoadableKg(anchor * (1 - widget.deloadPercent / 100));
    final next =
        resolveWeightsForCount(widget.setGroups, _weights.length, deloaded);
    setState(() => _weights.setAll(0, next));
    widget.onDeload();
    _syncField();
  }

  void _evenOut() {
    _weightFocus.unfocus();
    // Derive the anchor from the selected row's scheme factor (same as
    // recalcFromEditedSet) so evening out from a back-off or ramp row
    // re-resolves correctly instead of treating that row's weight as the top.
    final factors = anchorFactors(widget.setGroups);
    final f = _selected < factors.length ? factors[_selected] : 1.0;
    final anchor = f == 0 ? _weights[_selected] : _weights[_selected] / f;
    final next =
        resolveWeightsForCount(widget.setGroups, _weights.length, anchor);
    setState(() => _weights.setAll(0, next));
    widget.onApplyAll(anchor);
    _syncField();
  }

  // Orange-tinted ± buttons, matching the sheet's primary accent.
  ButtonStyle _stepperStyle(ColorScheme scheme) => IconButton.styleFrom(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      );

  // A primary underline that reads as "editable" whether or not it has focus.
  InputBorder _underline(ColorScheme scheme) => UnderlineInputBorder(
        borderSide: BorderSide(color: scheme.primary, width: 2),
      );

  // Neutral outlined pill for the set-count controls — quieter than the default
  // primary-tinted OutlinedButton so they don't compete with the accent.
  ButtonStyle _setControlStyle(ColorScheme scheme) => OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: AppTextStyles.of(context).buttonLabel,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = AppTextStyles.of(context);
    final loc = AppLocalizations.of(context)!;

    final scroll = SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.liftName,
            style: text.screenTitle,
            textAlign: TextAlign.center,
          ),
          Text(
            loc.setOfLabel(_selected + 1, _weights.length),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PlateHint(
            weightKg: _weights[_selected],
            unit: widget.unit,
            barKg: widget.barKg,
            compact: true,
          ),
          const SizedBox(height: 20),
          _SetTable(
            weights: _weights,
            reps: _reps,
            unit: widget.unit,
            selected: _selected,
            onSelect: _select,
          ),
          const SizedBox(height: 16),
          // Weight control: ± steppers flank a borderless tap-to-type field
          // (a primary underline marks it editable), with a hint caption below.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 28,
                style: _stepperStyle(scheme),
                icon: const Icon(Icons.remove),
                onPressed: () {
                  final w = _weights[_selected];
                  _editSelected(w <= 2.5 ? 0 : w - 2.5);
                },
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 148,
                child: TextField(
                  controller: _weightCtrl,
                  focusNode: _weightFocus,
                  textAlign: TextAlign.center,
                  style: text.heroNumber,
                  cursorColor: scheme.primary,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    border: _underline(scheme),
                    enabledBorder: _underline(scheme),
                    focusedBorder: _underline(scheme),
                  ),
                  onSubmitted: (_) => _weightFocus.unfocus(),
                  onTapOutside: (_) => _weightFocus.unfocus(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                iconSize: 28,
                style: _stepperStyle(scheme),
                icon: const Icon(Icons.add),
                onPressed: () => _editSelected(_weights[_selected] + 2.5),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            loc.tapToTypeHint(widget.unit.name),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          // One-tap deload for the whole lift: a small, quiet tonal chip so it
          // reads as a utility action, not a primary one.
          Center(
            child: FilledButton.tonalIcon(
              onPressed: _deload,
              style: FilledButton.styleFrom(
                backgroundColor: scheme.surfaceContainerHigh,
                foregroundColor: scheme.onSurface,
                iconSize: 18,
                textStyle: theme.textTheme.bodyMedium,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.download_outlined),
              label: Text(
                loc.deloadPercentLabel(formatWeight(widget.deloadPercent)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // A balanced pair for growing/shrinking the set list. Remove is
          // disabled at one set — a lift always keeps a set.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: _setControlStyle(scheme),
                  onPressed: _weights.length <= 1
                      ? null
                      : () {
                          setState(() {
                            _weights.removeLast();
                            _reps.removeLast();
                            if (_selected >= _weights.length) {
                              _selected = _weights.length - 1;
                            }
                          });
                          widget.onRemoveLast();
                          _syncField();
                        },
                  child: Text(loc.removeSetButton),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: _setControlStyle(scheme),
                  onPressed: () {
                    setState(() {
                      _weights.add(_weights.last);
                      _reps.add(_reps.last);
                    });
                    widget.onAddSet();
                  },
                  child: Text(loc.addSetButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Low-emphasis escape hatch: flatten every set back onto the selected
          // row's implied anchor, after per-set edits have left them uneven.
          TextButton(
            onPressed: _evenOut,
            style: TextButton.styleFrom(textStyle: text.buttonLabel),
            child: Text(loc.evenOutAllSets),
          ),
        ],
      ),
    );

    // The scrollable body plus an always-visible close button, so the sheet can
    // be dismissed even when tall content hides the drag handle / scrim.
    return Stack(
      children: [
        scroll,
        Positioned(
          top: 0,
          right: 4,
          child: IconButton(
            tooltip: loc.close,
            icon: const Icon(Icons.close),
            onPressed: () {
              _weightFocus.unfocus();
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}

/// The set·reps·kg table. Tapping a row selects it for the stepper.
class _SetTable extends StatelessWidget {
  const _SetTable({
    required this.weights,
    required this.reps,
    required this.unit,
    required this.selected,
    required this.onSelect,
  });

  final List<double> weights;
  final List<int> reps;
  final Unit unit;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget cell(
      String text, {
      TextAlign align = TextAlign.start,
      TextStyle? s,
    }) {
      return Text(text, textAlign: align, style: s);
    }

    // Rows carry the data you read mid-set; the weight column is the number you
    // act on, so it's weighted. (Roles from [AppTextStyles].)
    final text = AppTextStyles.of(context);
    final rowStyle = text.tableRow;
    final weightStyle = text.tableRowStrong;

    // Selected-row text sits on the primary container, so it uses that tone.
    TextStyle? selStyle({bool bold = false}) => rowStyle?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: bold ? FontWeight.w700 : null,
        );

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: cell(loc.setColumnHeader, s: muted)),
                Expanded(
                  child: cell(
                    loc.repsColumnHeader,
                    align: TextAlign.center,
                    s: muted,
                  ),
                ),
                Expanded(
                  child: cell(unit.name, align: TextAlign.end, s: muted),
                ),
              ],
            ),
          ),
          for (var i = 0; i < weights.length; i++)
            InkWell(
              onTap: () => onSelect(i),
              child: Container(
                color: i == selected ? scheme.primaryContainer : null,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: cell(
                        '${i + 1}',
                        s: i == selected ? selStyle() : rowStyle,
                      ),
                    ),
                    Expanded(
                      child: cell(
                        '${reps[i]}',
                        align: TextAlign.center,
                        s: i == selected ? selStyle() : rowStyle,
                      ),
                    ),
                    Expanded(
                      child: cell(
                        formatWeight(displayWeight(weights[i], unit)),
                        align: TextAlign.end,
                        s: i == selected ? selStyle(bold: true) : weightStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
