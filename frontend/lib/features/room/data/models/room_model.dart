import 'package:skora/features/auth/data/models/auth/user.dart';

class RoomModel {
  final String idRoom;
  final String roomName;
  final String description;
  final int durasi;
  final DateTime? startDate;
  final String questionTypes;
  final bool shuffleQuestions;
  final String roomCode;
  final int createdBy;
  final DateTime createdAt;
  final User? user;

  const RoomModel({
    required this.idRoom,
    required this.roomName,
    this.description = '',
    required this.durasi,
    this.startDate,
    this.questionTypes = '',
    this.shuffleQuestions = false,
    this.roomCode = '',
    required this.createdBy,
    required this.createdAt,
    this.user,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      idRoom: json['id_room'] as String,
      roomName: json['room_name'] as String,
      description: json['description'] as String? ?? '',
      durasi: json['durasi'] as int,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'] as String) : null,
      questionTypes: json['question_types'] as String? ?? '',
      shuffleQuestions: json['shuffle_questions'] as bool? ?? false,
      roomCode: json['room_code'] as String? ?? '',
      createdBy: json['created_by'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_room': idRoom,
      'room_name': roomName,
      'description': description,
      'durasi': durasi,
      if (startDate != null) 'start_date': startDate!.toIso8601String(),
      'question_types': questionTypes,
      'shuffle_questions': shuffleQuestions,
      'room_code': roomCode,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
    };
  }

  RoomModel copyWith({
    String? idRoom,
    String? roomName,
    String? description,
    int? durasi,
    DateTime? startDate,
    String? questionTypes,
    bool? shuffleQuestions,
    String? roomCode,
    int? createdBy,
    DateTime? createdAt,
    User? user,
  }) {
    return RoomModel(
      idRoom: idRoom ?? this.idRoom,
      roomName: roomName ?? this.roomName,
      description: description ?? this.description,
      durasi: durasi ?? this.durasi,
      startDate: startDate ?? this.startDate,
      questionTypes: questionTypes ?? this.questionTypes,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      roomCode: roomCode ?? this.roomCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
    );
  }

  bool get isActive => startDate == null || startDate!.isBefore(DateTime.now());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomModel && other.idRoom == idRoom;
  }

  @override
  int get hashCode => idRoom.hashCode;
}
