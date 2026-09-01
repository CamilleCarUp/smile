// Testet UploadController isoliert von der UI -- reine ChangeNotifier-Logik.
import 'package:flutter_test/flutter_test.dart';
import 'package:smile/state/upload_controller.dart';

void main() {
  setUp(() => uploadController.reset());
  tearDown(() => uploadController.reset());

  group('UploadController', () {
    test('addUploadedFile fügt eine Datei hinzu und benachrichtigt Listener', () {
      var notified = false;
      uploadController.addListener(() => notified = true);

      uploadController.addUploadedFile('Foto1.jpg', path: '/tmp/foto1.jpg');

      expect(uploadController.currentUploadFiles, hasLength(1));
      expect(uploadController.currentUploadFiles.first.name, 'Foto1.jpg');
      expect(notified, isTrue);
    });

    test('removeUploadedFile entfernt die Datei am gegebenen Index', () {
      uploadController.addUploadedFile('Foto1.jpg');
      uploadController.addUploadedFile('Foto2.jpg');

      uploadController.removeUploadedFile(0);

      expect(uploadController.currentUploadFiles, hasLength(1));
      expect(uploadController.currentUploadFiles.first.name, 'Foto2.jpg');
    });

    test('reset leert die Liste der hochgeladenen Dateien', () {
      uploadController.addUploadedFile('Foto1.jpg');
      uploadController.reset();
      expect(uploadController.currentUploadFiles, isEmpty);
    });

    test('processUpload erstellt eine Anfrage mit den hochgeladenen Dateien', () {
      uploadController.addUploadedFile('Rechnung_Test.pdf');
      final req = uploadController.processUpload();

      expect(req.filename, contains('Rechnung_Test.pdf'));
      expect(req.lines, isNotEmpty);
    });
  });
}
