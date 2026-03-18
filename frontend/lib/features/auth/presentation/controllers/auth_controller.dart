import 'package:flutter/material.dart';
import 'package:animated_login/animated_login.dart';
import '../../domain/usecases/signup_usecase.dart';
import '../../domain/usecases/social_login_usecase.dart';

class AuthController extends ChangeNotifier {
  final SignupUseCase signupUseCase;
  final SocialLoginUseCase socialLoginUseCase;

  bool _isLoading = false;
  String? _errorMessage;

  AuthController({
    required this.signupUseCase,
    required this.socialLoginUseCase,
  });

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String?> handleSignup(SignUpData data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await signupUseCase(
      email: data.email,
      password: data.password,
      name: data.name,
    );

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return failure.message;
      },
      (user) {
        notifyListeners();
        return null;
      },
    );
  }

  Future<String?> handleSocialLogin(String provider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await socialLoginUseCase(provider);

    _isLoading = false;

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        notifyListeners();
        return failure.message;
      },
      (user) {
        notifyListeners();
        return null;
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
