import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../data/datasources/ujian_remote_datasource_impl.dart';
import '../../data/models/sesi_ujian_model.dart';
import 'exam_session_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final _ds = UjianRemoteDataSourceImpl();
  List<SesiUjianModel> _sessions = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final user = await AuthStorageService.getCurrentUser();
      if (user == null) return;
      final sessions = await _ds.getSesiUjianByUser(user.idUsers);
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2942),
        title: const Text('Ujian Saya', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _error != null
              ? _buildError()
              : _sessions.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _SessionCard(
                          session: _sessions[i],
                          onResume: () => _resumeSession(_sessions[i]),
                        ),
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
          Text(_error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('Belum ada ujian', style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Bergabung ke room ujian untuk mulai mengerjakan', style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _resumeSession(SesiUjianModel session) {
    if (session.status != SesiUjianStatus.ongoing) return;
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
}

class _SessionCard extends StatelessWidget {
  final SesiUjianModel session;
  final VoidCallback onResume;

  const _SessionCard({required this.session, required this.onResume});

  @override
  Widget build(BuildContext context) {
    final isOngoing = session.status == SesiUjianStatus.ongoing;
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
    final roomName = session.room?.roomName ?? 'Room #${session.roomId.substring(0, 8)}';
    final date = session.startTime;

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
              Icon(Icons.assignment_outlined, color: statusColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 14),
              const SizedBox(width: 4),
              Text(
                '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              if (session.room != null) ...[ 
                const SizedBox(width: 16),
                Icon(Icons.timer_outlined, color: Colors.grey[600], size: 14),
                const SizedBox(width: 4),
                Text('${session.room!.durasi} menit', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ],
          ),
          if (isOngoing) ...[
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
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
