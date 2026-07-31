import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/features/auth/data/models/auth/user.dart';
import 'package:skora/features/profile/data/datasources/user_remote_datasource.dart';

enum ProfileStatus { idle, loading, saving, success, error }

class ProfileNotifier extends ChangeNotifier {
  final UserRemoteDataSource _ds;

  ProfileNotifier(this._ds);

  User? _user;
  ProfileStatus _status = ProfileStatus.idle;
  String _error = '';
  String _successMessage = '';

  User? get user => _user;
  ProfileStatus get status => _status;
  String get error => _error;
  String get successMessage => _successMessage;
  bool get isSaving => _status == ProfileStatus.saving;

  Future<void> load() async {
    _user = await AuthStorageService.getCurrentUser();
    notifyListeners();
    if (_user == null) return;

    // Refresh from server
    try {
      final fresh = await _ds.getUser(_user!.idUsers);
      // Preserve local role field since backend doesn't return it
      _user = fresh.copyWith(role: _user!.role);
      await AuthStorageService.updateCachedUser(_user!);
    } catch (_) {
      // Use cached if network fails — acceptable fallback
    }
    notifyListeners();
  }

  Future<bool> updateProfile({String? nama, String? email}) async {
    if (_user == null) return false;
    _status = ProfileStatus.saving;
    _error = '';
    notifyListeners();

    try {
      final updated = await _ds.updateProfile(
        userId: _user!.idUsers,
        nama: nama,
        email: email,
      );
      _user = updated.copyWith(role: _user!.role);
      await AuthStorageService.updateCachedUser(_user!);
      _status = ProfileStatus.success;
      _successMessage = 'Profil berhasil diperbarui';
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (_user == null) return false;
    _status = ProfileStatus.saving;
    _error = '';
    notifyListeners();

    try {
      await _ds.changePassword(
        userId: _user!.idUsers,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _status = ProfileStatus.success;
      _successMessage = 'Password berhasil diubah';
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _status = ProfileStatus.error;
      notifyListeners();
      return false;
    }
  }

  void clearStatus() {
    _status = ProfileStatus.idle;
    _error = '';
    _successMessage = '';
    notifyListeners();
  }

  /// Set role — persists to server AND cache.
  Future<bool> setRole(String role) async {
    if (_user == null) return false;
    _status = ProfileStatus.saving;
    notifyListeners();
    try {
      final updated = await _ds.updateRole(userId: _user!.idUsers, role: role);
      _user = updated;
      await AuthStorageService.updateCachedUser(_user!);
      _status = ProfileStatus.idle;
      notifyListeners();
      return true;
    } catch (e) {
      // Fallback: update locally so UI isn't stuck
      _user = _user!.copyWith(role: role);
      await AuthStorageService.updateCachedUser(_user!);
      _status = ProfileStatus.idle;
      notifyListeners();
      return false;
    }
  }

  bool _uploadingAvatar = false;
  bool get uploadingAvatar => _uploadingAvatar;

  Future<bool> uploadAvatar(File file) async {
    if (_user == null) return false;
    _uploadingAvatar = true;
    notifyListeners();
    try {
      final updated = await _ds.uploadAvatar(userId: _user!.idUsers, file: file);
      _user = updated;
      await AuthStorageService.updateCachedUser(_user!);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _uploadingAvatar = false;
      notifyListeners();
    }
  }
}
