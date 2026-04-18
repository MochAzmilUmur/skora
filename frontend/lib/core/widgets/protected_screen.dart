import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import '../services/screen_protection_service.dart';

/// Wrapper widget untuk screen yang memerlukan screen protection
/// Otomatis enable protection saat screen dibuka dan disable saat ditutup
class ProtectedScreen extends StatefulWidget {
  final Widget child;
  final bool enableScreenshotProtection;
  final bool enableDataLeakageProtection;
  final VoidCallback? onScreenshotDetected;

  const ProtectedScreen({
    Key? key,
    required this.child,
    this.enableScreenshotProtection = true,
    this.enableDataLeakageProtection = true,
    this.onScreenshotDetected,
  }) : super(key: key);

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> with WidgetsBindingObserver {
  final _screenProtection = ScreenProtectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableProtection();
    _setupScreenshotListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableProtection();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-enable protection when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _enableProtection();
    }
  }

  Future<void> _enableProtection() async {
    await _screenProtection.enableProtection();
  }

  Future<void> _disableProtection() async {
    await _screenProtection.disableProtection();
  }

  void _setupScreenshotListener() {
    // Listen for screenshot events (iOS only, Android blocks it)
    ScreenProtector.addListener(() {
      debugPrint('⚠️ Screenshot detected!');
      if (widget.onScreenshotDetected != null) {
        widget.onScreenshotDetected!();
      } else {
        _showWarningDialog();
      }
    }, (value) {
      // Second parameter for iOS screenshot callback
      debugPrint('⚠️ Screenshot detected on iOS!');
      if (widget.onScreenshotDetected != null) {
        widget.onScreenshotDetected!();
      } else {
        _showWarningDialog();
      }
    });
  }

  void _showWarningDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[400], size: 28),
            const SizedBox(width: 12),
            const Text(
              'Warning',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Screenshot and screen recording are not allowed during the exam session. This attempt has been logged.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
