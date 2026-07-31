import 'dart:convert';
import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../features/auth/data/models/models.dart';
import 'ujian_remote_datasource.dart';

class UjianRemoteDataSourceImpl implements UjianRemoteDataSource {
  // ── Pertanyaan ────────────────────────────────────────────────────────────

  @override
  Future<List<PertanyaanModel>> getPertanyaanByRoom(
    String roomId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await ApiClient.get(
        '/rooms/$roomId/pertanyaans?page=$page&limit=$limit',
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final list = body['data'] as List;
        return list.map((e) => PertanyaanModel.fromJson(e)).toList();
      }
      throw Exception('Failed to load soal: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('getPertanyaanByRoom', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<PertanyaanModel> getPertanyaanById(int pertanyaanId) async {
    try {
      final response = await ApiClient.get('/pertanyaans/$pertanyaanId');
      if (response.statusCode == 200) {
        return PertanyaanModel.fromJson(jsonDecode(response.body));
      }
      throw Exception('Soal not found: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('getPertanyaanById', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<PertanyaanModel> createPertanyaan({
    required String roomId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
    List<QuestionOptionModel>? options,
  }) async {
    try {
      final body = <String, dynamic>{
        'room_id': roomId,
        'pertanyaan_text': pertanyaanText,
        if (gambarUrl != null && gambarUrl.isNotEmpty) 'gambar_url': gambarUrl,
        'type_pertanyaan': typePertanyaan.toJson(),
        if (options != null)
          'question_options': options
              .map((o) => {
                    'option_text': o.optionText,
                    'is_correct': o.isCorrect,
                  })
              .toList(),
      };
      final response = await ApiClient.post('/pertanyaans', body);
      if (response.statusCode == 201) {
        return PertanyaanModel.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to create soal: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('createPertanyaan', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<PertanyaanModel> updatePertanyaan({
    required int pertanyaanId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
  }) async {
    try {
      final body = <String, dynamic>{
        'pertanyaan_text': pertanyaanText,
        'gambar_url': gambarUrl ?? '',
        'type_pertanyaan': typePertanyaan.toJson(),
      };
      final response = await ApiClient.put('/pertanyaans/$pertanyaanId', body);
      if (response.statusCode == 200) {
        return PertanyaanModel.fromJson(jsonDecode(response.body));
      }
      throw Exception('Failed to update soal: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('updatePertanyaan', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<void> deletePertanyaan(int pertanyaanId) async {
    try {
      final response = await ApiClient.delete('/pertanyaans/$pertanyaanId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete soal: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('deletePertanyaan', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<String> uploadImage(File file) async {
    try {
      final response = await ApiClient.uploadMultipart('/upload', file);
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['file_url'] as String;
      }
      throw Exception('Failed to upload image: ${response.statusCode}');
    } catch (e) {
      AppLogger.error('uploadImage', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  @override
  Future<int> importQuestionsExcel(String roomId, File excelFile) async {
    try {
      final response = await ApiClient.uploadMultipart(
        '/rooms/$roomId/import-excel',
        excelFile,
      );
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['total_imported'] as num).toInt();
      }
      final errorMsg = jsonDecode(response.body)['error'] ?? 'Import failed';
      throw Exception(errorMsg);
    } catch (e) {
      AppLogger.error('importQuestionsExcel', tag: 'UjianDS', error: e);
      rethrow;
    }
  }

  // ── Sesi Ujian ────────────────────────────────────────────────────────────

  @override
  Future<SesiUjianModel> startSesiUjian({
    required String roomId,
    required int userId,
  }) async {
    final response = await ApiClient.post('/sesi-ujians', {
      'room_id': roomId,
      'user_id': userId,
    });
    if (response.statusCode == 201) {
      return SesiUjianModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to start sesi: ${response.statusCode}');
  }

  @override
  Future<SesiUjianModel> getSesiUjianById(int sesiId) async {
    final response = await ApiClient.get('/sesi-ujians/$sesiId');
    if (response.statusCode == 200) {
      return SesiUjianModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Sesi not found: ${response.statusCode}');
  }

  @override
  Future<SesiUjianModel> endSesiUjian(int sesiId) async {
    final response = await ApiClient.put('/sesi-ujians/$sesiId', {'status': 'completed'});
    if (response.statusCode == 200) {
      return SesiUjianModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to end sesi: ${response.statusCode}');
  }

  @override
  Future<List<SesiUjianModel>> getSesiUjianByUser(int userId) async {
    final response = await ApiClient.get('/sesi-ujians?user_id=$userId');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => SesiUjianModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load sesi: ${response.statusCode}');
  }

  // ── Answer ────────────────────────────────────────────────────────────────

  @override
  Future<AnswerModel> submitAnswer({
    required int sessionId,
    required int questionId,
    String? answerText,
    int? selectedOptionId,
  }) async {
    final response = await ApiClient.post('/answers', {
      'session_id': sessionId,
      'question_id': questionId,
      if (answerText != null) 'answer_text': answerText,
      if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
    });
    if (response.statusCode == 201) {
      return AnswerModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to submit answer: ${response.statusCode}');
  }

  @override
  Future<List<AnswerModel>> getAnswersBySession(int sessionId) async {
    final response = await ApiClient.get('/answers?session_id=$sessionId');
    if (response.statusCode == 200) {
      final list = jsonDecode(response.body) as List;
      return list.map((e) => AnswerModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load answers: ${response.statusCode}');
  }

  // ── Hasil Ujian ───────────────────────────────────────────────────────────

  @override
  Future<HasilUjianModel> getHasilUjian(int sessionId) async {
    final response = await ApiClient.get('/hasil-ujians?session_id=$sessionId');
    if (response.statusCode == 200) {
      return HasilUjianModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Hasil not found: ${response.statusCode}');
  }

  @override
  Future<HasilUjianModel> calculateHasilUjian(int sessionId) async {
    final response = await ApiClient.post('/hasil-ujians', {'session_id': sessionId});
    if (response.statusCode == 201) {
      return HasilUjianModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to calculate hasil: ${response.statusCode}');
  }
}
