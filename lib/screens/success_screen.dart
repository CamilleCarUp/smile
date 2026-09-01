import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';

class SuccessScreen extends StatelessWidget {
  final bool mailAppOpened;
  const SuccessScreen({super.key, required this.mailAppOpened});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Fertig'),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.brand100, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 48, color: AppColors.good),
                ),
                const SizedBox(height: 24),
                Text(
                  mailAppOpened ? 'Mail-Entwurf bereit!' : 'Anfrage vorbereitet',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  mailAppOpened
                      ? 'Deine Mail-App hat sich mit dem vorbereiteten Anfragetext geöffnet. '
                        'Bitte dort noch die E-Mail-Adresse deines Zahnarztes eintragen und senden.'
                      : 'Auf diesem Gerät konnte keine Mail-App automatisch geöffnet werden. '
                        'Der Anfragetext steht weiterhin unter "Meine Anfragen" bereit.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.slate600, height: 1.4),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Zurück zur Startseite'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
