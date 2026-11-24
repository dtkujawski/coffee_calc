import 'package:coffee_calc/ratio_calc.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> to(List<Pour> p) => [for (final x in p) x.to];

void main() {
  test('3 pours, 15g at 1:17: 45, 150, 255', () {
    expect(to(pours(15, 17, 3)), [45, 150, 255]);
  });

  test('1st pour adds half of what is left after the bloom', () {
    final p = pours(20, 16, 3); // total 320, bloom 60, half of 260 = 130
    expect(to(p), [60, 190, 320]);
    expect([for (final x in p) x.add], [60, 130, 130]);
  });

  test('2 pours: bloom then pour to total', () {
    final p = pours(15, 17, 2);
    expect([for (final x in p) x.label], ['Bloom', 'Pour']);
    expect(to(p), [45, 255]);
  });
}
