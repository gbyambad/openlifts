import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/home/presentation/today_screen.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('renders the day lifts and a Start button', (tester) async {
    const view = TodayView(
      programName: 'StrongLifts 5x5',
      unit: Unit.kg,
      workouts: [
        PlannedWorkout(
          dayId: 'a',
          dayName: 'Workout A',
          dateLabel: 'Today',
          isNext: true,
          exercises: [
            PlannedExercise(name: 'Squat', scheme: '5×5 60 kg'),
            PlannedExercise(name: 'Bench Press', scheme: '5×5 45 kg'),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayProvider.overrideWith((ref) => view)],
        child: wrapWithLocalizations(const TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('Start workout'), findsOneWidget);
  });

  testWidgets('shows an empty state with no active program', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todayProvider.overrideWith((ref) => null)],
        child: wrapWithLocalizations(const TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('No active program'), findsOneWidget);
  });
}
