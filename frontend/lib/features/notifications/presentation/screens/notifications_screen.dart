import 'package:flutter/material.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../features/room/data/models/websocket_message_model.dart';

class NotificationsScreen extends StatefulWidget {
  final WebSocketService wsService;

  const NotificationsScreen({super.key, required this.wsService});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark all read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.wsService.markAllRead();
    });
  }

  Color _typeColor(WebSocketMessageType type) {
    switch (type) {
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

  IconData _typeIcon(WebSocketMessageType type) {
    switch (type) {
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

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.wsService,
      builder: (context, _) {
        final notifications = widget.wsService.notifications;
        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Notifikasi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            actions: [
              if (notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    widget.wsService.clearNotifications();
                  },
                  child: const Text(
                    'Hapus Semua',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ),
            ],
          ),
          body: notifications.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final n = notifications[i];
                    final color = _typeColor(n.type);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: n.isRead
                              ? const Color(0xFF334155)
                              : color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_typeIcon(n.type), color: color, size: 20),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            color: n.isRead
                                ? const Color(0xFF94A3B8)
                                : Colors.white,
                            fontWeight: n.isRead
                                ? FontWeight.normal
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(n.receivedAt),
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        trailing: n.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.notifications_none_outlined,
            size: 64,
            color: Color(0xFF334155),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Notifikasi real-time dari ujian akan muncul di sini.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
