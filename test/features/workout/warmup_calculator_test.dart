import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';

void main() {
  test('empty-bar lift starts at the bar and stays below the work weight', () {
    final sets = computeWarmups(100, startsLoaded: false);
    expect(sets.first.weightKg, 20);
    expect(sets.every((s) => s.weightKg < 100), isTrue);
  });

  test('tapers the final heavy warmup set to 3 reps, rest are 5', () {
    final sets = computeWarmups(110, startsLoaded: false);
    expect(sets.last.reps, 3);
    expect(sets.take(sets.length - 1).every((s) => s.reps == 5), isTrue);
  });

  test('does not taper when only empty-bar sets remain', () {
    // A work weight barely above the bar warms up with plain empty-bar fives.
    final sets = computeWarmups(30, startsLoaded: false);
    expect(sets, hasLength(2));
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

  test('ramps in fixed one-plate steps onto plate-friendly loads', () {
    // StrongLifts lands warmups on 40/60/80/100, not an even split of the gap
    // (which would give 37.5/55/75/92.5). The final jump into the work set is
    // the short remainder.
    final sets = computeWarmups(110, startsLoaded: false);
    expect(sets.map((s) => s.weightKg), [20, 20, 40, 60, 80, 100]);
  });

  test('a work weight at or below the bar needs no warmup', () {
    expect(computeWarmups(20, startsLoaded: false), isEmpty);
  });
}
