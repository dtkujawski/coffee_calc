import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'date_calc.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// How many months back the month wheel goes.
const _monthsBack = 24;
const _maxDays = 365;

String formatDate(DateTime d, DateTime today) {
  final base = '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}';
  return d.year == today.year ? base : '$base, ${d.year}';
}

String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

String ago(DateTime d, DateTime today) {
  final n = daysBetween(d, today);
  if (n == 0) return 'today';
  if (n < 0) return 'in ${plural(-n, 'day')}';
  return '${plural(n, 'day')} ago';
}

class DateScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const DateScreen({super.key, required this.prefs});

  @override
  State<DateScreen> createState() => _DateScreenState();
}

class _DateScreenState extends State<DateScreen> {
  static const _key = 'dateInputs';
  late DateInputs _inputs;
  DateField? _open;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    final raw = widget.prefs.getString(_key);
    _inputs = raw == null ? DateInputs.empty : DateInputs.fromJson(jsonDecode(raw));
    // The day may have rolled over while the app sat in the background.
    _lifecycle = AppLifecycleListener(onResume: () => setState(() {}));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _update(DateInputs next) {
    setState(() => _inputs = next);
    widget.prefs.setString(_key, jsonEncode(next.toJson()));
  }

  void _reset() {
    setState(() => _open = null);
    _update(DateInputs.empty);
  }

  @override
  Widget build(BuildContext context) {
    final today = dayOf(DateTime.now());
    final r = calculate(_inputs, today);
    final t = Theme.of(context).textTheme;

    Widget field(DateField f, String label, String hint) => _FieldTile(
          field: f,
          label: label,
          hint: hint,
          result: r,
          today: today,
          open: _open == f,
          onTap: () => setState(() => _open = _open == f ? null : f),
          onSet: (v) => _update(_inputs.set(f, v)),
          onClear: () => _update(_inputs.clear(f)),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Rest Calculator', style: t.headlineMedium)),
            TextButton.icon(
              onPressed: _inputs.isEmpty ? null : _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _Legend(),
        const SizedBox(height: 12),
        field(DateField.roasted, 'Roasted', 'Date roasted'),
        field(DateField.rested, 'Rested', 'Days before freezing'),
        field(DateField.stored, 'Stored', 'Date frozen'),
        field(DateField.thawed, 'Thawed', 'Date thawed'),
        field(DateField.frozen, 'Frozen', 'Days in the freezer'),
        const SizedBox(height: 8),
        _TotalCard(result: r, today: today),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = Theme.of(context).textTheme.bodySmall;
    Widget dot(Color c, {bool outline = false}) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: outline ? null : c,
            border: outline ? Border.all(color: c, width: 1.5) : null,
            shape: BoxShape.circle,
          ),
        );
    return Row(
      children: [
        dot(cs.primary),
        Text('  entered', style: s),
        const SizedBox(width: 16),
        dot(cs.tertiary, outline: true),
        Text('  calculated', style: s),
      ],
    );
  }
}

class _FieldTile extends StatelessWidget {
  final DateField field;
  final String label;
  final String hint;
  final DateResult result;
  final DateTime today;
  final bool open;
  final VoidCallback onTap;
  final ValueChanged<Object> onSet;
  final VoidCallback onClear;

