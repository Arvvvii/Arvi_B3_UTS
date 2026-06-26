import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arvi_b3_uts/features/dashboard/data/user_repository.dart';
import 'package:arvi_b3_uts/features/auth/domain/user_model.dart';

class TicketDetailScreen extends ConsumerWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.open:
        return Colors.blue;
    }
  }

  String _getShortId(String id) {
    if (id.length > 8) {
      return id.substring(0, 8).toUpperCase();
    }
    return id.toUpperCase();
  }

  Widget _buildAttachmentPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(LucideIcons.imageOff, size: 32, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'No attachment provided', 
            style: TextStyle(color: Colors.grey[500], fontSize: 13, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final user = ref.watch(authProvider).value;
    final isUser = user?.role.toString().split('.').last == 'user';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text('Ticket #${_getShortId(ticketId)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ticketAsync.when(
        data: (ticket) {
          if (ticket == null) return const Center(child: Text('Ticket not found', style: TextStyle(fontSize: 18)));

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.black26,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Title + Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ticket.title,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(ticket.status).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _getStatusColor(ticket.status).withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      ticket.status.name.toUpperCase(),
                                      style: TextStyle(
                                        color: _getStatusColor(ticket.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Subtitle
                              Row(
                                children: [
                                  const Icon(LucideIcons.user, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      ticket.createdBy,
                                      style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(LucideIcons.calendar, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('MMM dd, yyyy \u2022 HH:mm').format(ticket.createdAt),
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ],
                              ),
                              if (ticket.assignedTo != null && ticket.assignedTo!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.withOpacity(0.2)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.userCheck, size: 14, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          FutureBuilder<dynamic>(
                                            future: ticket.assignedTo!.contains('-') 
                                              ? Supabase.instance.client.from('profiles').select('full_name').eq('id', ticket.assignedTo!).single()
                                              : Future.value({'full_name': ticket.assignedTo}),
                                            builder: (context, snapshot) {
                                              final displayName = snapshot.hasData
                                                  ? snapshot.data['full_name']
                                                  : (snapshot.hasError ? 'Unknown User' : 'Fetching name...');
                                              return Text(
                                                'Assigned to: $displayName',
                                                style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 32),
                              // Description
                              Text(
                                'Description',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                ticket.description,
                                style: const TextStyle(fontSize: 15, height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              // Attachment
                              Text(
                                'Attachment',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 12),
                              if (ticket.attachedFilePath != null && ticket.attachedFilePath != 'EMPTY' && ticket.attachedFilePath!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    ticket.attachedFilePath!,
                                    width: double.infinity,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildAttachmentPlaceholder(),
                                  ),
                                )
                              else
                                _buildAttachmentPlaceholder(),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Tracking Status Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.activity, size: 20, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Tracking Status',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _ModernTimelineStepper(timelineEvents: ticket.timeline),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Buttons
              if (ticket.status == TicketStatus.resolved)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                  color: Colors.green.withOpacity(0.05),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.checkCircle2, color: Colors.green[600], size: 32),
                        const SizedBox(height: 8),
                        Text('This ticket has been resolved and is now closed.', 
                          style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Komentar bisa dipakai Siapapun (User & Helpdesk)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddCommentDialog(context, ref, ticket, user),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isUser ? Colors.blue : Colors.blueGrey,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(LucideIcons.messageSquarePlus),
                          label: const Text('Add Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      
                      // Fitur Admin/Helpdesk
                      if (!isUser) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _showUpdateStatusDialog(context, ref, ticket, user),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(LucideIcons.edit3),
                            label: const Text('Update Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (ticket.assignedTo == null || ticket.assignedTo!.isEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showAssignDialog(context, ref, ticket, user),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                side: const BorderSide(color: Colors.deepPurple, width: 2),
                                foregroundColor: Colors.deepPurple,
                              ),
                              icon: const Icon(LucideIcons.userPlus),
                              label: const Text('Assign Staff', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  // Hapus Fungsi State Wiping ref.invalidate(ticketListProvider);
  Future<void> _showUpdateStatusDialog(BuildContext context, WidgetRef ref, TicketModel ticket, dynamic user) async {
    final newStatus = await showDialog<TicketStatus>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TicketStatus.values.map((status) {
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              leading: Icon(
                status == TicketStatus.resolved ? LucideIcons.checkCircle :
                status == TicketStatus.inProgress ? LucideIcons.loader : LucideIcons.circle,
                color: _getStatusColor(status),
              ),
              title: Text(status.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(context, status),
            );
          }).toList(),
        ),
      ),
    );

    if (newStatus != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Updating status...')));
      try {
        await ref.read(ticketListProvider.notifier).updateTicketStatus(
          ticket.id, 
          newStatus, 
          user?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN'
        );
        ref.invalidate(ticketDetailProvider(ticketId));
        ref.invalidate(dashboardStatsProvider);
        // KUNCI: Kita mematikan invalidate(ticketListProvider) agar Timeline & Assigned Staff LOKAL tidak lenyap!
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status updated successfully!'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _showAddCommentDialog(BuildContext context, WidgetRef ref, TicketModel ticket, dynamic user) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(context: context, builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Comment', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
             hintText: 'Type your message...',
             border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            onPressed: () => context.pop(controller.text), 
            child: const Text('Send')
          ),
        ]
      );
    });

    if (comment != null && comment.isNotEmpty && context.mounted) {
      await ref.read(ticketListProvider.notifier).addComment(
          ticket.id, 
          comment, 
          user?.role.toString().split('.').last.toUpperCase() ?? 'USER'
      );
      // Refresh UI to show the new comment!
      ref.invalidate(ticketDetailProvider(ticketId));
    }
  }

  Future<void> _showAssignDialog(BuildContext context, WidgetRef ref, TicketModel ticket, dynamic user) async {
    // Show loading snackbar instead of blocking dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Memuat daftar staff...'), duration: Duration(milliseconds: 500)),
    );

    try {
      final staffList = await ref.read(userRepositoryProvider).getHelpdeskUsers();

      if (staffList.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada staff Helpdesk tersedia')));
        }
        return;
      }

      final selectedStaff = await showDialog<UserModel>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Assign Staff', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pilih staff helpdesk untuk menangani tiket ini:', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      final staff = staffList[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        leading: const Icon(LucideIcons.userCheck, color: Colors.deepPurple),
                        title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(staff.email, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        onTap: () => Navigator.pop(context, staff),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selectedStaff != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Menugaskan ke ${selectedStaff.name}...')));
        try {
          await ref.read(ticketListProvider.notifier).assignTicket(
            ticket.id, 
            selectedStaff.id, 
            selectedStaff.name,
            user?.role.toString().split('.').last.toUpperCase() ?? 'ADMIN'
          );
          ref.invalidate(ticketDetailProvider(ticketId));
          ref.invalidate(dashboardStatsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ticket assigned successfully!'), backgroundColor: Colors.green));
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to assign: $e'), backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat staff: $e')));
      }
    }
  }
}

class _ModernTimelineStepper extends StatelessWidget {
  final List<TicketTimeline> timelineEvents;

  const _ModernTimelineStepper({required this.timelineEvents});

  @override
  Widget build(BuildContext context) {
    if (timelineEvents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1), style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock3, size: 32, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No tracking activities yet.', 
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(timelineEvents.length, (index) {
        final event = timelineEvents[index];
        final isLast = index == timelineEvents.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline line and dot
              Column(
                children: [
                  Container(
                    width: 16, 
                    height: 16,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isLast ? Colors.blue : Colors.grey[400], 
                      shape: BoxShape.circle, 
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(color: (isLast ? Colors.blue : Colors.grey).withOpacity(0.3), blurRadius: 4)
                      ]
                    ),
                  ),
                  if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[300], margin: const EdgeInsets.symmetric(vertical: 4))),
                ],
              ),
              const SizedBox(width: 16),
              // Timeline Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isLast ? Colors.blue.withOpacity(0.05) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isLast ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.description, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            color: isLast 
                                ? (Theme.of(context).brightness == Brightness.dark ? Colors.blue[300] : Colors.blue[800]) 
                                : null,
                          )
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(LucideIcons.userCircle2, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              event.actorRole, 
                              style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                            const Spacer(),
                            Icon(LucideIcons.clock, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, HH:mm').format(event.timestamp), 
                              style: TextStyle(color: Colors.grey[500], fontSize: 12)
                            ),
                          ],
                        ),
                      ],
                    ),
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
