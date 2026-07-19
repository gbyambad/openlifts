import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/programs/application/program_detail.dart';
import 'package:openlifts/features/programs/presentation/program_detail_screen.dart';

void main() {
  testWidgets('shows the workout structure and training-day chips',
      (tester) async {
    const detail = ProgramDetail(
      id: 'sl',
      name: 'StrongLifts 5x5',
      isActive: false,
      weekdays: [1, 3, 5],
      workouts: [
        WorkoutOutline(
          name: 'Workout A',
          exercises: ['Squat  5×5', 'Bench Press  5×5', 'Barbell Row  5×5'],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [programDetailProvider('sl').overrideWith((ref) => detail)],
        child: const MaterialApp(home: ProgramDetailScreen(programId: 'sl')),
      ),
    );
    await tester.pumpAndSettle();

    // Structure (#4)
    expect(find.text('Workout A'), findsOneWidget);
    expect(find.text('Squat  5×5'), findsOneWidget);
    // Schedule picker (#5): 7 weekday chips, Mon/Wed/Fri pre-selected.
    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(find.text('Use this program'), findsOneWidget);
  });
}
