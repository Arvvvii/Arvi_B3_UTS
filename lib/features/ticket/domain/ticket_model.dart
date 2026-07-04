enum TicketStatus { open, inProgress, resolved }

class TicketModel {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final String priority; // 'high', 'medium', 'low'
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
    this.priority = 'medium',
    required this.createdAt,
    required this.createdBy,
    this.assignedTo,
    this.timeline = const [],
    this.attachedFilePath,
  });

  TicketModel copyWith({
    TicketStatus? status,
    String? priority,
    String? assignedTo,
    List<TicketTimeline>? timeline,
    String? attachedFilePath,
  }) {
    return TicketModel(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      createdBy: createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      timeline: timeline ?? this.timeline,
      attachedFilePath: attachedFilePath ?? this.attachedFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status == TicketStatus.inProgress ? 'in_progress' : status.name.toLowerCase(),
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'attachment_url': attachedFilePath,
      // 'timeline' is managed locally or via separate endpoints, excluded to prevent HTTP 500
    };
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: _parseStatus(json['status']),
      priority: _parsePriority(json['priority']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      createdBy: json['created_by'] ?? '',
      assignedTo: json['assigned_to'] ?? json['assignedTo'],
      attachedFilePath: json['attachment_url'] ?? json['attached_file_path'],
      timeline: (json['timeline'] as List<dynamic>?)
              ?.map((e) => TicketTimeline.fromJson(e as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  static TicketStatus _parseStatus(String? status) {
    switch(status?.toLowerCase()) {
      case 'inprogress':
      case 'in_progress': return TicketStatus.inProgress;
      case 'resolved': return TicketStatus.resolved;
      case 'open':
      default: return TicketStatus.open;
    }
  }

  static String _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high': return 'high';
      case 'low': return 'low';
      case 'medium':
      default: return 'medium';
    }
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

  factory TicketTimeline.fromJson(Map<String, dynamic> json) {
    return TicketTimeline(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
      actorRole: json['actor_role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'actor_role': actorRole,
    };
  }
}

// =============================================================================
// MODEL BARU v2.0.0
// =============================================================================

/// CommentModel merepresentasikan komentar pada tiket (tabel public.comments)
class CommentModel {
  final String id;
  final String ticketId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.ticketId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      authorId: json['author_id'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// TicketHistoryModel merepresentasikan log riwayat aksi pada tiket
/// (tabel public.ticket_histories, BR-005: Tracking)
class TicketHistoryModel {
  final String id;
  final String ticketId;
  final String action;
  final String actorId;
  final DateTime createdAt;

  TicketHistoryModel({
    required this.id,
    required this.ticketId,
    required this.action,
    required this.actorId,
    required this.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketHistoryModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      action: json['action'] ?? '',
      actorId: json['actor_id'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

/// DashboardStatsModel merepresentasikan statistik tiket dari GET /dashboard/stats
class DashboardStatsModel {
  final int open;
  final int inProgress;
  final int resolved;
  final int total;

  DashboardStatsModel({
    required this.open,
    required this.inProgress,
    required this.resolved,
    required this.total,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      open: json['open'] ?? 0,
      inProgress: json['in_progress'] ?? 0,
      resolved: json['resolved'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}
