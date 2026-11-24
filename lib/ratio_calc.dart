/// Pour targets for the Ratio screen. All values are running scale totals.
library;

const minDose = 12, maxDose = 30, defaultDose = 15;
const minRatio = 13, maxRatio = 18, defaultRatio = 16;

class Pours {
  final int bloom;
  final int first;
  final int second;
  const Pours(this.bloom, this.first, this.second);
}

/// Bloom is 3x dose, the 1st pour adds 7x dose, and the 2nd pour tops up to
/// dose x ratio.
Pours pours(int dose, int ratio) =>
    Pours(3 * dose, 10 * dose, dose * ratio);
