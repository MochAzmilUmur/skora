import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../features/auth/data/models/models.dart';
import '../../domain/repositories/ujian_repository.dart';

enum SoalStatus { idle, loading, loadingMore, saving, error }

class SoalNotifier extends ChangeNotifier {
  final UjianRepository _repo;

  SoalNotifier(this._repo);

  List<PertanyaanModel> _items = [];
  SoalStatus _status = SoalStatus.idle;
  String _errorMessage = '';
  int _page = 1;
  bool _hasMore = true;
  String? _roomId;

  List<PertanyaanModel> get items => _items;
  SoalStatus get status => _status;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  bool get isLoading => _status == SoalStatus.loading;
  bool get isSaving => _status == SoalStatus.saving;

  static const _limit = 20;

  /// Load first page for [roomId]. Resets state if room changes.
  Future<void> loadSoal(String roomId) async {
    if (_roomId != roomId) {
      _items = [];
      _page = 1;
      _hasMore = true;
      _roomId = roomId;
    }
    _status = SoalStatus.loading;
    notifyListeners();

    final result = await _repo.getPertanyaanByRoom(roomId, page: 1, limit: _limit);
    result.fold(
      (f) {
        _status = SoalStatus.error;
        _errorMessage = f.message;
      },
      (data) {
        _items = data;
        _page = 1;
        _hasMore = data.length >= _limit;
        _status = SoalStatus.idle;
      },
    );
    notifyListeners();
  }

  /// Load next page (infinite scroll).
  Future<void> loadMore() async {
    if (!_hasMore || _status == SoalStatus.loadingMore || _roomId == null) return;

    _status = SoalStatus.loadingMore;
    notifyListeners();

    final nextPage = _page + 1;
    final result = await _repo.getPertanyaanByRoom(
      _roomId!,
      page: nextPage,
      limit: _limit,
    );
    result.fold(
      (f) => _status = SoalStatus.error,
      (data) {
        _items = [..._items, ...data];
        _page = nextPage;
        _hasMore = data.length >= _limit;
        _status = SoalStatus.idle;
      },
    );
    notifyListeners();
  }

  Future<String?> uploadImage(File file) async {
    _status = SoalStatus.saving;
    notifyListeners();

    final result = await _repo.uploadImage(file);
    return result.fold(
      (f) {
        _errorMessage = f.message;
        _status = SoalStatus.idle;
        notifyListeners();
        return null;
      },
      (url) {
        _status = SoalStatus.idle;
        notifyListeners();
        return url;
      },
    );
  }

  Future<bool> createSoal({
    required String roomId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
    List<QuestionOptionModel>? options,
  }) async {
    _status = SoalStatus.saving;
    notifyListeners();

    final result = await _repo.createPertanyaan(
      roomId: roomId,
      pertanyaanText: pertanyaanText,
      gambarUrl: gambarUrl,
      typePertanyaan: typePertanyaan,
      options: options,
    );
    return result.fold(
      (f) {
        _errorMessage = f.message;
        _status = SoalStatus.idle;
        notifyListeners();
        return false;
      },
      (soal) {
        _items = [soal, ..._items];
        _status = SoalStatus.idle;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> updateSoal({
    required int pertanyaanId,
    required String pertanyaanText,
    String? gambarUrl,
    required TypePertanyaan typePertanyaan,
  }) async {
    _status = SoalStatus.saving;
    notifyListeners();

    final result = await _repo.updatePertanyaan(
      pertanyaanId: pertanyaanId,
      pertanyaanText: pertanyaanText,
      gambarUrl: gambarUrl,
      typePertanyaan: typePertanyaan,
    );
    return result.fold(
      (f) {
        _errorMessage = f.message;
        _status = SoalStatus.idle;
        notifyListeners();
        return false;
      },
      (updated) {
        final idx = _items.indexWhere((e) => e.id == pertanyaanId);
        if (idx != -1) {
          _items = [..._items]..[idx] = updated;
        }
        _status = SoalStatus.idle;
        notifyListeners();
        return true;
      },
    );
  }

  Future<int?> importExcel(String roomId, File excelFile) async {
    _status = SoalStatus.saving;
    notifyListeners();

    final result = await _repo.importQuestionsExcel(roomId, excelFile);
    return result.fold(
      (f) {
        _errorMessage = f.message;
        _status = SoalStatus.idle;
        notifyListeners();
        return null;
      },
      (importedCount) async {
        await loadSoal(roomId);
        return importedCount;
      },
    );
  }

  Future<bool> deleteSoal(int pertanyaanId) async {
    final result = await _repo.deletePertanyaan(pertanyaanId);
    return result.fold(
      (f) {
        _errorMessage = f.message;
        notifyListeners();
        return false;
      },
      (_) {
        _items = _items.where((e) => e.id != pertanyaanId).toList();
        notifyListeners();
        return true;
      },
    );
  }
}
