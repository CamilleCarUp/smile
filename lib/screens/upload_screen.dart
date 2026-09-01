import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/pdf_service.dart';
import '../state/upload_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'ocr_debug_screen.dart';

/// Phase 1: echte Kamera-/Galerie-Auswahl + on-device OCR.
/// PDF-Import folgt als naechster Schritt (Phase 1b).
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker = ImagePicker();
  bool _isAnalyzing = false;
  bool _isImportingPdf = false;

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        uploadController.addUploadedFile(photo.name, path: photo.path);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Aufnahme gemacht (abgebrochen).')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kamera-Fehler: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final photos = await _picker.pickMultiImage(imageQuality: 85);
      if (photos.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Fotos ausgewählt.')),
        );
      }
      for (final p in photos) {
        uploadController.addUploadedFile(p.name, path: p.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Galerie-Fehler: $e')),
        );
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Keine PDF-Datei ausgewählt.')),
          );
        }
        return;
      }
      setState(() => _isImportingPdf = true);
      for (final f in result.files) {
        final path = f.path;
        if (path == null) continue;
        final pageImages = await pdfService.renderPdfToImages(path);
        for (var i = 0; i < pageImages.length; i++) {
          final label = pageImages.length > 1 ? '${f.name} – Seite ${i + 1}' : f.name;
          uploadController.addUploadedFile(label, path: pageImages[i]);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF-Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImportingPdf = false);
    }
  }

  Future<void> _analyze() async {
    setState(() => _isAnalyzing = true);
    await uploadController.runOcrOnUploads(ocrService.recognizeText);
    setState(() => _isAnalyzing = false);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const OcrDebugScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Rechnung prüfen', showHome: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Oberer Bereich (Auswahl-Kacheln, Hinweistext, Dateiliste) ist
              // scrollbar, damit auf kleinen Bildschirmen/im Querformat nichts
              // ueberlaeuft. Der "Analysieren"-Button bleibt unten fixiert
              // sichtbar, statt im Scrollbereich zu verschwinden.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Rechnungsfoto(s) hinzufügen',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.slate600)),
                      const SizedBox(height: 12),
                      _PickerTile(
                        icon: Icons.photo_camera_outlined,
                        label: 'Foto aufnehmen',
                        sublabel: 'Nutzt die Kamera deines Smartphones',
                        onTap: _takePhoto,
                      ),
                      const SizedBox(height: 12),
                      _PickerTile(
                        icon: Icons.photo_library_outlined,
                        label: 'Aus Galerie wählen',
                        sublabel: 'Mehrfachauswahl möglich',
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(height: 12),
                      _PickerTile(
                        icon: Icons.picture_as_pdf_outlined,
                        label: _isImportingPdf ? 'PDF wird eingelesen…' : 'PDF-Datei auswählen',
                        sublabel: 'Mehrseitige PDFs werden automatisch aufgeteilt',
                        onTap: _isImportingPdf ? () {} : _pickPdf,
                        loading: _isImportingPdf,
                      ),
                      const SizedBox(height: 16),
                      const _PhaseNote(),
                      const SizedBox(height: 16),
                      AnimatedBuilder(
                        animation: uploadController,
                        builder: (context, _) {
                          final files = uploadController.currentUploadFiles;
                          if (files.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('Noch keine Datei ausgewählt.', style: TextStyle(color: AppColors.slate400)),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: files.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.brand50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.brand100),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.description_outlined, color: AppColors.brand500, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(files[i].name, overflow: TextOverflow.ellipsis)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    color: AppColors.slate400,
                                    onPressed: () => uploadController.removeUploadedFile(i),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Eigener AnimatedBuilder, damit der Button reagiert, sobald uploadController
              // sich aendert (Fotos hinzukommen) -- ohne diesen wuerde "onPressed" den
              // Dateistatus vom allerersten Build einfrieren und dauerhaft deaktiviert bleiben.
              AnimatedBuilder(
                animation: uploadController,
                builder: (context, _) => ElevatedButton(
                  onPressed: (_isAnalyzing || uploadController.currentUploadFiles.isEmpty) ? null : _analyze,
                  child: _isAnalyzing
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : const Text('Rechnung analysieren'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final bool loading;
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate300, width: 1.5),
        ),
        child: Column(
          children: [
            if (loading)
              const SizedBox(
                height: 36, width: 36,
                child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.brand400),
              )
            else
              Icon(icon, size: 36, color: AppColors.brand400),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate600)),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(sublabel!, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhaseNote extends StatelessWidget {
  const _PhaseNote();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.databoxBg, borderRadius: BorderRadius.circular(10)),
      child: const Text(
        'Foto, PDF-Import & Texterkennung laufen jetzt echt und komplett auf deinem Gerät (kein Upload). '
        'Die Auswertung selbst nutzt noch Demo-Daten – echtes Zuordnen von Tarifcode zu Preis folgt in Phase 2.',
        style: TextStyle(fontSize: 12, color: AppColors.slate600),
      ),
    );
  }
}
