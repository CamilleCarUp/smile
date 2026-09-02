import 'package:flutter/foundation.dart';
import '../data/plz_verzeichnis.dart';
import '../data/secure_store.dart';
import '../logic/invoice_matcher.dart';
import '../logic/praxis_ort.dart';
import '../logic/rechnungsname.dart';
import '../models/request.dart';

/// Verwaltet die Liste erfasster/gesendeter/abgeschlossener Anfragen.
/// Getrennt vom Upload-Ablauf, damit z.B. "Meine Anfragen" unabhaengig
/// von der Kamera/OCR-Logik getestet und weiterentwickelt werden kann.
class RequestsRepository extends ChangeNotifier {
  static const _storeName = 'requests';

  final SecureStore _store;
  RequestsRepository({SecureStore? store}) : _store = store ?? secureStore;

  final List<DentalRequest> requests = [];
  DentalRequest? currentRequest;
  int _nextInvoiceCounter = 112233;
  double taxpunktwert = 1.20;

  /// Laedt den Verlauf beim Start der App.
  Future<void> load() async {
    final data = await _store.read(_storeName);
    if (data == null) return;
    try {
      final restored = (data['requests'] as List)
          .map((r) => DentalRequest.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      requests
        ..clear()
        ..addAll(restored);
      _nextInvoiceCounter = (data['nextInvoiceCounter'] as int?) ?? _nextInvoiceCounter;
      notifyListeners();
    } catch (_) {
      // Ein unlesbarer Verlauf darf die App nicht am Starten hindern.
      await _store.delete(_storeName);
    }
  }

  /// Schreibt den Verlauf zurueck.
  ///
  /// Schlaegt bewusst nicht durch: Wenn das Speichern scheitert -- volle
  /// Platte, oder im Test gibt es gar kein Dateisystem -- soll die App
  /// weiterlaufen. [saveFailed] macht es sichtbar, statt es zu verschweigen.
  bool saveFailed = false;

  Future<void> _save() async {
    try {
      await _store.write(_storeName, {
        'requests': requests.map((r) => r.toJson()).toList(),
        'nextInvoiceCounter': _nextInvoiceCounter,
      });
      saveFailed = false;
    } catch (_) {
      saveFailed = true;
    }
  }

  DentalRequest createFromAnalysis({
    required List<UploadedFile> files,
    required InvoiceAnalysisResult analysis,
  }) {
    final header = analysis.header;

    // Ohne Kopfdaten liegt eine Demo-Auswertung vor -- dann die Werte aus dem
    // Klickdummy. Bei einer echten Rechnung wird uebernommen, was gelesen
    // wurde; was fehlt, wird als fehlend benannt statt erfunden.
    // Ort der Praxis: aus der Rechnung gelesen, in der Demo-Auswertung aus
    // der Beispieladresse.
    final praxisOrt = header == null
        ? PraxisOrt.ausAdresse('Alte Gasse 13, 8005 Zürich')
        : header.dentistPlace;

    final nummer = header == null
        ? (_nextInvoiceCounter++).toString()
        : (header.invoiceNumber ?? (_nextInvoiceCounter++).toString());
    final praxis = header == null
        ? 'Dr. med. dent. Max Muster'
        : (header.dentistName ?? 'Praxis nicht erkannt');
    final datum = header?.date ?? DateTime.now();

    // Gleich beim Erfassen benennen, nicht spaeter von Hand: Nach drei
    // Monaten sagt "IMG_20260216_101233.jpg" niemandem mehr etwas,
    // Rechnungsnummer und Praxis schon.
    final name = rechnungsName(
      rechnungsnummer: header == null ? null : header.invoiceNumber,
      praxis: praxis,
      datum: datum,
    );
    for (var i = 0; i < files.length; i++) {
      files[i].name = seitenName(
        basis: name,
        seite: i + 1,
        seiten: files.length,
        original: files[i].name,
      );
    }

    final req = DentalRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      filename: name,
      files: files,
      invoiceNumber: nummer,
      dentistName: praxis,
      dentistAddress: header == null
          ? 'Alte Gasse 13, 8005 Zürich'
          : (header.dentistAddress ?? ''),
      date: datum,
      lines: analysis.lines,
      invoiceTotal: analysis.invoiceTotal,
      referenceTotal: analysis.referenceTotal,
      dentistEmail: header?.dentistEmail,
      // Aus dem Briefkopf gelesen; der Kanton kommt aus dem
      // Ortschaftenverzeichnis. Ist es nicht geladen oder die Postleitzahl
      // unbekannt, bleibt der Kanton leer und der Ombudsstellen-Bildschirm
      // zeigt die vollstaendige Liste.
      dentistPostalCode: praxisOrt?.plz,
      dentistCity: praxisOrt?.ort,
      dentistCanton: PlzVerzeichnis.aktuell
          .kanton(plz: praxisOrt?.plz, ort: praxisOrt?.ort),
      factor: analysis.factor,
      statedTotal: analysis.statedTotal,
      totalsMatch: analysis.totalsMatch,
      isTrustworthy: analysis.isTrustworthy,
      findings: analysis.findings,
      wasPhotographedCrooked: analysis.wasPhotographedCrooked,
    );
    requests.insert(0, req);
    currentRequest = req;
    notifyListeners();
    _save();
    return req;
  }

  void submitCurrentRequest() {
    if (currentRequest != null) {
      currentRequest!.status = RequestStatus.sent;
      notifyListeners();
      _save();
    }
  }

  void markCompleted(int id) {
    requests.firstWhere((r) => r.id == id).status = RequestStatus.completed;
    notifyListeners();
    _save();
  }

  void cancelRequest(int id) {
    requests.removeWhere((r) => r.id == id);
    notifyListeners();
    _save();
  }

  /// Aendert eine noch nicht gesendete Anfrage.
  ///
  /// Nur solange sie erfasst ist: Was einmal raus ist, laesst sich nicht mehr
  /// nachtraeglich umschreiben -- die Praxis hat den Text ja schon.
  bool updateCaptured(int id, {String? dentistEmail, String? dentistName}) {
    final req = requests.firstWhere((r) => r.id == id);
    if (req.status != RequestStatus.captured) return false;
    if (dentistEmail != null) req.dentistEmail = dentistEmail.trim();
    if (dentistName != null) req.dentistName = dentistName.trim();
    notifyListeners();
    _save();
    return true;
  }

  /// Loescht den gesamten Verlauf.
  Future<void> clearAll() async {
    requests.clear();
    currentRequest = null;
    notifyListeners();
    await _store.delete(_storeName);
  }

  void openRequest(DentalRequest r) {
    currentRequest = r;
    notifyListeners();
  }
}

/// Bewusst veraenderbar statt `final` -- siehe [profileController].
RequestsRepository requestsRepository = RequestsRepository();
