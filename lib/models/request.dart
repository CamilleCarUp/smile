import 'ocr_result.dart';

enum RequestStatus { captured, sent, completed }

class UploadedFile {
  final String name;
  /// Lokaler Dateipfad auf dem Gerät (Kamera-Foto oder Galerie-Bild).
  /// Null bei Demo-Einträgen, die nie einen echten Datei-Ursprung hatten.
  final String? path;
  /// Roh-Text aus der on-device OCR. Nur noch fuer die Anzeige —
  /// zum Auswerten wird [ocrPage] genutzt, weil dort die Positionen
  /// erhalten bleiben.
  String? recognizedText;
  /// Erkannte Zeilen samt Bounding Box. Grundlage der Tabellen-
  /// rekonstruktion in Phase 2.
  OcrPage? ocrPage;

  UploadedFile(this.name, {this.path, this.recognizedText, this.ocrPage});
}

/// Eine Position aus der Rechnung, abgeglichen mit den Referenzdaten.
/// [flagged] = weicht vom typischen Behandlungsmuster ab (rotes X im Mockup).
class TariffLine {
  final String code;
  final String description;
  final double amountChf;
  final bool flagged;

  /// Zurueckgerechnete Anzahl. Null, wenn die Position nicht aufgeschluesselt
  /// werden konnte — dann zeigt die App bewusst nichts an, statt zu raten.
  final int? quantity;

  /// Verwendete Taxpunkte. Null, wenn nicht bestimmbar.
  final double? taxpunkte;

  /// Kamen die Taxpunkte aus der Referenzdatenbank (sicherer) oder von der
  /// Rechnung selbst?
  final bool taxpunkteFromCatalog;

  const TariffLine({
    required this.code,
    required this.description,
    required this.amountChf,
    this.flagged = false,
    this.quantity,
    this.taxpunkte,
    this.taxpunkteFromCatalog = false,
  });

  bool get isResolved => quantity != null && taxpunkte != null;
}

class DentalRequest {
  final int id;
  String filename;
  List<UploadedFile> files;
  String invoiceNumber;
  String dentistName;
  String dentistAddress;
  DateTime date;
  RequestStatus status;
  List<TariffLine> lines;
  double invoiceTotal;
  double referenceTotal;

  /// E-Mail der Praxis, falls auf der Rechnung gefunden. Damit laesst sich die
  /// Rueckfrage tatsaechlich adressieren, statt den Nutzer die Adresse selbst
  /// heraussuchen zu lassen.
  String? dentistEmail;

  /// Ermittelter Faktor zwischen Taxpunkten und Franken.
  /// Nicht als "Taxpunktwert der Praxis" beschriften: fuer Privatpatienten
  /// sind die Taxpunkte selbst eine Spanne, erst darauf wirkt der
  /// Taxpunktwert. Was hier steht, ist beides zusammen.
  double? factor;

  /// Auf der Rechnung ausgewiesenes Total, falls gefunden.
  double? statedTotal;

  /// Ging die Summenprobe auf?
  bool totalsMatch;

  /// Durfte die App aus diesem Ergebnis ueberhaupt eine Aussage ableiten?
  bool isTrustworthy;

  DentalRequest({
    required this.id,
    required this.filename,
    required this.files,
    required this.invoiceNumber,
    required this.dentistName,
    required this.dentistAddress,
    required this.date,
    this.status = RequestStatus.captured,
    required this.lines,
    required this.invoiceTotal,
    required this.referenceTotal,
    this.dentistEmail,
    this.factor,
    this.statedTotal,
    this.totalsMatch = false,
    this.isTrustworthy = false,
  });

  List<TariffLine> get flaggedLines => lines.where((l) => l.flagged).toList();
  List<TariffLine> get unresolvedLines => lines.where((l) => !l.isResolved).toList();
  double get difference => invoiceTotal - referenceTotal;
}

class OmbudsmanContact {
  final String region;
  final String name;
  final String location;
  final String phone;
  const OmbudsmanContact({
    required this.region,
    required this.name,
    required this.location,
    required this.phone,
  });
}
