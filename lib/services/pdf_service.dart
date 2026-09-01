import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Rendert jede Seite einer lokalen PDF-Datei zu einem PNG-Bild im
/// App-eigenen temporaeren Verzeichnis, damit die OCR (die nur Bilder
/// versteht) darueber laufen kann. Alles bleibt auf dem Geraet.
class PdfService {
  Future<List<String>> renderPdfToImages(String pdfPath) async {
    final document = await PdfDocument.openFile(pdfPath);
    final tempDir = await getTemporaryDirectory();
    final baseName = pdfPath.split(Platform.pathSeparator).last.replaceAll('.pdf', '');
    final paths = <String>[];

    try {
      for (var i = 1; i <= document.pagesCount; i++) {
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
              '${tempDir.path}${Platform.pathSeparator}${baseName}_seite$i.png',
            );
            await file.writeAsBytes(rendered.bytes);
            paths.add(file.path);
          }
        } finally {
          await page.close();
        }
      }
    } finally {
      await document.close();
    }
    return paths;
  }
}

final pdfService = PdfService();
