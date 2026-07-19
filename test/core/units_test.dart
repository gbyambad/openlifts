import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';

void main() {
  test('kg <-> lb round-trips within tolerance', () {
    expect(lbToKg(kgToLb(100)), closeTo(100, 1e-9));
  });

  test('displayWeight converts canonical kg per unit', () {
    expect(displayWeight(60, Unit.kg), 60);
    expect(displayWeight(60, Unit.lb), closeTo(132.28, 0.01));
  });

  test('roundToLoadable snaps to 2.5 kg / 5 lb', () {
    expect(roundToLoadable(61, Unit.kg), 60);
    expect(roundToLoadable(61.3, Unit.kg), 62.5);
    expect(roundToLoadable(133, Unit.lb), 135);
  });
}
