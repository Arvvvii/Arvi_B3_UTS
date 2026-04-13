enum TicketStatus { open, inProgress, resolved }

class TicketModel {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;
  final String createdBy; // User Name
  final String? assignedTo; // Admin/Helpdesk Name
  final List<TicketTimeline> timeline;
  final String? attachedFilePath;

  TicketModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.assignedTo,
    this.timeline = const [],
    this.attachedFilePath,
  });

  TicketModel copyWith({
    TicketStatus? status,
    String? assignedTo,
    List<TicketTimeline>? timeline,
  }) {
    return TicketModel(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      timeline: timeline ?? this.timeline,
      attachedFilePath: attachedFilePath,
    );
  }
}

class TicketTimeline {
  final String id;
  final String description;
  final DateTime timestamp;
  final String actorRole;

  TicketTimeline({
    required this.id,
    required this.description,
    required this.timestamp,
    required this.actorRole,
  });
}
