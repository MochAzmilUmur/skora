import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:skora/core/network/api_client.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/features/auth/data/models/auth/user.dart';

class UserRemoteDataSource {
  Future<User> getUser(int userId) async {
    final response = await ApiClient.get('/users/$userId');
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load user: ${response.statusCode}');
  }

  Future<User> updateProfile({
    required int userId,
    String? nama,
    String? email,
  }) async {
    final body = <String, dynamic>{
      if (nama != null && nama.isNotEmpty) 'nama': nama,
      if (email != null && email.isNotEmpty) 'email': email,
    };
    final response = await ApiClient.put('/users/$userId', body);
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    final err = jsonDecode(response.body)['error'] ?? 'Update failed';
    throw Exception(err);
  }

  Future<void> changePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await ApiClient.post('/users/$userId/change-password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body)['error'] ?? 'Change password failed';
      throw Exception(err);
    }
  }

  Future<User> updateRole({
    required int userId,
    required String role,
  }) async {
    final response = await ApiClient.put('/users/$userId/role', {'role': role});
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    }
    final err = jsonDecode(response.body)['error'] ?? 'Update role failed';
    throw Exception(err);
  }

  Future<User> uploadAvatar({
    required int userId,
    required File file,
  }) async {
    final token = await AuthStorageService.getToken();
    final uri = Uri.parse('${ApiClient.baseUrl}/users/$userId/avatar');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('avatar', file.path));

    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();
    final body = jsonDecode(String.fromCharCodes(bytes)) as Map<String, dynamic>;

    if (streamed.statusCode == 200) return User.fromJson(body);
    throw Exception(body['error'] ?? 'Upload avatar failed');
  }
}
