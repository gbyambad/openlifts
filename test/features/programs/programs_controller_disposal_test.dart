import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

import '../../support/test_app.dart';
import '../../support/test_database.dart';

/// Reproduces the "unresponsive Programs actions" crash surfaced on the
/// emulator: a screen obtains [ProgramsController] with `ref.read(...notifier)`
/// (no listener), so an auto-dispose controller is torn down before the tapped
/// action's async write runs — its Ref then throws `UnmountedRefException`
/// mid-write and the active program never changes. `keepAlive` fixes it.
class _Harness extends ConsumerWidget {
  const _Harness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(programsControllerProvider.notifier);
    return ElevatedButton(
      onPressed: () => ctrl.selectActive('madcow-5x5'),
      child: const Text('activate'),
    );
  }
}

void main() {
  testWidgets('a Programs action fires from a tap and persists (keepAlive)',
      (tester) async {
    final db = openTestDb();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: wrapWithLocalizations(const Scaffold(body: _Harness())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('activate'));
    await tester.pumpAndSettle();

    final settings = await DriftSettingsRepository(db).get();
    expect(settings.activeProgramId, 'madcow-5x5');
  });
}
