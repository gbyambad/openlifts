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

  test('a loaded lift lighter than 60 kg still gets a warmup', () {
    // The old flat 60 kg floor left a beginner's 40 kg deadlift with no
    // warmup at all, and a 65 kg one warming up at 60 kg — 92% of the work
    // set.
    final light = computeWarmups(40, startsLoaded: true);
    expect(light, isNotEmpty);
    expect(light.every((s) => s.weightKg < 40), isTrue);

    final medium = computeWarmups(65, startsLoaded: true);
    expect(medium.last.weightKg / 65, lessThan(0.85));
  });

  test('warmup jumps never exceed 20 kg, including into the work set', () {
    for (final work in [42.5, 45.0, 65.0, 90.0, 110.0, 140.0, 180.0]) {
      for (final loaded in [false, true]) {
        final sets = computeWarmups(work, startsLoaded: loaded);
        if (sets.isEmpty) continue;
        for (var i = 1; i < sets.length; i++) {
          expect(
            sets[i].weightKg - sets[i - 1].weightKg,
            lessThanOrEqualTo(20),
            reason: 'ramp jump at $work kg (loaded: $loaded)',
          );
        }
        expect(
          work - sets.last.weightKg,
          lessThanOrEqualTo(20),
          reason: 'jump into the work set at $work kg (loaded: $loaded)',
        );
      }
    }
  });

  test('reproduces the StrongLifts ramp when the gap divides by 20', () {
    final sets = computeWarmups(100, startsLoaded: false);
    expect(sets.map((s) => s.weightKg), [20, 20, 40, 60, 80]);
  });

  test('spreads the remainder instead of crowding the work weight', () {
    // Fixed 20 kg steps used to end at 100 kg for a 110 kg work set — 91%,
    // a work set rather than a warmup. Splitting the gap evenly keeps the top
    // warmup a full jump below, on loadable plate pairs.
    final sets = computeWarmups(110, startsLoaded: false);
    expect(sets.map((s) => s.weightKg), [20, 20, 37.5, 55, 75, 92.5]);
  });

  test('never ramps within one plate pair of the work weight', () {
    for (var work = 25.0; work <= 200.0; work += 2.5) {
      for (final loaded in [false, true]) {
        final sets = computeWarmups(work, startsLoaded: loaded);
        if (sets.isEmpty) continue;
        expect(
          sets.last.weightKg,
          lessThanOrEqualTo(work - 2.5),
          reason: 'top warmup at $work kg (loaded: $loaded)',
        );
      }
    }
  });

  test('every warmup lands on a loadable weight, in ascending order', () {
    for (var work = 25.0; work <= 200.0; work += 2.5) {
      for (final loaded in [false, true]) {
        final sets = computeWarmups(work, startsLoaded: loaded);
        for (final s in sets) {
          expect((s.weightKg / 2.5) % 1, 0, reason: '${s.weightKg} kg');
        }
        for (var i = 1; i < sets.length; i++) {
          expect(sets[i].weightKg, greaterThanOrEqualTo(sets[i - 1].weightKg));
        }
      }
    }
  });

  test('a work weight at or below the bar needs no warmup', () {
    expect(computeWarmups(20, startsLoaded: false), isEmpty);
  });
}
