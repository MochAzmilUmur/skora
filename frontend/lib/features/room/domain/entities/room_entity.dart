import 'package:equatable/equatable.dart';

class RoomEntity extends Equatable {
  final String idRoom;
  final String roomName;
  final int durasi;
  final int createdBy;
  final DateTime createdAt;

  const RoomEntity({
    required this.idRoom,
    required this.roomName,
    required this.durasi,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [idRoom, roomName, durasi, createdBy, createdAt];
}
