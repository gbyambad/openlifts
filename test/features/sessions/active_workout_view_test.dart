import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_view.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';

// Wrapped in reduced-motion so the cursor's repeating heartbeat pulse doesn't
// keep pumpAndSettle spinning; it also exercises the static-glow path.
Widget _view(
  WorkoutState state, {
  void Function(int, int)? onCycleSet,
  void Function(int, int, double)? onSetWeightAt,
  void Function(int, int, double)? onSetWeightFrom,
  void Function(double)? onLogBodyweight,
}) {
  return Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: ActiveWorkoutView(
        state: state,
        onCycleSet: onCycleSet ?? (_, __) {},
        onSetWeight: (_, __) {},
        onSetWeightAt: onSetWeightAt ?? (_, __, ___) {},
        onSetWeightFrom: onSetWeightFrom ?? (_, __, ___) {},
        onAddSet: (_) {},
        onRemoveSet: (_) {},
        onLogBodyweight: onLogBodyweight ?? (_) {},
        onSwitchDay: (_) {},
        onFinish: () {},
      ),
    ),
  );
}

/// The active tab index, read straight off the shared TabController.
int _currentTab(WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar)).controller!.index;

/// Hosts the view over mutable state, applying `onSetWeightAt` to the matching
/// set on the fly. This mirrors production (the weight editor commits live via
/// the controller and the ConsumerWidget rebuilds), which the cascade prompt
/// relies on: `_editSetWeight` reads the committed weight back off `state`.
class _CascadeHost extends StatefulWidget {
  const _CascadeHost({required this.initial, required this.onSetWeightFrom});

  final WorkoutState initial;
  final void Function(int, int, double) onSetWeightFrom;

  @override
  State<_CascadeHost> createState() => _CascadeHostState();
}

class _CascadeHostState extends State<_CascadeHost> {
  late WorkoutState _state = widget.initial;

  void _applyAt(int li, int si, double kg) {
    final lift = _state.lifts[li];
    final sets = [
      for (final ws in lift.workingSets)
        if (ws.index == si)
          ActiveSet(
            index: ws.index,
            weightKg: kg,
            targetReps: ws.targetReps,
            actualReps: ws.actualReps,
          )
        else
          ws,
    ];
    setState(() {
      _state = _state.copyWith(
        lifts: [
          for (var i = 0; i < _state.lifts.length; i++)
            if (i == li) lift.copyWith(workingSets: sets) else _state.lifts[i],
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _view(
        _state,
        onSetWeightAt: _applyAt,
        onSetWeightFrom: widget.onSetWeightFrom,
      ),
    );
  }
}

/// A non-straight lift (back-off scheme) with three sets, so editing one set
/// can offer to cascade to the following ones.
WorkoutState _backoffState() => const WorkoutState(
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
          setGroups: [
            SetGroupSpec(sets: 3, reps: 5, weightRule: WeightRule.backoff),
          ],
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5),
            ActiveSet(index: 1, weightKg: 50, targetReps: 5),
            ActiveSet(index: 2, weightKg: 50, targetReps: 5),
          ],
        ),
      ],
    );

