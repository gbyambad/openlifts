import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_bootstrap.g.dart';

/// One-time app startup: seed the database from bundled assets before the UI
/// reads data. The app gates on this future (splash until it resolves).
@riverpod
Future<void> bootstrap(Ref ref) async {
  await ensureSeededFromAssets(ref.watch(appDatabaseProvider));
}
