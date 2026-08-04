import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/datasources/ujian_remote_datasource_impl.dart';
import '../../data/models/sesi_ujian_model.dart';
import '../../../room/data/models/websocket_message_model.dart';
import 'exam_session_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final _ds = UjianRemoteDataSourceImpl();
  List<SesiUjianModel> _sessions = [];
  // roomId -> participant status
  final Map<String, String> _participantStatus = {};
  bool _isLoading = false;
  String? _error;
  int? _userId;
  StreamSubscription<WebSocketMessage>? _wsSub;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribeWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().messageStream.listen((msg) {
      if (!mounted) return;
      if (msg.type == WebSocketMessageType.remidiReviewed) {
        final roomId = msg.data['room_id'] as String?;
        final approved = msg.data['approved'] as bool? ?? false;
        if (roomId != null) {
          setState(() => _participantStatus[roomId] =
              approved ? 'active' : 'remidi_denied');
        }
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = await AuthStorageService.getCurrentUser();
      if (user == null) return;
      _userId = user.idUsers;

      final sessions = await _ds.getSesiUjianByUser(user.idUsers);

      // Fetch participant status for each unique room
      final roomIds = sessions.map((s) => s.roomId).toSet();
      final statusMap = <String, String>{};
      await Future.wait(roomIds.map((roomId) async {
        try {
          final res = await ApiClient.get(
              '/rooms/$roomId/participants');
          if (res.statusCode == 200) {
            final list = jsonDecode(res.body) as List;
            for (final p in list) {
              if (p['user_id'] == user.idUsers) {
                statusMap[roomId] = p['status'] as String? ?? 'active';
                break;
              }
            }
          }
        } catch (_) {}
      }));

      if (mounted) {
        setState(() {
          _sessions = sessions;
          _participantStatus.addAll(statusMap);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestRemidi(String roomId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Minta Remidi',
            style: TextStyle(color: Colors.white)),
        content: const Text(
            'Kirim permintaan remidi kepada asesor? Kamu bisa mengerjakan ujian kembali jika disetujui.',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final res = await ApiClient.post('/rooms/$roomId/remidi', {});
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() => _participantStatus[roomId] = 'remidi_pending');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Permintaan remidi terkirim ke asesor'),
            backgroundColor: Colors.blue),
      );
    } else {
      final msg = jsonDecode(res.body)['error'] ?? 'Gagal mengirim permintaan';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _resumeSession(SesiUjianModel session) {
    final room = session.room;
    if (room == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSessionScreen(
          roomId: room.idRoom,
          roomName: room.roomName,
          durasiMenit: room.durasi,
          userId: session.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2942),
        title: const Text('Ujian Saya',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue))
          : _error != null
              ? _buildError()
              : _sessions.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final s = _sessions[i];
                          final pStatus =
                              _participantStatus[s.roomId] ?? 'active';
                          return _SessionCard(
                            session: s,
                            participantStatus: pStatus,
                            onResume: s.status == SesiUjianStatus.ongoing
                                ? () => _resumeSession(s)
                                : null,
                            onRequestRemidi: pStatus == 'completed'
                                ? () => _requestRemidi(s.roomId)
                                : null,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(_error!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined,
              size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('Belum ada ujian',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Bergabung ke room ujian untuk mulai mengerjakan',
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SesiUjianModel session;
  final String participantStatus;
  final VoidCallback? onResume;
  final VoidCallback? onRequestRemidi;

  const _SessionCard({
    required this.session,
    required this.participantStatus,
    this.onResume,
    this.onRequestRemidi,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (session.status) {
      SesiUjianStatus.ongoing => Colors.orange,
      SesiUjianStatus.completed => Colors.green,
      SesiUjianStatus.timeout => Colors.red,
    };
    final statusLabel = switch (session.status) {
      SesiUjianStatus.ongoing => 'Berlangsung',
      SesiUjianStatus.completed => 'Selesai',
      SesiUjianStatus.timeout => 'Timeout',
    };
    final roomName = session.room?.roomName ??
        'Room #${session.roomId.substring(0, 8)}';
    final date = session.startTime;

    // Participant status info
    final (pLabel, pColor, pIcon) = switch (participantStatus) {
      'completed' => ('Akses Selesai', Colors.grey, Icons.lock_outline),
      'remidi_pending' => (
          'Menunggu Persetujuan',
          Colors.orange,
          Icons.hourglass_empty
        ),
      'remidi_denied' => (
          'Remidi Ditolak',
          Colors.red,
          Icons.cancel_outlined
        ),
      _ => ('Aktif', Colors.green, Icons.check_circle_outline),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined,
                  color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(roomName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(statusLabel,
                    style:
                        TextStyle(color: statusColor, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  color: Colors.grey[600], size: 14),
              const SizedBox(width: 4),
              Text(
                '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              if (session.room != null) ...[
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined,
                    color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text('${session.room!.durasi} menit',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 12)),
              ],
            ],
          ),
          // Participant access status
          if (participantStatus != 'active') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(pIcon, color: pColor, size: 14),
                const SizedBox(width: 6),
                Text(pLabel,
                    style: TextStyle(
                        color: pColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ],
          // Action buttons
          if (onResume != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Lanjutkan Ujian'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          if (onRequestRemidi != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRequestRemidi,
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Minta Remidi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
          if (participantStatus == 'remidi_pending') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Menunggu persetujuan asesor...',
                      style: TextStyle(
                          color: Colors.orange, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
