import 'package:coffee_calc/date_calc.dart';
import 'package:flutter_test/flutter_test.dart';

DateTime d(int m, int day) => DateTime.utc(2026, m, day);

void main() {
  final today = d(11, 24);

  test('roast only: total is days since roast', () {
    final r = calculate(DateInputs.empty.set(DateField.roasted, d(11, 10)), today);
    expect(r.total, 14);
    expect(r.frozen, isNull);
    expect(r.stored, isNull);
  });

  test('roast + rested: stored, frozen to today, total', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.rested, 10);
    final r = calculate(i, today);
    expect(r.stored, d(10, 11));
    expect(r.frozen, 44);
    expect(r.stillFrozen, isTrue);
    expect(r.total, 10);
    expect(r.entered, {DateField.roasted, DateField.rested});
  });

  test('roast + stored: rested, frozen to today, total', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.stored, d(10, 15));
    final r = calculate(i, today);
    expect(r.rested, 14);
    expect(r.frozen, 40);
    expect(r.total, 14);
  });

  test('roast + stored + thawed: frozen is thawed - stored', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.stored, d(10, 15))
        .set(DateField.thawed, d(11, 20));
    final r = calculate(i, today);
    expect(r.frozen, 36);
    expect(r.stillFrozen, isFalse);
    // 54 days since roast minus 36 in the freezer.
    expect(r.total, 18);
  });

  test('roast + rested + frozen days: stored and thawed filled in', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.rested, 14)
        .set(DateField.frozen, 30);
    final r = calculate(i, today);
    expect(r.stored, d(10, 15));
    expect(r.thawed, d(11, 14));
    expect(r.total, 54 - 30);
  });

  test('thawed + frozen days back-fill stored, then rested', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.thawed, d(11, 20))
        .set(DateField.frozen, 30);
    final r = calculate(i, today);
    expect(r.stored, d(10, 21));
    expect(r.rested, 20);
  });

  test('entering stored over roast + rested recalculates rested', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.rested, 10)
        .set(DateField.stored, d(10, 20));
    expect(i.values.keys.toSet(), {DateField.roasted, DateField.stored});
    expect(calculate(i, today).rested, 19);
  });

  test('entering rested over roast + stored recalculates stored', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.stored, d(10, 20))
        .set(DateField.rested, 10);
    expect(i.values.keys.toSet(), {DateField.roasted, DateField.rested});
    expect(calculate(i, today).stored, d(10, 11));
  });

  test('entering frozen days over stored + thawed recalculates thawed', () {
    final i = DateInputs.empty
        .set(DateField.stored, d(10, 20))
        .set(DateField.thawed, d(11, 1))
        .set(DateField.frozen, 5);
    expect(i.values.keys.toSet(), {DateField.stored, DateField.frozen});
    expect(calculate(i, today).thawed, d(10, 25));
  });

  test('thawed before stored is flagged', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.stored, d(10, 15))
        .set(DateField.thawed, d(10, 10));
    final r = calculate(i, today);
    expect(r.errors, containsAll([DateField.thawed, DateField.stored, DateField.frozen]));
  });

  test('day math is not thrown off by DST', () {
    final r = calculate(
      DateInputs.empty.set(DateField.roasted, DateTime(2026, 10, 31, 23)),
      DateTime(2026, 11, 2, 1),
    );
    expect(r.total, 2);
  });

  test('json round trip', () {
    final i = DateInputs.empty
        .set(DateField.roasted, d(10, 1))
        .set(DateField.rested, 14);
    final back = DateInputs.fromJson(i.toJson());
    expect(back.values, i.values);
  });

  test('bad json gives empty inputs', () {
    expect(DateInputs.fromJson({'nope': 1}).isEmpty, isTrue);
  });
}
