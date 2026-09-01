import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Duenner Wrapper um Google ML Kit Text Recognition.
/// Laeuft komplett lokal auf dem Geraet (kein Netzwerk, kein Server) —
/// entscheidend fuer den "sensible Patientendaten bleiben auf dem Handy"-Anspruch.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() {
    _recognizer.close();
  }
}

final ocrService = OcrService();
