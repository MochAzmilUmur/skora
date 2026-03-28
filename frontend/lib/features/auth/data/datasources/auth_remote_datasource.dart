import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> login({
    required String email,
    required String password,
  });

  Future<UserEntity> signup({
    required String email,
    required String password,
    required String name,
  });

  Future<UserEntity> socialLogin(String provider);

  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  Future<void> logout();
}
