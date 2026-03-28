import '../models/models.dart';

abstract class RoomRemoteDataSource {
  Future<List<RoomModel>> getRooms();
  
  Future<RoomModel> getRoomById(String roomId);
  
  Future<RoomModel> createRoom({
    required String roomName,
    required int durasi,
    required int createdBy,
  });
  
  Future<RoomModel> updateRoom({
    required String roomId,
    String? roomName,
    int? durasi,
  });
  
  Future<void> deleteRoom(String roomId);
  
  Future<List<RoomParticipantModel>> getRoomParticipants(String roomId);
  
  Future<RoomParticipantModel> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  });
  
  Future<void> removeParticipant(int participantId);
}
