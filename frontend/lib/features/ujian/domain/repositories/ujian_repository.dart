import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../features/auth/data/models/models.dart';

abstract class UjianRepository {
  // Pertanyaan
  Future<Either<Failure, List<PertanyaanModel>>> getPertanyaanByRoom(
    String roomId, {
    int page = 1,
    int limit = 20,
  });
  
  Future<Either<Failure, PertanyaanModel>> getPertanyaanById(int pertanyaanId);
  
  Future<Either<Failure, PertanyaanModel>> createPertanyaan({
    required String roomId,
    required String pertanyaanText,
    required TypePertanyaan typePertanyaan,
    List<QuestionOptionModel>? options,
  });

  Future<Either<Failure, PertanyaanModel>> updatePertanyaan({
    required int pertanyaanId,
    required String pertanyaanText,
    required TypePertanyaan typePertanyaan,
  });

  Future<Either<Failure, void>> deletePertanyaan(int pertanyaanId);
  
  // Sesi Ujian
  Future<Either<Failure, SesiUjianModel>> startSesiUjian({
    required String roomId,
    required int userId,
  });
  
  Future<Either<Failure, SesiUjianModel>> getSesiUjianById(int sesiId);
  
  Future<Either<Failure, SesiUjianModel>> endSesiUjian(int sesiId);
  
  Future<Either<Failure, List<SesiUjianModel>>> getSesiUjianByUser(int userId);
  
  // Answer
  Future<Either<Failure, AnswerModel>> submitAnswer({
    required int sessionId,
    required int questionId,
    String? answerText,
    int? selectedOptionId,
  });
  
  Future<Either<Failure, List<AnswerModel>>> getAnswersBySession(int sessionId);
  
  // Hasil Ujian
  Future<Either<Failure, HasilUjianModel>> getHasilUjian(int sessionId);
  
  Future<Either<Failure, HasilUjianModel>> calculateHasilUjian(int sessionId);
}
