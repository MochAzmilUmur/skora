import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import '../../../core/widgets/dialog_builder.dart';
import '../../../core/network/user_service.dart';
import '../../../core/utils/logger.dart';
import '../../../core/services/auth_storage_service.dart';

class AuthService {
  const AuthService(this.context);
  final BuildContext context;

  Future<String?> onLogin(LoginData loginData) async {
    AppLogger.log('Login attempt for: ${loginData.email}', tag: 'AuthService');
    DialogBuilder(context).showLoadingDialog();
    
    try {
      final user = await UserService.getUserByEmail(loginData.email);
      
      if (!context.mounted) {
        AppLogger.log('Context not mounted after API call', tag: 'AuthService');
        return null;
      }
      
      Navigator.of(context).pop();
      
      if (user != null) {
        AppLogger.log('Login successful for: ${user.email}', tag: 'AuthService');
        
        // Save user data to storage
        await AuthStorageService.saveUser(user);
        AppLogger.log('User data saved to storage', tag: 'AuthService');
        
        if (!context.mounted) {
          AppLogger.log('Context not mounted before navigation', tag: 'AuthService');
          return null;
        }
        
        AppLogger.log('Navigating to dashboard', tag: 'AuthService');
        Navigator.of(context).pushReplacementNamed('/dashboard');
        return null;
      }
      
      AppLogger.log('Login failed: User not found', tag: 'AuthService');
      return 'Invalid email or password';
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
      // Cek apakah email sudah terdaftar
      final existingUser = await UserService.getUserByEmail(signupData.email);
      
      if (existingUser != null) {
        if (!context.mounted) return null;
        Navigator.of(context).pop();
        AppLogger.log('Signup failed: Email already exists', tag: 'AuthService');
        return 'Email already registered. Please login.';
      }
      
      // Buat user baru
      final newUser = await UserService.createUser(
        signupData.name.isEmpty ? signupData.email.split('@')[0] : signupData.name,
        signupData.email,
        signupData.password,
      );
      
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      
      AppLogger.log('Signup successful for: ${newUser.email}', tag: 'AuthService');
      
      // Tampilkan dialog sukses
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 30),
              SizedBox(width: 10),
              Text('Registration Successful!'),
            ],
          ),
          content: Text(
            'Welcome ${newUser.nama}!\n\nYour account has been created successfully.\nYou can now login with your credentials.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      
      return null;
    } catch (e) {
      AppLogger.error('Signup error', tag: 'AuthService', error: e);
      if (!context.mounted) return null;
      Navigator.of(context).pop();
      return 'Registration failed: ${e.toString()}';
    }
  }

  Future<String?> socialLogin(String type) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    
    // Add your social login logic here
    
    DialogBuilder(context)
        .showResultDialog('Successful social login with $type.');
    return null;
  }

  Future<String?> onForgotPassword(String email) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    
    // Add your forgot password logic here
    // Navigator.of(context).pushNamed('/forgotPass');
    
    return null;
  }
}