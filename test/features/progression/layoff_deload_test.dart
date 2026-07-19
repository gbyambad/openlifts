import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/progression/domain/layoff_deload.dart';

void main() {
  test('layoff deload scales with time away', () {
    expect(layoffDeloadPercent(0), 0);
    expect(layoffDeloadPercent(13), 0); // under 2 weeks: none
    expect(layoffDeloadPercent(14), 10); // 2–4 weeks
    expect(layoffDeloadPercent(29), 10);
    expect(layoffDeloadPercent(30), 20); // 1–2 months
    expect(layoffDeloadPercent(59), 20);
    expect(layoffDeloadPercent(60), 30); // 2+ months
    expect(layoffDeloadPercent(200), 30);
  });
}
