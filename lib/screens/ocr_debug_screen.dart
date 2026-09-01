import 'package:flutter/material.dart';
import '../state/upload_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'summary_screen.dart';

/// Phase 1: zeigt den rohen OCR-Text pro Datei zur Kontrolle.
/// Die eigentliche Auswertung (Tarifcode-Erkennung, Abgleich) ist noch
/// die Demo-Logik aus Phase 0 — echtes Parsen folgt in Phase 2.
class OcrDebugScreen extends StatelessWidget {
  const OcrDebugScreen({super.key});

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
              child: const Text(
                'Das ist der Rohtext, den die on-device-Texterkennung aus deinen Fotos gelesen hat — '
                'zur Kontrolle, ob die Erkennung überhaupt brauchbar ist. Die Auswertung/den Abgleich mit '
                'den Tarifcodes gibt es erst ab Phase 2; unten siehst du weiterhin die Demo-Auswertung.',
                style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
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
                                      style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              (f.recognizedText == null || f.recognizedText!.trim().isEmpty)
                                  ? '(kein Text erkannt)'
                                  : f.recognizedText!,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.slate700),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () {
                  uploadController.processUpload();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
                },
                child: const Text('Weiter zur Demo-Auswertung'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
