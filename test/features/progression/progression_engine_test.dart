import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/progression/domain/progression_engine.dart';

void main() {
  const engine = ProgressionEngine();
  const cfg = LiftConfig(incrementKg: 2.5);

  test('success increments and resets fails', () {
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 60, consecutiveFailures: 1),
      cfg,
      allSetsHit: true,
    );
    expect(r.workingWeightKg, 62.5);
    expect(r.consecutiveFailures, 0);
  });

  test('partial fail increments the streak, weight unchanged', () {
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 60),
      cfg,
      allSetsHit: false,
    );
    expect(r.workingWeightKg, 60);
    expect(r.consecutiveFailures, 1);
  });

  test('deloads 10% on the 3rd consecutive fail and resets', () {
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 100, consecutiveFailures: 2),
      cfg,
      allSetsHit: false,
    );
    expect(r.workingWeightKg, 90);
    expect(r.consecutiveFailures, 0);
  });

  test('fail, fail, success resets without deloading', () {
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 100, consecutiveFailures: 2),
      cfg,
      allSetsHit: true,
    );
    expect(r.workingWeightKg, 102.5);
    expect(r.consecutiveFailures, 0);
  });

  test('configurable deloadAfterFails = 2 deloads on the 2nd fail', () {
    const cfg2 = LiftConfig(incrementKg: 2.5, deloadAfterFails: 2);
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 100, consecutiveFailures: 1),
      cfg2,
      allSetsHit: false,
    );
    expect(r.workingWeightKg, 90);
    expect(r.consecutiveFailures, 0);
  });

  test('deload result snaps to a loadable weight', () {
    final r = engine.applyLinear(
      const LiftState(workingWeightKg: 102.5, consecutiveFailures: 2),
      cfg,
      allSetsHit: false,
    );
    // 102.5 * 0.9 = 92.25 -> nearest 2.5 = 92.5
    expect(r.workingWeightKg, 92.5);
  });

  test('percentage: top set sets a new anchor, weekly advance applies', () {
    expect(engine.newAnchorFromTopSet(101), 100); // snaps to 2.5
    expect(engine.advanceWeekly(100, 2.5), 102.5);
  });
}
