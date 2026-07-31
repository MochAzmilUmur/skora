import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/repositories/assignment_repository.dart';

enum AssignmentStatus { idle, loading, uploading, success, error }

class AssignmentNotifier extends ChangeNotifier {
  final AssignmentRepository _repo;

  AssignmentNotifier(this._repo);

  static const int _maxBytes = 5 * 1024 * 1024; // 5 MB

  Assignment? _assignment;
  AssignmentStatus _status = AssignmentStatus.idle;
  String _error = '';

  Assignment? get assignment => _assignment;
  AssignmentStatus get status => _status;
  String get error => _error;
  bool get isLoading => _status == AssignmentStatus.loading;
  bool get isUploading => _status == AssignmentStatus.uploading;

  Future<void> load(int assignmentId) async {
    _status = AssignmentStatus.loading;
    _error = '';
    notifyListeners();

    final result = await _repo.getAssignment(assignmentId);
    result.fold(
      (f) {
        _error = f.message;
        _status = AssignmentStatus.error;
      },
      (a) {
        _assignment = a;
        _status = AssignmentStatus.idle;
      },
    );
    notifyListeners();
  }

  /// Returns error message string on validation/upload failure, null on success.
  Future<String?> submitPdf({
    required int userId,
    required File file,
  }) async {
    if (_assignment == null) return 'Assignment belum dimuat';

    // Frontend validation
    final ext = file.path.split('.').last.toLowerCase();
    if (ext != 'pdf') return 'File harus berformat PDF';

    final size = await file.length();
    if (size > _maxBytes) {
      return 'Ukuran file melebihi batas 5 MB (${(size / 1024 / 1024).toStringAsFixed(1)} MB)';
    }

    _status = AssignmentStatus.uploading;
    _error = '';
    notifyListeners();

    final result = await _repo.submitPdf(
      assignmentId: _assignment!.id,
      userId: userId,
      file: file,
    );

    return result.fold(
      (f) {
        _error = _cleanMessage(f);
        _status = AssignmentStatus.error;
        notifyListeners();
        return _error;
      },
      (submission) {
        // Rebuild assignment with the new submission attached
        _assignment = Assignment(
          id: _assignment!.id,
          title: _assignment!.title,
          description: _assignment!.description,
          deadline: _assignment!.deadline,
          mySubmission: submission,
        );
        _status = AssignmentStatus.success;
        notifyListeners();
        return null;
      },
    );
  }

  void clearError() {
    _error = '';
    if (_status == AssignmentStatus.error) _status = AssignmentStatus.idle;
    notifyListeners();
  }

  String _cleanMessage(Failure f) =>
      f.message.replaceFirst('Exception: ', '');
}
