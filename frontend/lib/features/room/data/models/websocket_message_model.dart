enum WebSocketMessageType {
  feedback,
  participantJoined,
  examStarted,
  notification,
  roleChanged,
  unknown;

  static WebSocketMessageType fromString(String type) {
    switch (type) {
      case 'feedback':
        return WebSocketMessageType.feedback;
      case 'participant_joined':
        return WebSocketMessageType.participantJoined;
      case 'exam_started':
        return WebSocketMessageType.examStarted;
      case 'notification':
        return WebSocketMessageType.notification;
      case 'role_changed':
        return WebSocketMessageType.roleChanged;
      default:
        return WebSocketMessageType.unknown;
    }
  }
}

class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;
  final DateTime receivedAt;

  const WebSocketMessage({
    required this.type,
    required this.data,
    required this.receivedAt,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.fromString(json['type'] as String? ?? 'unknown'),
      data: json,
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      ...data,
      'received_at': receivedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'WebSocketMessage(type: $type, receivedAt: $receivedAt)';
  }
}

class FeedbackWebSocketPayload {
  final int feedbackId;
  final int asesorId;
  final String komentar;
  final DateTime createdAt;

  const FeedbackWebSocketPayload({
    required this.feedbackId,
    required this.asesorId,
    required this.komentar,
    required this.createdAt,
  });

  factory FeedbackWebSocketPayload.fromJson(Map<String, dynamic> json) {
    return FeedbackWebSocketPayload(
      feedbackId: json['feedback_id'] as int,
      asesorId: json['asesor_id'] as int,
      komentar: json['komentar'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedback_id': feedbackId,
      'asesor_id': asesorId,
      'komentar': komentar,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'FeedbackWebSocketPayload(feedbackId: $feedbackId, asesorId: $asesorId)';
  }
}

class ParticipantJoinedPayload {
  final String roomId;
  final String roomName;
  final int userId;
  final String userName;
  final DateTime joinedAt;

  const ParticipantJoinedPayload({
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
    required this.joinedAt,
  });

  factory ParticipantJoinedPayload.fromJson(Map<String, dynamic> json) {
    return ParticipantJoinedPayload(
      roomId: json['room_id'] as String,
      roomName: json['room_name'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class ExamStartedPayload {
  final int sessionId;
  final String roomId;
  final String roomName;
  final int userId;
  final String userName;
  final DateTime startedAt;

  const ExamStartedPayload({
    required this.sessionId,
    required this.roomId,
    required this.roomName,
    required this.userId,
    required this.userName,
    required this.startedAt,
  });

  factory ExamStartedPayload.fromJson(Map<String, dynamic> json) {
    return ExamStartedPayload(
      sessionId: json['session_id'] as int,
      roomId: json['room_id'] as String,
      roomName: json['room_name'] as String,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
    );
  }
}
