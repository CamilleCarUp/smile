import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/ombudsman_data.dart';
import '../theme/app_theme.dart';

class OmbudsmanScreen extends StatelessWidget {
  const OmbudsmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ombudsstelle')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Falls keine Einigung erzielt wird, vermitteln die offiziellen SSO-Ombudsstellen '
                'kostenlos zwischen dir und deinem Zahnarzt.',
                style: TextStyle(color: AppColors.slate600, height: 1.4),
              ),
            ),
            for (final c in ombudsmanContacts)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.region, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand600, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(c.location, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.call_outlined, size: 16),
                              label: const Text('Anrufen', style: TextStyle(fontSize: 12)),
                              onPressed: () => launchUrl(Uri(scheme: 'tel', path: c.phone.replaceAll(' ', ''))),
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
              ),
          ],
        ),
      ),
    );
  }
}
