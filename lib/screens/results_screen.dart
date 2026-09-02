import 'package:flutter/material.dart';
import '../models/finding.dart';
import '../models/request.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import '../state/upload_controller.dart';
import 'request_screen.dart';
import 'upload_screen.dart';

/// Zeigt, was die App aus der Rechnung lesen konnte.
///
/// Bewusst zurueckhaltend: Solange keine Pruefregeln festgelegt sind, stellt
/// die App fest, was auf der Rechnung steht — sie beurteilt es nicht. Ein
/// gruener Haken neben jeder Position waere hier die gefaehrlichste Anzeige
/// von allen: Er saehe aus wie ein Freispruch, obwohl nur gelesen wurde.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    final offen = req.unresolvedLines.length;

    return Scaffold(
      appBar: smileAppBar(context, 'Ergebnis', showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Mehrere Rechnungen in einem Import: Der Nutzer sieht hier die
            // erste, die uebrigen liegen im Verlauf.
            if (uploadController.erkannteRechnungen > 1) ...[
              _MehrereKarte(anzahl: uploadController.erkannteRechnungen),
              const SizedBox(height: 16),
            ],
            if (!req.isTrustworthy) ...[
              _UnsicherKarte(request: req),
              const SizedBox(height: 16),
            ],
            for (final f in req.findings) _BefundKarte(finding: f),
            if (req.findings.isNotEmpty) const SizedBox(height: 16),
            _LesestatusKarte(
              gefunden: req.lines.length,
              offen: offen,
              faktor: req.factor,
              summenprobe: req.totalsMatch,
              statedTotal: req.statedTotal,
              summe: req.invoiceTotal,
            ),
            const SizedBox(height: 16),

            if (req.lines.isEmpty)
              const _Hinweis(
                icon: Icons.search_off_rounded,
                text: 'Auf den Bildern wurde keine Tarifposition gefunden. Häufigster Grund: '
                    'Das Foto zeigt nicht die Leistungsaufstellung, oder es ist zu unscharf. '
                    'Am zuverlässigsten funktioniert der direkte PDF-Import.',
              )
            else ...[
              const Text('Erfasste Positionen',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.databoxBg,
                  border: Border.all(color: AppColors.databoxBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [for (final l in req.lines) _PositionsZeile(line: l)],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.databox500, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _Betragszeile('Summe der Positionen', req.invoiceTotal),
                  if (req.statedTotal != null) ...[
                    const SizedBox(height: 8),
                    _Betragszeile('Auf der Rechnung ausgewiesen', req.statedTotal!),
                  ],
                  if (req.flaggedLines.isNotEmpty) ...[
                    const Divider(color: Colors.black12, height: 24),
                    _Betragszeile('Differenz', req.difference, fett: true),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            _Hinweis(
              icon: Icons.info_outline_rounded,
              text: req.findings.isEmpty
                  ? 'Geprüft wurde bisher nur das Preisniveau gegen den tariflichen '
                      'Höchstsatz — hier ohne Befund. Ob eine Leistung häufiger verrechnet '
                      'wurde als üblich, prüft die App noch nicht. "Kein Befund" heisst '
                      'also nicht "alles in Ordnung", sondern "nichts, was sich belegen lässt".'
                  : 'Der Befund beruht auf einer Rechnung, nicht auf einer Beurteilung der '
                      'Behandlung. Es kann Gründe geben, die die App nicht kennt — deshalb '
                      'ist der nächste Schritt eine Frage an die Praxis, keine Forderung.',
            ),

            const SizedBox(height: 20),
            if (req.isTrustworthy)
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RequestScreen())),
                child: const Text('Rückfrage vorbereiten'),
              )
            else
              // Die neue Aufnahme steht oben in der Unsicher-Karte, direkt bei
              // der Begruendung. Hier unten bleibt nur die Nebenhandlung --
              // wer trotzdem fragen will, muss erst an allem vorbei, worauf
              // er sich gerade nicht verlassen soll.
              OutlinedButton(
                onPressed: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const RequestScreen())),
                child: const Text('Trotzdem Rückfrage vorbereiten'),
              ),
          ],
        ),
      ),
    );
  }
}

class _LesestatusKarte extends StatelessWidget {
  final int gefunden;
  final int offen;
  final double? faktor;
  final bool summenprobe;
  final double? statedTotal;
  final double summe;

  const _LesestatusKarte({
    required this.gefunden,
    required this.offen,
    required this.summenprobe,
    required this.summe,
    this.faktor,
    this.statedTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Was gelesen wurde',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 10),
            _Zeile(
              ok: gefunden > 0,
              text: '$gefunden Position${gefunden == 1 ? '' : 'en'} erkannt',
            ),
            if (offen > 0)
              _Zeile(
                ok: false,
                warnung: true,
                text: '$offen davon nicht aufschlüsselbar — Betrag zählt mit, '
                    'Taxpunkte und Menge blieben unklar',
              ),
            if (faktor != null)
              _Zeile(ok: true, text: 'Faktor Taxpunkte → Franken: ${faktor!.toStringAsFixed(2)}'),
            if (statedTotal != null)
              _Zeile(
                ok: summenprobe,
                warnung: !summenprobe,
                text: summenprobe
                    ? 'Summenprobe stimmt mit dem Rechnungstotal überein'
                    : 'Summenprobe geht nicht auf — die Rechnung wurde vermutlich '
                        'nicht vollständig erfasst',
              )
            else
              const _Zeile(
                ok: false,
                warnung: true,
                text: 'Kein Rechnungstotal gefunden — die Gegenprobe fehlt',
              ),
          ],
        ),
      ),
    );
  }
}

