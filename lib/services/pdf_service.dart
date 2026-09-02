import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Was beim Aufbereiten eines PDF herauskam.
class PdfSeiten {
  /// Pfade der erzeugten Bilder, eines je aufbereiteter Seite.
  final List<String> pfade;

  /// Wieviele Seiten das Dokument insgesamt hat.
  final int seitenImDokument;

  const PdfSeiten({required this.pfade, required this.seitenImDokument});

  /// Wurde nicht das ganze Dokument aufbereitet?
  bool get begrenzt => pfade.length < seitenImDokument;
}

/// Rendert Seiten einer lokalen PDF-Datei zu PNG-Bildern, damit die
/// Texterkennung (die nur Bilder versteht) darueber laufen kann. Alles bleibt
/// auf dem Geraet.
class PdfService {
  /// Mehr Seiten bereitet Smile nicht auf.
  ///
  /// Ein 40-seitiges Dokument waere sonst gut hundert Megabyte an
  /// Zwischenbildern und einige Minuten Texterkennung -- waehrend derer die
  /// App still steht und der Nutzer nicht weiss, ob sie noch lebt. Eine
  /// Rechnung hat ein bis drei Seiten; wer mehr schickt, schickt einen Stapel.
  static const int maxSeiten = 20;

  /// Eigener Unterordner, damit sich die Zwischenbilder wiederfinden und
  /// aufraeumen lassen -- ohne fremde Dateien im temporaeren Verzeichnis
  /// anzufassen.
  static const String unterordner = 'smile_pdf';

  /// [fortschritt] wird nach jeder Seite gerufen (fertig, gesamt) -- ohne das
  /// steht die App minutenlang stumm da.
  Future<PdfSeiten> renderPdfToImages(
    String pdfPath, {
    void Function(int fertig, int gesamt)? fortschritt,
  }) async {
    final ziel = await _verzeichnis();
    final document = await PdfDocument.openFile(pdfPath);
    final baseName =
        pdfPath.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
    final paths = <String>[];

    try {
      final gesamt = document.pagesCount;
      final aufzubereiten = gesamt < maxSeiten ? gesamt : maxSeiten;
      for (var i = 1; i <= aufzubereiten; i++) {
        final page = await document.getPage(i);
        try {
          // 2x Aufloesung fuer bessere OCR-Trefferquote bei kleiner Schrift.
          final rendered = await page.render(
            width: page.width * 2,
            height: page.height * 2,
            format: PdfPageImageFormat.png,
          );
          if (rendered != null) {
            final file = File(
                '${ziel.path}${Platform.pathSeparator}${baseName}_seite$i.png');
            await file.writeAsBytes(rendered.bytes);
            paths.add(file.path);
          }
        } finally {
          await page.close();
        }
        fortschritt?.call(i, aufzubereiten);
      }
      return PdfSeiten(pfade: paths, seitenImDokument: gesamt);
    } finally {
      await document.close();
    }
  }

  /// Loescht die Zwischenbilder frueherer Importe.
  ///
  /// Aufgerufen **vor** dem naechsten Import, nicht danach: Solange die App
  /// laeuft, zeigen die erfassten Seiten noch auf diese Dateien. So bleibt
  /// hoechstens ein Import lang etwas liegen, statt bei jedem Versuch mehr.
  Future<void> raeumeAuf() async {
    try {
      final ziel = await _verzeichnis();
      await for (final eintrag in ziel.list()) {
        if (eintrag is File) await eintrag.delete();
      }
    } catch (_) {
      // Aufraeumen ist Kuer. Scheitert es, laeuft der Import trotzdem.
    }
  }

  Future<Directory> _verzeichnis() async {
    final temp = await getTemporaryDirectory();
    final ziel = Directory('${temp.path}${Platform.pathSeparator}$unterordner');
    if (!await ziel.exists()) await ziel.create(recursive: true);
    return ziel;
  }
}

final pdfService = PdfService();
