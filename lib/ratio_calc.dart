/// Pour targets for the Brew Calculator. All targets are running scale totals.
library;

const minDose = 12, maxDose = 30, defaultDose = 15;
const minRatio = 13, maxRatio = 20, defaultRatio = 16;
const pourCounts = [2, 3];
const defaultPourCount = 3;

class Pour {
  final String label;
  final int to;
  final int add;
  const Pour(this.label, this.to, this.add);
}

/// Bloom is 3x dose. With 3 pours the 1st pour adds half of what's left
/// after the bloom and the 2nd tops up to dose x ratio. With 2 pours the
/// single pour goes straight to dose x ratio.
List<Pour> pours(int dose, int ratio, int count) {
  final total = dose * ratio;
  final bloom = 3 * dose;
  if (count == 2) {
    return [Pour('Bloom', bloom, bloom), Pour('Pour', total, total - bloom)];
  }
  final first = bloom + ((total - bloom) / 2).round();
  return [
    Pour('Bloom', bloom, bloom),
    Pour('1st pour', first, first - bloom),
    Pour('2nd pour', total, total - first),
  ];
}
