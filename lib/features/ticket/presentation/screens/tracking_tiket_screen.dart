import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/providers/ticket_provider.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:arvi_b3_uts/core/theme/glassmorphism.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// TrackingTiketScreen menampilkan timeline lengkap riwayat tiket
/// dengan menggabungkan data dari ticket_histories dan comments (BR-005).
class TrackingTiketScreen extends ConsumerWidget {
  final String ticketId;

  const TrackingTiketScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historiesAsync = ref.watch(ticketHistoriesProvider(ticketId));
    final commentsAsync = ref.watch(ticketCommentsProvider(ticketId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tracking #${ticketId.length > 8 ? ticketId.substring(0, 8).toUpperCase() : ticketId.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          // Tombol refresh
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(ticketHistoriesProvider(ticketId));
              ref.invalidate(ticketCommentsProvider(ticketId));
            },
          ),
        ],
      ),
      body: _buildBody(context, historiesAsync, commentsAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<TicketHistoryModel>> historiesAsync,
    AsyncValue<List<CommentModel>> commentsAsync,
  ) {
    // Tunggu kedua data selesai dimuat
    if (historiesAsync.isLoading || commentsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historiesAsync.hasError) {
      return Center(child: Text('Error: ${historiesAsync.error}'));
    }

    final histories = historiesAsync.value ?? [];
    final comments = commentsAsync.value ?? [];

    // Gabungkan histories dan comments menjadi satu timeline terpadu
    final List<_TimelineEntry> timeline = [];

    // Tambahkan histories
    for (final h in histories) {
      timeline.add(_TimelineEntry(
        id: h.id,
        description: h.action,
        actorId: h.actorId,
        timestamp: h.createdAt,
        type: _TimelineType.history,
      ));
    }

    // Tambahkan comments
    for (final c in comments) {
      timeline.add(_TimelineEntry(
        id: c.id,
        description: c.content,
        actorId: c.authorId,
        timestamp: c.createdAt,
        type: _TimelineType.comment,
      ));
    }

    // Sort berdasarkan waktu (kronologis)
    timeline.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (timeline.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clock3, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Riwayat perubahan tiket akan muncul di sini',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final entry = timeline[index];
        final isLast = index == timeline.length - 1;
        final isFirst = index == 0;

        return _TimelineTile(
          entry: entry,
          isFirst: isFirst,
          isLast: isLast,
        );
      },
    );
  }
}

// =============================================================================
// INTERNAL MODELS & WIDGETS
// =============================================================================

enum _TimelineType { history, comment }

class _TimelineEntry {
  final String id;
  final String description;
  final String actorId;
  final DateTime timestamp;
  final _TimelineType type;

  _TimelineEntry({
    required this.id,
    required this.description,
    required this.actorId,
    required this.timestamp,
    required this.type,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineEntry entry;
  final bool isFirst;
  final bool isLast;

  const _TimelineTile({
    required this.entry,
    required this.isFirst,
    required this.isLast,
  });

  Color _getDotColor() {
    if (isLast) return Colors.blue;
    switch (entry.type) {
      case _TimelineType.history:
        if (entry.description.toLowerCase().contains('resolved')) {
          return Colors.green;
        }
        if (entry.description.toLowerCase().contains('in_progress') ||
            entry.description.toLowerCase().contains('in progress')) {
          return Colors.orange;
        }
        if (entry.description.toLowerCase().contains('created')) {
          return Colors.purple;
        }
        return Colors.blueGrey;
      case _TimelineType.comment:
        return Colors.teal;
    }
  }

  IconData _getIcon() {
    switch (entry.type) {
      case _TimelineType.history:
        if (entry.description.toLowerCase().contains('created')) {
          return LucideIcons.plus;
        }
        if (entry.description.toLowerCase().contains('status')) {
          return LucideIcons.refreshCw;
        }
        if (entry.description.toLowerCase().contains('assigned')) {
          return LucideIcons.userCheck;
        }
        return LucideIcons.activity;
      case _TimelineType.comment:
        return LucideIcons.messageCircle;
    }
  }

  String _getTypeLabel() {
    switch (entry.type) {
      case _TimelineType.history:
        return 'SYSTEM';
      case _TimelineType.comment:
        return 'COMMENT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _getDotColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === Timeline column (dot + line) ===
          SizedBox(
            width: 40,
            child: Column(
              children: [
                // Dot
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2.5),
                    boxShadow: isLast
                        ? [BoxShadow(color: dotColor.withOpacity(0.3), blurRadius: 8)]
                        : [],
                  ),
                  child: Icon(_getIcon(), size: 10, color: dotColor),
                ),
                // Line (jika bukan item terakhir)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [dotColor.withOpacity(0.5), Colors.grey.withOpacity(0.2)],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // === Content card ===
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: GlassmorphismCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: type badge + timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _getTypeLabel(),
                            style: TextStyle(
                              color: dotColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy • HH:mm').format(entry.timestamp),
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Description
                    Text(
                      entry.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Actor
                    FutureBuilder<dynamic>(
                      future: entry.actorId.contains('-')
                          ? Supabase.instance.client
                              .from('profiles')
                              .select('full_name')
                              .eq('id', entry.actorId)
                              .maybeSingle()
                          : Future.value({'full_name': entry.actorId}),
                      builder: (context, snapshot) {
                        final name = snapshot.hasData && snapshot.data != null
                            ? snapshot.data['full_name'] ?? 'Unknown'
                            : (snapshot.hasError ? 'Unknown' : '...');
                        return Row(
                          children: [
                            Icon(LucideIcons.userCircle2, size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
