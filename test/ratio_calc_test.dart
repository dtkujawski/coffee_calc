import 'package:coffee_calc/ratio_calc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('15g at 1:17 pours to 45, 150, 255', () {
    final p = pours(15, 17);
    expect([p.bloom, p.first, p.second], [45, 150, 255]);
  });
}
