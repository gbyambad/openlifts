import 'package:drift_flutter/drift_flutter.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// The app-wide database (native sqlite file via drift_flutter). Kept alive for
/// the app's lifetime and closed on dispose. Every feature's repository
/// providers read this.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase(driftDatabase(name: 'openlifts'));
  ref.onDispose(db.close);
  return db;
}
