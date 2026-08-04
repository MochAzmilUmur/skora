import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../features/auth/data/models/models.dart';
import '../../../../features/room/data/models/websocket_message_model.dart';
import '../../domain/repositories/ujian_repository.dart';

enum ExamStatus { loading, active, submitting, completed, error }

class ExamSessionNotifier extends ChangeNotifier {
  final UjianRepository _repo;

  ExamSessionNotifier(this._repo);

  // ── Session state ──────────────────────────────────────────────────────
  ExamStatus _status = ExamStatus.loading;
  String _errorMessage = '';
  SesiUjianModel? _sesi;
  HasilUjianModel? _hasil;

  // ── Question state ─────────────────────────────────────────────────────
  List<PertanyaanModel> _soal = [];
  int _currentIndex = 0;

  // answers: questionId → selectedOptionId (MC) or answerText (essay)
  final Map<int, int?> _selectedOptions = {};
  final Map<int, String?> _textAnswers = {};
  final Map<int, String?> _fileAnswers = {}; // questionId → uploaded file URL
  final Set<int> _bookmarked = {};

  // ── Real-time feedback ─────────────────────────────────────────────────
  final List<FeedbackWebSocketPayload> _incomingFeedbacks = [];
  List<FeedbackWebSocketPayload> get incomingFeedbacks =>
      List.unmodifiable(_incomingFeedbacks);
  bool get hasFeedback => _incomingFeedbacks.isNotEmpty;

  // ── Timer ──────────────────────────────────────────────────────────────
  int _remainingSeconds = 0;
  Timer? _timer;

  // ── Getters ────────────────────────────────────────────────────────────
  ExamStatus get status => _status;
  String get errorMessage => _errorMessage;
  SesiUjianModel? get sesi => _sesi;
  HasilUjianModel? get hasil => _hasil;
  List<PertanyaanModel> get soal => _soal;
  int get currentIndex => _currentIndex;
  int get remainingSeconds => _remainingSeconds;
  int get totalQuestions => _soal.length;
  Set<int> get bookmarked => Set.unmodifiable(_bookmarked);

  PertanyaanModel? get currentSoal =>
      _soal.isEmpty ? null : _soal[_currentIndex];

  int? selectedOption(int questionId) => _selectedOptions[questionId];
  String? textAnswer(int questionId) => _textAnswers[questionId];
  String? fileAnswer(int questionId) => _fileAnswers[questionId];
  bool isBookmarked(int questionId) => _bookmarked.contains(questionId);
  bool isAnswered(int questionId) =>
      _selectedOptions.containsKey(questionId) ||
      (_textAnswers[questionId]?.isNotEmpty ?? false) ||
      (_fileAnswers[questionId]?.isNotEmpty ?? false);

  int get answeredCount =>
      _soal.where((s) => isAnswered(s.id)).length;

  String get formattedTime {
    final h = _remainingSeconds ~/ 3600;
    final m = (_remainingSeconds % 3600) ~/ 60;
    final s = _remainingSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  bool get isTimeCritical => _remainingSeconds < 300;

  // ── Real-time feedback ─────────────────────────────────────────────────
  /// Called by ExamSessionScreen when a WS feedback message arrives.
  void addFeedback(FeedbackWebSocketPayload payload) {
    _incomingFeedbacks.add(payload);
    notifyListeners();
  }

  void clearFeedbacks() {
    _incomingFeedbacks.clear();
    notifyListeners();
  }

  // ── Init ───────────────────────────────────────────────────────────────
  /// Call once when entering exam screen.
  Future<void> init({
    required String roomId,
    required int userId,
    required int durasiMenit,
  }) async {
    _status = ExamStatus.loading;
    _soal = [];
    _selectedOptions.clear();
    _textAnswers.clear();
    _bookmarked.clear();
    _currentIndex = 0;
    notifyListeners();

    // Start session
    final sesiResult = await _repo.startSesiUjian(
      roomId: roomId,
      userId: userId,
    );
    if (sesiResult.isLeft()) {
      _status = ExamStatus.error;
      _errorMessage = sesiResult.fold((f) => f.message, (_) => '');
      notifyListeners();
      return;
    }
    _sesi = sesiResult.getOrElse(() => throw StateError('unreachable'));

    // Load all soal (load all pages)
    await _loadAllSoal(roomId);

    // Start timer from room durasi
    _remainingSeconds = durasiMenit * 60;
    _startTimer();

    _status = ExamStatus.active;
    notifyListeners();
  }

  Future<void> _loadAllSoal(String roomId) async {
    const limit = 100; // ponytail: single large page; room soal rarely exceeds 100
    final result = await _repo.getPertanyaanByRoom(roomId, page: 1, limit: limit);
    result.fold(
      (f) {
        _status = ExamStatus.error;
        _errorMessage = f.message;
      },
      (list) => _soal = list,
    );
  }

  // ── Timer ──────────────────────────────────────────────────────────────

  // ── Timer ──────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        submitExam(isTimeout: true);
        return;
      }
      _remainingSeconds--;
      notifyListeners();
    });
  }

  // ── Answer ─────────────────────────────────────────────────────────────
  void selectOption(int questionId, int optionId) {
    _selectedOptions[questionId] = optionId;
    notifyListeners();
    _saveAnswerToBackend(questionId);
  }

  void setTextAnswer(int questionId, String text) {
    _textAnswers[questionId] = text;
    notifyListeners();
    // ponytail: debounce not needed, submit is fire-and-forget
    _saveAnswerToBackend(questionId);
  }

  void setFileAnswer(int questionId, String fileUrl) {
    _fileAnswers[questionId] = fileUrl;
    notifyListeners();
    _saveAnswerToBackend(questionId);
  }

  void _saveAnswerToBackend(int questionId) {
    if (_sesi == null) return;
    _repo.submitAnswer(
      sessionId: _sesi!.id,
      questionId: questionId,
      selectedOptionId: _selectedOptions[questionId],
      answerText: _textAnswers[questionId],
      fileUrl: _fileAnswers[questionId],
    );
    // fire-and-forget; errors silently ignored (optimistic local state is source of truth)
  }

  // ── Navigation ─────────────────────────────────────────────────────────
  void goTo(int index) {
    if (index < 0 || index >= _soal.length) return;
    _currentIndex = index;
    notifyListeners();
  }

  void next() => goTo(_currentIndex + 1);
  void previous() => goTo(_currentIndex - 1);

  // ── Bookmark ───────────────────────────────────────────────────────────
  void toggleBookmark(int questionId) {
    if (_bookmarked.contains(questionId)) {
      _bookmarked.remove(questionId);
    } else {
      _bookmarked.add(questionId);
    }
    notifyListeners();
  }

  // ── Submit ─────────────────────────────────────────────────────────────
  Future<HasilUjianModel?> submitExam({bool isTimeout = false}) async {
    if (_status == ExamStatus.submitting || _status == ExamStatus.completed) {
      return _hasil;
    }
    _timer?.cancel();
    _status = ExamStatus.submitting;
    notifyListeners();

    // End session
    if (_sesi != null) {
      await _repo.endSesiUjian(_sesi!.id);
    }

    // Calculate hasil
    if (_sesi != null) {
      final hasilResult = await _repo.calculateHasilUjian(_sesi!.id);
      hasilResult.fold(
        (f) => _errorMessage = f.message,
        (h) => _hasil = h,
      );
    }

    _status = ExamStatus.completed;
    notifyListeners();
    return _hasil;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