class _Zeile extends StatelessWidget {
  final bool ok;
  final bool warnung;
  final String text;
  const _Zeile({required this.ok, required this.text, this.warnung = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_rounded : (warnung ? Icons.error_outline_rounded : Icons.remove_rounded),
            size: 16,
            color: ok ? AppColors.good : (warnung ? AppColors.danger : AppColors.slate400),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _PositionsZeile extends StatelessWidget {
  final TariffLine line;
  const _PositionsZeile({required this.line});

  @override
  Widget build(BuildContext context) {
    final unklar = !line.isResolved;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(line.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: line.flagged ? FontWeight.bold : FontWeight.normal,
                  color: line.flagged ? AppColors.danger : AppColors.slate500,
                )),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.description,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: line.flagged ? FontWeight.bold : FontWeight.normal,
                      color: unklar ? AppColors.slate400 : AppColors.slate700,
                    )),
                if (line.isResolved)
                  Text(
                    '${line.quantity} × ${line.taxpunkte} TP'
                    '${line.taxpunkteFromCatalog ? '' : ' (von der Rechnung gelesen)'}',
                    style: const TextStyle(fontSize: 11, color: AppColors.slate400),
                  )
                else
                  const Text('nicht aufschlüsselbar',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.slate400, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('CHF ${line.amountChf.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 13, color: AppColors.slate700)),
        ],
      ),
    );
  }
}

class _Betragszeile extends StatelessWidget {
  final String label;
  final double betrag;
  final bool fett;
  const _Betragszeile(this.label, this.betrag, {this.fett = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        color: AppColors.slate800, fontWeight: fett ? FontWeight.bold : FontWeight.normal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('CHF ${betrag.toStringAsFixed(2)}', style: style),
      ],
    );
  }
}

class _Hinweis extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Hinweis({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.slate400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4)),
          ),
        ],
      ),
    );
  }
}


class _BefundKarte extends StatelessWidget {
  final InvoiceFinding finding;
  const _BefundKarte({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.06),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.priority_high_rounded, size: 18, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(finding.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.danger, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(finding.explanation,
              style: const TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.45)),
          if (finding.excessChf != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Differenz zum Höchstsatz',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('CHF ${finding.excessChf!.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}


/// Wird gezeigt, wenn die Rechnung nicht sicher gelesen werden konnte.
///
/// Die Hinweise sind bewusst konkret: "Bild zu unscharf" hilft niemandem
/// weiter. Was die App aus dem Fehlerbild ableiten kann, sagt sie auch.
class _UnsicherKarte extends StatelessWidget {
  final DentalRequest request;
  const _UnsicherKarte({required this.request});

  List<String> get _tipps {
    final tipps = <String>[];
    if (request.wasPhotographedCrooked) {
      // Bewusst ohne Gradzahl: "9 Grad" sagt niemandem etwas, "schief" schon.
      tipps.add('Das Bild wurde schief aufgenommen. Leg das Blatt flach hin und '
          'halte die Kamera gerade darüber — dann stehen die Spalten sauber '
          'nebeneinander.');
    }
    if (!request.totalsMatch) {
      tipps.add('Achte darauf, dass die ganze Leistungsaufstellung im Bild ist — '
          'inklusive der Totalzeile ganz unten.');
    }
    if (request.unresolvedLines.isNotEmpty && !request.wasPhotographedCrooked) {
      tipps.add('Achte auf gutes, gleichmässiges Licht ohne Schatten auf dem Blatt.');
    }
    tipps.add('Am zuverlässigsten ist der direkte PDF-Import — dabei entfällt das '
        'Fotografieren ganz.');
    return tipps;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        border: Border.all(color: AppColors.slate300),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.image_search_outlined, size: 18, color: AppColors.slate600),
              SizedBox(width: 8),
              Expanded(
                child: Text('Diese Rechnung konnte nicht sicher gelesen werden',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Die Zahlen unten stammen aus dieser Rechnung, könnten aber der falschen '
            'Position zugeordnet sein. Verlass dich nicht darauf — eine neue Aufnahme '
            'ist schnell gemacht.',
            style: TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.45),
          ),
          const SizedBox(height: 12),
          for (final tipp in _tipps)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  ', style: TextStyle(color: AppColors.slate400)),
                  Expanded(
                    child: Text(tipp,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate600, height: 1.4)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Rechnung neu aufnehmen'),
              onPressed: () {
                uploadController.reset();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadScreen()),
                  (route) => route.isFirst,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MehrereKarte extends StatelessWidget {
  final int anzahl;
  const _MehrereKarte({required this.anzahl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.databoxBg,
          border: Border.all(color: AppColors.databoxBorder),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.collections_bookmark_outlined,
              size: 18, color: AppColors.brand600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$anzahl Rechnungen erkannt. Du siehst die erste — die übrigen '
              'liegen unter "Meine Anfragen", jede für sich geprüft.',
              style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
