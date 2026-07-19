import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/progress/presentation/progress_screen.dart';

void main() {
  testWidgets('shows an empty state when nothing is logged', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProgressView(charts: [], bodyweight: [], unit: Unit.kg),
      ),
    );

    expect(find.textContaining('No workouts logged yet'), findsOneWidget);
  });

  testWidgets('renders a card per lift with the latest weight', (tester) async {
    final charts = [
      LiftChart(
        exerciseId: 'squat',
        name: 'Squat',
        points: [
          WeightPoint(date: DateTime(2026), weightKg: 60),
          WeightPoint(date: DateTime(2026, 1, 3), weightKg: 65),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: ProgressView(charts: charts, bodyweight: const [], unit: Unit.kg),
      ),
    );

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('65 kg'), findsOneWidget);
  });
}
