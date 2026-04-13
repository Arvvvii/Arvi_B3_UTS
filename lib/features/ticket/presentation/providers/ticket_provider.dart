import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ticket_model.dart';
import '../data/ticket_repository.dart';

class TicketListNotifier extends StateNotifier<AsyncValue<List<TicketModel>>> {
  final TicketRepository _repository;
  int _currentPage = 1;
  bool _isFetchingMore = false;
  bool _hasMore = true;

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

  Future<void> addTicketLocally(TicketModel newTicket) async {
    await _repository.createTicket(newTicket);
    final currentList = state.value ?? [];
    state = AsyncValue.data([newTicket, ...currentList]);
  }
}

final ticketListProvider = StateNotifierProvider<TicketListNotifier, AsyncValue<List<TicketModel>>>((ref) {
  final repo = ref.watch(ticketRepositoryProvider);
  return TicketListNotifier(repo);
});

final ticketDetailProvider = FutureProvider.family<TicketModel?, String>((ref, id) async {
  final repo = ref.watch(ticketRepositoryProvider);
  return repo.getTicketById(id);
});
