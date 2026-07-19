import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_view.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';

ActiveWorkoutView _view(
  WorkoutState state, {
  void Function(int, int)? onCycleSet,
  void Function(int, int, double)? onSetWeightAt,
}) {
  return ActiveWorkoutView(
    state: state,
    onCycleSet: onCycleSet ?? (_, __) {},
    onSetWeight: (_, __) {},
    onSetWeightAt: onSetWeightAt ?? (_, __, ___) {},
    onAddSet: (_) {},
    onRemoveSet: (_) {},
    onLogBodyweight: (_) {},
    onSwitchDay: (_) {},
    onFinish: () {},
  );
}

/// The active tab index, read straight off the shared TabController.
int _currentTab(WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index;

void main() {
  testWidgets('renders lifts, per-set weights, and tapping a set logs it',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5),
            ActiveSet(index: 1, weightKg: 60, targetReps: 5),
          ],
        ),
      ],
    );

    final tapped = <List<int>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _view(state, onCycleSet: (li, si) => tapped.add([li, si])),
      ),
    );

    expect(find.text('Squat'), findsWidgets);
    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('5'), findsNWidgets(2)); // two set circles
    expect(find.text('60'), findsWidgets); // per-set weights shown

    await tester.tap(find.text('5').first);
    await tester.pump();
    expect(tapped, [
      [0, 0],
    ]);
  });

  testWidgets('tapping a set weight opens the per-set editor and edits it',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5),
            ActiveSet(index: 1, weightKg: 60, targetReps: 5),
          ],
        ),
      ],
    );

    // A phone-sized surface so the weight-editor bottom sheet has room.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final edits = <List<num>>[];
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          state,
          onSetWeightAt: (li, si, kg) => edits.add([li, si, kg]),
        ),
      ),
    );

    // Tap the first set's weight label to open its editor.
    await tester.tap(find.text('60').first);
    await tester.pumpAndSettle();
    expect(find.text('Squat — set 1 weight'), findsOneWidget);

    // Step it up: 60 -> 62.5, reported for set index 0.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(edits, [
      [0, 0, 62.5],
    ]);
  });

  testWidgets('completed set uses the brand colour, a missed set is error-red',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5, actualReps: 5),
            ActiveSet(index: 1, weightKg: 60, targetReps: 5, actualReps: 3),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));

    BoxDecoration cellFor(String reps) => tester
        .widget<Container>(
          find
              .ancestor(of: find.text(reps), matching: find.byType(Container))
              .first,
        )
        .decoration! as BoxDecoration;

    final primary =
        Theme.of(tester.element(find.text('5'))).colorScheme.primary;
    expect(cellFor('5').color, primary);
    expect(cellFor('3').color, SemanticColors.brand.failure);
  });

  testWidgets('shows a sets-progress header counting logged sets',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5, actualReps: 5),
            ActiveSet(index: 1, weightKg: 60, targetReps: 5),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));

    expect(find.text('1 / 2 sets'), findsOneWidget);
  });

  testWidgets('a fully-logged lift shows a done check and completion label',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5, actualReps: 5),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));

    expect(find.text('All sets logged'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('body weight row shows the current bodyweight', (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      bodyweightKg: 72.5,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [ActiveSet(index: 0, weightKg: 60, targetReps: 5)],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));

    expect(find.text('Body weight'), findsOneWidget);
    expect(find.text('72.5 kg'), findsOneWidget);
  });

  testWidgets('a warmup checks off on tap and the mark survives a tab switch',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          // Two warmups so checking one doesn't auto-advance the tab.
          warmups: [
            WarmupSet(weightKg: 20, reps: 5),
            WarmupSet(weightKg: 40, reps: 5),
          ],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [ActiveSet(index: 0, weightKg: 60, targetReps: 5)],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsNothing);
    await tester.tap(find.text('5×20 kg'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(_currentTab(tester), 1); // still on Warmup (not all done)

    // Round-trip to Workout and back — the mark persists.
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('checking the last warmup auto-advances to the Workout tab',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [WarmupSet(weightKg: 20, reps: 5)],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [ActiveSet(index: 0, weightKg: 60, targetReps: 5)],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 1);

    await tester.tap(find.text('5×20 kg')); // the only warmup -> all done
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 0); // jumped to the working sets
  });

  testWidgets('completing a lift auto-advances to warm up the next lift',
      (tester) async {
    ActiveLift squat(int? actualReps) => ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: const [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(
              index: 0,
              weightKg: 60,
              targetReps: 5,
              actualReps: actualReps,
            ),
          ],
        );
    const bench = ActiveLift(
      exerciseId: 'bench',
      name: 'Bench',
      anchorKg: 40,
      warmups: [WarmupSet(weightKg: 20, reps: 5)],
      incrementKg: 2.5,
      deloadAfterFails: 3,
      deloadPercent: 10,
      workingSets: [ActiveSet(index: 0, weightKg: 40, targetReps: 5)],
    );

    // Squat not yet done.
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          WorkoutState(
            dayId: 'a',
            dayName: 'A',
            unit: Unit.kg,
            isLinear: true,
            lifts: [squat(null), bench],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 0);

    // Squat's set becomes logged -> nudge to Warmup for Bench.
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          WorkoutState(
            dayId: 'a',
            dayName: 'A',
            unit: Unit.kg,
            isLinear: true,
            lifts: [squat(5), bench],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 1);
  });

  testWidgets('logging a set reveals the rest bar with a skip control',
      (tester) async {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 60,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));

    await tester.tap(find.text('5')); // log the (unlogged) set -> starts rest
    await tester.pump();

    expect(find.text('Rest'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Cancel the countdown so no timer is pending at teardown.
    await tester.tap(find.text('Skip'));
    await tester.pump();
  });
}
