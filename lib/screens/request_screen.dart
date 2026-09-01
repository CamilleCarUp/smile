import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'ombudsman_screen.dart';
import 'success_screen.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});


  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    final flagged = req.flaggedLines;
    final reason = flagged.isEmpty
        ? 'Es wurden keine Abweichungen zum typischen Behandlungsmuster gefunden.'
        : 'Die Tarifposition ${flagged.first.code} "${flagged.first.description}" wurde mehrfach verrechnet, '
            'während das Referenzmuster diese Leistung nur einmal vorsieht. Könnten Sie kurz erklären, weshalb? '
            'Bitte passen Sie die Rechnung entsprechend an.';
    final bodyText = 'Sehr geehrter Herr Dr. ${req.dentistName.split(' ').last},\n\n'
        'Ich bitte um Prüfung folgender Position(en) auf meiner Rechnung Nr. ${req.invoiceNumber}:\n'
        '${flagged.map((l) => '- ${l.code} ${l.description}').join('\n')}\n\n'
        'Grund:\n$reason\n\n'
        'Freundliche Grüsse';

    return Scaffold(
      appBar: smileAppBar(context, 'Anfrage', showHome: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.databox500, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entwurf', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                        const SizedBox(height: 12),
                        Text('Sehr geehrter Herr Dr. ${req.dentistName.split(' ').last},',
                            style: const TextStyle(color: AppColors.slate800)),
                        const SizedBox(height: 12),
                        const Text('Bitte um Prüfung von:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                        const SizedBox(height: 6),
                        for (final l in flagged)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 4),
                            child: Text('•  ${l.code} ${l.description}',
                                style: const TextStyle(color: AppColors.slate800)),
                          ),
                        const SizedBox(height: 12),
                        const Text('Grund:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                        const SizedBox(height: 4),
                        Text(reason, style: const TextStyle(color: AppColors.slate800, height: 1.4)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Anfrage senden'),
                onPressed: () async {
                  final uri = Uri(
                    scheme: 'mailto',
                    query: 'subject=${Uri.encodeComponent('Rückfrage zu Rechnung Nr. ${req.invoiceNumber}')}'
                        '&body=${Uri.encodeComponent(bodyText)}',
                  );
                  final opened = await launchUrl(uri);
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
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OmbudsmanScreen())),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
