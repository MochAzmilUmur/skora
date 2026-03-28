enum WebSocketMessageType {
  feedback,
  notification,
  unknown;

  static WebSocketMessageType fromString(String type) {
    return WebSocketMessageType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => WebSocketMessageType.unknown,
    );
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
