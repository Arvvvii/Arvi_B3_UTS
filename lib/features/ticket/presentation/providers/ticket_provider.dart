import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:arvi_b3_uts/features/ticket/domain/ticket_model.dart';
import 'package:arvi_b3_uts/features/ticket/data/ticket_repository.dart';
import 'package:arvi_b3_uts/features/auth/presentation/providers/auth_provider.dart';

// =============================================================================
// TICKET LIST NOTIFIER — State management utama untuk daftar tiket
// =============================================================================

class TicketListNotifier extends StateNotifier<AsyncValue<List<TicketModel>>> {
  final TicketRepository _repository;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMore = true;

  bool get isFetchingMore => _isFetchingMore;
  bool get hasMore => _hasMore;

  TicketListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    state = const AsyncValue.loading();
    _currentPage = 1;
    _hasMore = true;
    try {
      final initialData = await _repository.getTickets(page: _currentPage);
      final mergedData = await _mergeWithLocalExtraData(initialData);
      state = AsyncValue.data(mergedData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<TicketModel>> _mergeWithLocalExtraData(List<TicketModel> tickets) async {
    final prefs = await SharedPreferences.getInstance();
    return tickets.map((t) {
      final extraDataString = prefs.getString('ticket_extra_${t.id}');
      if (extraDataString != null) {
        final extraData = jsonDecode(extraDataString);
        return t.copyWith(
          assignedTo: t.assignedTo?.isNotEmpty == true ? t.assignedTo : extraData['assignedTo'],
          timeline: t.timeline.isEmpty ? (extraData['timeline'] as List<dynamic>?)?.map((e) => TicketTimeline.fromJson(e)).toList() : t.timeline,
        );
      }
      return t;
    }).toList();
  }

  Future<void> _saveExtraData(TicketModel ticket) async {
    final prefs = await SharedPreferences.getInstance();
    final extraData = {
      'assignedTo': ticket.assignedTo,
      'timeline': ticket.timeline.map((e) => e.toJson()).toList(),
    };
    await prefs.setString('ticket_extra_${ticket.id}', jsonEncode(extraData));
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;

    try {
      _currentPage++;
      final moreData = await _repository.getTickets(page: _currentPage);
      final currentList = state.value ?? [];
      
      // Fix for infinite scroll: Deduplicate incoming data
      final newItems = moreData.where((newItem) => !currentList.any((existing) => existing.id == newItem.id)).toList();
      
      if (newItems.isEmpty) {
        _hasMore = false;
      } else {
        final mergedItems = await _mergeWithLocalExtraData(newItems);
        state = AsyncValue.data([...currentList, ...mergedItems]);
      }
    } catch (e) {
      // Handle error gracefully without overriding list
    } finally {
      _isFetchingMore = false;
    }
  }

  Future<void> createTicket(TicketModel newTicket, [File? attachment]) async {
    String? fileUrl;
    if (attachment != null) {
      fileUrl = await _repository.uploadTicketAttachment(attachment);
    }
    
    final ticketToCreate = fileUrl != null ? newTicket.copyWith(attachedFilePath: fileUrl) : newTicket;
    await _repository.createTicket(ticketToCreate);
    
    final currentList = state.value ?? [];
    state = AsyncValue.data([ticketToCreate, ...currentList]);
    await _saveExtraData(ticketToCreate);
  }

  Future<void> updateTicketStatus(String id, TicketStatus newStatus, String actorRole) async {
    final currentList = state.value ?? [];
    final ticketIndex = currentList.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

    final targetTicket = currentList[ticketIndex];
    
    // Add to timeline
    final newTimelineEvent = TicketTimeline(
      id: 'tml_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Status changed to ${newStatus.name}',
      timestamp: DateTime.now(),
      actorRole: actorRole,
    );

    final updatedTicket = targetTicket.copyWith(
      status: newStatus,
      timeline: [...targetTicket.timeline, newTimelineEvent],
    );

    await _repository.updateTicket(updatedTicket);

    // Update local state list
    final updatedList = List<TicketModel>.from(currentList);
    updatedList[ticketIndex] = updatedTicket;
    state = AsyncValue.data(updatedList);
    await _saveExtraData(updatedTicket);
  }

  Future<void> addComment(String id, String comment, String actorRole) async {
    final currentList = state.value ?? [];
    final ticketIndex = currentList.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

    // [v2.0.0] Kirim komentar ke backend via POST /tickets/:id/comments
    await _repository.createComment(id, comment);

    final targetTicket = currentList[ticketIndex];
    
    final newTimelineEvent = TicketTimeline(
      id: 'tml_${DateTime.now().millisecondsSinceEpoch}',
      description: comment,
      timestamp: DateTime.now(),
      actorRole: actorRole,
    );

    final updatedTicket = targetTicket.copyWith(
      timeline: [...targetTicket.timeline, newTimelineEvent],
    );

    // Save to master list state locally
    final updatedList = List<TicketModel>.from(currentList);
    updatedList[ticketIndex] = updatedTicket;
    state = AsyncValue.data(updatedList);
    await _saveExtraData(updatedTicket);
  }

  /// [NEW v2.0.0] Hapus tiket (Admin only)
  Future<void> deleteTicket(String id) async {
    await _repository.deleteTicket(id);
    
    // Hapus dari state lokal
    final currentList = state.value ?? [];
    final updatedList = currentList.where((t) => t.id != id).toList();
    state = AsyncValue.data(updatedList);

    // Hapus extra data lokal
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ticket_extra_$id');
  }

  Future<void> assignTicket(String id, String staffId, String staffName, String actorRole) async {
    final currentList = state.value ?? [];
    final ticketIndex = currentList.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

    final targetTicket = currentList[ticketIndex];
    
    // Add to timeline
    final newTimelineEvent = TicketTimeline(
      id: 'tml_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Ticket assigned to $staffName',
      timestamp: DateTime.now(),
      actorRole: actorRole,
    );

    final updatedTicket = targetTicket.copyWith(
      assignedTo: staffId,
      timeline: [...targetTicket.timeline, newTimelineEvent],
    );

    await _repository.updateTicket(updatedTicket);

    // Update local state list
    final updatedList = List<TicketModel>.from(currentList);
    updatedList[ticketIndex] = updatedTicket;
    state = AsyncValue.data(updatedList);
    await _saveExtraData(updatedTicket);
  }

  /// [NEW v2.0.0] Handler untuk Supabase Realtime event.
  /// Dipanggil saat ada INSERT/UPDATE/DELETE pada tabel tickets.
  void handleRealtimeEvent(Map<String, dynamic> newRecord, Map<String, dynamic> oldRecord, String eventType) {
    final currentList = state.value ?? [];

    switch (eventType) {
      case 'INSERT':
        final newTicket = TicketModel.fromJson(newRecord);
        // Cek apakah tiket sudah ada (untuk menghindari duplikasi)
        if (!currentList.any((t) => t.id == newTicket.id)) {
          state = AsyncValue.data([newTicket, ...currentList]);
        }
        break;

      case 'UPDATE':
        final updatedTicket = TicketModel.fromJson(newRecord);
        final updatedList = currentList.map((t) {
          if (t.id == updatedTicket.id) {
            // Pertahankan timeline lokal jika backend tidak mengirimnya
            return updatedTicket.copyWith(
              timeline: updatedTicket.timeline.isEmpty ? t.timeline : updatedTicket.timeline,
              assignedTo: updatedTicket.assignedTo?.isNotEmpty == true ? updatedTicket.assignedTo : t.assignedTo,
            );
          }
          return t;
        }).toList();
        state = AsyncValue.data(updatedList);
        break;

      case 'DELETE':
        final deletedId = oldRecord['id'] ?? '';
        final filteredList = currentList.where((t) => t.id != deletedId).toList();
        state = AsyncValue.data(filteredList);
        break;
    }
  }
}

// =============================================================================
// PROVIDERS
// =============================================================================

final ticketListProvider = StateNotifierProvider<TicketListNotifier, AsyncValue<List<TicketModel>>>((ref) {
  // [v2.0.0] Watch authProvider agar saat ganti user (login/logout), 
  // TicketListNotifier otomatis ter-reset dan load data baru milik user aktif.
  ref.watch(authProvider);
  
  final repo = ref.watch(ticketRepositoryProvider);
  return TicketListNotifier(repo);
});

final ticketDetailProvider = FutureProvider.family<TicketModel?, String>((ref, id) async {
  final repo = ref.watch(ticketRepositoryProvider);
  final fetchedTicket = await repo.getTicketById(id);
  
  // Ambil state lokal dari master list
  final listState = ref.read(ticketListProvider).value;
  final localTicket = listState?.cast<TicketModel?>().firstWhere((t) => t?.id == id, orElse: () => null);

  if (fetchedTicket != null && localTicket != null) {
    // Gabungkan state: Jika backend mengembalikan null untuk assignedTo, gunakan dari local state
    return fetchedTicket.copyWith(
      assignedTo: fetchedTicket.assignedTo?.isNotEmpty == true ? fetchedTicket.assignedTo : localTicket.assignedTo,
      timeline: fetchedTicket.timeline.isEmpty ? localTicket.timeline : fetchedTicket.timeline,
    );
  }

  return fetchedTicket;
});

final ticketFilterProvider = StateProvider<String>((ref) => 'All');

/// [NEW v2.0.0] Provider untuk dashboard stats dari backend (RBAC filtered).
final dashboardStatsProvider = FutureProvider<DashboardStatsModel>((ref) async {
  // [v2.0.0] Watch authProvider agar saat ganti user (login/logout), 
  // dashboard stats otomatis ter-reset dan load data baru milik user aktif.
  ref.watch(authProvider);
  
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getDashboardStats();
});

/// [NEW v2.0.0] Provider untuk komentar per tiket.
final ticketCommentsProvider = FutureProvider.family<List<CommentModel>, String>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getComments(ticketId);
});

/// [NEW v2.0.0] Provider untuk riwayat aksi tiket (tracking timeline).
final ticketHistoriesProvider = FutureProvider.family<List<TicketHistoryModel>, String>((ref, ticketId) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketHistories(ticketId);
});
