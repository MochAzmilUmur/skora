import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/dialog_builder.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/services/auth_storage_service.dart';
import '../../../core/services/websocket_service.dart';
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
        // Connect WebSocket immediately after login
        context.read<WebSocketService>().connect();
        AppToast.showSuccess(context, 'Selamat datang kembali, ${user.nama}!');
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return null;
      }

      final error = jsonDecode(response.body)['error'] ?? 'Email atau password salah';
      AppToast.showError(context, error);
      return error;
    } catch (e) {
      AppLogger.error('Login error', tag: 'AuthService', error: e);
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      final err = 'Koneksi error: ${e.toString()}';
      AppToast.showError(context, err);
      return err;
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

        AppToast.showSuccess(
          context,
          'Akun ${user.nama} berhasil dibuat. Silakan login.',
          title: 'Registrasi Berhasil',
        );
        return null;
      }

      if (response.statusCode == 409) {
        const msg = 'Email sudah terdaftar. Silakan login.';
        AppToast.showWarning(context, msg);
        return msg;
      }
      final error = jsonDecode(response.body)['error'] ?? 'Registrasi gagal';
      AppToast.showError(context, error);
      return error;
    } catch (e) {
      AppLogger.error('Signup error', tag: 'AuthService', error: e);
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      final err = 'Registrasi gagal: ${e.toString()}';
      AppToast.showError(context, err);
      return err;
    }
  }

  Future<String?> onForgotPassword(String email) async {
    DialogBuilder(context).showLoadingDialog();

    try {
      final response = await ApiClient.post('/auth/forgot-password', {'email': email});

      if (!context.mounted) return null;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        AppToast.showInfo(
          context,
          'Jika email terdaftar, tautan reset password telah dikirim ke email Anda.',
          title: 'Email Terkirim',
        );
        return null;
      }

      const msg = 'Gagal mengirim email reset password. Silakan coba lagi.';
      AppToast.showError(context, msg);
      return msg;
    } catch (e) {
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      final err = 'Koneksi error: ${e.toString()}';
      AppToast.showError(context, err);
      return err;
    }
  }

  Future<String?> socialLogin(String type) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 1));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    AppToast.showInfo(context, 'Login sosial dengan $type belum didukung.');
    return null;
  }
}
