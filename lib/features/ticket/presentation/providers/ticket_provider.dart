import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';
import 'package:maauts003/features/ticket/data/ticket_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      state = AsyncValue.data(initialData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> loadMore() async {
    if (_isFetchingMore || !_hasMore) return;
    _isFetchingMore = true;

    try {
      _currentPage++;
      final moreData = await _repository.getTickets(page: _currentPage);
      if (moreData.isEmpty) {
        _hasMore = false;
      } else {
        final currentList = state.value ?? [];
        state = AsyncValue.data([...currentList, ...moreData]);
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
  }

  Future<void> addComment(String id, String comment, String actorRole) async {
    final currentList = state.value ?? [];
    final ticketIndex = currentList.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

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
  }

  Future<void> autoAssignTicket(String id, String targetRole, String actorRole) async {
    final currentList = state.value ?? [];
    final ticketIndex = currentList.indexWhere((t) => t.id == id);
    if (ticketIndex == -1) return;

    final staffList = await _repository.getStaffByRole(targetRole);
    if (staffList.isEmpty) {
      throw Exception('Belum ada staff dengan role: $targetRole');
    }
    
    // Pick random staff
    final selectedStaff = staffList[DateTime.now().millisecondsSinceEpoch % staffList.length];
    
    final staffId = selectedStaff['id'] as String;
    final staffName = selectedStaff['full_name'] as String;

    final targetTicket = currentList[ticketIndex];
    
    // Add to timeline
    final newTimelineEvent = TicketTimeline(
      id: 'tml_${DateTime.now().millisecondsSinceEpoch}',
      description: 'Ticket auto-assigned to $staffName ($targetRole)',
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
  }
}

final ticketListProvider = StateNotifierProvider<TicketListNotifier, AsyncValue<List<TicketModel>>>((ref) {
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
