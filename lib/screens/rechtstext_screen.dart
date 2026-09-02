import 'package:flutter/material.dart';

import '../data/rechtstexte.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

/// Zeigt einen der rechtlichen Texte.
///
/// Ein Bildschirm fuer alle drei: Datenschutz, Haftung, Impressum. Sie
/// unterscheiden sich im Inhalt, nicht in der Darstellung.
class RechtstextScreen extends StatelessWidget {
  final Rechtstext text;
  const RechtstextScreen({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, text.titel, showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(text.kurz,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate800,
                    height: 1.45)),
            const SizedBox(height: 20),

            // Solange Platzhalter drinstehen, sagt es die App selbst. Ein
            // unvollstaendiges Impressum faellt sonst erst jemand anderem auf.
            if (text.hatPlatzhalter) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Dieser Text ist noch nicht fertig — die Angaben in ‹spitzen '
                        'Klammern› fehlen. Vor einer Veröffentlichung im App Store muss '
                        'das ausgefüllt sein.',
                        style: TextStyle(fontSize: 12, color: AppColors.slate700, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            for (final abschnitt in text.abschnitte) ...[
              Text(abschnitt.titel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brand600)),
              const SizedBox(height: 6),
              Text(abschnitt.text,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.slate600, height: 1.5)),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