/// A phone-sized surface so the weight-editor bottom sheet has room.
void _phoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

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

  testWidgets(
      "finishing one lift's warmups returns to Workout even if a later lift "
      'still has warmups', (tester) async {
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
          warmups: [
            WarmupSet(weightKg: 20, reps: 5),
            WarmupSet(weightKg: 40, reps: 5),
          ],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [ActiveSet(index: 0, weightKg: 60, targetReps: 5)],
        ),
        // A later lift with its own warmup — must NOT keep us on the tab.
        ActiveLift(
          exerciseId: 'bench',
          name: 'Bench',
          anchorKg: 50,
          warmups: [WarmupSet(weightKg: 25, reps: 5)],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [ActiveSet(index: 0, weightKg: 50, targetReps: 5)],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp(home: _view(state)));
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 1);

    // Check off both of Squat's warmups (distinct weights from Bench's).
    await tester.tap(find.text('5×20 kg'));
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 1); // one still pending
    await tester.tap(find.text('5×40 kg'));
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 0); // Squat done -> onto its working sets
  });

  testWidgets("changing a lift's weight clears its stale warmup check-marks",
      (tester) async {
    ActiveLift squat(List<WarmupSet> warmups) => ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 80,
          warmups: warmups,
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: const [ActiveSet(index: 0, weightKg: 80, targetReps: 5)],
        );
    WorkoutState stateWith(List<WarmupSet> warmups) => WorkoutState(
          dayId: 'a',
          dayName: 'A',
          unit: Unit.kg,
          isLinear: true,
          lifts: [squat(warmups)],
        );

    // Three warmups so checking one doesn't auto-jump to the Workout tab.
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          stateWith(const [
            WarmupSet(weightKg: 20, reps: 5),
            WarmupSet(weightKg: 40, reps: 5),
            WarmupSet(weightKg: 60, reps: 5),
          ]),
        ),
      ),
    );
    await tester.tap(find.text('Warmup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5×20 kg'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget); // one warmup marked done

    // A working-weight change reshapes the ramp -> the old mark must clear.
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          stateWith(const [
            WarmupSet(weightKg: 25, reps: 5),
            WarmupSet(weightKg: 45, reps: 5),
            WarmupSet(weightKg: 65, reps: 5),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsNothing); // stale mark cleared
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

  testWidgets(
      'completing a lift stays on Workout when the next lift has no warmups',
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
    // The next lift has no warmups — finishing squat should not jump to the
    // (empty) Warmup tab.
    const deadlift = ActiveLift(
      exerciseId: 'deadlift',
      name: 'Deadlift',
      anchorKg: 100,
      warmups: [],
      incrementKg: 2.5,
      deloadAfterFails: 3,
      deloadPercent: 10,
      workingSets: [ActiveSet(index: 0, weightKg: 100, targetReps: 5)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          WorkoutState(
            dayId: 'a',
            dayName: 'A',
            unit: Unit.kg,
            isLinear: true,
            lifts: [squat(null), deadlift],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 0);

    // Squat's set becomes logged -> stay on Workout (deadlift needs no warmup).
    await tester.pumpWidget(
      MaterialApp(
        home: _view(
          WorkoutState(
            dayId: 'a',
            dayName: 'A',
            unit: Unit.kg,
            isLinear: true,
            lifts: [squat(5), deadlift],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_currentTab(tester), 0); // did not jump to Warmup
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

  testWidgets(
      'editing a set on a non-straight scheme offers to cascade to the '
      'following sets', (tester) async {
    _phoneSurface(tester);
    final cascaded = <List<num>>[];

    await tester.pumpWidget(
      _CascadeHost(
        initial: _backoffState(),
        onSetWeightFrom: (li, si, kg) => cascaded.add([li, si, kg]),
      ),
    );

    // Edit set 1 (index 0, weight 60), which has following sets.
    await tester.tap(find.text('60'));
    await tester.pumpAndSettle();
    expect(find.text('Squat — set 1 weight'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add)); // 60 -> 62.5
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // The cascade prompt appears; confirming fires onSetWeightFrom.
    expect(find.text('Update the following sets?'), findsOneWidget);
    await tester.tap(find.text('Update following'));
    await tester.pumpAndSettle();

    expect(cascaded, [
      [0, 0, 62.5],
    ]);
  });

  testWidgets('"Only this set" leaves the following sets alone',
      (tester) async {
    _phoneSurface(tester);
    final cascaded = <List<num>>[];

    await tester.pumpWidget(
      _CascadeHost(
        initial: _backoffState(),
        onSetWeightFrom: (li, si, kg) => cascaded.add([li, si, kg]),
      ),
    );

    await tester.tap(find.text('60'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(find.text('Update the following sets?'), findsOneWidget);
    await tester.tap(find.text('Only this set'));
    await tester.pumpAndSettle();

    expect(cascaded, isEmpty);
  });

  testWidgets('a long day name in the workout selector does not overflow',
      (tester) async {
    _phoneSurface(tester);
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'Upper Body Hypertrophy and Accessory Volume Day',
      unit: Unit.kg,
      isLinear: true,
      // Two+ days so the title renders the tappable selector (not plain text).
      days: [
        (id: 'a', name: 'Upper Body Hypertrophy and Accessory Volume Day'),
        (id: 'b', name: 'Lower Body'),
      ],
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
    await tester.pump();

    // A RenderFlex overflow surfaces as a thrown FlutterError during layout.
    expect(tester.takeException(), isNull);
    expect(find.byType(PopupMenuButton<String>), findsOneWidget);
  });

  testWidgets('a straight scheme offers to copy the weight forward',
      (tester) async {
    _phoneSurface(tester);
    final cascaded = <List<num>>[];

    const straight = WorkoutState(
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
          // No setGroups -> a plain straight-weight lift.
          workingSets: [
            ActiveSet(index: 0, weightKg: 60, targetReps: 5),
            ActiveSet(index: 1, weightKg: 60, targetReps: 5),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _CascadeHost(
        initial: straight,
        onSetWeightFrom: (li, si, kg) => cascaded.add([li, si, kg]),
      ),
    );

    await tester.tap(find.text('60').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add)); // 60 -> 62.5
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Straight sets read as a plain "set them all to X too" copy.
    expect(find.text('Update the following sets?'), findsOneWidget);
    await tester.tap(find.text('Update following'));
    await tester.pumpAndSettle();
    expect(cascaded, [
      [0, 0, 62.5],
    ]);
  });

  testWidgets('editing the top set recalculates the back-offs proportionally',
      (tester) async {
    _phoneSurface(tester);
    final cascaded = <List<num>>[];

    const topBackoff = WorkoutState(
      dayId: 'a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      lifts: [
        ActiveLift(
          exerciseId: 'squat',
          name: 'Squat',
          anchorKg: 100,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          setGroups: [
            SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
            SetGroupSpec(
              sets: 3,
              reps: 5,
              weightRule: WeightRule.backoff,
              weightParam: 10,
            ),
          ],
          workingSets: [
            ActiveSet(index: 0, weightKg: 100, targetReps: 5), // top set
            ActiveSet(index: 1, weightKg: 90, targetReps: 5), // back-offs
            ActiveSet(index: 2, weightKg: 90, targetReps: 5),
            ActiveSet(index: 3, weightKg: 90, targetReps: 5),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      _CascadeHost(
        initial: topBackoff,
        onSetWeightFrom: (li, si, kg) => cascaded.add([li, si, kg]),
      ),
    );

    // Edit the top set (index 0, weight 100 -> 102.5).
    await tester.tap(find.text('100'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Back-offs would change to a *different* weight, so this reads as a
    // recalculation, not a copy.
    expect(find.text('Recalculate the following sets?'), findsOneWidget);
    await tester.tap(find.text('Recalculate'));
    await tester.pumpAndSettle();
    expect(cascaded, [
      [0, 0, 102.5],
    ]);
  });

  group('body-weight dialog', () {
    const state = WorkoutState(
      dayId: 'a',
      dayName: 'A',
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
          workingSets: [ActiveSet(index: 0, weightKg: 60, targetReps: 5)],
        ),
      ],
    );

    testWidgets(
        'Save logs the entered weight without a disposed-controller '
        'error', (tester) async {
      _phoneSurface(tester);
      final logged = <double>[];
      await tester.pumpWidget(
        MaterialApp(home: _view(state, onLogBodyweight: logged.add)),
      );

      await tester.tap(find.text('Body weight'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '72.5');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(logged, [72.5]);
      expect(tester.takeException(), isNull); // no "used after disposed"
    });

    testWidgets('Cancel logs nothing and throws nothing', (tester) async {
      _phoneSurface(tester);
      final logged = <double>[];
      await tester.pumpWidget(
        MaterialApp(home: _view(state, onLogBodyweight: logged.add)),
      );

      await tester.tap(find.text('Body weight'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '80');
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(logged, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Save is disabled until a valid weight is entered',
        (tester) async {
      _phoneSurface(tester);
      await tester.pumpWidget(MaterialApp(home: _view(state)));

      await tester.tap(find.text('Body weight'));
      await tester.pumpAndSettle();

      FilledButton saveButton() => tester.widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Save'),
          );
      expect(saveButton().onPressed, isNull); // empty -> disabled

      await tester.enterText(find.byType(TextField), '75');
      await tester.pump();
      expect(saveButton().onPressed, isNotNull); // valid -> enabled
    });
  });

  testWidgets('exactly one lift shows the cursor, and it moves as lifts finish',
      (tester) async {
    ActiveLift lift(String id, String name, {required bool done}) => ActiveLift(
          exerciseId: id,
          name: name,
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
              actualReps: done ? 5 : null,
            ),
          ],
        );
    WorkoutState stateWith({required bool firstDone}) => WorkoutState(
          dayId: 'a',
          dayName: 'A',
          unit: Unit.kg,
          isLinear: true,
          lifts: [
            lift('a', 'Squat', done: firstDone),
            lift('b', 'Bench', done: false),
          ],
        );

    // Both lifts have an unlogged set, but only one cursor shows (the current).
    await tester.pumpWidget(
      MaterialApp(home: _view(stateWith(firstDone: false))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cursorSet')), findsOneWidget);
    expect(find.text('Squat'), findsWidgets); // cursor is on the first lift

    // Finish the first lift -> the single cursor moves to the second.
    await tester.pumpWidget(
      MaterialApp(home: _view(stateWith(firstDone: true))),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('cursorSet')), findsOneWidget);
  });

  testWidgets('completing lifts scrolls the current exercise into view',
      (tester) async {
    // A short viewport so the lift list is guaranteed to overflow and scroll.
    tester.view.physicalSize = const Size(1500, 1200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    ActiveLift lift(String id, String name, {required bool done}) => ActiveLift(
          exerciseId: id,
          name: name,
          anchorKg: 60,
          warmups: const [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            for (var i = 0; i < 5; i++)
              ActiveSet(
                index: i,
                weightKg: 60,
                targetReps: 5,
                actualReps: done ? 5 : null,
              ),
          ],
        );
    // Six lifts so the list overflows the viewport; mark the first [doneCount]
    // done so the current lift moves down off-screen.
    const names = ['Squat', 'Bench', 'Row', 'OHP', 'Curl', 'Calf'];
    WorkoutState stateWith(int doneCount) => WorkoutState(
          dayId: 'a',
          dayName: 'A',
          unit: Unit.kg,
          isLinear: true,
          lifts: [
            for (var i = 0; i < names.length; i++)
              lift('e$i', names[i], done: i < doneCount),
          ],
        );

    await tester.pumpWidget(MaterialApp(home: _view(stateWith(0))));
    await tester.pumpAndSettle();
    final before = tester
        .widget<SingleChildScrollView>(
          find.byKey(const Key('activeWorkoutList')),
        )
        .controller!
        .offset;

    // Finish the first five -> current lift is the last, well below the fold.
    await tester.pumpWidget(MaterialApp(home: _view(stateWith(5))));
    await tester.pumpAndSettle();
    final after = tester
        .widget<SingleChildScrollView>(
          find.byKey(const Key('activeWorkoutList')),
        )
        .controller!
        .offset;

    expect(before, 0); // started at the top
    expect(after, greaterThan(before)); // scrolled down to the current lift
  });
}
