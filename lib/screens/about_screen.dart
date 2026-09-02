import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

/// Erklaert, was Smile tut -- und was nicht.
///
/// Ersetzt die frueheren Anmelde- und Registrierungsbildschirme. Die waren
/// eine Attrappe: Es gibt kein Konto, bei dem man sich anmelden koennte, und
/// nichts, was eine Anmeldung schuetzen wuerde. Statt einer grundlosen Huerde
/// steht hier die Auskunft, die Nutzer tatsaechlich brauchen.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Wie Smile funktioniert', showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [
            _Abschnitt(
              icon: Icons.receipt_long_outlined,
              titel: 'Rechnung nachvollziehen',
              text: 'Du fotografierst deine Zahnarztrechnung oder wählst sie als PDF. '
                  'Smile liest die Tarifpositionen, rechnet nach, wie sich die Beträge '
                  'zusammensetzen, und zeigt dir das verständlich an.',
            ),
            _Abschnitt(
              icon: Icons.phonelink_lock_outlined,
              titel: 'Deine Daten bleiben bei dir',
              text: 'Alles passiert auf diesem Gerät: Texterkennung, Berechnung, Abgleich. '
                  'Es gibt keinen Server, kein Konto und keine Anmeldung. Deine Rechnung '
                  'wird nirgends hochgeladen und nach dem Schliessen der App nicht '
                  'aufbewahrt.',
            ),
            _Abschnitt(
              icon: Icons.fact_check_outlined,
              titel: 'Was geprüft wird',
              text: 'Ob die Beträge zum Tarif passen und ob die Rechnung in sich stimmt. '
                  'Liegt das Preisniveau über dem, was der Tarif für Privatpatienten '
                  'zulässt, sagt Smile das und rechnet es vor.',
            ),
            _Abschnitt(
              icon: Icons.help_outline_rounded,
              titel: 'Was nicht geprüft wird',
              text: 'Ob eine Behandlung nötig oder richtig war — das kann keine App '
                  'beurteilen. Auch ob eine Leistung häufiger verrechnet wurde als '
                  'üblich, prüft Smile noch nicht. Und die Referenzdaten decken bisher '
                  'nur einen Teil des Tarifs ab. "Kein Befund" heisst deshalb nicht '
                  '"alles in Ordnung", sondern "nichts, was sich belegen lässt".',
            ),
            _Abschnitt(
              icon: Icons.forum_outlined,
              titel: 'Nachfragen ist dein Recht',
              text: 'Findet Smile etwas oder verstehst du eine Position nicht, bereitet '
                  'die App eine höfliche Rückfrage an die Praxis vor. Das ist keine '
                  'Beschwerde und kein Vorwurf — eine Rechnung erklärt zu bekommen, '
                  'steht dir zu. Kommt ihr nicht weiter, vermitteln die kantonalen '
                  'Ombudsstellen der SSO kostenlos.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Abschnitt extends StatelessWidget {
  final IconData icon;
  final String titel;
  final String text;
  const _Abschnitt({required this.icon, required this.titel, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: AppColors.brand500),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 6),
                Text(text,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.slate600, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
