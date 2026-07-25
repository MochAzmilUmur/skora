import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/logger.dart';
import 'auth_storage_service.dart';
import '../../features/room/data/models/websocket_message_model.dart';

/// Represents an in-app notification entry stored in the notification list.
class AppNotification {
  final String id;
  final WebSocketMessageType type;
  final String title;
  final String body;
  final DateTime receivedAt;
  bool isRead;
  final Map<String, dynamic> data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
    required this.data,
  });
}

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

/// WebSocketService manages the single persistent WebSocket connection.
///
/// Lifecycle:
/// - Call [connect] once after login.
/// - Call [disconnect] on logout.
/// - Automatically reconnects with exponential backoff on unexpected disconnection.
/// - Broadcasts [WebSocketMessage] events through [messageStream].
class WebSocketService extends ChangeNotifier {
  static final WebSocketService _instance = WebSocketService._();
  factory WebSocketService() => _instance;
  WebSocketService._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;

  WsConnectionState _state = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _state;
  bool get isConnected => _state == WsConnectionState.connected;

  // In-app notification list (shown in dashboard bell)
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Stream for components that need to react to real-time events
  final _controller = StreamController<WebSocketMessage>.broadcast();
  Stream<WebSocketMessage> get messageStream => _controller.stream;

  int _reconnectAttempt = 0;
  static const int _maxReconnectDelay = 30; // seconds

  /// Connect using the stored JWT. No-op if already connected.
  Future<void> connect() async {
    if (_state == WsConnectionState.connected ||
        _state == WsConnectionState.connecting) return;

    final token = await AuthStorageService.getToken();
    final valid = await AuthStorageService.isTokenValid();
    if (token == null || !valid) {
      AppLogger.log('WS: no valid token, skipping connect', tag: 'WS');
      return;
    }

    _setState(WsConnectionState.connecting);

    final host = Platform.isAndroid ? '192.168.1.19' : 'localhost';
    final uri = Uri.parse('ws://$host:8080/ws?token=$token');

    AppLogger.log('WS: connecting to $uri', tag: 'WS');

    try {
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 20),
      );

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _setState(WsConnectionState.connected);
      _reconnectAttempt = 0;
      AppLogger.log('WS: connected', tag: 'WS');
    } catch (e) {
      AppLogger.error('WS: connect failed', tag: 'WS', error: e);
      _setState(WsConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final json = jsonDecode(raw as String) as Map<String, dynamic>;
      final msg = WebSocketMessage.fromJson(json);
      _controller.add(msg);
      _buildNotification(msg, json);
      notifyListeners();
    } catch (e) {
      AppLogger.error('WS: parse error', tag: 'WS', error: e);
    }
  }

  void _buildNotification(WebSocketMessage msg, Map<String, dynamic> json) {
    String title;
    String body;

    switch (msg.type) {
      case WebSocketMessageType.feedback:
        title = 'Feedback dari Asesor';
        body = json['komentar'] as String? ?? '';
      case WebSocketMessageType.participantJoined:
        final name = json['user_name'] as String? ?? 'Seseorang';
        final room = json['room_name'] as String? ?? '';
        title = 'Peserta Baru';
        body = '$name bergabung ke room "$room"';
      case WebSocketMessageType.examStarted:
        final name = json['user_name'] as String? ?? 'Peserta';
        final room = json['room_name'] as String? ?? '';
        title = 'Ujian Dimulai';
        body = '$name mulai mengerjakan ujian di room "$room"';
      case WebSocketMessageType.notification:
        title = json['title'] as String? ?? 'Notifikasi';
        body = json['body'] as String? ?? '';
      case WebSocketMessageType.unknown:
        return; // don't show unknown types
    }

    final notif = AppNotification(
      id: '${msg.type.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: msg.type,
      title: title,
      body: body,
      receivedAt: DateTime.now(),
      data: json,
    );
    _notifications.insert(0, notif);

    // Cap list at 50 entries
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }

  void _onError(Object error) {
    AppLogger.error('WS: stream error', tag: 'WS', error: error);
    _handleDisconnect();
  }

  void _onDone() {
    AppLogger.log('WS: connection closed', tag: 'WS');
    _handleDisconnect();
  }

  void _handleDisconnect() {
    _sub?.cancel();
    _channel = null;
    _setState(WsConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() async {
    final valid = await AuthStorageService.isTokenValid();
    if (!valid) return; // don't reconnect if token expired / logged out

    _reconnectAttempt++;
    // Exponential backoff: 2, 4, 8, 16, 30 seconds
    final delay = Duration(
      seconds: (_maxReconnectDelay < (2 << _reconnectAttempt))
          ? _maxReconnectDelay
          : (2 << _reconnectAttempt),
    );
    AppLogger.log(
      'WS: reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempt)',
      tag: 'WS',
    );
    _setState(WsConnectionState.reconnecting);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  /// Gracefully disconnect. Call on logout.
  void disconnect() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _reconnectAttempt = 0;
    _setState(WsConnectionState.disconnected);
    AppLogger.log('WS: disconnected by user', tag: 'WS');
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      notifyListeners();
    }
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void _setState(WsConnectionState s) {
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _controller.close();
    super.dispose();
  }
}
