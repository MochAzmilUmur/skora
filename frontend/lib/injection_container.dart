import 'package:get_it/get_it.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/signup_usecase.dart';
import 'features/auth/domain/usecases/social_login_usecase.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // Controllers
  sl.registerFactory(
    () => AuthController(
      signupUseCase: sl(),
      socialLoginUseCase: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => SignupUseCase(sl()));
  sl.registerLazySingleton(() => SocialLoginUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data Sources - TODO: Implement actual remote datasource
  // sl.registerLazySingleton<AuthRemoteDataSource>(
  //   () => AuthRemoteDataSourceImpl(client: sl()),
  // );
}
