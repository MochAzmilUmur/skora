import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../datasources/assignment_remote_datasource.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource remoteDataSource;

  AssignmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Assignment>> getAssignment(int assignmentId) async {
    try {
      return Right(await remoteDataSource.getAssignment(assignmentId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Assignment>>> getAssignmentsByRoom(
      String roomId) async {
    try {
      return Right(await remoteDataSource.getAssignmentsByRoom(roomId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssignmentSubmission>> submitPdf({
    required int assignmentId,
    required int userId,
    required File file,
  }) async {
    try {
      return Right(await remoteDataSource.submitPdf(
        assignmentId: assignmentId,
        userId: userId,
        file: file,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AssignmentSubmission>> getMySubmission({
    required int assignmentId,
    required int userId,
  }) async {
    try {
      return Right(await remoteDataSource.getMySubmission(
        assignmentId: assignmentId,
        userId: userId,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
