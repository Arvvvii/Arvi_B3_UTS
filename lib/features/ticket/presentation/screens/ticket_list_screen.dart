import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';

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

  // =========================================================================
  // FILTER BOTTOM SHEET
  // =========================================================================

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketListProvider);
    final filter = ref.watch(ticketFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tickets'),
        actions: [
          // Filter Button with active indicator
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.sliders),
                tooltip: 'Filter',
                onPressed: _showFilterBottomSheet,
              ),
              if (filter.isActive)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tickets/create'),
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(LucideIcons.plus, color: colorScheme.onPrimary),
      ),
      body: ticketsState.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (tickets) {
          // Apply multi-criteria filter
          final filteredTickets = filter.apply(tickets);

          if (filteredTickets.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.inbox, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    filter.isActive ? 'No tickets match your filter.' : 'No tickets found.',
                    style: TextStyle(color: colorScheme.outline, fontSize: 15),
                  ),
                  if (filter.isActive) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ref.read(ticketFilterProvider.notifier).state = const TicketFilter(),
                      icon: const Icon(LucideIcons.x, size: 16),
                      label: const Text('Clear filters'),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(ticketListProvider.notifier).loadInitial(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: filteredTickets.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == filteredTickets.length) {
                  final notifier = ref.read(ticketListProvider.notifier);
                  if (notifier.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }

                final ticket = filteredTickets[index];
                return _TicketCard(ticket: ticket);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, trace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.alertTriangle, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text('Error: $e', style: TextStyle(color: colorScheme.error)),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => ref.read(ticketListProvider.notifier).loadInitial(),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MODERN TICKET CARD (Clean & Flat style)
// =============================================================================

class _TicketCard extends StatelessWidget {
  final TicketModel ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayId = ticket.id.length > 8 ? '#${ticket.id.substring(0, 8).toUpperCase()}' : '#${ticket.id.toUpperCase()}';

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/tickets/${ticket.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: ID + Badges
              Row(
                children: [
                  Text(
                    displayId,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.outline,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  _PriorityBadge(priority: ticket.priority),
                  const SizedBox(width: 6),
                  _StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                ticket.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Bottom Row: Date + Assigned indicator
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 14, color: colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(ticket.createdAt.toLocal()),
                    style: TextStyle(color: colorScheme.outline, fontSize: 12),
                  ),
                  if (ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty) ...[
                    const Spacer(),
                    Icon(LucideIcons.userCheck, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// STATUS BADGE — Theme-aware
// =============================================================================

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String text) = switch (status) {
      TicketStatus.open => (
        const Color(0xFFFFF3E0),
        const Color(0xFFE65100),
        'Open',
      ),
      TicketStatus.inProgress => (
        const Color(0xFFE3F2FD),
        const Color(0xFF1565C0),
        'In Progress',
      ),
      TicketStatus.resolved => (
        const Color(0xFFE8F5E9),
        const Color(0xFF2E7D32),
        'Resolved',
      ),
    };

    // In dark mode, invert the approach: dark bg, lighter fg
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? fg.withOpacity(0.15) : bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withOpacity(isDark ? 0.3 : 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? fg.withOpacity(0.9) : fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================================
// PRIORITY BADGE — High=Merah, Medium=Jingga, Low=Biru
// =============================================================================

class _PriorityBadge extends StatelessWidget {
  final String priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (Color color, String label, IconData icon) = switch (priority) {
      'high' => (const Color(0xFFD32F2F), 'High', LucideIcons.chevronsUp),
      'medium' => (const Color(0xFFF57C00), 'Medium', LucideIcons.minus),
      'low' => (const Color(0xFF1976D2), 'Low', LucideIcons.chevronsDown),
      _ => (const Color(0xFFF57C00), 'Medium', LucideIcons.minus),
    };

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// FILTER BOTTOM SHEET — ModalBottomSheet with ChoiceChips
// =============================================================================

class _FilterBottomSheet extends ConsumerWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(ticketFilterProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Icon(LucideIcons.sliders, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Filter Tickets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (filter.isActive)
                    TextButton(
                      onPressed: () {
                        ref.read(ticketFilterProvider.notifier).state = const TicketFilter();
                      },
                      child: Text('Reset', style: TextStyle(color: colorScheme.error)),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // STATUS section
              Text(
                'Status',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(context, ref, TicketStatus.open, 'Open', filter),
                  _buildStatusChip(context, ref, TicketStatus.inProgress, 'In Progress', filter),
                  _buildStatusChip(context, ref, TicketStatus.resolved, 'Resolved', filter),
                ],
              ),
              const SizedBox(height: 24),

              // PRIORITY section
              Text(
                'Priority',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPriorityChip(context, ref, 'high', 'High', filter),
                  _buildPriorityChip(context, ref, 'medium', 'Medium', filter),
                  _buildPriorityChip(context, ref, 'low', 'Low', filter),
                ],
              ),
              const SizedBox(height: 28),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, WidgetRef ref, TicketStatus status, String label, TicketFilter filter) {
    final isSelected = filter.statuses.contains(status);
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final current = Set<TicketStatus>.from(filter.statuses);
        if (selected) {
          current.add(status);
        } else {
          current.remove(status);
        }
        ref.read(ticketFilterProvider.notifier).state = filter.copyWith(statuses: current);
      },
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: isSelected ? colorScheme.primary.withOpacity(0.3) : colorScheme.outlineVariant,
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context, WidgetRef ref, String priority, String label, TicketFilter filter) {
    final isSelected = filter.priorities.contains(priority);
    final colorScheme = Theme.of(context).colorScheme;
    final Color chipColor = switch (priority) {
      'high' => const Color(0xFFD32F2F),
      'medium' => const Color(0xFFF57C00),
      'low' => const Color(0xFF1976D2),
      _ => colorScheme.primary,
    };

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        final current = Set<String>.from(filter.priorities);
        if (selected) {
          current.add(priority);
        } else {
          current.remove(priority);
        }
        ref.read(ticketFilterProvider.notifier).state = filter.copyWith(priorities: current);
      },
      selectedColor: chipColor.withOpacity(0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: isSelected ? chipColor.withOpacity(0.4) : colorScheme.outlineVariant,
      ),
    );
  }
}
