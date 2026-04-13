import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maauts003/features/ticket/domain/ticket_model.dart';

class TicketRepository {
  final List<TicketModel> _mockTickets = List.generate(50, (index) {
    final now = DateTime.now();
    return TicketModel(
      id: 'TCK-${1000 + index}',
      title: 'Issue with system module ${index + 1}',
      description: 'The system module ${index + 1} is not responding correctly. Please check the logs.',
      status: index % 3 == 0 ? TicketStatus.open : (index % 2 == 0 ? TicketStatus.resolved : TicketStatus.inProgress),
      createdAt: now.subtract(Duration(days: index)),
      createdBy: 'User ${index % 5 + 1}',
      timeline: [
        TicketTimeline(
          id: 'tml_${index}_1',
          description: 'Ticket created',
          timestamp: now.subtract(Duration(days: index)),
          actorRole: 'User',
        ),
        if (index % 3 != 0)
          TicketTimeline(
            id: 'tml_${index}_2',
            description: 'Ticket marked as In Progress',
            timestamp: now.subtract(Duration(days: index, hours: -2)),
            actorRole: 'Helpdesk',
          ),
        if (index % 2 == 0 && index % 3 != 0)
          TicketTimeline(
            id: 'tml_${index}_3',
            description: 'Ticket Resolved',
            timestamp: now.subtract(Duration(days: index, hours: -5)),
            actorRole: 'Admin',
          ),
      ],
    );
  });

  Future<List<TicketModel>> getTickets({int page = 1, int limit = 10, String? filterRole}) async {
    await Future.delayed(const Duration(seconds: 1)); // Mock network latency for lazy loading
    int startIndex = (page - 1) * limit;
    if (startIndex >= _mockTickets.length) return [];
    
    int endIndex = startIndex + limit;
    if (endIndex > _mockTickets.length) endIndex = _mockTickets.length;

    return _mockTickets.sublist(startIndex, endIndex);
  }

  Future<TicketModel?> getTicketById(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    try {
      return _mockTickets.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createTicket(TicketModel ticket) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockTickets.insert(0, ticket);
  }
}

final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  return TicketRepository();
});
