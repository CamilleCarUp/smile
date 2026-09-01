import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/ocr_result.dart';

/// Duenner Wrapper um Google ML Kit Text Recognition.
/// Laeuft komplett lokal auf dem Geraet (kein Netzwerk, kein Server) —
/// entscheidend fuer den "sensible Patientendaten bleiben auf dem Handy"-Anspruch.
///
/// Diese Klasse ist die einzige Stelle mit Plugin-Abhaengigkeit: sie uebersetzt
/// das ML-Kit-Ergebnis in die neutralen Strukturen aus models/ocr_result.dart.
/// Alles, was danach kommt (Parsen, Abgleich), arbeitet nur noch mit diesen —
/// und ist dadurch ohne Geraet testbar.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Erkennt Text samt Position je Zeile.
  Future<OcrPage> recognizePage(String imagePath, {String? sourceName}) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);

    final lines = <OcrTextLine>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        lines.add(OcrTextLine(
          text: line.text,
          box: OcrBox(
            left: rect.left,
            top: rect.top,
            right: rect.right,
            bottom: rect.bottom,
          ),
        ));
      }
    }

    return OcrPage(
      sourceName: sourceName ?? imagePath.split(RegExp(r'[/\\]')).last,
      lines: lines,
    );
  }

  /// Nur der flache Text — fuer Anzeigezwecke.
  Future<String> recognizeText(String imagePath) async {
    final page = await recognizePage(imagePath);
    return page.flatText;
  }

  void dispose() {
    _recognizer.close();
  }
}

final ocrService = OcrService();
