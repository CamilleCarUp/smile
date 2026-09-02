import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/ombudsman_data.dart';
import '../data/swiss_cantons.dart';
import '../models/request.dart';
import '../state/profile_controller.dart';
import '../theme/app_theme.dart';

/// Die kantonalen Ombudsstellen der SSO.
///
/// Zustaendig ist die Stelle im Kanton der Praxis. Steht der Ort der Praxis
/// auf der Rechnung, entscheidet er; sonst dient der Kanton aus dem Profil
/// als Notbehelf. So durchsucht niemand 21 Eintraege, waehrend er ohnehin
/// schon verunsichert ist.
class OmbudsmanScreen extends StatelessWidget {
  /// Kanton der Praxis, aus der Rechnung gelesen.
  final String? praxisKanton;

  /// Ort der Praxis, nur zur Anzeige ("Für die Praxis in 8005 Zürich").
  final String? praxisOrt;

  const OmbudsmanScreen({super.key, this.praxisKanton, this.praxisOrt});

  @override
  Widget build(BuildContext context) {
    final ausRechnung = (praxisKanton ?? '').isNotEmpty;
    final kanton = ausRechnung ? praxisKanton! : profileController.profile.canton;
    final zustaendig = ombudsmanContacts.where((c) => c.covers(kanton)).toList();
    final uebrige = ombudsmanContacts.where((c) => !c.covers(kanton)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Ombudsstelle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Falls keine Einigung erzielt wird, vermitteln die offiziellen '
                'SSO-Ombudsstellen kostenlos zwischen dir und deinem Zahnarzt.',
                style: TextStyle(color: AppColors.slate600, height: 1.4),
              ),
            ),

            if (zustaendig.isNotEmpty) ...[
              Text(
                  ausRechnung
                      ? 'Für die Praxis in ${praxisOrt ?? cantonName(kanton) ?? kanton}'
                      : 'Für ${cantonName(kanton) ?? kanton}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand600)),
              const SizedBox(height: 8),
              for (final c in zustaendig) _Eintrag(kontakt: c, hervorgehoben: true),
              _Hinweis(
                text: ausRechnung
                    ? 'Smile hat den Ort der Praxis aus der Rechnung gelesen. Zuständig '
                        'ist die Stelle im Kanton der Praxis, nicht deines Wohnorts.'
                    : 'Zuständig ist in der Regel die Stelle im Kanton der Praxis, nicht '
                        'deines Wohnorts. Behandelt dich jemand ausserhalb deines Kantons, '
                        'nimm die Stelle von dort.',
              ),
              const SizedBox(height: 20),
              const Text('Alle Stellen',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.slate500)),
              const SizedBox(height: 8),
            ] else if (kanton.isNotEmpty) ...[
              _Hinweis(
                warnung: true,
                text: 'Für ${cantonName(kanton) ?? kanton} ist hier keine eigene Stelle '
                    'hinterlegt. Wende dich an eine benachbarte Stelle im Kanton der '
                    'Praxis.',
              ),
              const SizedBox(height: 12),
            ] else ...[
              const _Hinweis(
                text: 'Unter "Meine Angaben" kannst du deinen Kanton hinterlegen — dann '
                    'steht die zuständige Stelle künftig zuoberst.',
              ),
              const SizedBox(height: 12),
            ],

            for (final c in uebrige) _Eintrag(kontakt: c, hervorgehoben: false),
          ],
        ),
      ),
    );
  }
}

class _Eintrag extends StatelessWidget {
  final OmbudsmanContact kontakt;
  final bool hervorgehoben;
  const _Eintrag({required this.kontakt, required this.hervorgehoben});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: hervorgehoben
          ? RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.brand400, width: 1.5),
              borderRadius: BorderRadius.circular(16))
          : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(kontakt.region,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.brand600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(kontakt.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(kontakt.location,
                style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.call_outlined, size: 16),
                    label: const Text('Anrufen', style: TextStyle(fontSize: 12)),
                    onPressed: () => launchUrl(
                        Uri(scheme: 'tel', path: kontakt.phone.replaceAll(' ', ''))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mail_outline, size: 16),
                    label: const Text('E-Mail', style: TextStyle(fontSize: 12)),
                    onPressed: () => launchUrl(Uri(
                      scheme: 'mailto',
                      query: 'subject=${Uri.encodeComponent('Anfrage Ombudsstelle')}',
                    )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Hinweis extends StatelessWidget {
  final String text;
  final bool warnung;
  const _Hinweis({required this.text, this.warnung = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(warnung ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              size: 16, color: warnung ? AppColors.danger : AppColors.slate400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.slate600, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
