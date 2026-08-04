import '../../../../features/auth/data/models/models.dart';

abstract class FeedbackRemoteDataSource {
  Future<FeedbackModel> sendFeedback({
    required int hasilId,
    required int asesorId,
    required int senderId,
    required String komentar,
  });
  
  Future<List<FeedbackModel>> getFeedbackByHasil(int hasilId);
  
  Future<List<FeedbackModel>> getFeedbackByAsesor(int asesorId);
  
  Future<void> deleteFeedback(int feedbackId);
  
  // Activity Log
  Future<List<ActivityLogModel>> getActivityLogsBySession(int sessionId);
  
  Future<ActivityLogModel> logActivity({
    required int sessionId,
    required String activityType,
  });
}
