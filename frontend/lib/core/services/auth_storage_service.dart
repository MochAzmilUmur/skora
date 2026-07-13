import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/data/models/auth/user.dart';

class AuthStorageService {
  static const String _keyUser = 'current_user';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyToken = 'auth_token';
  static const String _keyTokenExpiry = 'token_expiry';

  /// Save logged in user data + JWT token
  static Future<void> saveUser(User user, {String? token, DateTime? expiresAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setBool(_keyIsLoggedIn, true);
    if (token != null) await prefs.setString(_keyToken, token);
    if (expiresAt != null) await prefs.setString(_keyTokenExpiry, expiresAt.toIso8601String());
    debugPrint('✅ User saved to storage: ${user.nama} (ID: ${user.idUsers})');
  }

  /// Get JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Check if token is still valid (not expired)
  static Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(_keyTokenExpiry);
    if (expiryStr == null) return false;
    final expiry = DateTime.tryParse(expiryStr);
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
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

  /// Check if user is logged in AND token is still valid
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!loggedIn) return false;
    return isTokenValid();
  }

  /// Clear user data (logout)
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyTokenExpiry);
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
