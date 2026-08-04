import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/data/models/models.dart';
import '../../domain/repositories/ujian_repository.dart';
import '../datasources/ujian_remote_datasource.dart';

class UjianRepositoryImpl implements UjianRepository {
  final UjianRemoteDataSource remoteDataSource;

  UjianRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<PertanyaanModel>>> getPertanyaanByRoom(
    String roomId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final pertanyaans = await remoteDataSource.getPertanyaanByRoom(
        roomId,
        page: page,
        limit: limit,
      );
      return Right(pertanyaans);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PertanyaanModel>> getPertanyaanById(
      int pertanyaanId) async {
    try {
      final pertanyaan = await remoteDataSource.getPertanyaanById(pertanyaanId);
      return Right(pertanyaan);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PertanyaanModel>> createPertanyaan({
    required String roomId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
    List<QuestionOptionModel>? options,
  }) async {
    try {
      final pertanyaan = await remoteDataSource.createPertanyaan(
        roomId: roomId,
        pertanyaanText: pertanyaanText,
        gambarUrl: gambarUrl,
        typePertanyaan: typePertanyaan,
        options: options,
      );
      return Right(pertanyaan);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePertanyaan(int pertanyaanId) async {
    try {
      await remoteDataSource.deletePertanyaan(pertanyaanId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PertanyaanModel>> updatePertanyaan({
    required int pertanyaanId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
  }) async {
    try {
      final result = await remoteDataSource.updatePertanyaan(
        pertanyaanId: pertanyaanId,
        pertanyaanText: pertanyaanText,
        gambarUrl: gambarUrl,
        typePertanyaan: typePertanyaan,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadImage(File file) async {
    try {
      final url = await remoteDataSource.uploadImage(file);
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> importQuestionsExcel(
      String roomId, File excelFile) async {
    try {
      final count = await remoteDataSource.importQuestionsExcel(roomId, excelFile);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SesiUjianModel>> startSesiUjian({
    required String roomId,
    required int userId,
  }) async {
    try {
      final sesi = await remoteDataSource.startSesiUjian(
        roomId: roomId,
        userId: userId,
      );
      return Right(sesi);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SesiUjianModel>> getSesiUjianById(int sesiId) async {
    try {
      final sesi = await remoteDataSource.getSesiUjianById(sesiId);
      return Right(sesi);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SesiUjianModel>> endSesiUjian(int sesiId) async {
    try {
      final sesi = await remoteDataSource.endSesiUjian(sesiId);
      return Right(sesi);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SesiUjianModel>>> getSesiUjianByUser(
      int userId) async {
    try {
      final sessions = await remoteDataSource.getSesiUjianByUser(userId);
      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, AnswerModel>> submitAnswer({
    required int sessionId,
    required int questionId,
    String? answerText,
    int? selectedOptionId,
    String? fileUrl,
  }) async {
    try {
      final answer = await remoteDataSource.submitAnswer(
        sessionId: sessionId,
        questionId: questionId,
        answerText: answerText,
        selectedOptionId: selectedOptionId,
        fileUrl: fileUrl,
      );
      return Right(answer);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AnswerModel>>> getAnswersBySession(
      int sessionId) async {
    try {
      final answers = await remoteDataSource.getAnswersBySession(sessionId);
      return Right(answers);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HasilUjianModel>> getHasilUjian(int sessionId) async {
    try {
      final hasil = await remoteDataSource.getHasilUjian(sessionId);
      return Right(hasil);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HasilUjianModel>> calculateHasilUjian(
      int sessionId) async {
    try {
      final hasil = await remoteDataSource.calculateHasilUjian(sessionId);
      return Right(hasil);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
