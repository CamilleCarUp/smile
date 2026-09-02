import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/fehlertexte.dart';
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

  /// Was gerade aufbereitet wird ("Seite 7 von 40"). Ohne diese Anzeige steht
  /// die App bei einem dicken PDF minutenlang stumm da.
  String? _pdfFortschritt;

  /// Wieviele Seiten schon gelesen sind. Null, solange nichts laeuft.
  int? _gelesen;
  int _zuLesen = 0;

  /// Meldungen mit Platz fuer einen ganzen Satz: Die Standard-Snackbar
  /// schneidet lange Texte ab, und gerade die erklaeren, was zu tun ist.
  void _melde(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 8),
      ));
  }

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
      if (mounted) _melde(kameraFehlerText(e));
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
      if (mounted) _melde(galerieFehlerText(e));
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

      // Zwischenbilder des letzten Imports wegraeumen, bevor neue entstehen.
      await pdfService.raeumeAuf();

      for (final f in result.files) {
        final path = f.path;
        if (path == null) continue;
        final seiten = await pdfService.renderPdfToImages(
          path,
          fortschritt: (fertig, gesamt) {
            if (mounted) {
              setState(() => _pdfFortschritt = 'Seite $fertig von $gesamt');
            }
          },
        );
        for (var i = 0; i < seiten.pfade.length; i++) {
          final label =
              seiten.pfade.length > 1 ? '${f.name} – Seite ${i + 1}' : f.name;
          uploadController.addUploadedFile(label, path: seiten.pfade[i]);
        }
        if (seiten.begrenzt && mounted) {
          _melde('${f.name} hat ${seiten.seitenImDokument} Seiten. Smile hat die '
              'ersten ${seiten.pfade.length} aufbereitet — eine Rechnung ist selten '
              'länger. Fehlt etwas, importiere den Rest als eigene Datei.');
        }
      }
    } catch (e) {
      if (mounted) _melde(pdfFehlerText(e));
    } finally {
      if (mounted) {
        setState(() {
          _isImportingPdf = false;
          _pdfFortschritt = null;
        });
      }
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _isAnalyzing = true;
      _gelesen = 0;
      _zuLesen = uploadController.currentUploadFiles.where((f) => f.path != null).length;
    });
    await uploadController.runOcrOnUploads(
      ocrService.recognizePage,
      fortschritt: (fertig, gesamt) {
        if (mounted) {
          setState(() {
            _gelesen = fertig;
            _zuLesen = gesamt;
          });
        }
      },
    );
    setState(() {
      _isAnalyzing = false;
      _gelesen = null;
    });
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
                      if (_isAnalyzing) ...[
                        _LesenKarte(gelesen: _gelesen ?? 0, gesamt: _zuLesen),
                        const SizedBox(height: 16),
                      ],
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
                        sublabel: _pdfFortschritt ??
                            'Mehrseitige PDFs werden automatisch aufgeteilt',
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
    // Als ein Element vorlesen, nicht als Icon, Zeile und Unterzeile
    // einzeln -- und ausdruecklich als Schaltflaeche.
    return Semantics(
      button: true,
      label: sublabel == null ? label : '$label. $sublabel',
      excludeSemantics: true,
      child: InkWell(
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
      ),
    );
  }
}

/// Was waehrend der Texterkennung zu sehen ist.
///
/// Sekunden je Bild sind lang genug, dass jemand sich fragt, ob die App noch
/// lebt -- und lang genug, um das Wichtigste ueber Smile zu sagen: Das Bild
/// bleibt hier. Ein Balken allein haette diesen Platz verschenkt.
class _LesenKarte extends StatelessWidget {
  final int gelesen;
  final int gesamt;
  const _LesenKarte({required this.gelesen, required this.gesamt});

  @override
  Widget build(BuildContext context) {
    final mehrere = gesamt > 1;
    final anteil = gesamt == 0 ? null : gelesen / gesamt;

    return Semantics(
      liveRegion: true,
      label: mehrere
          ? 'Rechnung wird gelesen, Seite ${gelesen + 1} von $gesamt'
          : 'Rechnung wird gelesen',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.brand50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brand100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.brand500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mehrere
                        ? 'Seite ${gelesen < gesamt ? gelesen + 1 : gesamt} von $gesamt wird gelesen'
                        : 'Die Rechnung wird gelesen',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.brand600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: anteil == null || anteil == 0 ? null : anteil,
                minHeight: 6,
                backgroundColor: AppColors.brand100,
                color: AppColors.brand500,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Das Bild bleibt auf deinem Gerät. Smile lädt nichts hoch und fragt '
              'niemanden — gelesen wird hier, im Telefon.',
              style: TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4),
            ),
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
        'Foto, PDF-Import, Texterkennung und Auswertung laufen komplett auf deinem Gerät — '
        'kein Upload, kein Konto. Am zuverlässigsten liest Smile ein direkt importiertes PDF.',
        style: TextStyle(fontSize: 12, color: AppColors.slate600),
      ),
    );
  }
}
