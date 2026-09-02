import 'package:flutter/foundation.dart';
import '../data/tariff_repository.dart';
import '../logic/invoice_matcher.dart';
import '../logic/rechnungs_trenner.dart';
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
    unlesbareSeiten.clear();
    notifyListeners();
  }

  /// Laesst on-device OCR ueber alle aktuell hochgeladenen Bilder laufen und
  /// speichert je Datei die erkannten Zeilen samt Position.
  ///
  /// [recognize] wird bewusst hereingereicht statt fest verdrahtet: im Test
  /// laesst sich so eine aufgezeichnete Erkennung einsetzen, ohne dass ein
  /// Geraet oder ML Kit noetig waere.
  /// Seiten, an denen die Texterkennung gescheitert ist.
  ///
  /// Bei drei Fotos, von denen eines unlesbar war, hat die App frueher zwei
  /// ausgewertet und ueber das dritte geschwiegen -- das Ergebnis sah
  /// vollstaendig aus, war es aber nicht.
  final List<String> unlesbareSeiten = [];

  /// [fortschritt] wird nach jeder Seite gerufen (fertig, gesamt). Die
  /// Erkennung dauert Sekunden je Bild -- ohne Rueckmeldung sieht die App in
  /// dieser Zeit aus, als haenge sie.
  Future<void> runOcrOnUploads(
    Future<OcrPage> Function(String path) recognize, {
    void Function(int fertig, int gesamt)? fortschritt,
  }) async {
    unlesbareSeiten.clear();
    final gesamt = currentUploadFiles.where((f) => f.path != null).length;
    var fertig = 0;
    for (final f in currentUploadFiles) {
      if (f.path == null) continue;
      try {
        final page = await recognize(f.path!);
        f.ocrPage = page;
        f.recognizedText = page.flatText;
      } catch (e) {
        f.ocrPage = null;
        f.recognizedText = '(Fehler bei der Texterkennung: $e)';
        unlesbareSeiten.add(f.name);
      }
      fortschritt?.call(++fertig, gesamt);
    }
    notifyListeners();
  }

  /// Wertet die hochgeladenen Dateien aus und legt daraus eine Anfrage an.
  ///
  /// Liegen Erkennungsdaten vor, laeuft die echte Auswertung: Tabellen-
  /// rekonstruktion, Tarifcodes, Betraege, Mengen, Summenprobe. Nur wenn gar
  /// keine Erkennung vorliegt (etwa beim Durchklicken ohne Foto), greift die
  /// Demo-Auswertung aus dem Klickdummy.
  /// Wieviele Rechnungen der letzte Import ergeben hat.
  ///
  /// Mehr als eine ist der Normalfall bei einem PDF aus der Praxis. Der
  /// Nutzer muss es erfahren: Still vier Eintraege anzulegen waere so
  /// verwirrend, wie vier Totale zu addieren.
  int erkannteRechnungen = 1;

  Future<DentalRequest> processUpload() async {
    final mitSeiten =
        currentUploadFiles.where((f) => f.ocrPage != null).toList();

    if (mitSeiten.isEmpty) {
      erkannteRechnungen = 1;

      // Zwei sehr verschiedene Faelle, die frueher denselben Ausgang hatten:
      //
      //   * Gar keine Datei -- jemand klickt sich ohne Foto durch. Dafuer die
      //     Demo-Auswertung aus dem Klickdummy.
      //   * Dateien da, aber keine Erkennung -- das Foto war unlesbar oder
      //     die Texterkennung ist gescheitert. Hier darf die Demo NICHT
      //     einspringen: Sonst stuende eine erfundene Rechnung samt markierter
      //     Position als Ergebnis eines echten Fotos da. Das waere der
      //     schlimmste Fehler, den diese App machen kann.
      final leer = currentUploadFiles.isEmpty;
      if (leer) currentUploadFiles.add(UploadedFile('Rechnung_Seite1.pdf'));

      final req = requestsRepository.createFromAnalysis(
        files: List.of(currentUploadFiles),
        analysis: leer ? analyzeInvoiceDemo() : analyzeUnreadable(),
      );
      notifyListeners();
      return req;
    }

    final katalog = await tariffRepository.load();
    final gruppen =
        rechnungsTrenner.trennen(mitSeiten.map((f) => f.ocrPage!).toList());

    // Seiten ohne Erkennung haengen an der ersten Rechnung: Sie sollen im
    // Verlauf nicht spurlos verschwinden.
    final ohneSeiten =
        currentUploadFiles.where((f) => f.ocrPage == null).toList();

    DentalRequest? erste;
    for (final gruppe in gruppen) {
      final dateien = mitSeiten
          .where((f) => gruppe.seiten.any((s) => identical(s, f.ocrPage)))
          .toList();
      final req = requestsRepository.createFromAnalysis(
        files: [...dateien, if (erste == null) ...ohneSeiten],
        analysis: analyzeInvoice(gruppe.seiten, katalog),
      );
      erste ??= req;
    }

    erkannteRechnungen = gruppen.length;
    // Angezeigt wird die erste, nicht die zuletzt angelegte.
    requestsRepository.currentRequest = erste;
    notifyListeners();
    return erste!;
  }
}

final uploadController = UploadController();
