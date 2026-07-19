import 'package:openlifts/core/database/app_database.dart';

/// The user's bodyweight time-series (stored in kg).
abstract interface class BodyweightRepository {
  Future<void> add(DateTime loggedAt, double weightKg, {String? note});

  Future<List<BodyweightEntry>> series();

  /// Ordered oldest-first, for plotting.
  Stream<List<BodyweightEntry>> watchSeries();
}
