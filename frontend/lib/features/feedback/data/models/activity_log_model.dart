import 'package:frontend/features/ujian/data/models/sesi_ujian_model.dart';

class ActivityLogModel {
  final int id;
  final int sessionId;
  final String activityType;
  final DateTime activityTime;
  final SesiUjianModel? sesiUjian;

  const ActivityLogModel({
    required this.id,
    required this.sessionId,
    required this.activityType,
    required this.activityTime,
    this.sesiUjian,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      activityType: json['activity_type'] as String,
      activityTime: DateTime.parse(json['activity_time'] as String),
      sesiUjian: json['sesi_ujian'] != null
          ? SesiUjianModel.fromJson(json['sesi_ujian'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'activity_type': activityType,
      'activity_time': activityTime.toIso8601String(),
      if (sesiUjian != null) 'sesi_ujian': sesiUjian!.toJson(),
    };
  }

  ActivityLogModel copyWith({
    int? id,
    int? sessionId,
    String? activityType,
    DateTime? activityTime,
    SesiUjianModel? sesiUjian,
  }) {
    return ActivityLogModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      activityType: activityType ?? this.activityType,
      activityTime: activityTime ?? this.activityTime,
      sesiUjian: sesiUjian ?? this.sesiUjian,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityLogModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityLogModel(id: $id, type: $activityType, time: $activityTime)';
  }
}
