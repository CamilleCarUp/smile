import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/request.dart';
import '../state/profile_controller.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'ombudsman_screen.dart';
import 'success_screen.dart';

/// Bereitet die Rueckfrage an die Praxis vor.
///
/// Grundhaltung: Die Mail stellt eine Frage, sie erhebt keinen Vorwurf. Das
/// ist nicht nur hoeflich, sondern die Voraussetzung dafuer, dass Praxen die
/// App nicht als Angriff verstehen — laut Thesis die groesste Huerde des
/// ganzen Vorhabens.
class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  /// Bewusst geschlechtsneutral. Eine feste Anrede "Sehr geehrter Herr Dr."
  /// waere bei jeder zweiten Praxis schlicht falsch.
  String _anrede(DentalRequest req) => 'Sehr geehrte Damen und Herren';

  String _grund(DentalRequest req) {
    if (req.findings.isNotEmpty) {
      final f = req.findings.first;
      return '${f.explanation}\n\n'
          'Könnten Sie mir erläutern, wie der Betrag zustande kommt?';
    }
    final flagged = req.flaggedLines;
    if (flagged.isNotEmpty) {
      final l = flagged.first;
      return 'Die Position ${l.code} "${l.description}" erscheint mehrfach, während das '
          'übliche Behandlungsmuster sie einmal vorsieht. Könnten Sie mir kurz erläutern, '
          'weshalb sie mehrfach anfällt?';
    }
    return 'Ich möchte die Rechnung gerne nachvollziehen können und bitte Sie um eine kurze '
        'Erläuterung der aufgeführten Positionen.';
  }

  /// Positionen werden nur aufgezaehlt, wenn die Rechnung sicher gelesen
  /// wurde. Sonst stuenden dort womoeglich Positionen, die der Praxis gar
  /// nicht zuzuordnen sind -- eine Rueckfrage mit falschen Angaben ist
  /// schlimmer als eine allgemeine.
  List<TariffLine> _positionen(DentalRequest req) =>
      req.isTrustworthy ? req.flaggedLines : const [];

  String _mailText(DentalRequest req) {
    final positionen = _positionen(req);
    final aufzaehlung = positionen.isEmpty
        ? ''
        : 'Konkret geht es um:\n${positionen.map((l) => '- ${l.code} ${l.description}').join('\n')}\n\n';
    return '${_anrede(req)}\n\n'
        'Ich bitte Sie um Auskunft zu meiner Rechnung Nr. ${req.invoiceNumber}'
        '${req.factor != null ? '' : ''}.\n\n'
        '$aufzaehlung'
        '${_grund(req)}\n\n'
        'Besten Dank für Ihre Rückmeldung.\n\n'
        'Freundliche Grüsse'
        // Ohne Namen endet der Brief mit der Grussformel und nichts weiter --
        // die Praxis wuesste nicht, wer schreibt.
        '${profileController.profile.isComplete ? '\n${profileController.profile.fullName}' : ''}';
  }

  /// Laesst die Empfaengeradresse korrigieren, solange die Anfrage noch nicht
  /// gesendet ist. Die Texterkennung liest E-Mail-Adressen nicht immer
  /// richtig, und ohne richtige Adresse geht die Rueckfrage ins Leere.
  Future<void> _adresseAendern(BuildContext context, DentalRequest req) async {
    final feld = TextEditingController(text: req.dentistEmail ?? '');
    final neu = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('E-Mail der Praxis'),
        content: TextField(
          controller: feld,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'praxis@beispiel.ch'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, feld.text.trim()),
              child: const Text('Übernehmen')),
        ],
      ),
    );
    feld.dispose();
    if (neu != null) {
      requestsRepository.updateCaptured(req.id, dentistEmail: neu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    final positionen = _positionen(req);

    return Scaffold(
      appBar: smileAppBar(context, 'Anfrage', showHome: true),
      body: AnimatedBuilder(
        animation: requestsRepository,
        builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            color: AppColors.databox500, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entwurf',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, color: AppColors.slate800)),
                            const SizedBox(height: 12),
                            SelectableText(_mailText(req),
                                style: const TextStyle(color: AppColors.slate800, height: 1.4)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (req.dentistEmail != null && req.dentistEmail!.isNotEmpty)
                        _Empfaenger(
                          icon: Icons.mail_outline_rounded,
                          text: 'Wird an ${req.dentistEmail} adressiert.',
                          aktion: req.status == RequestStatus.captured
                              ? () => _adresseAendern(context, req)
                              : null,
                        )
                      else
                        _Empfaenger(
                          icon: Icons.help_outline_rounded,
                          warnung: true,
                          text: 'Auf der Rechnung wurde keine E-Mail-Adresse gefunden.',
                          aktion: req.status == RequestStatus.captured
                              ? () => _adresseAendern(context, req)
                              : null,
                        ),
                      if (profileController.profile.wantsCopy)
                        _Empfaenger(
                          icon: Icons.content_copy_outlined,
                          text: 'Eine Kopie geht an ${profileController.profile.email}.',
                        ),
                      if (!req.isTrustworthy) ...[
                        const SizedBox(height: 12),
                        const _Empfaenger(
                          icon: Icons.warning_amber_rounded,
                          warnung: true,
                          text: 'Die Rechnung konnte nicht sicher gelesen werden. Der Entwurf '
                              'nennt deshalb bewusst keine einzelnen Positionen — sie könnten '
                              'falsch zugeordnet sein. Besser wäre eine neue Aufnahme.',
                        ),
                      ] else if (positionen.isEmpty) ...[
                        const SizedBox(height: 12),
                        const _Empfaenger(
                          icon: Icons.info_outline_rounded,
                          text: 'Die App hat keine bestimmte Position hervorgehoben. Der Entwurf '
                              'bittet deshalb allgemein um Erläuterung — das ist dein gutes Recht '
                              'als Patientin oder Patient.',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Anfrage senden'),
                onPressed: () async {
                  final profil = profileController.profile;
                  final uri = Uri(
                    scheme: 'mailto',
                    path: req.dentistEmail ?? '',
                    query: 'subject=${Uri.encodeComponent('Rückfrage zu Rechnung Nr. ${req.invoiceNumber}')}'
                        '&body=${Uri.encodeComponent(_mailText(req))}'
                        '${profil.wantsCopy ? '&cc=${Uri.encodeComponent(profil.email)}' : ''}',
                  );
                  var opened = false;
                  try {
                    opened = await launchUrl(uri);
                  } catch (_) {
                    opened = false;
                  }
                  requestsRepository.submitCurrentRequest();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => SuccessScreen(mailAppOpened: opened)),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.balance_outlined, size: 18),
                label: const Text('Ombudsstelle kontaktieren'),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => OmbudsmanScreen(
                              praxisKanton: req.dentistCanton,
                              praxisOrt: req.dentistPostalCode == null
                                  ? req.dentistCity
                                  : '${req.dentistPostalCode} ${req.dentistCity ?? ''}'.trim(),
                            ))),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _Empfaenger extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warnung;
  final VoidCallback? aktion;
  const _Empfaenger({
    required this.icon,
    required this.text,
    this.warnung = false,
    this.aktion,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration:
          BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: warnung ? AppColors.danger : AppColors.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: AppColors.slate600, height: 1.4)),
          ),
          if (aktion != null)
            TextButton(
              onPressed: aktion,
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
              child: const Text('Ändern', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
