import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:maauts003/core/theme/glassmorphism.dart';
import 'package:maauts003/features/auth/presentation/providers/auth_provider.dart';
import 'package:maauts003/features/auth/domain/user_model.dart';
import 'package:maauts003/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final ticketState = ref.watch(ticketListProvider);

    int total = 0;
    int resolved = 0;
    int inProgress = 0;
    int open = 0;
    List<TicketModel> filteredTickets = [];

    if (ticketState.value != null && authState.value != null) {
      final role = authState.value!.role;
      final userId = authState.value!.id;
      final userEmail = authState.value!.email;

      filteredTickets = ticketState.value!.where((t) {
        if (role == UserRole.admin || role == UserRole.helpdesk) return true;
        // Asumsi backend menyimpan UUID user di created_by
        return t.createdBy == userId || t.createdBy == userEmail; 
      }).toList();

      total = filteredTickets.length;
      resolved = filteredTickets.where((t) => t.status == TicketStatus.resolved).length;
      inProgress = filteredTickets.where((t) => t.status == TicketStatus.inProgress).length;
      open = filteredTickets.where((t) => t.status == TicketStatus.open).length;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(ticketListProvider.notifier).loadInitial();
          },
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      Text(
                        authState.value?.name ?? 'User',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    radius: 24,
                    child: Icon(LucideIcons.user, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (ticketState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (ticketState.hasError)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text('Failed to load tickets API. Start Golang Server at http://10.0.2.2:8080.', style: TextStyle(color: Colors.red)),
                )
              else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _BentoCard(
                              title: 'Total Tickets',
                              value: '$total',
                              icon: LucideIcons.layers,
                              color: Colors.blue,
                              onTap: () {
                                ref.read(ticketFilterProvider.notifier).state = 'All';
                                context.go('/tickets');
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _BentoCard(
                              title: 'Resolved',
                              value: '$resolved',
                              icon: LucideIcons.checkCircle,
                              color: Colors.green,
                              onTap: () {
                                ref.read(ticketFilterProvider.notifier).state = 'Resolved';
                                context.go('/tickets');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BentoCard(
                              title: 'In Progress',
                              value: '$inProgress',
                              icon: LucideIcons.loader,
                              color: Colors.orange,
                              onTap: () {
                                ref.read(ticketFilterProvider.notifier).state = 'In Progress';
                                context.go('/tickets');
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _BentoCard(
                              title: 'Open',
                              value: '$open',
                              icon: LucideIcons.alertCircle,
                              color: Colors.red,
                              onTap: () {
                                ref.read(ticketFilterProvider.notifier).state = 'Open';
                                context.go('/tickets');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              const SizedBox(height: 32),
              
              ElevatedButton.icon(
                onPressed: () => context.push('/tickets/create'),
                icon: const Icon(LucideIcons.plus),
                label: const Text('Create New Ticket'),
              ),
              const SizedBox(height: 32),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (!ticketState.isLoading && ticketState.value != null)
              GlassmorphismCard(
                padding: const EdgeInsets.all(0),
                child: filteredTickets.isEmpty 
                  ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No recent activity', style: TextStyle(color: Colors.grey))))
                  : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTickets.take(3).length, // Use filtered list
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ticket = filteredTickets[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/tickets/${ticket.id}'),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.fileText, color: Theme.of(context).primaryColor, size: 20),
                          ),
                          title: Text(ticket.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1),
                          subtitle: Text('Status: ${ticket.status.name}'),
                          trailing: const Text('View', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BentoCard({required this.title, required this.value, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: GlassmorphismCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
