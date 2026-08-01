import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/widgets/protected_screen.dart';
import '../../data/models/models.dart';
import '../../../ujian/presentation/screens/soal_management_screen.dart';
import '../../../ujian/presentation/screens/exam_session_screen.dart';
import '../../../ujian/presentation/screens/rekam_nilai_screen.dart';

class ExamRoomScreen extends StatefulWidget {
  final RoomModel room;

  const ExamRoomScreen({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  State<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends State<ExamRoomScreen> {
  bool _isLoading = false;
  List<RoomParticipantModel> _participants = [];
  int _questionsCount = 0;
  StreamSubscription<WebSocketMessage>? _wsSub;

  String get _roomCode => widget.room.roomCode;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeWs();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiClient.get('/rooms/${widget.room.idRoom}/participants'),
        ApiClient.get('/rooms/${widget.room.idRoom}/pertanyaans'),
      ]);
      if (!mounted) return;
      final participantsRes = results[0];
      final questionsRes = results[1];
      setState(() {
        if (participantsRes.statusCode == 200) {
          final list = jsonDecode(participantsRes.body) as List<dynamic>;
          _participants = list
              .map((e) => RoomParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (questionsRes.statusCode == 200) {
          final list = jsonDecode(questionsRes.body) as List<dynamic>;
          _questionsCount = list.length;
        }
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().messageStream.listen((msg) {
      if (!mounted) return;
      final data = msg.data;
      if (data['room_id'] != widget.room.idRoom) return;

      if (msg.type == WebSocketMessageType.participantJoined ||
          msg.type == WebSocketMessageType.examStarted) {
        _loadData();
      }
    });
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _roomCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showQRCode() {
    if (_roomCode.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Room QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: 'ROOM:${widget.room.idRoom}:$_roomCode',
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _roomCode,
                style: const TextStyle(
                  color: Color(0xFF3B82F6),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.room.roomName,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              const Text(
                'Students can scan this QR code to join the room',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room code copied!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Room Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewAllParticipants() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ParticipantListSheet(participants: _participants),
    );
  }

  void _openSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room settings - Coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _manageQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoalManagementScreen(room: widget.room),
      ),
    );
  }

  void _viewRekamNilai() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekamNilaiScreen(room: widget.room),
      ),
    );
  }

  void _startSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Start Exam Session',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to start the exam session? All waiting students will be able to begin.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmStartSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text('Start Session'),
          ),
        ],
      ),
    );
  }

  void _confirmStartSession() async {
    final user = await AuthStorageService.getCurrentUser();
    if (user == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamSessionScreen(
          roomId: widget.room.idRoom,
          roomName: widget.room.roomName,
          durasiMenit: widget.room.durasi,
          userId: user.idUsers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedScreen(
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              const Text(
                'Exam Room',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Protected',
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: _openSettings,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.blue),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderImage(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRoomInfo(),
                          const SizedBox(height: 24),
                          _buildStatsCards(),
                          const SizedBox(height: 24),
                          _buildRoomCode(),
                          const SizedBox(height: 24),
                          _buildParticipantsSection(),
                          const SizedBox(height: 24),
                          _buildRulesOfConduct(),
                          const SizedBox(height: 24),
                          _buildActionButtons(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3B82F6).withOpacity(0.8),
            const Color(0xFF8B5CF6).withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: 20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.room.roomName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              'Class 10-A • ${widget.room.user?.nama ?? 'Unknown'}',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatusChip(
              icon: Icons.access_time,
              label: 'Scheduled: 10:00 AM',
              color: Colors.green,
            ),
            const SizedBox(width: 12),
            _buildStatusChip(
              icon: Icons.lock_outline,
              label: 'Proctored',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.timer_outlined,
            label: 'Duration',
            value: '${widget.room.durasi}m',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.quiz_outlined,
            label: 'Questions',
            value: _questionsCount.toString(),
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            label: 'Peserta',
            value: _participants.length.toString(),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCode() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Entry Code',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _roomCode.isEmpty ? '---' : _roomCode,
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showQRCode,
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('QR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _copyRoomCode,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF334155),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Share this code with students to let them join the room.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    final count = _participants.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Participants',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: count > 0 ? _viewAllParticipants : null,
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: count > 0 ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  count == 0
                      ? 'Belum ada peserta'
                      : '$count Peserta Terdaftar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (count > 0)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF475569)),
                  ),
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRulesOfConduct() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rules of Conduct',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildRuleItem(
          icon: Icons.videocam_outlined,
          title: 'Camera Required',
          description: 'Your camera must be on throughout the entire session for proctoring.',
        ),
        const SizedBox(height: 12),
        _buildRuleItem(
          icon: Icons.tab_outlined,
          title: 'No Tab Switching',
          description: 'Leaving the exam window will be recorded and flagged to the assessor.',
        ),
        const SizedBox(height: 12),
        _buildRuleItem(
          icon: Icons.mic_off_outlined,
          title: 'Microphone Muted',
          description: 'Keep your microphone muted unless asked by the invigilator.',
        ),
      ],
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Kelola Soal button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _manageQuestions,
            icon: const Icon(Icons.quiz_outlined, size: 20),
            label: const Text('Kelola Soal'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Rekap Nilai button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewRekamNilai,
            icon: const Icon(Icons.bar_chart, size: 20),
            label: const Text('Rekap Nilai Peserta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF94A3B8),
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined, size: 20),
                label: const Text('Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFF334155)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.arrow_forward, size: 20),
                label: const Text('Start Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParticipantListSheet extends StatelessWidget {
  final List<RoomParticipantModel> participants;

  const _ParticipantListSheet({required this.participants});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                'Daftar Peserta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF334155)),
        Flexible(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: participants.length,
            itemBuilder: (_, i) {
              final p = participants[i];
              final name = p.user?.nama ?? 'User #${p.userId}';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF334155),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(
                  p.role.name,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
                trailing: Text(
                  '${p.joinedAt.hour.toString().padLeft(2, '0')}:${p.joinedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
