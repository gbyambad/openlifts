import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/programs/application/program_weights.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/programs/presentation/programs_screen.dart';

Future<void> _pump(WidgetTester tester, ProgramsView view) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        programsViewProvider.overrideWith((ref) => view),
        programWeightsProvider.overrideWith((ref) => null),
      ],
      child: const MaterialApp(home: ProgramsScreen()),
    ),
  );
}

void main() {
  testWidgets('pins the active program on top and groups the rest',
      (tester) async {
    const view = ProgramsView(
      active: ProgramCard(
        id: 'sl',
        name: 'StrongLifts 5x5',
        scheduleSummary: 'Mon · Wed · Fri',
        isActive: true,
        isBuiltIn: true,
        nextWorkout: 'Workout A · Today',
      ),
      templates: [
        ProgramCard(
          id: 'madcow',
          name: 'Madcow 5x5',
          scheduleSummary: '3×/week',
          isActive: false,
          isBuiltIn: true,
        ),
      ],
    );

    await _pump(tester, view);
    await tester.pumpAndSettle();

    // Active program is surfaced as the current-program card.
    expect(find.text('CURRENT PROGRAM'), findsOneWidget);
    expect(find.text('StrongLifts 5x5'), findsOneWidget);
    expect(find.text('Next: Workout A · Today'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    // The rest sits under a Templates header.
    expect(find.text('Templates'), findsOneWidget);
    expect(find.text('Madcow 5x5'), findsOneWidget);
  });

  testWidgets('shows a My programs section and a per-card menu',
      (tester) async {
    const view = ProgramsView(
      active: ProgramCard(
        id: 'sl',
        name: 'StrongLifts 5x5',
        scheduleSummary: 'Mon · Wed · Fri',
        isActive: true,
        isBuiltIn: true,
      ),
      custom: [
        ProgramCard(
          id: 'custom-1',
          name: 'My Program',
          scheduleSummary: 'Mon · Wed',
          isActive: false,
          isBuiltIn: false,
        ),
      ],
    );

    await _pump(tester, view);
    await tester.pumpAndSettle();

    expect(find.text('Create'), findsOneWidget);
    expect(find.text('My programs'), findsOneWidget);
    // One menu on the current card, one on the custom row.
    expect(find.byType(PopupMenuButton<String>), findsNWidgets(2));

    // The custom row's menu exposes Edit/Delete.
    await tester.tap(find.byType(PopupMenuButton<String>).last);
    await tester.pumpAndSettle();
    expect(find.text('Duplicate & customize'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('tapping a program row opens the schedule picker',
      (tester) async {
    const view = ProgramsView(
      templates: [
        ProgramCard(
          id: 'madcow',
          name: 'Madcow 5x5',
          scheduleSummary: '3×/week',
          isActive: false,
          isBuiltIn: true,
        ),
      ],
    );

    await _pump(tester, view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Madcow 5x5'));
    await tester.pumpAndSettle();

    // The day-picker sheet appears with its activate CTA and weekday chips.
    expect(find.text('Use this program'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(7));
  });

  testWidgets('with no active program, shows the pick-one banner',
      (tester) async {
    const view = ProgramsView(
      templates: [
        ProgramCard(
          id: 'madcow',
          name: 'Madcow 5x5',
          scheduleSummary: '3×/week',
          isActive: false,
          isBuiltIn: true,
        ),
      ],
    );

    await _pump(tester, view);
    await tester.pumpAndSettle();

    expect(find.textContaining('No active program'), findsOneWidget);
  });
}
