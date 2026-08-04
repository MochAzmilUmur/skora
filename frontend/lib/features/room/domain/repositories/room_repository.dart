import 'package:dartz/dartz.dart';
import 'package:skora/core/error/failures.dart';
import '../../data/models/models.dart';

abstract class RoomRepository {
  Future<Either<Failure, List<RoomModel>>> getRooms();
  Future<Either<Failure, List<RoomModel>>> getRoomsByUser(int userId);
  Future<Either<Failure, RoomModel>> getRoomById(String roomId);
  Future<Either<Failure, RoomModel>> getRoomByCode(String code);

  Future<Either<Failure, RoomModel>> createRoom({
    required String roomName,
    required String description,
    required int durasi,
    required DateTime? startDate,
    required String roomType,
    required bool shuffleQuestions,
    required int createdBy,
  });

  Future<Either<Failure, RoomModel>> updateRoom({
    required String roomId,
    String? roomName,
    String? description,
    int? durasi,
    DateTime? startDate,
    String? roomType,
    bool? shuffleQuestions,
  });

  Future<Either<Failure, void>> deleteRoom(String roomId);

  Future<Either<Failure, Map<String, dynamic>>> joinRoom({
    required String roomCode,
    required int userId,
  });

  Future<Either<Failure, List<RoomParticipantModel>>> getRoomParticipants(String roomId);
  Future<Either<Failure, RoomParticipantModel>> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  });
  Future<Either<Failure, void>> removeParticipant(String roomId, int participantId);
}
