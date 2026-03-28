import 'package:dartz/dartz.dart';
import 'package:frontend/core/error/failures.dart';
import '../../data/models/models.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<RoomModel>>> getRooms();
  
  Future<Either<Failure, RoomModel>> getRoomById(String roomId);
  
  Future<Either<Failure, RoomModel>> createRoom({
    required String roomName,
    required int durasi,
    required int createdBy,
  });
  
  Future<Either<Failure, RoomModel>> updateRoom({
    required String roomId,
    String? roomName,
    int? durasi,
  });
  
  Future<Either<Failure, void>> deleteRoom(String roomId);
  
  Future<Either<Failure, List<RoomParticipantModel>>> getRoomParticipants(String roomId);
  
  Future<Either<Failure, RoomParticipantModel>> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  });
  
  Future<Either<Failure, void>> removeParticipant(int participantId);
}
