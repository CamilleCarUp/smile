import 'package:flutter/foundation.dart';
import '../data/tariff_repository.dart';
import '../logic/invoice_matcher.dart';
import '../models/ocr_result.dart';
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

  /// Laesst on-device OCR ueber alle aktuell hochgeladenen Bilder laufen und
  /// speichert je Datei die erkannten Zeilen samt Position.
  ///
  /// [recognize] wird bewusst hereingereicht statt fest verdrahtet: im Test
  /// laesst sich so eine aufgezeichnete Erkennung einsetzen, ohne dass ein
  /// Geraet oder ML Kit noetig waere.
  Future<void> runOcrOnUploads(Future<OcrPage> Function(String path) recognize) async {
    for (final f in currentUploadFiles) {
      if (f.path == null) continue;
      try {
        final page = await recognize(f.path!);
        f.ocrPage = page;
        f.recognizedText = page.flatText;
      } catch (e) {
        f.ocrPage = null;
        f.recognizedText = '(Fehler bei der Texterkennung: $e)';
      }
    }
    notifyListeners();
  }

  /// Wertet die hochgeladenen Dateien aus und legt daraus eine Anfrage an.
  ///
  /// Liegen Erkennungsdaten vor, laeuft die echte Auswertung: Tabellen-
  /// rekonstruktion, Tarifcodes, Betraege, Mengen, Summenprobe. Nur wenn gar
  /// keine Erkennung vorliegt (etwa beim Durchklicken ohne Foto), greift die
  /// Demo-Auswertung aus dem Klickdummy.
  Future<DentalRequest> processUpload() async {
    final pages = currentUploadFiles
        .map((f) => f.ocrPage)
        .whereType<OcrPage>()
        .toList();

    final InvoiceAnalysisResult analysis;
    if (pages.isEmpty) {
      if (currentUploadFiles.isEmpty) {
        currentUploadFiles.add(UploadedFile('Rechnung_Seite1.pdf'));
      }
      analysis = analyzeInvoiceDemo();
    } else {
      analysis = analyzeInvoice(pages, await tariffRepository.load());
    }

    final req = requestsRepository.createFromAnalysis(
      files: List.of(currentUploadFiles),
      analysis: analysis,
    );
    notifyListeners();
    return req;
  }
}

final uploadController = UploadController();
