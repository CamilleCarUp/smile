import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/upload_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'summary_screen.dart';

/// Kontrollansicht fuer die Texterkennung.
///
/// Zeigt nicht nur den erkannten Text, sondern auch dessen Position auf der
/// Seite — denn genau daran haengt Phase 2: In einer Rechnung stehen
/// Tarifcode und Betrag weit auseinander, aber auf gleicher Hoehe. Im flachen
/// Text geht dieser Bezug verloren, in den Positionsdaten nicht.
///
/// Der "JSON kopieren"-Knopf gibt die Erkennung in maschinenlesbarer Form
/// heraus, damit der Parser gegen echte Rechnungen entwickelt werden kann
/// statt gegen ausgedachte Beispiele.
class OcrDebugScreen extends StatelessWidget {
  const OcrDebugScreen({super.key});

  String _buildJson() {
    final pages = uploadController.currentUploadFiles
        .where((f) => f.ocrPage != null)
        .map((f) => f.ocrPage!.toJson())
        .toList();
    return const JsonEncoder.withIndent('  ').convert({'pages': pages});
  }

  int get _totalLines => uploadController.currentUploadFiles
      .fold(0, (sum, f) => sum + (f.ocrPage?.lines.length ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Erkannter Text (Debug)', showHome: true),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: AppColors.databoxBg,
              child: Text(
                'Erkannte Zeilen samt Position auf der Seite ($_totalLines Zeilen). '
                'Die Zahlen in Klammern sind die Bildkoordinaten – daran erkennt die App, '
                'welcher Betrag zu welchem Tarifcode gehört. Die Auswertung unten nutzt '
                'noch Demo-Daten; das echte Auslesen entsteht gerade.',
                style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final f in uploadController.currentUploadFiles)
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 16, color: AppColors.brand500),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(f.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                Text('${f.ocrPage?.lines.length ?? 0}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (f.ocrPage == null)
                              SelectableText(
                                f.recognizedText ?? '(kein Text erkannt)',
                                style: const TextStyle(
                                    fontFamily: 'monospace', fontSize: 12, color: AppColors.slate700),
                              )
                            else
                              for (final line in f.ocrPage!.sortedByPosition)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 78,
                                        child: Text(
                                          '(${line.box.left.round()},${line.box.top.round()})',
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 10,
                                              color: AppColors.slate400),
                                        ),
                                      ),
                                      Expanded(
                                        child: SelectableText(
                                          line.text,
                                          style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 12,
                                              color: AppColors.slate700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_all_outlined, size: 18),
                    label: const Text('Erkennung als JSON kopieren'),
                    onPressed: _totalLines == 0
                        ? null
                        : () async {
                            await Clipboard.setData(ClipboardData(text: _buildJson()));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('JSON in die Zwischenablage kopiert.')),
                              );
                            }
                          },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await uploadController.processUpload();
                      if (context.mounted) {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SummaryScreen()));
                      }
                    },
                    child: const Text('Rechnung auswerten'),
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
