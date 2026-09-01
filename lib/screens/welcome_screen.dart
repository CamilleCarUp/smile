import 'package:flutter/material.dart';
import '../state/upload_controller.dart';
import '../widgets/smile_app_bar.dart';
import 'upload_screen.dart';
import 'cost_estimate_screen.dart';
import 'requests_list_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Willkommen', showLogout: true),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Willkommen bei Smile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text('Was möchtest du heute tun?',
                      style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Rechnung prüfen'),
                    onPressed: () {
                      uploadController.reset();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
                    },
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.checklist_rounded),
                    label: const Text('Meine Anfragen'),
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const RequestsListScreen())),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Kostenschätzung'),
                    onPressed: () => Navigator.push(
                        context, MaterialPageRoute(builder: (_) => const CostEstimateScreen())),
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
