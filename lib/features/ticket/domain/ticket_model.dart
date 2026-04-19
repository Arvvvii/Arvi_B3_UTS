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
    String? attachedFilePath,
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
      attachedFilePath: attachedFilePath ?? this.attachedFilePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status == TicketStatus.inProgress ? 'in_progress' : status.name.toLowerCase(),
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
