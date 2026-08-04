import 'package:dartz/dartz.dart';
import 'package:skora/core/error/failures.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'package:skora/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:skora/features/feedback/data/datasources/feedback_remote_datasource.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;

  FeedbackRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, FeedbackModel>> sendFeedback({
    required int hasilId,
    required int asesorId,
    required int senderId,
    required String komentar,
  }) async {
    try {
      final feedback = await remoteDataSource.sendFeedback(
        hasilId: hasilId,
        asesorId: asesorId,
        senderId: senderId,
        komentar: komentar,
      );
      return Right(feedback);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FeedbackModel>>> getFeedbackByHasil(
      int hasilId) async {
    try {
      final feedbacks = await remoteDataSource.getFeedbackByHasil(hasilId);
      return Right(feedbacks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FeedbackModel>>> getFeedbackByAsesor(
      int asesorId) async {
    try {
      final feedbacks = await remoteDataSource.getFeedbackByAsesor(asesorId);
      return Right(feedbacks);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFeedback(int feedbackId) async {
    try {
      await remoteDataSource.deleteFeedback(feedbackId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLogModel>>> getActivityLogsBySession(
      int sessionId) async {
    try {
      final logs = await remoteDataSource.getActivityLogsBySession(sessionId);
      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ActivityLogModel>> logActivity({
    required int sessionId,
    required String activityType,
  }) async {
    try {
      final log = await remoteDataSource.logActivity(
        sessionId: sessionId,
        activityType: activityType,
      );
      return Right(log);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
