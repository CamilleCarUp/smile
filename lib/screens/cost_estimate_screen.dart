import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

class _EstimateItem {
  final String code;
  final String description;
  final double tp; // Taxpunkte
  const _EstimateItem(this.code, this.description, this.tp);
}

class _EstimateTreatment {
  final String name;
  final List<_EstimateItem> items;
  const _EstimateTreatment(this.name, this.items);
}

/// Taxpunkt-Werte 1:1 aus dem Klickdummy übernommen (Chapter 4.4.2 der Thesis).
const _treatments = <_EstimateTreatment>[
  _EstimateTreatment('1. Einflächige Kompositfüllung', [
    _EstimateItem('4.0020', 'Kurze klinische Untersuchung', 33.1),
    _EstimateItem('4.0650', 'Infiltrationsanästhesie', 38.4),
    _EstimateItem('4.5350', 'Kompositfüllung, einflächig', 122.0),
    _EstimateItem('4.5800', 'Schmelzätzung', 19.2),
    _EstimateItem('4.5810', 'Dentinkonditionierung', 15.7),
  ]),
  _EstimateTreatment('2. Eckaufbau', [
    _EstimateItem('4.0020', 'Kurze klinische Untersuchung', 33.1),
    _EstimateItem('4.0650', 'Infiltrationsanästhesie', 38.4),
    _EstimateItem('4.5800', 'Schmelzätzung', 19.2),
    _EstimateItem('4.5810', 'Dentinkonditionierung', 15.7),
    _EstimateItem('4.5390', 'Komposit-Eckaufbau', 170.8),
  ]),
  _EstimateTreatment('3. Prämolaren-Aufbau', [
    _EstimateItem('4.0020', 'Kurze klinische Untersuchung', 33.1),
    _EstimateItem('4.0650', 'Infiltrationsanästhesie', 38.4),
    _EstimateItem('4.5800', 'Schmelzätzung', 19.2),
    _EstimateItem('4.5810', 'Dentinkonditionierung', 15.7),
    _EstimateItem('4.5510', 'Komposit-Aufbau Prämolar', 240.6),
  ]),
];

class CostEstimateScreen extends StatefulWidget {
  const CostEstimateScreen({super.key});

  @override
  State<CostEstimateScreen> createState() => _CostEstimateScreenState();
}

class _CostEstimateScreenState extends State<CostEstimateScreen> {
  double _tpw = 1.20;
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final treatment = _treatments[_selected];
    final total = treatment.items.fold(0.0, (sum, i) => sum + i.tp * _tpw);

    return Scaffold(
      appBar: smileAppBar(context, 'Kostenschätzung', showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Taxpunktwert deines Zahnarztes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: TextFormField(
                            initialValue: _tpw.toStringAsFixed(2),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            onChanged: (v) {
                              final parsed = double.tryParse(v.replaceAll(',', '.'));
                              if (parsed != null) setState(() => _tpw = parsed);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('(üblich: 1.0 – 1.7)', style: TextStyle(color: AppColors.slate500, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Beispielbehandlung wählen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _selected,
              items: [
                for (var i = 0; i < _treatments.length; i++)
                  DropdownMenuItem(value: i, child: Text(_treatments[i].name)),
              ],
              onChanged: (v) => setState(() => _selected = v ?? 0),
            ),
            const SizedBox(height: 20),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final item in treatment.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Text(item.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(child: Text(item.description)),
                                Text((item.tp * _tpw).toStringAsFixed(2)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: AppColors.brand50,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Basiskosten', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('CHF ${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: AppColors.brand100),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Erwarteter Bereich (±15%)', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'CHF ${(total * 0.85).toStringAsFixed(2)} – ${(total * 1.15).toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
