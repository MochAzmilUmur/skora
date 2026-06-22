import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/models/auth/user.dart';

class AuthStorageService {
  static const String _keyUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';

  /// Save logged in user data
  static Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyIsLoggedIn, true);
    debugPrint('✅ User saved to storage: ${user.nama} (ID: ${user.idUsers})');
  }

  /// Get current logged in user
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      debugPrint('📖 Retrieved user from storage: ${user.nama} (ID: ${user.idUsers})');
      return user;
    }
    debugPrint('⚠️ No user found in storage');
    return null;
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  /// Clear user data (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    final user = await getCurrentUser();
    debugPrint('🆔 User ID: ${user?.idUsers}');
    return user?.idUsers;
  }

  /// Get user name
  static Future<String?> getUserName() async {
    final user = await getCurrentUser();
    return user?.nama;
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final user = await getCurrentUser();
    return user?.email;
  }
}
