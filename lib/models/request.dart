enum RequestStatus { captured, sent, completed }

class UploadedFile {
  final String name;
  /// Lokaler Dateipfad auf dem Gerät (Kamera-Foto oder Galerie-Bild).
  /// Null bei Demo-Einträgen, die nie einen echten Datei-Ursprung hatten.
  final String? path;
  /// Roh-Text aus der on-device OCR (Phase 1). Wird nach dem Erkennen befuellt.
  String? recognizedText;

  UploadedFile(this.name, {this.path, this.recognizedText});
}

/// Eine Position aus der Rechnung, abgeglichen mit den Referenzdaten.
/// [flagged] = weicht vom typischen Behandlungsmuster ab (rotes X im Mockup).
class TariffLine {
  final String code;
  final String description;
  final double amountChf;
  final bool flagged;

  const TariffLine({
    required this.code,
    required this.description,
    required this.amountChf,
    this.flagged = false,
  });
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
  });

  List<TariffLine> get flaggedLines => lines.where((l) => l.flagged).toList();
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
