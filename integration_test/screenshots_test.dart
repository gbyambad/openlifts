import 'dart:convert';
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/core/theme/app_theme.dart';
import 'package:openlifts/features/home/presentation/today_screen.dart';
import 'package:openlifts/features/programs/presentation/programs_screen.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_view.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';
import 'package:openlifts/features/settings/presentation/settings_screen.dart';

/// Captures README screenshots by rendering each screen on-device against a
/// freshly-seeded in-memory database, then grabbing the layer via
/// `RepaintBoundary.toImage` at a fixed pixel ratio. This is device-resolution
/// independent (crisp regardless of the AVD's native size) and uses the real
/// bundled fonts. The PNG bytes go back to the host through `reportData`; the
/// driver (`test_driver/integration_test.dart`) writes them. Run via
/// `tool/screenshots.sh`.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final boundaryKey = GlobalKey();
  final shots = <String, dynamic>{};

  // 360x800 logical, captured at 3x -> crisp 1080x2400 PNGs.
  const capturePixelRatio = 3.0;

  Future<AppDatabase> seededDb() async {
    final db = AppDatabase(NativeDatabase.memory());
    await ensureSeededFromAssets(db);
    await DriftSettingsRepository(db).save(
      const SettingsCompanion(activeProgramId: Value('stronglifts-5x5')),
    );
    return db;
  }

  // Mirrors AppShell's bottom nav so screenshots read as the real in-app frame.
  Widget shellFrame(int navIndex, Widget child) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt),
            label: 'Programs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget host(
    Widget child, {
    required int navIndex,
    AppDatabase? db,
    bool reducedMotion = false,
  }) {
    return RepaintBoundary(
      key: boundaryKey,
      child: ProviderScope(
        overrides: [
          if (db != null) appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          home: reducedMotion
              ? Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(disableAnimations: true),
                    child: shellFrame(navIndex, child),
                  ),
                )
              : shellFrame(navIndex, child),
        ),
      ),
    );
  }

  Future<void> capture(String name) async {
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: capturePixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    shots[name] = base64Encode(data!.buffer.asUint8List());
  }

  testWidgets('capture README screenshots', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = capturePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final todayDb = await seededDb();
    addTearDown(todayDb.close);
    await tester
        .pumpWidget(host(const TodayScreen(), db: todayDb, navIndex: 0));
    await tester.pumpAndSettle();
    await capture('today');

    final programsDb = await seededDb();
    addTearDown(programsDb.close);
    await tester
        .pumpWidget(host(const ProgramsScreen(), db: programsDb, navIndex: 3));
    await tester.pumpAndSettle();
    await capture('programs');

    final settingsDb = await seededDb();
    addTearDown(settingsDb.close);
    await tester
        .pumpWidget(host(const SettingsScreen(), db: settingsDb, navIndex: 4));
    await tester.pumpAndSettle();
    await capture('settings');

    // Workout — first set logged, cursor on the next. Reduced motion keeps the
    // heartbeat static; tapping the next set reveals the rest timer bar.
    const workout = WorkoutState(
      dayId: 'sl5x5-a',
      dayName: 'Workout A',
      unit: Unit.kg,
      isLinear: true,
      days: [(id: 'sl5x5-a', name: 'Workout A')],
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
            ActiveSet(index: 2, weightKg: 60, targetReps: 5),
            ActiveSet(index: 3, weightKg: 60, targetReps: 5),
            ActiveSet(index: 4, weightKg: 60, targetReps: 5),
          ],
        ),
        ActiveLift(
          exerciseId: 'bench',
          name: 'Bench Press',
          anchorKg: 45,
          warmups: [],
          incrementKg: 2.5,
          deloadAfterFails: 3,
          deloadPercent: 10,
          workingSets: [
            ActiveSet(index: 0, weightKg: 45, targetReps: 5),
            ActiveSet(index: 1, weightKg: 45, targetReps: 5),
            ActiveSet(index: 2, weightKg: 45, targetReps: 5),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      host(
        ActiveWorkoutView(
          state: workout,
          onCycleSet: (_, __) {},
          onSetWeight: (_, __) {},
          onSetWeightAt: (_, __, ___) {},
          onSetWeightFrom: (_, __, ___) {},
          onAddSet: (_) {},
          onRemoveSet: (_) {},
          onLogBodyweight: (_) {},
          onSwitchDay: (_) {},
          onFinish: () {},
        ),
        db: todayDb, // keeps the ProviderScope override count constant
        navIndex: 0, // the workout lives under the Today branch
        reducedMotion: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').at(1)); // next set -> starts rest timer
    await tester.pump(const Duration(milliseconds: 500));
    await capture('workout');

    // Tear down the tree so the rest timer doesn't outlive the test.
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    binding.reportData = shots;
  });
}
