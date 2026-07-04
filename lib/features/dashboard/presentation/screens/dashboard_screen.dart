import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final ticketState = ref.watch(ticketListProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    
    final user = authState.value;
    final role = user?.role.toString().split('.').last.toLowerCase() ?? 'user';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(ticketListProvider.notifier).loadInitial();
            ref.invalidate(dashboardStatsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // HEADER
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverToBoxAdapter(
                  child: _buildHeader(context, user, role),
                ),
              ),
              
              // MAIN CONTENT BASED ON ROLE
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverToBoxAdapter(
                  child: _buildRoleContent(context, ref, role, statsAsync, ticketState),
                ),
              ),

              // RECENT ACTIVITY (For all roles, but adapted)
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role == 'admin' ? 'System Activity' : 'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (!ticketState.isLoading && ticketState.value != null)
                        Builder(
                          builder: (context) {
                            final allTickets = ticketState.value!;
                            // [BUG 1 FIX] Filter specifically for Helpdesk
                            final displayTickets = role == 'helpdesk'
                                ? allTickets.where((t) => t.assignedTo == user?.id).toList()
                                : allTickets;
                            return _buildRecentActivity(context, ref, displayTickets, role);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel? user, String role) {
    final colorScheme = Theme.of(context).colorScheme;
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) greeting = 'Good Morning';
    else if (hour < 17) greeting = 'Good Afternoon';
    else greeting = 'Good Evening';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user?.name ?? 'User',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            radius: 24,
            child: Icon(LucideIcons.user, color: colorScheme.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleContent(
    BuildContext context, 
    WidgetRef ref, 
    String role, 
    AsyncValue<dynamic> statsAsync, 
    AsyncValue<List<TicketModel>> ticketState
  ) {
    if (role == 'user') return _buildUserDashboard(context, ref, ticketState);
    if (role == 'helpdesk') return _buildHelpdeskDashboard(context, ref, statsAsync);
    return _buildAdminDashboard(context, ref, statsAsync);
  }

  // =========================================================================
  // USER DASHBOARD
  // =========================================================================
  Widget _buildUserDashboard(BuildContext context, WidgetRef ref, AsyncValue<List<TicketModel>> ticketState) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Hitung tiket aktif milik user
    final activeTickets = ticketState.value?.where((t) => t.status != TicketStatus.resolved).length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BIG HERO BUTTON FOR CREATE TICKET
        Material(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => context.push('/tickets/create'),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Helpdesk?',
                          style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a New Ticket',
                          style: TextStyle(color: colorScheme.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: colorScheme.onPrimary.withOpacity(0.2), shape: BoxShape.circle),
                    child: Icon(LucideIcons.plus, color: colorScheme.onPrimary, size: 28),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // QUICK STATS
        Row(
          children: [
            Expanded(
              child: _buildMiniStatCard(
                context, 
                title: 'Active Tickets', 
                value: activeTickets.toString(), 
                icon: LucideIcons.activity, 
                color: colorScheme.primary,
                onTap: () {
                  ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.open, TicketStatus.inProgress});
                  context.go('/tickets');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMiniStatCard(
                context, 
                title: 'History', 
                value: 'View All', 
                icon: LucideIcons.history, 
                color: colorScheme.tertiary,
                onTap: () {
                  ref.read(ticketFilterProvider.notifier).state = const TicketFilter();
                  context.go('/tickets');
                },
              ),
            ),
          ],
        )
      ],
    );
  }

  // =========================================================================
  // HELPDESK DASHBOARD
  // =========================================================================
  Widget _buildHelpdeskDashboard(BuildContext context, WidgetRef ref, AsyncValue<dynamic> statsAsync) {
    final colorScheme = Theme.of(context).colorScheme;

    return statsAsync.when(
      data: (stats) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Workspace',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // BENTO GRID FOR HELPDESK
          Row(
            children: [
              Expanded(
                child: _buildBentoCard(
                  context,
                  title: 'My Tasks',
                  value: '${stats.inProgress}',
                  subtitle: 'In Progress',
                  icon: LucideIcons.briefcase,
                  color: colorScheme.primary,
                  onTap: () {
                    ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.inProgress});
                    context.go('/tickets');
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildMiniStatCard(
                      context,
                      title: 'Needs Action',
                      value: '${stats.open}',
                      icon: LucideIcons.alertCircle,
                      color: colorScheme.error,
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.open});
                        context.go('/tickets');
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMiniStatCard(
                      context,
                      title: 'Resolved',
                      value: '${stats.resolved}',
                      icon: LucideIcons.checkCircle2,
                      color: const Color(0xFF2E7D32),
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.resolved});
                        context.go('/tickets');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading stats: $e', style: TextStyle(color: colorScheme.error))),
    );
  }

  // =========================================================================
  // ADMIN DASHBOARD
  // =========================================================================
  Widget _buildAdminDashboard(BuildContext context, WidgetRef ref, AsyncValue<dynamic> statsAsync) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            OutlinedButton.icon(
              onPressed: () => context.push('/user-management'),
              icon: const Icon(LucideIcons.users, size: 16),
              label: const Text('Manage Users'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        statsAsync.when(
          data: (stats) => Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildBentoCard(
                      context,
                      title: 'Total Tickets',
                      value: '${stats.total}',
                      subtitle: 'All time',
                      icon: LucideIcons.layers,
                      color: colorScheme.primary,
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter();
                        context.go('/tickets');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoCard(
                      context,
                      title: 'Resolved',
                      value: '${stats.resolved}',
                      subtitle: 'Completed',
                      icon: LucideIcons.checkCircle,
                      color: const Color(0xFF2E7D32), // Green
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.resolved});
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
                    child: _buildBentoCard(
                      context,
                      title: 'In Progress',
                      value: '${stats.inProgress}',
                      subtitle: 'Being handled',
                      icon: LucideIcons.loader,
                      color: const Color(0xFFF57C00), // Orange
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.inProgress});
                        context.go('/tickets');
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBentoCard(
                      context,
                      title: 'Open',
                      value: '${stats.open}',
                      subtitle: 'Needs assignment',
                      icon: LucideIcons.alertCircle,
                      color: colorScheme.error,
                      onTap: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter(statuses: {TicketStatus.open});
                        context.go('/tickets');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error loading stats: $e', style: TextStyle(color: colorScheme.error))),
        ),
      ],
    );
  }

  // =========================================================================
  // REUSABLE WIDGETS
  // =========================================================================

  Widget _buildBentoCard(BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
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
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: colorScheme.outline, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5), width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
                    ),
                    Text(
                      title,
                      style: TextStyle(color: colorScheme.outline, fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, WidgetRef ref, List<TicketModel> tickets, String role) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Sort logic for helpdesk: if priority is high, bring to top (optional UX boost).
    // Here we just take the first 5 recent tickets.
    final recentTickets = tickets.take(5).toList();

    if (recentTickets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(LucideIcons.inbox, size: 40, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text('No recent activity', style: TextStyle(color: colorScheme.outline, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentTickets.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 20, endIndent: 20, color: colorScheme.outlineVariant.withOpacity(0.5)),
        itemBuilder: (context, index) {
          final ticket = recentTickets[index];
          
          final (Color statusColor, IconData statusIcon) = switch (ticket.status) {
            TicketStatus.open => (colorScheme.error, LucideIcons.alertCircle),
            TicketStatus.inProgress => (const Color(0xFFF57C00), LucideIcons.loader),
            TicketStatus.resolved => (const Color(0xFF2E7D32), LucideIcons.checkCircle2),
          };

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/tickets/${ticket.id}'),
              borderRadius: BorderRadius.circular(index == 0 ? 20 : (index == recentTickets.length - 1 ? 20 : 0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(statusIcon, color: statusColor, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (ticket.priority == 'high') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('HIGH', style: TextStyle(color: colorScheme.error, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, HH:mm').format(ticket.createdAt.toLocal()),
                            style: TextStyle(color: colorScheme.outline, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight, size: 16, color: colorScheme.outline),
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
