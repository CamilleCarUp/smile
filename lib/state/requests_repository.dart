import 'package:flutter/foundation.dart';
import '../logic/invoice_matcher.dart';
import '../models/request.dart';

/// Verwaltet die Liste erfasster/gesendeter/abgeschlossener Anfragen.
/// Getrennt vom Upload-Ablauf, damit z.B. "Meine Anfragen" unabhaengig
/// von der Kamera/OCR-Logik getestet und weiterentwickelt werden kann.
class RequestsRepository extends ChangeNotifier {
  final List<DentalRequest> requests = [];
  DentalRequest? currentRequest;
  int _nextInvoiceCounter = 112233;
  double taxpunktwert = 1.20;

  DentalRequest createFromAnalysis({
    required List<UploadedFile> files,
    required InvoiceAnalysisResult analysis,
  }) {
    final primaryName = files.first.name;
    final suffix = files.length > 1 ? ' (+${files.length - 1})' : '';
    final req = DentalRequest(
      id: DateTime.now().millisecondsSinceEpoch,
      filename: '$primaryName$suffix',
      files: files,
      invoiceNumber: (_nextInvoiceCounter++).toString(),
      dentistName: 'Dr. med. dent. Max Muster',
      dentistAddress: 'Alte Gasse 13, 8005 Zürich',
      date: DateTime.now(),
      lines: analysis.lines,
      invoiceTotal: analysis.invoiceTotal,
      referenceTotal: analysis.referenceTotal,
    );
    requests.insert(0, req);
    currentRequest = req;
    notifyListeners();
    return req;
  }

  void submitCurrentRequest() {
    if (currentRequest != null) {
      currentRequest!.status = RequestStatus.sent;
      notifyListeners();
    }
  }

  void markCompleted(int id) {
    requests.firstWhere((r) => r.id == id).status = RequestStatus.completed;
    notifyListeners();
  }

  void cancelRequest(int id) {
    requests.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void openRequest(DentalRequest r) {
    currentRequest = r;
    notifyListeners();
  }
}

final requestsRepository = RequestsRepository();
