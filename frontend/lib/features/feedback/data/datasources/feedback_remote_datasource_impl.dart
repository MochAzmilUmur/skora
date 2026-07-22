import 'dart:convert';
import 'package:skora/core/network/api_client.dart';
import 'package:skora/core/utils/logger.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'feedback_remote_datasource.dart';

class FeedbackRemoteDataSourceImpl implements FeedbackRemoteDataSource {
  @override
  Future<FeedbackModel> sendFeedback({
    required int hasilId,
    required int asesorId,
    required String komentar,
  }) async {
    final response = await ApiClient.post('/feedback', {
      'hasil_id': hasilId,
      'asesor_id': asesorId,
      'komentar': komentar,
    });
    if (response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FeedbackModel.fromJson(body['feedback'] as Map<String, dynamic>);
    }
    throw Exception('Failed to send feedback: ${response.statusCode}');
  }

  @override
  Future<List<FeedbackModel>> getFeedbackByHasil(int hasilId) async {
    final response = await ApiClient.get('/feedback?hasil_id=$hasilId');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => FeedbackModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load feedback: ${response.statusCode}');
  }

  @override
  Future<List<FeedbackModel>> getFeedbackByAsesor(int asesorId) async {
    // ponytail: no dedicated endpoint yet; filter client-side if needed
    throw UnimplementedError('getFeedbackByAsesor not yet implemented');
  }

  @override
  Future<void> deleteFeedback(int feedbackId) async {
    final response = await ApiClient.delete('/feedback/$feedbackId');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete feedback: ${response.statusCode}');
    }
  }

  @override
  Future<List<ActivityLogModel>> getActivityLogsBySession(int sessionId) async {
    AppLogger.log('getActivityLogsBySession not yet implemented', tag: 'FeedbackDS');
    return [];
  }

  @override
  Future<ActivityLogModel> logActivity({
    required int sessionId,
    required String activityType,
  }) async {
    throw UnimplementedError('logActivity not yet implemented');
  }
}
