import 'finding.dart';
import 'ocr_result.dart';

enum RequestStatus { captured, sent, completed }

class UploadedFile {
  /// Anzeigename der Seite. Aenderbar, weil er beim Erfassen durch einen
  /// sprechenden ersetzt wird, sobald der Briefkopf gelesen ist -- aus
  /// "IMG_20260216_101233.jpg" wird "112233 Dr. med. dent. Max Muster.jpg".
  String name;
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

  /// Bewusst ohne [recognizedText] und [ocrPage]: Die Erkennungsdaten sind
  /// gross und werden nach der Auswertung nicht mehr gebraucht. Was bleibt,
  /// ist der Name fuer die Anzeige.
  Map<String, dynamic> toJson() => {'name': name, 'path': path};

  factory UploadedFile.fromJson(Map<String, dynamic> json) =>
      UploadedFile(json['name'] as String, path: json['path'] as String?);
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

  Map<String, dynamic> toJson() => {
        'code': code,
        'description': description,
        'amountChf': amountChf,
        'flagged': flagged,
        'quantity': quantity,
        'taxpunkte': taxpunkte,
        'taxpunkteFromCatalog': taxpunkteFromCatalog,
      };

  factory TariffLine.fromJson(Map<String, dynamic> json) => TariffLine(
        code: json['code'] as String,
        description: json['description'] as String,
        amountChf: (json['amountChf'] as num).toDouble(),
        flagged: (json['flagged'] ?? false) as bool,
        quantity: json['quantity'] as int?,
        taxpunkte: (json['taxpunkte'] as num?)?.toDouble(),
        taxpunkteFromCatalog: (json['taxpunkteFromCatalog'] ?? false) as bool,
      );
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

  /// Postleitzahl, Ort und daraus abgeleiteter Kanton der Praxis.
  /// Der Kanton wird bei der Erfassung einmal bestimmt und mitgespeichert,
  /// damit ein spaeter aktualisiertes Verzeichnis eine alte Rechnung nicht
  /// nachtraeglich anders beantwortet.
  String? dentistPostalCode;
  String? dentistCity;
  String? dentistCanton;

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

  /// Belegbare Befunde zur Rechnung.
  List<InvoiceFinding> findings;

  /// Wurde die Rechnung erkennbar schief aufgenommen? Der haeufigste Grund
  /// dafuer, dass eine Lesung nicht aufgeht.
  bool wasPhotographedCrooked;

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
    this.dentistPostalCode,
    this.dentistCity,
    this.dentistCanton,
    this.factor,
    this.statedTotal,
    this.totalsMatch = false,
    this.isTrustworthy = false,
    this.findings = const [],
    this.wasPhotographedCrooked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'files': files.map((f) => f.toJson()).toList(),
        'invoiceNumber': invoiceNumber,
        'dentistName': dentistName,
        'dentistAddress': dentistAddress,
        'dentistEmail': dentistEmail,
        'dentistPostalCode': dentistPostalCode,
        'dentistCity': dentistCity,
        'dentistCanton': dentistCanton,
        'date': date.toIso8601String(),
        'status': status.name,
        'lines': lines.map((l) => l.toJson()).toList(),
        'invoiceTotal': invoiceTotal,
        'referenceTotal': referenceTotal,
        'factor': factor,
        'statedTotal': statedTotal,
        'totalsMatch': totalsMatch,
        'isTrustworthy': isTrustworthy,
        'wasPhotographedCrooked': wasPhotographedCrooked,
        'findings': findings.map((f) => f.toJson()).toList(),
      };

  factory DentalRequest.fromJson(Map<String, dynamic> json) => DentalRequest(
        id: json['id'] as int,
        filename: json['filename'] as String,
        files: (json['files'] as List)
            .map((f) => UploadedFile.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
        invoiceNumber: json['invoiceNumber'] as String,
        dentistName: json['dentistName'] as String,
        dentistAddress: json['dentistAddress'] as String,
        dentistEmail: json['dentistEmail'] as String?,
        dentistPostalCode: json['dentistPostalCode'] as String?,
        dentistCity: json['dentistCity'] as String?,
        dentistCanton: json['dentistCanton'] as String?,
        date: DateTime.parse(json['date'] as String),
        status: RequestStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => RequestStatus.captured,
        ),
        lines: (json['lines'] as List)
            .map((l) => TariffLine.fromJson(Map<String, dynamic>.from(l as Map)))
            .toList(),
        invoiceTotal: (json['invoiceTotal'] as num).toDouble(),
        referenceTotal: (json['referenceTotal'] as num).toDouble(),
        factor: (json['factor'] as num?)?.toDouble(),
        statedTotal: (json['statedTotal'] as num?)?.toDouble(),
        totalsMatch: (json['totalsMatch'] ?? false) as bool,
        isTrustworthy: (json['isTrustworthy'] ?? false) as bool,
        wasPhotographedCrooked: (json['wasPhotographedCrooked'] ?? false) as bool,
        findings: (json['findings'] as List? ?? const [])
            .map((f) => InvoiceFinding.fromJson(Map<String, dynamic>.from(f as Map)))
            .toList(),
      );

  List<TariffLine> get flaggedLines => lines.where((l) => l.flagged).toList();
  List<TariffLine> get unresolvedLines => lines.where((l) => !l.isResolved).toList();
  double get difference => invoiceTotal - referenceTotal;
}

class OmbudsmanContact {
  final String region;
  final String name;
  final String location;
  final String phone;

  /// Kantonskuerzel, fuer die diese Stelle zustaendig ist. Meist genau eines,
  /// St. Gallen deckt zusaetzlich beide Appenzell ab.
  final List<String> cantons;

  const OmbudsmanContact({
    required this.region,
    required this.name,
    required this.location,
    required this.phone,
    this.cantons = const [],
  });

  bool covers(String? cantonCode) =>
      cantonCode != null && cantons.contains(cantonCode);
}
