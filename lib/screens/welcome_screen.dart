import 'package:flutter/material.dart';
import '../state/upload_controller.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'cost_estimate_screen.dart';
import 'requests_list_screen.dart';
import 'upload_screen.dart';

/// Startbildschirm der App.
///
/// Bewusst ohne Anmeldung: Es gibt kein Konto und nichts, was eine Anmeldung
/// schuetzen wuerde. Wer die App oeffnet, soll sofort zu dem kommen, weswegen
/// er sie geoeffnet hat.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smile')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.emoji_emotions_outlined,
                      size: 48, color: AppColors.brand500),
                  const SizedBox(height: 16),
                  const Text('Zahnarztrechnung verstehen',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Alles bleibt auf deinem Gerät — kein Konto, kein Upload.',
                      style: TextStyle(color: AppColors.slate500, fontSize: 13),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Rechnung prüfen'),
                    onPressed: () {
                      uploadController.reset();
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const UploadScreen()));
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Kostenschätzung'),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CostEstimateScreen())),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Meine Anfragen'),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RequestsListScreen())),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    child: const Text('Wie Smile funktioniert'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
