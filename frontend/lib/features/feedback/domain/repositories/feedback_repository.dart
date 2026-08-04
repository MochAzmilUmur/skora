import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/data/models/models.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, FeedbackModel>> sendFeedback({
    required int hasilId,
    required int asesorId,
    required int senderId,
    required String komentar,
  });
  
  Future<Either<Failure, List<FeedbackModel>>> getFeedbackByHasil(int hasilId);
  
  Future<Either<Failure, List<FeedbackModel>>> getFeedbackByAsesor(int asesorId);
  
  Future<Either<Failure, void>> deleteFeedback(int feedbackId);
  
  // Activity Log
  Future<Either<Failure, List<ActivityLogModel>>> getActivityLogsBySession(int sessionId);
  
  Future<Either<Failure, ActivityLogModel>> logActivity({
    required int sessionId,
    required String activityType,
  });
}
