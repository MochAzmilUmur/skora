import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skora/core/network/api_client.dart';
import 'package:skora/core/utils/app_toast.dart';
import 'package:skora/core/utils/logger.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/core/services/websocket_service.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'package:skora/features/feedback/data/datasources/feedback_remote_datasource_impl.dart';
import 'package:skora/features/feedback/data/repositories/feedback_repository_impl.dart';

/// Screen for real-time feedback conversation between Peserta (Student) and Asesor.
/// Messages are displayed in WhatsApp style:
/// - Oldest messages at top
/// - Newest messages at bottom
/// - Auto-scroll to bottom on opening & sending new messages
class FeedbackScreen extends StatefulWidget {
  final HasilUjianModel hasil;
  final String pesertaNama;
  final int asesorId;

  const FeedbackScreen({
    super.key,
    required this.hasil,
    required this.pesertaNama,
    required this.asesorId,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = FeedbackRepositoryImpl(
    remoteDataSource: FeedbackRemoteDataSourceImpl(),
  );
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<FeedbackModel> _feedbacks = [];
  bool _loading = true;
  bool _sending = false;
  int? _currentUserId;
  int _resolvedAsesorId = 0;
  StreamSubscription<WebSocketMessage>? _wsSub;

  @override
  void initState() {
    super.initState();
    _resolvedAsesorId = widget.asesorId;
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await AuthStorageService.getUserId();

    // Ensure WebSocket is connected for real-time feedback
    final ws = WebSocketService();
    if (!ws.isConnected) {
      ws.connect();
    }

    // Try resolving asesorId from widget properties
    final createdBy = widget.hasil.sesiUjian?.room?.createdBy;
    if (_resolvedAsesorId == 0 && createdBy != null) {
      _resolvedAsesorId = createdBy;
    }

    await _loadFeedback();
    _subscribeWs();

    // If _resolvedAsesorId is STILL 0, fetch sesiUjian details from API automatically
    if (_resolvedAsesorId == 0) {
      await _fetchAsesorIdFromSesi();
    }
  }

  Future<void> _fetchAsesorIdFromSesi() async {
    try {
      final response = await ApiClient.get('/sesi-ujians/${widget.hasil.sessionId}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['room'] != null && data['room']['created_by'] != null) {
          final createdBy = (data['room']['created_by'] as num).toInt();
          if (createdBy > 0 && mounted) {
            setState(() => _resolvedAsesorId = createdBy);
            AppLogger.log('Auto-resolved asesorId: $createdBy', tag: 'FeedbackScreen');
          }
        }
      }
    } catch (e) {
      AppLogger.error('Failed to fetch asesorId from sesi', tag: 'FeedbackScreen', error: e);
    }
  }

  Future<void> _loadFeedback() async {
    setState(() => _loading = true);
    final result = await _repo.getFeedbackByHasil(widget.hasil.id);
    result.fold(
      (f) => setState(() => _loading = false),
      (list) => setState(() {
        // Sort chronologically ascending (oldest first -> newest at bottom like WhatsApp)
        final sortedList = List<FeedbackModel>.from(list)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        _feedbacks = sortedList;
        _loading = false;

        if (_resolvedAsesorId == 0 && list.isNotEmpty) {
          _resolvedAsesorId = list.first.asesorId;
        }
      }),
    );
    _scrollToBottom();
  }

  void _subscribeWs() {
    _wsSub = WebSocketService().messageStream.listen((msg) {
      if (!mounted) return;
      if (msg.type != WebSocketMessageType.feedback) return;
      final data = msg.data;

      // Filter: ignore if payload specifies a different hasil_id
      final msgHasilId = data['hasil_id'] as int?;
      if (msgHasilId != null && msgHasilId != widget.hasil.id) return;

      final fbId = data['feedback_id'] ?? data['id'] ?? 0;
      // Prevent duplicate rendering if already added
      if (fbId != 0 && _feedbacks.any((e) => e.id == fbId)) return;

      try {
        final fb = FeedbackModel.fromJson({
          'id': fbId,
          'hasil_id': widget.hasil.id,
          'asesor_id': data['asesor_id'] ?? _resolvedAsesorId,
          'sender_id': data['sender_id'] ?? data['asesor_id'] ?? _resolvedAsesorId,
          'komentar': data['komentar'] ?? '',
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        });

        setState(() {
          _feedbacks.add(fb);
          // If asesor_id was unknown, update it from incoming WS message
          if (_resolvedAsesorId == 0 && fb.asesorId > 0) {
            _resolvedAsesorId = fb.asesorId;
          }
        });
        _scrollToBottom();
      } catch (e) {
        AppLogger.error('Failed to parse WS feedback', tag: 'FeedbackScreen', error: e);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final komentar = _textCtrl.text.trim();
    if (komentar.isEmpty || _currentUserId == null) return;

    // If asesorId is still 0, try resolving it once more from API before proceeding
    if (_resolvedAsesorId == 0) {
      await _fetchAsesorIdFromSesi();
    }

    if (_resolvedAsesorId == 0) {
      AppToast.showWarning(context, 'Tidak dapat mengidentifikasi Asesor untuk room ujian ini');
      return;
    }

    setState(() => _sending = true);
    final result = await _repo.sendFeedback(
      hasilId: widget.hasil.id,
      asesorId: _resolvedAsesorId,
      senderId: _currentUserId!,
      komentar: komentar,
    );
    if (!mounted) return;
    setState(() => _sending = false);

    result.fold(
      (f) => AppToast.showError(context, f.message),
      (fb) {
        _textCtrl.clear();
        setState(() {
          // Avoid duplicate if WS already added it
          if (!_feedbacks.any((e) => e.id == fb.id && fb.id != 0)) {
            _feedbacks.add(fb);
          }
        });
        _scrollToBottom();
      },
    );
  }

  Future<void> _delete(FeedbackModel fb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Pesan', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus pesan ini?',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await _repo.deleteFeedback(fb.id);
    if (!mounted) return;
    result.fold(
      (f) => AppToast.showError(context, f.message),
      (_) => setState(
          () => _feedbacks = _feedbacks.where((e) => e.id != fb.id).toList()),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Hari ini';
    } else if (targetDate == yesterday) {
      return 'Kemarin';
    } else {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2942),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feedback Pelajar & Asesor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.pesertaNama,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ScoreBanner(hasil: widget.hasil),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _feedbacks.isEmpty
                    ? const _EmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        itemCount: _feedbacks.length,
                        itemBuilder: (ctx, i) {
                          final fb = _feedbacks[i];
                          final isMine = fb.senderId == _currentUserId;

                          final showDateHeader = i == 0 ||
                              !_isSameDay(_feedbacks[i - 1].createdAt, fb.createdAt);

                          return Column(
                            key: ValueKey(fb.id),
                            children: [
                              if (showDateHeader)
                                _DateHeader(
                                  dateText: _formatDateHeader(fb.createdAt),
                                ),
                              _ChatBubble(
                                feedback: fb,
                                isMine: isMine,
                                onDelete: isMine ? () => _delete(fb) : null,
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _ChatInput(
            controller: _textCtrl,
            sending: _sending,
            onSend: _send,
          ),
        ],
      ),
    );
  }
}

// ── SUB WIDGETS ─────────────────────────────────────────────────────────────

class _ScoreBanner extends StatelessWidget {
  final HasilUjianModel hasil;
  const _ScoreBanner({required this.hasil});

  @override
  Widget build(BuildContext context) {
    final passed = hasil.isPassed;
    final color = passed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: const Color(0xFF1A2942),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Skor: ${hasil.skor.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${hasil.jawabanBenar}/${hasil.totalQuestions} benar',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              passed ? 'Lulus' : 'Tidak Lulus',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String dateText;
  const _DateHeader({required this.dateText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF334155),
              width: 0.8,
            ),
          ),
          child: Text(
            dateText,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF64748B),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada pesan feedback',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mulai percakapan antara Pelajar dan Asesor di sini',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final FeedbackModel feedback;
  final bool isMine;
  final VoidCallback? onDelete;

  const _ChatBubble({
    required this.feedback,
    required this.isMine,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dt = feedback.createdAt;
    final timeStr =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    final senderNama = feedback.sender?.nama.trim().isNotEmpty == true
        ? feedback.sender!.nama
        : feedback.asesor?.nama.trim().isNotEmpty == true
            ? feedback.asesor!.nama
            : isMine
                ? 'Saya'
                : 'Asesor';
    final initial =
        senderNama.isNotEmpty ? senderNama[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF334155),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMine
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMine ? 16 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 16),
                  ),
                  border: Border.all(
                    color: isMine
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF334155),
                    width: 0.8,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x20000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          senderNama,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Text(
                      feedback.komentar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.done_all_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2942),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tulis feedback...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sending
                    ? const Color(0xFF334155)
                    : const Color(0xFF1D4ED8),
                shape: BoxShape.circle,
                boxShadow: sending
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x401D4ED8),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

