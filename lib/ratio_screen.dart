import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ratio_calc.dart';

class RatioScreen extends StatefulWidget {
  final SharedPreferences prefs;
  const RatioScreen({super.key, required this.prefs});

  @override
  State<RatioScreen> createState() => _RatioScreenState();
}

class _RatioScreenState extends State<RatioScreen> {
  static const _doseKey = 'dose', _ratioKey = 'ratio', _countKey = 'pourCount';
  late int _dose;
  late int _ratio;
  late int _count;

  @override
  void initState() {
    super.initState();
    _dose = (widget.prefs.getInt(_doseKey) ?? defaultDose).clamp(minDose, maxDose);
    _ratio = (widget.prefs.getInt(_ratioKey) ?? defaultRatio).clamp(minRatio, maxRatio);
    _count = widget.prefs.getInt(_countKey) ?? defaultPourCount;
    if (!pourCounts.contains(_count)) _count = defaultPourCount;
  }

  bool get _isDefault =>
      _dose == defaultDose && _ratio == defaultRatio && _count == defaultPourCount;

  void _reset() {
    setState(() {
      _dose = defaultDose;
      _ratio = defaultRatio;
      _count = defaultPourCount;
    });
    widget.prefs
      ..remove(_doseKey)
      ..remove(_ratioKey)
      ..remove(_countKey);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = pours(_dose, _ratio, _count);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Row(
          children: [
            Expanded(child: Text('Brew Calculator', style: t.headlineMedium)),
            TextButton.icon(
              onPressed: _isDefault ? null : _reset,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SliderRow(
          label: 'Dose',
          value: '${_dose}g',
          slider: Slider(
            value: _dose.toDouble(),
            min: minDose.toDouble(),
            max: maxDose.toDouble(),
            divisions: maxDose - minDose,
            label: '${_dose}g',
            onChanged: (v) {
              setState(() => _dose = v.round());
              widget.prefs.setInt(_doseKey, _dose);
            },
          ),
        ),
        _SliderRow(
          label: 'Brew ratio',
          value: '1:$_ratio',
          slider: Slider(
            value: _ratio.toDouble(),
            min: minRatio.toDouble(),
            max: maxRatio.toDouble(),
            divisions: maxRatio - minRatio,
            label: '1:$_ratio',
            onChanged: (v) {
              setState(() => _ratio = v.round());
              widget.prefs.setInt(_ratioKey, _ratio);
            },
          ),
        ),
        Row(
          children: [
            Expanded(child: Text('Pours', style: t.titleMedium)),
            DropdownButton<int>(
              value: _count,
              borderRadius: BorderRadius.circular(12),
              items: [
                for (final c in pourCounts)
                  DropdownMenuItem(value: c, child: Text('$c pours')),
              ],
              onChanged: (c) {
                if (c == null) return;
                setState(() => _count = c);
                widget.prefs.setInt(_countKey, c);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final pour in p) _PourRow(label: pour.label, to: pour.to, add: pour.add),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget slider;
  const _SliderRow({required this.label, required this.value, required this.slider});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: t.titleMedium),
              const Spacer(),
              Text(value,
                  style: t.headlineSmall?.copyWith(
                      color: cs.primary, fontWeight: FontWeight.w600)),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

class _PourRow extends StatelessWidget {
  final String label;
  final int to;
  final int add;
  const _PourRow({required this.label, required this.to, required this.add});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHigh,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(label, style: t.titleMedium)),
            Expanded(
              child: Text('+${add}g',
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
            ),
            Expanded(
              child: Text('${to}g',
                  textAlign: TextAlign.right,
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
