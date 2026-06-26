import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:arvi_b3_uts/core/theme/glassmorphism.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:intl/intl.dart';
import 'package:arvi_b3_uts/core/services/local_notification_service.dart';

// =============================================================================
// REALTIME NOTIFICATION PROVIDER (BR-003)
// =============================================================================
// Provider ini mengelola notifikasi yang datang dari Supabase Realtime.
// Setiap kali ada INSERT/UPDATE pada tabel tickets, notifikasi baru ditambahkan.

class RealtimeNotification {
  final String id;
  final String ticketId;
  final String title;
  final String message;
  final DateTime time;
  bool isRead;

  RealtimeNotification({
    required this.id,
    required this.ticketId,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
  });
}

class RealtimeNotificationNotifier extends StateNotifier<List<RealtimeNotification>> {
  RealtimeNotificationNotifier() : super([]);

  void addNotification(RealtimeNotification notif) {
    // Cegah duplikasi berdasarkan ID
    if (!state.any((n) => n.id == notif.id)) {
      state = [notif, ...state];
    }
  }

  void markAllAsRead() {
    state = state.map((n) => n..isRead = true).toList();
  }

  void markAsRead(String id) {
    state = state.map((n) {
      if (n.id == id) n.isRead = true;
      return n;
    }).toList();
  }

  void clearAll() {
    state = [];
  }
}

final realtimeNotificationProvider =
    StateNotifierProvider<RealtimeNotificationNotifier, List<RealtimeNotification>>((ref) {
  return RealtimeNotificationNotifier();
});

/// Provider untuk badge count (jumlah notifikasi belum dibaca)
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(realtimeNotificationProvider);
  return notifications.where((n) => !n.isRead).length;
});

// =============================================================================
// NOTIFICATION SCREEN
// =============================================================================

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  // Realtime listener sudah dipindahkan ke RealtimeService (global)
  // Tidak perlu setup/dispose channel di sini lagi

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(realtimeNotificationProvider);

    // Fallback: jika belum ada notif realtime, tampilkan dari timeline lokal
    List<RealtimeNotification> displayList = notifications;
    if (displayList.isEmpty) {
      final ticketsState = ref.watch(ticketListProvider);
      if (ticketsState.value != null) {
        for (final ticket in ticketsState.value!) {
          for (final event in ticket.timeline) {
            displayList.add(RealtimeNotification(
              id: event.id,
              ticketId: ticket.id,
              title: 'Ticket Update: ${ticket.id.length > 8 ? '${ticket.id.substring(0, 8)}...' : ticket.id}',
              message: event.description,
              time: event.timestamp,
              isRead: true,
            ));
          }
        }
        displayList.sort((a, b) => b.time.compareTo(a.time));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Tombol tes notifikasi
          IconButton(
            icon: const Icon(LucideIcons.bellRing),
            tooltip: 'Test Notification',
            onPressed: () {
              debugPrint('🔔 [TEST] Triggering test notification...');
              LocalNotificationService.showNotification(
                id: 999,
                title: '🧪 Test Notifikasi',
                body: 'Jika kamu melihat ini, local notification BERHASIL!',
                payload: 'test',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Test notification dikirim! Cek notification bar.')),
              );
            },
          ),
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.checkCheck),
              tooltip: 'Mark all as read',
              onPressed: () {
                ref.read(realtimeNotificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca')),
                );
              },
            ),
        ],
      ),
      body: displayList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.bellOff, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Notifikasi realtime akan muncul di sini',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notif = displayList[index];
                final isRead = notif.isRead;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      // Tandai sudah dibaca
                      ref.read(realtimeNotificationProvider.notifier).markAsRead(notif.id);
                      // Navigasi ke detail tiket (jika tiket masih ada)
                      if (notif.ticketId.isNotEmpty) {
                        context.push('/tickets/${notif.ticketId}');
                      }
                    },
                    child: GlassmorphismCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isRead
                                  ? Colors.grey.withOpacity(0.1)
                                  : Theme.of(context).primaryColor.withOpacity(0.1),
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
                                  DateFormat('dd MMM yyyy • HH:mm').format(notif.time),
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
