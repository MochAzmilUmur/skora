import 'dart:async';
import 'dart:convert';
import 'package:gal/gal.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/widgets/protected_screen.dart';
import '../../data/models/models.dart';
import '../../../ujian/presentation/screens/soal_management_screen.dart';
import '../../../ujian/presentation/screens/exam_session_screen.dart';
import '../../../ujian/presentation/screens/rekam_nilai_screen.dart';

class ExamRoomScreen extends StatefulWidget {
  final RoomModel room;

  const ExamRoomScreen({super.key, required this.room});

  @override
  State<ExamRoomScreen> createState() => _ExamRoomScreenState();
}

class _ExamRoomScreenState extends State<ExamRoomScreen> {
  bool _isLoading = false;
  List<RoomParticipantModel> _participants = [];
  int _questionsCount = 0;
  StreamSubscription<WebSocketMessage>? _wsSub;
  int? _currentUserId;
  // null = belum dicek, true/false = sudah ada sesi completed/timeout
  bool? _hasCompletedSession;

  String get _roomCode => widget.room.roomCode;

  /// True when the logged-in user is the one who created this room.
  bool get _isAsesor => _currentUserId != null && widget.room.createdBy == _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadData();
    _subscribeWs();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthStorageService.getCurrentUser();
    if (!mounted) return;
    setState(() => _currentUserId = user?.idUsers);
    // For peserta: check if they already have a completed/timeout session in this room
    if (user != null && widget.room.createdBy != user.idUsers) {
      _checkCompletedSession(user.idUsers);
    }
  }

  Future<void> _checkCompletedSession(int userId) async {
    try {
      final response = await ApiClient.get('/sesi-ujians?user_id=$userId');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        final done = list.any((e) {
          final roomId = e['room_id'] as String? ?? '';
          final status = e['status'] as String? ?? '';
          return roomId == widget.room.idRoom &&
              (status == 'completed' || status == 'timeout');
        });
        setState(() => _hasCompletedSession = done);
      }
    } catch (_) {
      // non-critical: default to allowing attempt if check fails
    }
  }  @override
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
          final body = jsonDecode(questionsRes.body) as Map<String, dynamic>;
          _questionsCount = (body['total'] as num?)?.toInt() ??
              (body['data'] as List?)?.length ??
              0;
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
          msg.type == WebSocketMessageType.examStarted ||
          msg.type == WebSocketMessageType.remidiRequest) {
        _loadData();
      }
    });
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: _roomCode));
    AppToast.showSuccess(context, 'Room code copied to clipboard');
  }

  void _showQRCode() {
    if (_roomCode.isEmpty) return;
    final screenshotController = ScreenshotController();

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
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: QrImageView(
                    // FIX: encode hanya roomCode, bukan format ROOM:id:code
                    data: _roomCode,
                    version: QrVersions.auto,
                    size: 250,
                    backgroundColor: Colors.white,
                  ),
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
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _roomCode));
                        AppToast.showSuccess(context, 'Room code copied!');
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadQRCode(context, screenshotController),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Unduh QR'),
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
            ],
          ),
        ),
      ),
    );
  }

Future<void> _downloadQRCode(
    BuildContext dialogContext,
    ScreenshotController screenshotController,
  ) async {
    try {
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) return;

      // Menyimpan gambar ke galeri menggunakan package 'gal'
      await Gal.putImageBytes(imageBytes, name: 'qr_room_$_roomCode');
      
      if (!mounted) return;
      
      // Jika berhasil, beri tahu pengguna
      AppToast.showSuccess(context, 'QR Code berhasil diunduh ke galeri!');
      Navigator.pop(dialogContext);
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menyimpan QR Code.');
    }
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
    AppToast.showInfo(context, 'Room settings - Coming soon');
  }

  void _manageQuestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SoalManagementScreen(room: widget.room),
      ),
    ).then((_) => _loadData());
  }

  void _viewRekamNilai() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RekamNilaiScreen(room: widget.room),
      ),
    );
  }

  /// Asesor: membuka sesi untuk peserta — asesor sendiri tidak mengerjakan ujian.
  void _startSession() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.play_circle_outline, color: Color(0xFF3B82F6), size: 26),
            SizedBox(width: 10),
            Text('Buka Sesi Ujian', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Sesi ujian sudah dibuka. Peserta yang terdaftar dapat mulai mengerjakan soal.\n\nAnda sebagai asesor tidak mengerjakan ujian ini.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Peserta: masuk ke halaman ujian.
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
    ).then((_) {
      // Re-check completed status when returning from exam
      if (mounted && _currentUserId != null) {
        _checkCompletedSession(_currentUserId!);
      }
    });
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
                  color: Colors.red.withValues(alpha: 0.2),
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
            if (_isAsesor)
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
                          if (_isAsesor) ...[
                            _buildRoomCode(),
                            const SizedBox(height: 24),
                          ],
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
            const Color(0xFF3B82F6).withValues(alpha: 0.8),
            const Color(0xFF8B5CF6).withValues(alpha: 0.8),
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
                color: Colors.white.withValues(alpha: 0.1),
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
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.white.withValues(alpha: 0.9),
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
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
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
    if (_isAsesor) {
      return _buildAsesorActions();
    }
    return _buildPesertaActions();
  }

  /// Full control for the room creator (asesor).
  Widget _buildAsesorActions() {
    final remidiPending = _participants
        .where((p) => p.status == 'remidi_pending')
        .toList();
    
    return Column(
      children: [
        if (remidiPending.isNotEmpty) ...[_buildRemidiPendingSection(), const SizedBox(height: 12)],
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startSession,
            icon: const Icon(Icons.play_arrow, size: 20),
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
    );
  }

  Widget _buildRemidiPendingSection() {
    final remidiPending = _participants
        .where((p) => p.status == 'remidi_pending')
        .toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Permintaan Remidi (${remidiPending.length})',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...remidiPending.map((p) => _buildRemidiRequestItem(p)),
        ],
      ),
    );
  }

  Widget _buildRemidiRequestItem(RoomParticipantModel participant) {
    final name = participant.user?.nama ?? 'User #${participant.userId}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Meminta remidi',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _approveRemidi(participant.userId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Setuju', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 32,
              child: OutlinedButton(
                onPressed: () => _denyRemidi(participant.userId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text('Tolak', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveRemidi(int userId) async {
    final res = await ApiClient.patch(
      '/rooms/${widget.room.idRoom}/participants/$userId/remidi',
      {'approved': true},
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      _loadData();
      AppToast.showSuccess(context, 'Remidi disetujui');
    } else {
      AppToast.showError(context, 'Gagal menyetujui remidi');
    }
  }

  Future<void> _denyRemidi(int userId) async {
    final res = await ApiClient.patch(
      '/rooms/${widget.room.idRoom}/participants/$userId/remidi',
      {'approved': false},
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      _loadData();
      AppToast.showWarning(context, 'Remidi ditolak');
    } else {
      AppToast.showError(context, 'Gagal menolak remidi');
    }
  }

  /// Peserta only sees "Mulai Ujian" or a "Selesai" banner if already done.
  Widget _buildPesertaActions() {
    // Still loading completion status
    if (_hasCompletedSession == null) {
      return const SizedBox(
        height: 52,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6), strokeWidth: 2)),
      );
    }

    // Already completed
    if (_hasCompletedSession == true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 22),
            SizedBox(width: 10),
            Text(
              'Ujian sudah diselesaikan',
              style: TextStyle(
                color: Colors.green,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Not yet taken
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _confirmStartSession,
        icon: const Icon(Icons.play_arrow, size: 20),
        label: const Text('Mulai Ujian'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
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
