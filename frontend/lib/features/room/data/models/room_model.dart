import 'package:skora/features/auth/data/models/auth/user.dart';

class RoomModel {
  final String idRoom;
  final String roomName;
  final int durasi;
  final int createdBy;
  final DateTime createdAt;
  final User? user;

  const RoomModel({
    required this.idRoom,
    required this.roomName,
    required this.durasi,
    required this.createdBy,
    required this.createdAt,
    this.user,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      idRoom: json['id_room'] as String,
      roomName: json['room_name'] as String,
      durasi: json['durasi'] as int,
      createdBy: json['created_by'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_room': idRoom,
      'room_name': roomName,
      'durasi': durasi,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  RoomModel copyWith({
    String? idRoom,
    String? roomName,
    int? durasi,
    int? createdBy,
    DateTime? createdAt,
    User? user,
  }) {
    return RoomModel(
      idRoom: idRoom ?? this.idRoom,
      roomName: roomName ?? this.roomName,
      durasi: durasi ?? this.durasi,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomModel && other.idRoom == idRoom;
  }

  @override
  int get hashCode => idRoom.hashCode;

  @override
  String toString() {
    return 'RoomModel(idRoom: $idRoom, roomName: $roomName, durasi: $durasi)';
  }
}
