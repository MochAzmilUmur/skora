import 'dart:async';
import 'package:flutter/material.dart';
import '../services/websocket_service.dart';
import '../../features/room/data/models/websocket_message_model.dart';

/// Wraps a child widget and shows an in-app toast when a WebSocket message arrives.
/// Place this high in the widget tree (e.g. wrapping Scaffold body or as a Stack layer).
class NotificationOverlay extends StatefulWidget {
  final Widget child;
  final WebSocketService wsService;

  const NotificationOverlay({
    super.key,
    required this.child,
    required this.wsService,
  });

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _sub;
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  String _title = '';
  String _body = '';
  WebSocketMessageType _type = WebSocketMessageType.notification;
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _sub = widget.wsService.messageStream.listen(_onMessage);
  }

  void _onMessage(WebSocketMessage msg) {
    if (!mounted) return;

    final notifs = widget.wsService.notifications;
    if (notifs.isEmpty) return;
    final latest = notifs.first;

    setState(() {
      _title = latest.title;
      _body = latest.body;
      _type = latest.type;
      _visible = true;
    });

    _animController.forward(from: 0);
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), _hide);
  }

  void _hide() {
    if (!mounted) return;
    _animController.reverse().then((_) {
      if (mounted) setState(() => _visible = false);
    });
  }

  Color _typeColor() {
    switch (_type) {
      case WebSocketMessageType.feedback:
        return const Color(0xFF3B82F6);
      case WebSocketMessageType.participantJoined:
        return const Color(0xFF10B981);
      case WebSocketMessageType.examStarted:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _typeIcon() {
    switch (_type) {
      case WebSocketMessageType.feedback:
        return Icons.comment_outlined;
      case WebSocketMessageType.participantJoined:
        return Icons.person_add_outlined;
      case WebSocketMessageType.examStarted:
        return Icons.play_circle_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_visible)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnim,
              child: _ToastCard(
                title: _title,
                body: _body,
                color: _typeColor(),
                icon: _typeIcon(),
                onDismiss: _hide,
              ),
            ),
          ),
      ],
    );
  }
}

class _ToastCard extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final IconData icon;
  final VoidCallback onDismiss;

  const _ToastCard({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Color(0xFF64748B), size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
