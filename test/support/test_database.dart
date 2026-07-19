import 'package:drift/native.dart';
import 'package:openlifts/core/database/app_database.dart';

/// A fresh in-memory database for tests — real Drift, no mocks.
/// Close it in `tearDown`.
AppDatabase openTestDb() => AppDatabase(NativeDatabase.memory());
