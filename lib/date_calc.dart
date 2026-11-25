/// Pure date math for the Date screen. No Flutter imports, so it is easy to test.
library;

/// The fields on the Date screen.
enum DateField { roasted, rested, stored, thawed, frozen, total }

/// Fields the user can type in. Total is always calculated.
const enteredFields = [
  DateField.roasted,
  DateField.rested,
  DateField.stored,
  DateField.thawed,
  DateField.frozen,
];

/// Relations of three fields where any two give the third.
const _relations = [
  {DateField.roasted, DateField.rested, DateField.stored},
  {DateField.stored, DateField.frozen, DateField.thawed},
];

bool isDateField(DateField f) =>
    f == DateField.roasted || f == DateField.stored || f == DateField.thawed;

/// Strips the time and stores the day as UTC midnight so day math ignores DST.
DateTime dayOf(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int daysBetween(DateTime from, DateTime to) =>
    dayOf(to).difference(dayOf(from)).inDays;

/// What the user has entered. Dates are UTC midnights, day counts are ints.
class DateInputs {
  final Map<DateField, Object> values;

  const DateInputs({this.values = const {}});

  static const empty = DateInputs();

  bool get isEmpty => values.isEmpty;

  /// Sets [field] to [value]. If that leaves all three fields of a relation
  /// entered, one of the other two is dropped so it gets calculated instead.
  /// The one dropped is the less important, in [_keepPriority] order.
  DateInputs set(DateField field, Object value) {
    assert(field != DateField.total);
    final v = Map<DateField, Object>.of(values);
    v[field] = value is DateTime ? dayOf(value) : value;
    for (final rel in _relations) {
      if (!rel.contains(field) || !rel.every(v.containsKey)) continue;
      final drop = _keepPriority.lastWhere((f) => rel.contains(f) && f != field);
      v.remove(drop);
    }
    return DateInputs(values: v);
  }

  /// Most important first. Roasted is the anchor everything hangs off.
  static const _keepPriority = [
    DateField.roasted,
    DateField.stored,
    DateField.thawed,
    DateField.rested,
    DateField.frozen,
  ];

  DateInputs clear(DateField field) =>
      DateInputs(values: Map<DateField, Object>.of(values)..remove(field));

  Map<String, Object> toJson() => {
        'values': {
          for (final e in values.entries)
            e.key.name: e.value is DateTime
                ? (e.value as DateTime).toIso8601String()
                : e.value,
        },
      };

  static DateInputs fromJson(Map<String, dynamic> json) {
    try {
      final raw = (json['values'] as Map).cast<String, dynamic>();
      final values = <DateField, Object>{};
      for (final e in raw.entries) {
        final f = DateField.values.byName(e.key);
        values[f] = isDateField(f)
            ? dayOf(DateTime.parse(e.value as String))
            : (e.value as num).toInt();
      }
      return DateInputs(values: values);
    } catch (_) {
      return empty;
    }
  }
}

/// The full set of values shown on screen, entered or calculated.
class DateResult {
  final DateTime? roasted;
  final int? rested;
  final DateTime? stored;
  final DateTime? thawed;
  final int? frozen;
  final int? total;

  /// Which fields came from the user rather than the math.
  final Set<DateField> entered;

  /// Fields whose value doesn't make sense, such as a thaw before freezing.
  final Set<DateField> errors;

  /// True when Frozen counts up to today because the coffee isn't thawed yet.
  final bool stillFrozen;

  const DateResult({
    this.roasted,
    this.rested,
    this.stored,
    this.thawed,
    this.frozen,
    this.total,
    this.entered = const {},
    this.errors = const {},
    this.stillFrozen = false,
  });

  Object? valueOf(DateField f) => switch (f) {
        DateField.roasted => roasted,
        DateField.rested => rested,
        DateField.stored => stored,
        DateField.thawed => thawed,
        DateField.frozen => frozen,
        DateField.total => total,
      };
}

/// Works out every field it can from [inputs], with [today] as the end of
/// the rest when the coffee hasn't been thawed.
DateResult calculate(DateInputs inputs, DateTime today) {
  today = dayOf(today);
  DateTime? roasted = inputs.values[DateField.roasted] as DateTime?;
  int? rested = inputs.values[DateField.rested] as int?;
  DateTime? stored = inputs.values[DateField.stored] as DateTime?;
  DateTime? thawed = inputs.values[DateField.thawed] as DateTime?;
  int? frozen = inputs.values[DateField.frozen] as int?;

  // Two passes are enough for the two linked relations to settle.
  for (var i = 0; i < 2; i++) {
    if (roasted != null && rested != null && stored == null) {
      stored = roasted.add(Duration(days: rested));
    } else if (roasted != null && stored != null && rested == null) {
      rested = daysBetween(roasted, stored);
    } else if (stored != null && rested != null && roasted == null) {
      roasted = stored.subtract(Duration(days: rested));
    }
    if (stored != null && thawed != null && frozen == null) {
      frozen = daysBetween(stored, thawed);
    } else if (stored != null && frozen != null && thawed == null) {
      thawed = stored.add(Duration(days: frozen));
    } else if (thawed != null && frozen != null && stored == null) {
      stored = thawed.subtract(Duration(days: frozen));
    }
  }

  // Not thawed yet: it has been in the freezer up to today.
  var stillFrozen = false;
  if (stored != null && thawed == null && frozen == null) {
    frozen = daysBetween(stored, today);
    stillFrozen = true;
  }

  int? total;
  if (roasted != null) {
    total = daysBetween(roasted, today) - (frozen ?? 0);
  }

  final errors = <DateField>{};
  void flag(bool bad, DateField f) {
    if (bad) errors.add(f);
  }

  flag(roasted != null && roasted.isAfter(today), DateField.roasted);
  flag(stored != null && stored.isAfter(today), DateField.stored);
  flag(thawed != null && thawed.isAfter(today), DateField.thawed);
  flag(rested != null && rested < 0, DateField.rested);
  flag(frozen != null && frozen < 0, DateField.frozen);
  if (frozen != null && frozen < 0) {
    // A thaw before the freeze: mark the dates too.
    if (stored != null) errors.add(DateField.stored);
    if (thawed != null) errors.add(DateField.thawed);
  }
  flag(total != null && total < 0, DateField.total);

  return DateResult(
    roasted: roasted,
    rested: rested,
    stored: stored,
    thawed: thawed,
    frozen: frozen,
    total: total,
    entered: inputs.values.keys.toSet(),
    errors: errors,
    stillFrozen: stillFrozen,
  );
}
