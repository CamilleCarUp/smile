import 'package:flutter/material.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'request_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    return Scaffold(
      appBar: smileAppBar(context, 'Ergebnis', showHome: true),
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
                  const Text('Einflächige Kompositfüllung',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rechnungsbetrag', style: TextStyle(color: AppColors.slate800)),
                      Text('CHF ${req.invoiceTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.slate800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Referenzbetrag', style: TextStyle(color: AppColors.slate800)),
                      Text('CHF ${req.referenceTotal.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.slate800)),
                    ],
                  ),
                  const Divider(color: Colors.black12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Differenz', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                      Text('CHF ${req.difference.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.databoxBg,
                border: Border.all(color: AppColors.databoxBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (final l in req.lines)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(l.code,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: l.flagged ? FontWeight.bold : FontWeight.normal,
                                  color: l.flagged ? AppColors.danger : AppColors.slate500,
                                )),
                          ),
                          Expanded(
                            child: Text(l.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: l.flagged ? FontWeight.bold : FontWeight.normal,
                                  color: l.flagged ? AppColors.slate800 : AppColors.slate700,
                                )),
                          ),
                          Icon(
                            l.flagged ? Icons.close_rounded : Icons.check_rounded,
                            color: l.flagged ? AppColors.danger : AppColors.good,
                            size: l.flagged ? 22 : 18,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RequestScreen())),
              child: const Text('Weiter'),
            ),
          ],
        ),
      ),
    );
  }
}
