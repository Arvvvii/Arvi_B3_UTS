import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:maauts003/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';
import 'package:maauts003/features/auth/domain/user_model.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';

class TicketListScreen extends ConsumerStatefulWidget {
  const TicketListScreen({super.key});

  @override
  ConsumerState<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends ConsumerState<TicketListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(ticketListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildStatusBadge(TicketStatus status) {
    Color color;
    String text;
    switch (status) {
      case TicketStatus.open:
        color = Colors.red;
        text = 'Open';
        break;
      case TicketStatus.inProgress:
        color = Colors.orange;
        text = 'In Progress';
        break;
      case TicketStatus.resolved:
        color = Colors.green;
        text = 'Resolved';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketListProvider);
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
            if (user?.role == UserRole.user)
              IconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: () => context.push('/tickets/create'),
              )
        ],
      ),
      body: ticketsState.when(
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('No tickets found.'));
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(ticketListProvider.notifier).loadInitial(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: tickets.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == tickets.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final ticket = tickets[index];
                return GestureDetector(
                  onTap: () => context.push('/tickets/${ticket.id}'),
                  child: GlassmorphismCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(ticket.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            _buildStatusBadge(ticket.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ticket.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(LucideIcons.calendar, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
