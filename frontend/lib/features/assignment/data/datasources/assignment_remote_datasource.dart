import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../models/assignment_model.dart';

abstract class AssignmentRemoteDataSource {
  Future<AssignmentModel> getAssignment(int assignmentId);
  Future<List<AssignmentModel>> getAssignmentsByRoom(String roomId);
  Future<AssignmentSubmissionModel> submitPdf({
    required int assignmentId,
    required int userId,
    required File file,
  });
  Future<AssignmentSubmissionModel> getMySubmission({
    required int assignmentId,
    required int userId,
  });
}

class AssignmentRemoteDataSourceImpl implements AssignmentRemoteDataSource {
  @override
  Future<AssignmentModel> getAssignment(int assignmentId) async {
    final res = await ApiClient.get('/assignments/$assignmentId');
    if (res.statusCode == 200) {
      return AssignmentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load assignment: ${res.statusCode}');
  }

  @override
  Future<List<AssignmentModel>> getAssignmentsByRoom(String roomId) async {
    final res = await ApiClient.get('/rooms/$roomId/assignments');
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load assignments: ${res.statusCode}');
  }

  @override
  Future<AssignmentSubmissionModel> submitPdf({
    required int assignmentId,
    required int userId,
    required File file,
  }) async {
    final url = '${ApiClient.baseUrl}/assignments/$assignmentId/submissions';
    final token = await AuthStorageService.getToken();

    final request = http.MultipartRequest('POST', Uri.parse(url));
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['user_id'] = userId.toString();
    request.files.add(await http.MultipartFile.fromPath('pdf', file.path));

    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();
    final body = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    if (streamed.statusCode == 201) {
      return AssignmentSubmissionModel.fromJson(body);
    }
    throw Exception(body['error'] ?? 'Upload gagal: ${streamed.statusCode}');
  }

  @override
  Future<AssignmentSubmissionModel> getMySubmission({
    required int assignmentId,
    required int userId,
  }) async {
    final res = await ApiClient.get(
      '/assignments/$assignmentId/submissions?user_id=$userId',
    );
    if (res.statusCode == 200) {
      return AssignmentSubmissionModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Submission not found: ${res.statusCode}');
  }
}
