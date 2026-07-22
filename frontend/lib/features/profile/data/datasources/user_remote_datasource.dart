import 'dart:convert';
import 'package:skora/core/network/api_client.dart';
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
}
