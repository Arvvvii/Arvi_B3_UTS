import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arvi_b3_uts/core/services/local_notification_service.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/notification/presentation/screens/notification_screen.dart';

/// Global Realtime Service yang selalu aktif selama app berjalan.
/// Tidak bergantung pada halaman Notification.
class RealtimeService {
  final Ref ref;
  RealtimeChannel? _channel;

  RealtimeService(this.ref);

  void start() {
    // Jangan subscribe ulang jika sudah aktif
    if (_channel != null) return;

    final supabase = Supabase.instance.client;
    debugPrint('🔔 [GLOBAL REALTIME] Starting global realtime listener...');

    _channel = supabase
        .channel('tickets-global')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'tickets',
          callback: (payload) {
            debugPrint('🔔 [GLOBAL REALTIME] Event received: ${payload.eventType}');
            debugPrint('🔔 [GLOBAL REALTIME] New record keys: ${payload.newRecord.keys}');

            final eventType = payload.eventType.name.toUpperCase();
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            // 1. Generate local notification
            _handleNotification(eventType, newRecord, oldRecord);

            // 2. Update ticket list state
            ref.read(ticketListProvider.notifier).handleRealtimeEvent(
              newRecord,
              oldRecord,
              eventType,
            );

            // 3. Refresh dashboard stats
            ref.invalidate(dashboardStatsProvider);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('🔔 [GLOBAL REALTIME] Channel status: $status, error: $error');
        });
  }

  void _handleNotification(
    String eventType,
    Map<String, dynamic> newRecord,
    Map<String, dynamic> oldRecord,
  ) {
    String title = '';
    String message = '';
    String ticketId = '';

    switch (eventType) {
      case 'INSERT':
        ticketId = newRecord['id'] ?? '';
        final ticketTitle = newRecord['title'] ?? 'Untitled';
        title = '🆕 Tiket Baru';
        message = 'Tiket "$ticketTitle" telah dibuat';
        break;

      case 'UPDATE':
        ticketId = newRecord['id'] ?? '';
        final ticketTitle = newRecord['title'] ?? 'Untitled';
        final newStatus = newRecord['status'] ?? '';
        final oldStatus = oldRecord['status'] ?? '';

        if (newStatus != oldStatus && oldStatus.isNotEmpty) {
          title = '🔄 Status Update';
          message = '"$ticketTitle" berubah dari $oldStatus → $newStatus';
        } else if (newRecord['assigned_to'] != oldRecord['assigned_to']) {
          title = '👤 Ticket Assigned';
          message = '"$ticketTitle" telah di-assign ke staff baru';
        } else {
          title = '📝 Ticket Updated';
          message = '"$ticketTitle" telah diperbarui';
        }
        break;

      case 'DELETE':
        ticketId = oldRecord['id'] ?? '';
        title = '🗑️ Tiket Dihapus';
        message = 'Sebuah tiket telah dihapus oleh admin';
        break;
    }

    if (title.isNotEmpty && message.isNotEmpty) {
      // Trigger system local notification
      LocalNotificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: message,
        payload: ticketId,
      );

      // Add to in-app notification list
      ref.read(realtimeNotificationProvider.notifier).addNotification(
        RealtimeNotification(
          id: '${ticketId}_${DateTime.now().millisecondsSinceEpoch}',
          ticketId: ticketId,
          title: title,
          message: message,
          time: DateTime.now(),
        ),
      );
    }
  }

  void stop() {
    _channel?.unsubscribe();
    _channel = null;
    debugPrint('🔔 [GLOBAL REALTIME] Stopped.');
  }
}

/// Provider global — akan hidup selama app berjalan
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService(ref);
  ref.onDispose(() => service.stop());
  return service;
});
