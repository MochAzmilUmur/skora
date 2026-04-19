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
      final rooms = await remoteDataSource.getRooms();
      return Right(rooms);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> getRoomById(String roomId) async {
    try {
      final room = await remoteDataSource.getRoomById(roomId);
      return Right(room);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> createRoom({
    required String roomName,
    required int durasi,
    required int createdBy,
  }) async {
    try {
      final room = await remoteDataSource.createRoom(
        roomName: roomName,
        durasi: durasi,
        createdBy: createdBy.toString(),
      );
      return Right(room);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, RoomModel>> updateRoom({
    required String roomId,
    String? roomName,
    int? durasi,
  }) async {
    try {
      final data = <String, dynamic>{
        if (roomName != null) 'room_name': roomName,
        if (durasi != null) 'durasi': durasi,
      };
      final room = await remoteDataSource.updateRoom(roomId, data);
      return Right(room);
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
  Future<Either<Failure, List<RoomParticipantModel>>> getRoomParticipants(
      String roomId) async {
    try {
      final participants = await remoteDataSource.getRoomParticipants(roomId);
      return Right(participants);
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
      final participant = await remoteDataSource.addParticipant(
        roomId: roomId,
        userId: userId,
        role: role,
      );
      return Right(participant);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeParticipant(int participantId) async {
    try {
      await remoteDataSource.removeParticipant(participantId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
