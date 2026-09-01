import 'package:flutter/foundation.dart';
import '../logic/invoice_matcher.dart';
import '../models/request.dart';
import 'requests_repository.dart';

/// Zustand rund um den Upload-Ablauf: ausgewaehlte Dateien, OCR-Ergebnisse,
/// Anstoss der (aktuell noch simulierten) Auswertung. Getrennt vom
/// Anfragen-Verlauf ([RequestsRepository]) und vom Login ([AuthController]),
/// damit jedes Stueck fuer sich testbar bleibt.
class UploadController extends ChangeNotifier {
  final List<UploadedFile> currentUploadFiles = [];

  void addUploadedFile(String name, {String? path}) {
    currentUploadFiles.add(UploadedFile(name, path: path));
    notifyListeners();
  }

  void removeUploadedFile(int index) {
    currentUploadFiles.removeAt(index);
    notifyListeners();
  }

  void reset() {
    currentUploadFiles.clear();
    notifyListeners();
  }

  /// Laesst on-device OCR ueber alle aktuell hochgeladenen Bilder laufen
  /// und speichert den erkannten Rohtext je Datei.
  Future<void> runOcrOnUploads(Future<String> Function(String path) recognize) async {
    for (final f in currentUploadFiles) {
      if (f.path == null) continue;
      try {
        f.recognizedText = await recognize(f.path!);
      } catch (e) {
        f.recognizedText = '(Fehler bei der Texterkennung: $e)';
      }
    }
    notifyListeners();
  }

  /// Erstellt aus den aktuell hochgeladenen Dateien eine neue Anfrage im
  /// [requestsRepository]. Nutzt noch die Demo-Analyse aus
  /// logic/invoice_matcher.dart -- Phase 2 ersetzt nur deren Innenleben.
  DentalRequest processUpload() {
    if (currentUploadFiles.isEmpty) {
      currentUploadFiles.add(UploadedFile('Rechnung_Seite1.pdf'));
    }
    final analysis = analyzeInvoiceDemo();
    final req = requestsRepository.createFromAnalysis(
      files: List.of(currentUploadFiles),
      analysis: analysis,
    );
    notifyListeners();
    return req;
  }
}

final uploadController = UploadController();
