import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import '../widgets/dialog_builder.dart';

class AuthService {
  const AuthService(this.context);
  final BuildContext context;

  Future<String?> onLogin(LoginData loginData) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    
    // Add your login logic here
    // Example: API call, validation, etc.
    
    DialogBuilder(context).showResultDialog('Successful login.');
    return null;
  }

  Future<String?> onSignup(SignUpData signupData) async {
    DialogBuilder(context).showLoadingDialog();
    await Future.delayed(const Duration(seconds: 2));
    if (!context.mounted) return null;
    Navigator.of(context).pop();
    
    // Add your signup logic here
    // Example: API call, validation, etc.
    
    DialogBuilder(context).showResultDialog('Successful sign up.');
    return null;
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