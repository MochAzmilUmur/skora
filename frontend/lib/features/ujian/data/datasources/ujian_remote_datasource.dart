import '../../../../features/auth/data/models/models.dart';

abstract class UjianRemoteDataSource {
  // Pertanyaan
  Future<List<PertanyaanModel>> getPertanyaanByRoom(String roomId);
  
  Future<PertanyaanModel> getPertanyaanById(int pertanyaanId);
  
  Future<PertanyaanModel> createPertanyaan({
    required String roomId,
    required String pertanyaanText,
    required TypePertanyaan typePertanyaan,
    List<QuestionOptionModel>? options,
  });
  
  Future<void> deletePertanyaan(int pertanyaanId);
  
  // Sesi Ujian
  Future<SesiUjianModel> startSesiUjian({
    required String roomId,
    required int userId,
  });
  
  Future<SesiUjianModel> getSesiUjianById(int sesiId);
  
  Future<SesiUjianModel> endSesiUjian(int sesiId);
  
  Future<List<SesiUjianModel>> getSesiUjianByUser(int userId);
  
  // Answer
  Future<AnswerModel> submitAnswer({
    required int sessionId,
    required int questionId,
    String? answerText,
    int? selectedOptionId,
  });
  
  Future<List<AnswerModel>> getAnswersBySession(int sessionId);
  
  // Hasil Ujian
  Future<HasilUjianModel> getHasilUjian(int sessionId);
  
  Future<HasilUjianModel> calculateHasilUjian(int sessionId);
}
