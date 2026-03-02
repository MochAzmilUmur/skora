import 'dart:convert';
import 'package:frontend/models/user.dart';
import 'package:frontend/services/api/api_client.dart';
import 'package:frontend/utils/logger.dart';

class UserService {
  static Future<List<User>> getUsers() async {
    try {
      AppLogger.log('Fetching all users', tag: 'UserService');
      final response = await ApiClient.get('/users');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final users = data.map((json) => User.fromJson(json)).toList();
        AppLogger.log('Fetched ${users.length} users', tag: 'UserService');
        return users;
      }
      throw Exception('Failed to load users: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error fetching users', tag: 'UserService', error: e);
      rethrow;
    }
  }

  static Future<User?> getUserByEmail(String email) async {
    try {
      AppLogger.log('Searching user by email: $email', tag: 'UserService');
      final users = await getUsers();
      final user = users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );
      AppLogger.log('User found: ${user.nama}', tag: 'UserService');
      return user;
    } catch (e) {
      AppLogger.error('User not found with email: $email', tag: 'UserService', error: e);
      return null;
    }
  }

  static Future<User> createUser(String nama, String email, String password) async {
    try {
      AppLogger.log('Creating user: $email', tag: 'UserService');
      final response = await ApiClient.post('/users', {
        'nama': nama,
        'email': email,
        'password_hash': password,
      });

      if (response.statusCode == 201) {
        final user = User.fromJson(jsonDecode(response.body));
        AppLogger.log('User created successfully: ${user.nama}', tag: 'UserService');
        return user;
      }
      throw Exception('Failed to create user: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('Error creating user', tag: 'UserService', error: e);
      rethrow;
    }
  }
}
