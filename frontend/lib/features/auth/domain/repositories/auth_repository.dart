import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signup({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<Failure, UserEntity>> socialLogin(String provider);
}