  const _FieldTile({
    required this.field,
    required this.label,
    required this.hint,
    required this.result,
    required this.today,
    required this.open,
    required this.onTap,
    required this.onSet,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final value = result.valueOf(field);
    final entered = result.entered.contains(field);
    final error = result.errors.contains(field);
    final isDate = isDateField(field);

    final Color accent = error
        ? cs.error
        : entered
            ? cs.primary
            : cs.tertiary;

    String main;
    String? sub;
    if (value == null) {
      main = '—';
      sub = hint;
    } else if (value is DateTime) {
      main = formatDate(value, today);
      sub = ago(value, today);
    } else {
      main = plural(value as int, 'day');
      sub = field == DateField.frozen && result.stillFrozen
          ? 'Frozen'
          : null;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      color: entered ? cs.primaryContainer.withValues(alpha: 0.35) : cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: value == null && !error ? cs.outlineVariant : accent,
          width: entered || error ? 2 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: t.titleMedium),
                        if (sub != null)
                          Text(sub,
                              style: t.bodySmall?.copyWith(
                                  color: error ? cs.error : cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(main,
                          style: t.titleMedium?.copyWith(
                            color: value == null ? cs.onSurfaceVariant : accent,
                            fontWeight: entered ? FontWeight.w700 : FontWeight.w400,
                            fontStyle: !entered && value != null
                                ? FontStyle.italic
                                : FontStyle.normal,
                          )),
                      if (value != null)
                        Text(entered ? 'entered' : 'calculated',
                            style: t.labelSmall?.copyWith(color: accent)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: open
                ? _Picker(
                    isDate: isDate,
                    initial: value ??
                        (isDate ? today : (field == DateField.rested ? 14 : 30)),
                    today: today,
                    entered: entered,
                    onSet: onSet,
                    onClear: onClear,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// Inline scroll wheels. Scrolling sets the value right away.
class _Picker extends StatefulWidget {
  final bool isDate;
  final Object initial;
  final DateTime today;
  final bool entered;
  final ValueChanged<Object> onSet;
  final VoidCallback onClear;

  const _Picker({
    required this.isDate,
    required this.initial,
    required this.today,
    required this.entered,
    required this.onSet,
    required this.onClear,
  });

  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  late FixedExtentScrollController _a; // month, or day count
  FixedExtentScrollController? _b; // day of month
  late int _monthIndex; // 0 = oldest month on the wheel
  late int _day;
  late int _count;

  DateTime _monthAt(int i) {
    final t = widget.today;
    return DateTime.utc(t.year, t.month - _monthsBack + i, 1);
  }

  int _daysIn(DateTime m) => DateTime.utc(m.year, m.month + 1, 0).day;

  DateTime get _date {
    final m = _monthAt(_monthIndex);
    return DateTime.utc(m.year, m.month, _day.clamp(1, _daysIn(m)));
  }

  @override
  void initState() {
    super.initState();
    if (widget.isDate) {
      var d = widget.initial as DateTime;
      final t = widget.today;
      var idx = (d.year - t.year) * 12 + d.month - t.month + _monthsBack;
      if (idx < 0 || idx > _monthsBack) {
        d = t;
        idx = _monthsBack;
      }
      _monthIndex = idx;
      _day = d.day;
      _a = FixedExtentScrollController(initialItem: _monthIndex);
      _b = FixedExtentScrollController(initialItem: _day - 1);
    } else {
      _count = (widget.initial as int).clamp(0, _maxDays);
      _a = FixedExtentScrollController(initialItem: _count);
    }
  }

  @override
  void dispose() {
    _a.dispose();
    _b?.dispose();
    super.dispose();
  }

  Widget _wheel({
    required FixedExtentScrollController c,
    required int count,
    required String Function(int) text,
    required ValueChanged<int> onChanged,
    bool Function(int)? enabled,
  }) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListWheelScrollView.useDelegate(
            controller: c,
            itemExtent: 40,
            diameterRatio: 1.6,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (_, i) => Center(
                child: Text(
                  text(i),
                  style: t.titleMedium?.copyWith(
                    color: (enabled?.call(i) ?? true)
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      children: [
        if (widget.isDate)
          TextButton(
            onPressed: () {
              _monthIndex = _monthsBack;
              _day = widget.today.day;
              _a.animateToItem(_monthIndex,
                  duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              _b!.animateToItem(_day - 1,
                  duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
              widget.onSet(widget.today);
            },
            child: const Text('Today'),
          ),
        const Spacer(),
        if (widget.entered)
          TextButton(onPressed: widget.onClear, child: const Text('Clear')),
      ],
    );

    final Widget wheels;
    if (widget.isDate) {
      final daysInMonth = _daysIn(_monthAt(_monthIndex));
      wheels = Row(
        children: [
          Expanded(
            flex: 3,
            child: _wheel(
              c: _a,
              count: _monthsBack + 1,
              text: (i) {
                final m = _monthAt(i);
                return '${_months[m.month - 1]} ${m.year}';
              },
              onChanged: (i) {
                setState(() => _monthIndex = i);
                widget.onSet(_date);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _wheel(
              c: _b!,
              count: 31,
              text: (i) => '${i + 1}',
              // Days past the end of the month snap to the last day.
              enabled: (i) => i < daysInMonth,
              onChanged: (i) {
                setState(() => _day = i + 1);
                widget.onSet(_date);
              },
            ),
          ),
        ],
      );
    } else {
      wheels = _wheel(
        c: _a,
        count: _maxDays + 1,
        text: (i) => plural(i, 'day'),
        onChanged: (i) {
          _count = i;
          widget.onSet(i);
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(children: [wheels, buttons]),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final DateResult result;
  final DateTime today;
  const _TotalCard({required this.result, required this.today});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final total = result.total;
    final error = result.errors.contains(DateField.total);
    String? detail;
    if (total != null && result.roasted != null) {
      final since = daysBetween(result.roasted!, today);
      detail = result.frozen == null
          ? '${plural(since, 'day')} since roast'
          : '${plural(since, 'day')} since roast − ${result.frozen} frozen';
    }
    return Card(
      elevation: 0,
      color: error ? cs.errorContainer : cs.tertiaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total rest',
                      style: t.titleMedium?.copyWith(color: cs.onTertiaryContainer)),
                  Text(detail ?? 'Set a roast date to start',
                      style: t.bodySmall?.copyWith(color: cs.onTertiaryContainer)),
                ],
              ),
            ),
            Text(total == null ? '—' : plural(total, 'day'),
                style: t.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: error ? cs.onErrorContainer : cs.onTertiaryContainer)),
          ],
        ),
      ),
    );
  }
}
