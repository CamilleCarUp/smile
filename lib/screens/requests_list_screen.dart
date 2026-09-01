import 'package:flutter/material.dart';
import '../models/request.dart';
import '../state/requests_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/smile_app_bar.dart';
import 'summary_screen.dart';
import 'view_request_screen.dart';

class RequestsListScreen extends StatelessWidget {
  const RequestsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: smileAppBar(context, 'Meine Anfragen', showHome: true),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: requestsRepository,
          builder: (context, _) {
            final pending = requestsRepository.requests
                .where((r) => r.status == RequestStatus.captured || r.status == RequestStatus.sent)
                .toList();
            final completed = requestsRepository.requests.where((r) => r.status == RequestStatus.completed).toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Offen (erfasst & gesendet)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate500, fontSize: 13)),
                const SizedBox(height: 10),
                if (pending.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('Keine offenen Anfragen.', style: TextStyle(color: AppColors.slate400, fontStyle: FontStyle.italic)),
                  )
                else
                  for (final r in pending) _RequestCard(request: r),
                const SizedBox(height: 20),
                const Text('Abgeschlossen',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate500, fontSize: 13)),
                const SizedBox(height: 10),
                if (completed.isEmpty)
                  const Text('Keine abgeschlossenen Anfragen.', style: TextStyle(color: AppColors.slate400, fontStyle: FontStyle.italic))
                else
                  for (final r in completed) _RequestCard(request: r),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DentalRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    late final Widget action;

    switch (request.status) {
      case RequestStatus.captured:
        label = 'ERFASST';
        color = AppColors.slate500;
        action = IconButton(
          icon: const Icon(Icons.close_rounded),
          color: AppColors.slate400,
          onPressed: () => requestsRepository.cancelRequest(request.id),
        );
        break;
      case RequestStatus.sent:
        label = 'GESENDET';
        color = AppColors.databox500;
        action = IconButton(
          icon: const Icon(Icons.check_rounded),
          color: AppColors.slate400,
          onPressed: () => requestsRepository.markCompleted(request.id),
        );
        break;
      case RequestStatus.completed:
        label = 'ABGESCHLOSSEN';
        color = AppColors.good;
        action = const Icon(Icons.check_circle_rounded, color: AppColors.good);
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          requestsRepository.openRequest(request);
          if (request.status == RequestStatus.captured) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SummaryScreen()));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewRequestScreen()));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppColors.brand50, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.receipt_long_outlined, color: AppColors.brand500, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rechnung #${request.invoiceNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(request.dentistName, style: const TextStyle(fontSize: 12, color: AppColors.slate500)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ),
                  ],
                ),
              ),
              action,
            ],
          ),
        ),
      ),
    );
  }
}
