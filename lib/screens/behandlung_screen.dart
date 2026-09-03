import 'package:flutter/material.dart';

import '../data/erklaerungen.dart';
import '../logic/behandlung.dart';
import '../models/request.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

/// Die Rechnung als Behandlung erzaehlt.
///
/// Das eigentliche Versprechen der App: nicht "ist das zu teuer", sondern
/// "was ist da eigentlich passiert". Jede Position mit dem, was sie bedeutet,
/// und mit dem Rechenweg zu ihrem Betrag -- gruppiert nach Behandlungstag,
/// wo die Praxis Zeilendaten druckt.
class BehandlungScreen extends StatelessWidget {
  const BehandlungScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    final tage = sitzungen(req.lines);

    return Scaffold(
      appBar: smileAppBar(context, 'Die Behandlung', showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const _WieDerPreisEntsteht(),
            const SizedBox(height: 20),
            if (req.lines.isEmpty)
              const Text(
                'Aus dieser Aufnahme liessen sich keine Positionen lesen — es gibt '
                'nichts zu erklären.',
                style: TextStyle(color: AppColors.slate600, height: 1.5),
              ),
            for (var i = 0; i < tage.length; i++) ...[
              _SitzungsKopf(sitzung: tage[i], nummer: i + 1, von: tage.length),
              const SizedBox(height: 12),
              for (final line in tage[i].positionen) _PositionsErklaerung(line: line),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            const _Grenze(),
          ],
        ),
      ),
    );
  }
}

class _WieDerPreisEntsteht extends StatelessWidget {
  const _WieDerPreisEntsteht();

  @override
  Widget build(BuildContext context) {
    final faktor = requestsRepository.currentRequest?.factor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.databoxBg,
          border: Border.all(color: AppColors.databoxBorder),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wie der Preis entsteht',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand600)),
          const SizedBox(height: 6),
          Text(
            'Jede Leistung im Zahnarzttarif hat eine feste Punktzahl — die Taxpunkte. '
            'Was du zahlst, ist diese Punktzahl mal dem Wert, den deine Praxis je Punkt '
            'ansetzt${faktor == null ? '' : ' — hier ${faktor.toStringAsFixed(2)} Franken'}. '
            'Deshalb kostet dieselbe Behandlung in zwei Praxen unterschiedlich viel.',
            style: const TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SitzungsKopf extends StatelessWidget {
  final Sitzung sitzung;
  final int nummer;
  final int von;
  const _SitzungsKopf({required this.sitzung, required this.nummer, required this.von});

  @override
  Widget build(BuildContext context) {
    final datum = sitzung.datum;
    final titel = datum == null
        ? (von == 1 ? 'Verrechnete Leistungen' : 'Ohne Datum auf der Rechnung')
        : 'Behandlung vom ${datum.day.toString().padLeft(2, '0')}.'
            '${datum.month.toString().padLeft(2, '0')}.${datum.year}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(titel,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.slate800)),
        ),
        const SizedBox(width: 12),
        Text('CHF ${sitzung.summe.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, color: AppColors.slate500)),
      ],
    );
  }
}

class _PositionsErklaerung extends StatelessWidget {
  final TariffLine line;
  const _PositionsErklaerung({required this.line});

  /// Der Rechenweg zu genau diesem Betrag -- damit niemand glauben muss, dass
  /// die Zahl stimmt.
  String? get _rechenweg {
    final tp = line.taxpunkte;
    final menge = line.quantity;
    if (tp == null || menge == null) return null;
    final proStueck = line.amountChf / menge;
    return menge == 1
        ? '$tp Taxpunkte → CHF ${line.amountChf.toStringAsFixed(2)}'
        : '$menge × $tp Taxpunkte je CHF ${proStueck.toStringAsFixed(2)} '
            '→ CHF ${line.amountChf.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final erklaerung = erklaerungZu(line.code);
    final rechenweg = _rechenweg;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.slate200),
          borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(line.description.isEmpty ? line.code : line.description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate800)),
              ),
              const SizedBox(width: 10),
              Text('CHF ${line.amountChf.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            erklaerung ??
                'Zu dieser Position hat Smile keine Erklärung hinterlegt. Was dabei '
                    'gemacht wurde, sagt dir die Praxis am besten selbst.',
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: erklaerung == null ? AppColors.slate400 : AppColors.slate600,
                fontStyle: erklaerung == null ? FontStyle.italic : FontStyle.normal),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(line.code,
                  style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
              if (rechenweg != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(rechenweg,
                      style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Grenze extends StatelessWidget {
  const _Grenze();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.slate400),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Die Erklärungen beschreiben allgemein, was eine Position umfasst — nicht, '
              'warum bei dir so behandelt wurde und ob es nötig war. Das weiss nur deine '
              'Praxis. Genau danach zu fragen, steht dir zu.',
              style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
