import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:arvi_b3_uts/core/theme/glassmorphism.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final ticketState = ref.watch(ticketListProvider);
    // [v2.0.0] Stats dari backend (RBAC filtered)
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(ticketListProvider.notifier).loadInitial();
            ref.invalidate(dashboardStatsProvider);
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

              // ============================================================
              // [v2.0.0] BENTO GRID STATS — Sekarang menggunakan data dari
              // backend (GET /dashboard/stats) yang sudah RBAC filtered.
              // Visible untuk SEMUA role (user, helpdesk, admin).
              // ============================================================
              statsAsync.when(
                data: (stats) => Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _BentoCard(
                            title: 'Total Tickets',
                            value: '${stats.total}',
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
                            value: '${stats.resolved}',
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
                            value: '${stats.inProgress}',
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
                            value: '${stats.open}',
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Failed to load stats. Start Golang Server at http://10.0.2.2:8080.\nError: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              
              // ============================================================
              // [v2.0.0] CREATE TICKET BUTTON
              // Sekarang visible untuk SEMUA role (user, helpdesk, admin),
              // bukan hanya user saja.
              // ============================================================
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
              _buildRecentActivity(context, ref, ticketState, authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TicketModel>> ticketState,
    AsyncValue<UserModel?> authState,
  ) {
    // Tampilkan 3 tiket terbaru (backend sudah RBAC filtered)
    final recentTickets = ticketState.value!.take(3).toList();

    return GlassmorphismCard(
      padding: const EdgeInsets.all(0),
      child: recentTickets.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No recent activity',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTickets.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final ticket = recentTickets[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/tickets/${ticket.id}'),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .primaryColor
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(LucideIcons.fileText,
                            color: Theme.of(context).primaryColor,
                            size: 20),
                      ),
                      title: Text(ticket.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1),
                      subtitle: Text('Status: ${ticket.status.name}'),
                      trailing: const Text('View',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                  ),
                );
              },
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
