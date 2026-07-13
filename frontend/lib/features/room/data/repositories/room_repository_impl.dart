import 'package:dartz/dartz.dart';
import 'package:skora/core/error/failures.dart';
import 'package:skora/features/room/domain/repositories/room_repository.dart';
import 'package:skora/features/room/data/datasources/room_remote_datasource.dart';
import 'package:skora/features/room/data/models/models.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource remoteDataSource;

  RoomRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<RoomModel>>> getRooms() async {
    try {
      return Right(await remoteDataSource.getRooms());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoomModel>>> getRoomsByUser(int userId) async {
    try {
      return Right(await remoteDataSource.getRoomsByUser(userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> getRoomById(String roomId) async {
    try {
      return Right(await remoteDataSource.getRoomById(roomId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> getRoomByCode(String code) async {
    try {
      return Right(await remoteDataSource.getRoomByCode(code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> createRoom({
    required String roomName,
    required String description,
    required int durasi,
    required DateTime? startDate,
    required String questionTypes,
    required bool shuffleQuestions,
    required int createdBy,
  }) async {
    try {
      final data = <String, dynamic>{
        'room_name': roomName,
        'description': description,
        'durasi': durasi,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        'question_types': questionTypes,
        'shuffle_questions': shuffleQuestions,
        'created_by': createdBy,
      };
      return Right(await remoteDataSource.createRoom(data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> updateRoom({
    required String roomId,
    String? roomName,
    String? description,
    int? durasi,
    DateTime? startDate,
    String? questionTypes,
    bool? shuffleQuestions,
  }) async {
    try {
      final data = <String, dynamic>{
        if (roomName != null) 'room_name': roomName,
        if (description != null) 'description': description,
        if (durasi != null) 'durasi': durasi,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (questionTypes != null) 'question_types': questionTypes,
        if (shuffleQuestions != null) 'shuffle_questions': shuffleQuestions,
      };
      return Right(await remoteDataSource.updateRoom(roomId, data));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRoom(String roomId) async {
    try {
      await remoteDataSource.deleteRoom(roomId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> joinRoom({
    required String roomCode,
    required int userId,
  }) async {
    try {
      return Right(await remoteDataSource.joinRoom(roomCode, userId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RoomParticipantModel>>> getRoomParticipants(String roomId) async {
    try {
      return Right(await remoteDataSource.getRoomParticipants(roomId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomParticipantModel>> addParticipant({
    required String roomId,
    required int userId,
    required ParticipantRole role,
  }) async {
    try {
      return Right(await remoteDataSource.addParticipant(roomId: roomId, userId: userId, role: role));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeParticipant(String roomId, int participantId) async {
    try {
      await remoteDataSource.removeParticipant(roomId, participantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
