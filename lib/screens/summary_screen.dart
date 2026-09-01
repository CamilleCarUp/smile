import 'package:flutter/material.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'results_screen.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    return Scaffold(
      appBar: smileAppBar(context, 'Zusammenfassung', showHome: true),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.databox500, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zahnarztadresse:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  const SizedBox(height: 4),
                  Text(
                    [req.dentistName, req.dentistAddress, req.dentistEmail]
                        .where((e) => e != null && e.isNotEmpty)
                        .join('\n'),
                    style: const TextStyle(color: AppColors.slate800),
                  ),
                  const SizedBox(height: 16),
                  Text('Rechnung Nr. ${req.invoiceNumber}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  const SizedBox(height: 8),
                  for (final l in req.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(width: 48, child: Text(l.code, style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text(l.description, style: const TextStyle(fontSize: 12))),
                          if (l.quantity != null && l.quantity! > 1)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text('${l.quantity}×', style: const TextStyle(fontSize: 12)),
                            ),
                          Text('CHF ${l.amountChf.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  const Divider(color: Colors.black12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('CHF ${req.invoiceTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final f in req.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text('Anzeigen: ${f.name}'),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dokumentvorschau für "${f.name}" folgt in Phase 1.')),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultsScreen())),
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }
}
