import '../../domain/entities/user_entity.dart';

abstract class AuthRemoteDataSource {
  Future<UserEntity> signup({
    required String email,
    required String password,
    required String name,
  });

  Future<UserEntity> socialLogin(String provider);
}
