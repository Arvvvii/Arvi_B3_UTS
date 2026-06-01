import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:arvi_b3_uts/core/theme/glassmorphism.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:intl/intl.dart';

class NotificationItem {
  final String ticketId;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;

  NotificationItem({required this.ticketId, required this.title, required this.message, required this.time, this.isRead = false});
}

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsState = ref.watch(ticketListProvider);

    List<NotificationItem> notifications = [];

    if (ticketsState.value != null) {
      for (final ticket in ticketsState.value!) {
        for (final event in ticket.timeline) {
          notifications.add(
            NotificationItem(
              ticketId: ticket.id,
              title: 'Ticket Update: ${ticket.id.length > 8 ? '${ticket.id.substring(0, 8)}...' : ticket.id}',
              message: event.description,
              time: event.timestamp,
              isRead: false,
            ),
          );
        }
      }
    }

    notifications.sort((a, b) => b.time.compareTo(a.time));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All marked as read')));
            },
          ),
        ],
      ),
      body: notifications.isEmpty 
        ? const Center(child: Text('No new notifications'))
        : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          final isRead = notif.isRead;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                context.push('/tickets/${notif.ticketId}');
              },
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isRead ? Colors.grey.withOpacity(0.1) : Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.bellRing,
                      color: isRead ? Colors.grey : Theme.of(context).primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('hh:mm a').format(notif.time),
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      ),
    );
  }
}
