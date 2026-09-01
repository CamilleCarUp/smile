import 'package:flutter/material.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';

class ViewRequestScreen extends StatelessWidget {
  const ViewRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final req = requestsRepository.currentRequest!;
    final flagged = req.flaggedLines;

    return Scaffold(
      appBar: AppBar(title: const Text('Gesendete Anfrage')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.databox500.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_outline, size: 16, color: AppColors.slate800),
                      SizedBox(width: 6),
                      Text('SCHREIBGESCHÜTZTE ANSICHT',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.slate800)),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.black12, height: 1)),
                  Text('Sehr geehrter Herr Dr. ${req.dentistName.split(' ').last},',
                      style: const TextStyle(color: AppColors.slate800)),
                  const SizedBox(height: 12),
                  const Text('Angefragte Prüfung von:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate800)),
                  for (final l in flagged)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 4),
                      child: Text('•  ${l.code} ${l.description}', style: const TextStyle(color: AppColors.slate800)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Angehängte Dokumente:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            for (final f in req.files)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(f.name),
                  onPressed: () {},
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zurück zur Liste'),
            ),
          ],
        ),
      ),
    );
  }
}
