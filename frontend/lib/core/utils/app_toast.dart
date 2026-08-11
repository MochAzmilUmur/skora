import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Toast type variants.
enum ToastType { success, error, warning, info }

/// Global top-floating toast utility (Flushbar/Toast style).
/// Usage:
///   AppToast.showSuccess(context, 'Data berhasil disimpan');
///   AppToast.showError(context, 'Gagal memuat data');
///   AppToast.showApiError(context, apiResponseJson);
class AppToast {
  static OverlayEntry? _activeEntry;
  static Timer? _activeTimer;

  /// Show success toast with soothing emerald green theme.
  static void showSuccess(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: ToastType.success,
      duration: duration,
    );
  }

  /// Show error toast with clear validation/error details.
  static void showError(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: ToastType.error,
      duration: duration,
    );
  }

  /// Show warning toast with amber theme.
  static void showWarning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: ToastType.warning,
      duration: duration,
    );
  }

  /// Show info toast with blue theme.
  static void showInfo(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      title: title,
      type: ToastType.info,
      duration: duration,
    );
  }

  /// Convenience method to parse and show errors returned from Golang API responses.
  /// Accepts Map, String, Exception, or dynamic errors.
  static void showApiError(
    BuildContext context,
    dynamic error, {
    String fallbackMessage = 'Terjadi kendala pada koneksi server',
    String? title,
  }) {
    String message = fallbackMessage;

    if (error is Map) {
      if (error.containsKey('error') && error['error'] != null) {
        message = error['error'].toString();
      } else if (error.containsKey('message') && error['message'] != null) {
        message = error['message'].toString();
      } else if (error.containsKey('details') && error['details'] != null) {
        message = error['details'].toString();
      }
    } else if (error is String && error.trim().isNotEmpty) {
      message = error;
    } else if (error != null) {
      final str = error.toString();
      if (str.startsWith('Exception: ')) {
        message = str.substring(11);
      } else {
        message = str;
      }
    }

    showError(
      context,
      message,
      title: title ?? 'Gagal Memproses Permintaan',
    );
  }

  /// Programmatically dismiss current active toast.
  static void dismiss() {
    _activeTimer?.cancel();
    _activeTimer = null;

    if (_activeEntry != null) {
      _activeEntry?.remove();
      _activeEntry = null;
    }
  }

  static void _show(
    BuildContext context, {
    required String message,
    required ToastType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Dismiss any active toast immediately to avoid overlap
    dismiss();

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (overlayContext) => _ToastWidget(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: () {
          if (_activeEntry == entry) {
            dismiss();
          }
        },
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODERN GLASSMORPHISM TOP-FLOATING TOAST WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ToastWidget extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _scaleAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnim = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _timer = Timer(widget.duration, _dismissWithAnimation);
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _ToastConfig.from(widget.type);
    final topPadding = MediaQuery.of(context).padding.top + 14;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Material(
              color: Colors.transparent,
              child: Dismissible(
                key: ValueKey(widget.message + widget.type.toString()),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: config.backgroundColor.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: config.accentColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: config.accentColor.withValues(alpha: 0.15),
                            blurRadius: 16,
                            spreadRadius: -2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Icon badge
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: config.accentColor.withValues(alpha: 0.16),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: config.accentColor.withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    config.icon,
                                    color: config.accentColor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title & Message
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.title ?? config.defaultTitle,
                                        style: TextStyle(
                                          color: config.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        widget.message,
                                        style: const TextStyle(
                                          color: Color(0xFFF1F5F9),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 8),

                                // Close button
                                InkWell(
                                  onTap: _dismissWithAnimation,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Color(0xFF94A3B8),
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Animated progress timer bar
                          _ProgressBar(
                            duration: widget.duration,
                            color: config.accentColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;

  const _ProgressBar({
    required this.duration,
    required this.color,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            height: 2.5,
            width: MediaQuery.of(context).size.width * (1.0 - _anim.value),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.8),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ToastConfig {
  final Color backgroundColor;
  final Color accentColor;
  final IconData icon;
  final String defaultTitle;

  const _ToastConfig({
    required this.backgroundColor,
    required this.accentColor,
    required this.icon,
    required this.defaultTitle,
  });

  factory _ToastConfig.from(ToastType type) {
    return switch (type) {
      ToastType.success => const _ToastConfig(
          backgroundColor: Color(0xFF064E3B), // Emerald dark background
          accentColor: Color(0xFF10B981),     // Modern emerald green
          icon: Icons.check_circle_rounded,
          defaultTitle: 'BERHASIL',
        ),
      ToastType.error => const _ToastConfig(
          backgroundColor: Color(0xFF451A1A), // Crimson dark background
          accentColor: Color(0xFFEF4444),     // Modern rose/coral red
          icon: Icons.error_rounded,
          defaultTitle: 'GAGAL',
        ),
      ToastType.warning => const _ToastConfig(
          backgroundColor: Color(0xFF38240D), // Dark amber background
          accentColor: Color(0xFFF59E0B),     // Warm amber yellow
          icon: Icons.warning_rounded,
          defaultTitle: 'PERINGATAN',
        ),
      ToastType.info => const _ToastConfig(
          backgroundColor: Color(0xFF0F294A), // Dark sapphire blue background
          accentColor: Color(0xFF3B82F6),     // Electric blue
          icon: Icons.info_rounded,
          defaultTitle: 'INFORMASI',
        ),
    };
  }
}

