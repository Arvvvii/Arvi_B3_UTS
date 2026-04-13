import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:maauts003/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('Ticket $ticketId'),
      ),
      body: ticketAsync.when(
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassmorphismCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ticket.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('By: ${ticket.createdBy} \u2022 ${DateFormat('MMM dd, yyyy HH:mm').format(ticket.createdAt)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      Text(ticket.description),
                      const SizedBox(height: 16),
                      if (ticket.attachedFilePath != null) ...[
                        Row(
                          children: [
                            const Icon(LucideIcons.paperclip, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(ticket.attachedFilePath!.split('/').last, style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('Tracking Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                import_timeline_stepper(ticket),
                
                if (user?.role.toString().split('.').last != 'user') ...[
                  const SizedBox(height: 32),
                  Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                     onPressed: () {
                         // Action to assign / change status
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action simulated')));
                     },
                     icon: const Icon(LucideIcons.edit),
                     label: const Text('Update Status'),
                  )
                ]
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget import_timeline_stepper(TicketModel ticket) {
     // dynamic import inside the same package
     return _LocalTimelineStepper(timelineEvents: ticket.timeline);
  }
}

class _LocalTimelineStepper extends StatelessWidget {
  final List<TicketTimeline> timelineEvents;

  const _LocalTimelineStepper({required this.timelineEvents});

  @override
  Widget build(BuildContext context) {
    if (timelineEvents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(timelineEvents.length, (index) {
        final event = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).cardColor, width: 3)),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: Theme.of(context).primaryColor.withOpacity(0.3))),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('By: ${event.actorRole} \u2022 ${DateFormat('MMM dd, yyyy HH:mm').format(event.timestamp)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
