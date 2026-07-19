import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/bodyweight/data/bodyweight_repository_impl.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftBodyweightRepository repo;

  setUp(() {
    db = openTestDb();
    repo = DriftBodyweightRepository(db);
  });
  tearDown(() => db.close());

  test('entries surface as an ordered, plottable series', () async {
    await repo.add(DateTime(2026, 7, 10), 75);
    await repo.add(DateTime(2026, 7, 18), 77);

    final series = await repo.watchSeries().first;
    expect(series.map((e) => e.weightKg).toList(), [75, 77]);
  });
}
