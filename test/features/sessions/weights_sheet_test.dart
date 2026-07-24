import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/features/sessions/presentation/weights_sheet.dart';

/// Pumps a button that opens the weights sheet, recording every callback.
Future<void> _open(
  WidgetTester tester, {
  required List<WeightsSheetSet> sets,
  required List<List<num>> rowWeights,
  required List<double> applied,
  required List<String> events,
  List<SetGroupSpec> setGroups = const [],
  Unit unit = Unit.kg,
  double deloadPercent = 10,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showWeightsSheet(
              context,
              liftName: 'Squat',
              sets: sets,
              setGroups: setGroups,
              unit: unit,
              barKg: 20,
              deloadPercent: deloadPercent,
              onRowWeight: (i, kg) => rowWeights.add([i, kg]),
              onApplyAll: applied.add,
              onAddSet: () => events.add('add'),
              onRemoveLast: () => events.add('remove'),
              onDeload: () => events.add('deload'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  const straight = [
    (weightKg: 60.0, reps: 5),
    (weightKg: 60.0, reps: 5),
    (weightKg: 60.0, reps: 5),
  ];

  testWidgets('opens with the set table, top set selected, and a plate hint',
      (tester) async {
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: [],
      events: [],
    );

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Set 1 of 3'), findsOneWidget); // top set selected
    expect(find.text('Set'), findsOneWidget); // table header
    expect(find.text('Reps'), findsOneWidget);
    expect(find.textContaining('/ side'), findsOneWidget); // plate hint
  });

  testWidgets('stepping a straight set carries the weight forward',
      (tester) async {
    final rowWeights = <List<num>>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: rowWeights,
      applied: [],
      events: [],
    );

    // Top set 60 -> 62.5; a straight scheme carries it to the later sets.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(rowWeights, [
      [0, 62.5],
    ]);
    // The tap-to-type field now reads the edited weight.
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '62.5',
    );
  });

  testWidgets('selecting a later row edits that row, not the top set',
      (tester) async {
    final rowWeights = <List<num>>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: rowWeights,
      applied: [],
      events: [],
    );

    // Select set 3 (the last "60" cell) then step it down.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.text('Set 3 of 3'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
    await tester.pump();
    expect(rowWeights, [
      [2, 57.5],
    ]);
  });

  testWidgets('Even out all sets re-resolves and reports the anchor (straight)',
      (tester) async {
    final applied = <double>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: applied,
      events: [],
    );

    await tester.tap(find.text('Even out all sets'));
    await tester.pump();
    expect(applied, [60.0]);
  });

  testWidgets('Even out all sets from a back-off row uses the implied anchor',
      (tester) async {
    // Regression guard: selecting a factor<1 row must not treat its weight as
    // the anchor (that halved the working weight on ramp/back-off schemes).
    final applied = <double>[];
    await _open(
      tester,
      sets: const [
        (weightKg: 100.0, reps: 5),
        (weightKg: 90.0, reps: 5),
        (weightKg: 90.0, reps: 5),
      ],
      setGroups: const [
        SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
        SetGroupSpec(
          sets: 2,
          reps: 5,
          weightRule: WeightRule.backoff,
          weightParam: 10,
        ),
      ],
      rowWeights: [],
      applied: applied,
      events: [],
    );

    // Select a back-off row (90, factor 0.9), then Even out all sets.
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Even out all sets'));
    await tester.pumpAndSettle();

    // Implied anchor is 90 / 0.9 = 100, so weights stay 100/90/90 (not 90/81).
    expect(applied, [100.0]);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('81'), findsNothing);
  });

  testWidgets('Add set appends a row and reports it', (tester) async {
    final events = <String>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: [],
      events: events,
    );

    expect(find.text('Set 1 of 3'), findsOneWidget);
    await tester.tap(find.text('Add set'));
    await tester.pumpAndSettle();

    expect(events, ['add']);
    expect(find.text('4'), findsOneWidget); // fourth set row appeared
  });

  testWidgets('Remove last is disabled at one set and drops a set otherwise',
      (tester) async {
    final events = <String>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: [],
      events: events,
    );

    await tester.tap(find.text('Remove set'));
    await tester.pumpAndSettle();
    expect(events, ['remove']);
    expect(find.text('3'), findsNothing); // third set row gone

    // Drop to a single set; the button then disables.
    await tester.tap(find.text('Remove set'));
    await tester.pumpAndSettle();
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Remove set'),
    );
    expect(button.onPressed, isNull);
    expect(events, ['remove', 'remove']);
  });

  testWidgets('editing the top set recalculates back-offs proportionally',
      (tester) async {
    final rowWeights = <List<num>>[];
    await _open(
      tester,
      sets: const [
        (weightKg: 100.0, reps: 5),
        (weightKg: 90.0, reps: 5),
        (weightKg: 90.0, reps: 5),
      ],
      setGroups: const [
        SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
        SetGroupSpec(
          sets: 2,
          reps: 5,
          weightRule: WeightRule.backoff,
          weightParam: 10,
        ),
      ],
      rowWeights: rowWeights,
      applied: [],
      events: [],
    );

    // Top set 100 -> 102.5; back-offs re-derive to 102.5 * 0.9 = 92.25 -> 92.5.
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();
    expect(rowWeights, [
      [0, 102.5],
    ]);
    expect(find.text('92.5'), findsNWidgets(2)); // both back-off rows updated
  });

  testWidgets('Remove last clamps the selection when the last row was selected',
      (tester) async {
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: [],
      events: [],
    );

    // Select the last row, then remove it — selection must clamp, not throw.
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(find.text('Set 3 of 3'), findsOneWidget);

    await tester.tap(find.text('Remove set'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Set 2 of 2'), findsOneWidget); // clamped 2 -> 1
  });

  testWidgets('renders weights in lb when the unit is pounds', (tester) async {
    await _open(
      tester,
      sets: straight,
      rowWeights: [],
      applied: [],
      events: [],
      unit: Unit.lb,
    );

    // The stepper, table, and plate hint all render the lb-converted path.
    expect(find.textContaining('lb'), findsWidgets);
    expect(find.text('60 kg'), findsNothing); // not the raw kg label
  });

  testWidgets('typing a weight applies it and cascades to later sets',
      (tester) async {
    final rowWeights = <List<num>>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: rowWeights,
      applied: [],
      events: [],
    );

    // Type an exact weight into the tap-to-type field, then commit it.
    await tester.enterText(find.byType(TextField), '100');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(rowWeights, [
      [0, 100.0],
    ]);
    // Straight scheme cascades to all 3 rows; the field mirrors it (4 total).
    expect(find.text('100'), findsNWidgets(4));
  });

  testWidgets('invalid typed weight reverts to the current value',
      (tester) async {
    final rowWeights = <List<num>>[];
    await _open(
      tester,
      sets: straight,
      rowWeights: rowWeights,
      applied: [],
      events: [],
    );

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(rowWeights, isEmpty); // nothing applied
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '60', // reverted to the selected set's weight
    );
  });

  testWidgets('Deload drops every set by the percent and reports it',
      (tester) async {
    final events = <String>[];
    await _open(
      tester,
      sets: straight, // 3 × 60
      rowWeights: [],
      applied: [],
      events: events,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Deload 10%'));
    await tester.pumpAndSettle();

    // 60 * 0.9 = 54 -> loadable 55 for every set (3 rows + the field mirror).
    expect(events, ['deload']);
    expect(find.text('55'), findsNWidgets(4));
  });
}
