import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/assignment.dart';

abstract class AssignmentRepository {
  Future<Either<Failure, Assignment>> getAssignment(int assignmentId);
  Future<Either<Failure, List<Assignment>>> getAssignmentsByRoom(String roomId);
  Future<Either<Failure, AssignmentSubmission>> submitPdf({
    required int assignmentId,
    required int userId,
    required File file,
  });
  Future<Either<Failure, AssignmentSubmission>> getMySubmission({
    required int assignmentId,
    required int userId,
  });
}
