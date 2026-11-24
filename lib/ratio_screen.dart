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
  static const _doseKey = 'dose', _ratioKey = 'ratio';
  late int _dose;
  late int _ratio;

  @override
  void initState() {
    super.initState();
    _dose = (widget.prefs.getInt(_doseKey) ?? defaultDose).clamp(minDose, maxDose);
    _ratio = (widget.prefs.getInt(_ratioKey) ?? defaultRatio).clamp(minRatio, maxRatio);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = pours(_dose, _ratio);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text('Ratio', style: t.headlineMedium),
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
        const SizedBox(height: 16),
        _PourRow(label: 'Bloom', to: p.bloom, add: p.bloom),
        _PourRow(label: '1st pour', to: p.first, add: p.first - p.bloom),
        _PourRow(label: '2nd pour', to: p.second, add: p.second - p.first),
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
            Text('+${add}g  ',
                style: t.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            Text('${to}g',
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
