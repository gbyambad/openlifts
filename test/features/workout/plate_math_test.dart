import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/workout/domain/plate_math.dart';

void main() {
  test('breaks a kg load into the fewest standard plates per side', () {
    // 72.5 kg on a 20 kg bar -> 26.25/side -> 25 + 1.25 (greedy, fewest plates).
    final load = platesPerSide(72.5, 20, kgPlates);
    expect(load.perSide, [25, 1.25]);
    expect(load.leftover, 0);
    expect(load.perSideTotal, 26.25);
  });

  test('empty when the target is at or below the bar', () {
    expect(platesPerSide(20, 20, kgPlates).perSide, isEmpty);
    expect(platesPerSide(15, 20, kgPlates).perSide, isEmpty);
  });

  test('reports leftover when plates cannot match exactly', () {
    // 21 kg -> 0.5/side, no 0.5 plate -> leftover.
    final load = platesPerSide(21, 20, kgPlates);
    expect(load.perSide, isEmpty);
    expect(load.leftover, closeTo(0.5, 1e-9));
  });

  test('stacks multiple of the same plate', () {
    // 120 kg on a 20 kg bar -> 50/side -> 25 + 25.
    expect(platesPerSide(120, 20, kgPlates).perSide, [25, 25]);
  });
}
