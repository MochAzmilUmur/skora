import 'package:skora/features/room/data/models/room_model.dart';
import 'package:skora/features/auth/data/models/auth/user.dart';

enum SesiUjianStatus {
  ongoing,
  completed,
  timeout;

  static SesiUjianStatus fromString(String status) {
    return SesiUjianStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => SesiUjianStatus.ongoing,
    );
  }

  String toJson() => name;
}

class SesiUjianModel {
  final int id;
  final String roomId;
  final int userId;
  final DateTime startTime;
  final DateTime? endTime;
  final SesiUjianStatus status;
  final RoomModel? room;
  final User? user;

  const SesiUjianModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.status,
    this.room,
    this.user,
  });

  factory SesiUjianModel.fromJson(Map<String, dynamic> json) {
    return SesiUjianModel(
      id: json['id'] as int,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as int,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      status: SesiUjianStatus.fromString(json['status'] as String),
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      if (endTime != null) 'end_time': endTime!.toIso8601String(),
      'status': status.toJson(),
      if (room != null) 'room': room!.toJson(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  SesiUjianModel copyWith({
    int? id,
    String? roomId,
    int? userId,
    DateTime? startTime,
    DateTime? endTime,
    SesiUjianStatus? status,
    RoomModel? room,
    User? user,
  }) {
    return SesiUjianModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      room: room ?? this.room,
      user: user ?? this.user,
    );
  }

  Duration? get remainingTime {
    if (room == null || endTime != null) return null;
    final deadline = startTime.add(Duration(minutes: room!.durasi));
    final now = DateTime.now();
    if (now.isAfter(deadline)) return Duration.zero;
    return deadline.difference(now);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SesiUjianModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SesiUjianModel(id: $id, userId: $userId, status: $status)';
  }
}
