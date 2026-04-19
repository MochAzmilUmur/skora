import 'package:skora/features/auth/data/models/auth/user.dart';
import 'room_model.dart';

enum ParticipantRole {
  asesor,
  pelajar;

  static ParticipantRole fromString(String role) {
    return ParticipantRole.values.firstWhere(
      (e) => e.name == role,
      orElse: () => ParticipantRole.pelajar,
    );
  }

  String toJson() => name;
}

class RoomParticipantModel {
  final int id;
  final String roomId;
  final int userId;
  final ParticipantRole role;
  final DateTime joinedAt;
  final RoomModel? room;
  final User? user;

  const RoomParticipantModel({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.room,
    this.user,
  });

  factory RoomParticipantModel.fromJson(Map<String, dynamic> json) {
    return RoomParticipantModel(
      id: json['id'] as int,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as int,
      role: ParticipantRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
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
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
      if (room != null) 'room': room!.toJson(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  RoomParticipantModel copyWith({
    int? id,
    String? roomId,
    int? userId,
    ParticipantRole? role,
    DateTime? joinedAt,
    RoomModel? room,
    User? user,
  }) {
    return RoomParticipantModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      room: room ?? this.room,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomParticipantModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RoomParticipantModel(id: $id, userId: $userId, role: $role)';
  }
}
