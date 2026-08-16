import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/progress/presentation/progress_screen.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';

import '../../support/test_app.dart';

/// The progress screen now has several stacked sections (range selector,
/// Overall stats, Charts, Personal Records) that overflow the default test
/// surface — a tall one keeps everything mounted so finders can see it.
Future<void> _pumpTall(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(wrapWithLocalizations(child));
}

void main() {
  testWidgets('shows an empty state when nothing is logged', (tester) async {
    await _pumpTall(
      tester,
      const ProgressView(charts: [], bodyweight: [], unit: Unit.kg),
    );

    expect(find.textContaining('No workouts logged yet'), findsOneWidget);
  });

  testWidgets(
      'renders a lift chart and its personal record, with an up arrow when '
      'the latest top set is the all-time best', (tester) async {
    final now = DateTime.now();
    final charts = [
      LiftChart(
        exerciseId: 'squat',
        name: 'Squat',
        points: [
          WeightPoint(
            date: now.subtract(const Duration(days: 10)),
            weightKg: 60,
          ),
          WeightPoint(
            date: now.subtract(const Duration(days: 3)),
            weightKg: 65,
          ),
        ],
      ),
    ];

    await _pumpTall(
      tester,
      ProgressView(charts: charts, bodyweight: const [], unit: Unit.kg),
    );

    // Once in the strength chart card, once in the Personal Records row.
    expect(find.text('Squat'), findsNWidgets(2));
    expect(find.text('65 kg'), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
  });

  testWidgets(
      'does not show the up arrow when the latest top set is below the '
      'all-time best', (tester) async {
    final now = DateTime.now();
    final charts = [
      LiftChart(
        exerciseId: 'squat',
        name: 'Squat',
        points: [
          WeightPoint(
            date: now.subtract(const Duration(days: 10)),
            weightKg: 70,
          ),
          WeightPoint(
            date: now.subtract(const Duration(days: 3)),
            weightKg: 65,
          ),
        ],
      ),
    ];

    await _pumpTall(
      tester,
      ProgressView(charts: charts, bodyweight: const [], unit: Unit.kg),
    );

    expect(find.byIcon(Icons.arrow_upward), findsNothing);
  });

  testWidgets(
      'keeps personal records outside the selected range, but hides the '
      'chart for that range', (tester) async {
    final now = DateTime.now();
    final charts = [
      LiftChart(
        exerciseId: 'squat',
        name: 'Squat',
        // Older than the default 6-month range, so the chart tab should be
        // empty even though this is still an all-time personal record.
        points: [
          WeightPoint(
            date: now.subtract(const Duration(days: 400)),
            weightKg: 60,
          ),
        ],
      ),
    ];

    await _pumpTall(
      tester,
      ProgressView(charts: charts, bodyweight: const [], unit: Unit.kg),
    );

    // Personal Records still lists it...
    expect(find.text('Squat'), findsOneWidget);
    // ...but the strength chart tab has nothing in range.
    expect(find.textContaining('No data in this range'), findsOneWidget);
  });

  testWidgets('switching to 1Y reveals the chart for older points',
      (tester) async {
    final now = DateTime.now();
    final charts = [
      LiftChart(
        exerciseId: 'squat',
        name: 'Squat',
        // Outside the default 6-month range, but inside 1 year.
        points: [
          WeightPoint(
            date: now.subtract(const Duration(days: 300)),
            weightKg: 60,
          ),
        ],
      ),
    ];

    await _pumpTall(
      tester,
      ProgressView(charts: charts, bodyweight: const [], unit: Unit.kg),
    );
    // Only the Personal Records row, not the chart card yet.
    expect(find.text('Squat'), findsOneWidget);

    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();

    // Now both the chart card and the Personal Records row show it.
    expect(find.text('Squat'), findsNWidgets(2));
  });

  testWidgets('Overall stats reflect workout count and total volume',
      (tester) async {
    final now = DateTime.now();
    final history = [
      HistoryEntry(
        sessionId: 1,
        date: now.subtract(const Duration(days: 5)),
        dayName: 'Day A',
        setsLogged: 5,
        totalVolumeKg: 1000,
      ),
      HistoryEntry(
        sessionId: 2,
        date: now.subtract(const Duration(days: 2)),
        dayName: 'Day B',
        setsLogged: 5,
        totalVolumeKg: 1500,
      ),
    ];

    await _pumpTall(
      tester,
      ProgressView(
        charts: const [],
        bodyweight: const [],
        history: history,
        unit: Unit.kg,
      ),
    );

    expect(find.text('2'), findsOneWidget); // workout count
    expect(find.text('2,500 kg'), findsOneWidget); // total volume
  });

  testWidgets('switching to the Weight tab shows the bodyweight chart',
      (tester) async {
    final now = DateTime.now();
    final bodyweight = [
      WeightPoint(date: now.subtract(const Duration(days: 10)), weightKg: 80),
      WeightPoint(date: now.subtract(const Duration(days: 3)), weightKg: 78),
    ];

    await _pumpTall(
      tester,
      ProgressView(charts: const [], bodyweight: bodyweight, unit: Unit.kg),
    );
    // Only the tab label itself before switching.
    expect(find.text('Bodyweight'), findsOneWidget);

    await tester.tap(find.text('Bodyweight'));
    await tester.pumpAndSettle();

    // Now the chart card title too.
    expect(find.text('Bodyweight'), findsNWidgets(2));
    expect(find.text('78 kg'), findsOneWidget);
  });
}
