import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import '../../../core/widgets/dialog_builder.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/auth_storage_service.dart';
import '../data/models/auth/user.dart';

class AuthService {
  const AuthService(this.context);
  final BuildContext context;

  Future<String?> onLogin(LoginData loginData) async {
    AppLogger.log('Login attempt for: ${loginData.email}', tag: 'AuthService');
    DialogBuilder(context).showLoadingDialog();

    try {
      final response = await ApiClient.post('/auth/login', {
        'email': loginData.email,
        'password': loginData.password,
      });

      if (!context.mounted) return null;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        final token = data['token'] as String;
        final expiresAt = DateTime.parse(data['expires_at']);

        await AuthStorageService.saveUser(user, token: token, expiresAt: expiresAt);
        AppLogger.log('Login successful: ${user.email}', tag: 'AuthService');

        if (!context.mounted) return null;
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return null;
      }

      final error = jsonDecode(response.body)['error'] ?? 'Invalid email or password';
      return error;
    } catch (e) {
      AppLogger.error('Login error', tag: 'AuthService', error: e);
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      return 'Connection error: ${e.toString()}';
    }
  }

  Future<String?> onSignup(SignUpData signupData) async {
    AppLogger.log('Signup attempt for: ${signupData.email}', tag: 'AuthService');
    DialogBuilder(context).showLoadingDialog();

    try {
      final response = await ApiClient.post('/auth/register', {
        'nama': signupData.name.isEmpty ? signupData.email.split('@')[0] : signupData.name,
        'email': signupData.email,
        'password': signupData.password,
      });

      if (!context.mounted) return null;
      Navigator.of(context).pop();

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Registration Successful!'),
            ]),
            content: Text('Welcome ${user.nama}!\n\nYour account has been created. You can now login.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return null;
      }

      if (response.statusCode == 409) return 'Email already registered. Please login.';
      final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
      return error;
    } catch (e) {
      AppLogger.error('Signup error', tag: 'AuthService', error: e);
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<String?> onForgotPassword(String email) async {
    DialogBuilder(context).showLoadingDialog();

    try {
      final response = await ApiClient.post('/auth/forgot-password', {'email': email});

      if (!context.mounted) return null;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Email Sent'),
            content: const Text('If the email is registered, a password reset link has been sent. Please check your inbox.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return null;
      }

      return 'Failed to send reset email. Please try again.';
    } catch (e) {
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      return 'Connection error: ${e.toString()}';
    }
  }

  Future<String?> socialLogin(String type) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    DialogBuilder(context).showResultDialog('Social login with $type is not yet supported.');
    return null;
  }
}
