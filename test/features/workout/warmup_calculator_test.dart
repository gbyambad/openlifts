import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';

void main() {
  test('empty-bar lift starts at the bar and stays below the work weight', () {
    final sets = computeWarmups(100, startsLoaded: false);
    expect(sets.first.weightKg, 20);
    expect(sets.every((s) => s.weightKg < 100), isTrue);
    expect(sets.every((s) => s.reps == 5), isTrue);
  });

  test('loaded lift (deadlift/row) does not start at the empty bar', () {
    final sets = computeWarmups(120, startsLoaded: true);
    expect(sets.first.weightKg, 60);
  });

  test('warmup jumps never exceed 20 kg', () {
    final sets = computeWarmups(140, startsLoaded: false);
    for (var i = 1; i < sets.length; i++) {
      expect(sets[i].weightKg - sets[i - 1].weightKg, lessThanOrEqualTo(20));
    }
  });

  test('a work weight at or below the bar needs no warmup', () {
    expect(computeWarmups(20, startsLoaded: false), isEmpty);
  });
}
