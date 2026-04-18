import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenProtectionService {
  static final ScreenProtectionService _instance = ScreenProtectionService._internal();
  factory ScreenProtectionService() => _instance;
  ScreenProtectionService._internal();

  bool _isProtectionEnabled = false;

  /// Enable screen protection (prevent screenshot and screen recording)
  Future<void> enableProtection() async {
    if (_isProtectionEnabled) return;

    try {
      // Prevent screenshots
      await ScreenProtector.protectDataLeakageOn();
      
      // Prevent screen recording (Android only)
      if (Platform.isAndroid) {
        await ScreenProtector.preventScreenshotOn();
      }
      
      debugPrint('✅ Screen protection enabled');
      _isProtectionEnabled = true;
    } catch (e) {
      debugPrint('❌ Error enabling screen protection: $e');
    }
  }

  /// Disable screen protection (allow screenshot and screen recording)
  Future<void> disableProtection() async {
    if (!_isProtectionEnabled) return;

    try {
      // Allow screenshots
      await ScreenProtector.protectDataLeakageOff();
      
      // Allow screen recording
      if (Platform.isAndroid) {
        await ScreenProtector.preventScreenshotOff();
      }
      
      debugPrint('✅ Screen protection disabled');
      _isProtectionEnabled = false;
    } catch (e) {
      debugPrint('❌ Error disabling screen protection: $e');
    }
  }

  /// Check if protection is currently enabled
  bool get isProtectionEnabled => _isProtectionEnabled;
}
