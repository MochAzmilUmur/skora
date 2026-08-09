import 'dart:async';


import 'package:flutter/material.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/core/services/websocket_service.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'package:skora/features/feedback/data/datasources/feedback_remote_datasource_impl.dart';
import 'package:skora/features/feedback/data/repositories/feedback_repository_impl.dart';


class FeedbackScreen extends StatefulWidget {
  final HasilUjianModel hasil;
  final String pesertaNama;
  // asesorId diperlukan agar peserta tahu ke siapa membalas
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
    await _loadFeedback();
    _subscribeWs();
  }

  Future<void> _loadFeedback() async {
    setState(() => _loading = true);
    final result = await _repo.getFeedbackByHasil(widget.hasil.id);
    result.fold(
      (f) => setState(() => _loading = false),
      (list) => setState(() {
        _feedbacks = list.reversed.toList();
        _loading = false;
        // Resolve asesorId dari feedback yang ada jika widget.asesorId == 0
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
      if (data['hasil_id'] != null && data['hasil_id'] != widget.hasil.id) return;

      // Buat FeedbackModel dari WS payload dan tambahkan ke list
      try {
        final fb = FeedbackModel.fromJson({
          'id': data['feedback_id'] ?? 0,
          'hasil_id': widget.hasil.id,
          'asesor_id': data['asesor_id'] ?? widget.asesorId,
          'sender_id': data['sender_id'] ?? data['asesor_id'] ?? widget.asesorId,
          'komentar': data['komentar'] ?? '',
          'created_at': data['created_at'] ?? DateTime.now().toIso8601String(),
        });
        setState(() => _feedbacks.add(fb));
        _scrollToBottom();
      } catch (_) {}
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final komentar = _textCtrl.text.trim();
    if (komentar.isEmpty || _currentUserId == null) return;
    if (_resolvedAsesorId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Asesor belum diketahui, tunggu feedback pertama'),
            backgroundColor: Colors.orange),
      );
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
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: Colors.red),
      ),
      (fb) {
        _textCtrl.clear();
        setState(() => _feedbacks.add(fb));
        _scrollToBottom();
      },
    );
  }

  Future<void> _delete(FeedbackModel fb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Pesan', style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus pesan ini?',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await _repo.deleteFeedback(fb.id);
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: Colors.red),
      ),
      (_) => setState(
          () => _feedbacks = _feedbacks.where((e) => e.id != fb.id).toList()),
    );
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
            const Text('Feedback',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(widget.pesertaNama,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          _ScoreBanner(hasil: widget.hasil),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue))
                : _feedbacks.isEmpty
                    ? const Center(
                        child: Text('Belum ada pesan',
                            style: TextStyle(color: Color(0xFF64748B))),
                      )
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _feedbacks.length,
                        itemBuilder: (ctx, i) {
                          final fb = _feedbacks[i];
                          final isMine = fb.senderId == _currentUserId;
                          return _ChatBubble(
                            feedback: fb,
                            isMine: isMine,
                            onDelete: isMine ? () => _delete(fb) : null,
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

class _ScoreBanner extends StatelessWidget {
  final HasilUjianModel hasil;
  const _ScoreBanner({required this.hasil});

  @override
  Widget build(BuildContext context) {
    final passed = hasil.isPassed;
    final color = passed ? Colors.green : Colors.red;
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
                color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Text(
            '${hasil.jawabanBenar}/${hasil.totalQuestions} benar',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              passed ? 'Lulus' : 'Tidak Lulus',
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w500),
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

    // Nama pengirim — fallback aman tanpa RangeError
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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF334155),
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onDelete,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMine
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMine ? 14 : 2),
                    bottomRight: Radius.circular(isMine ? 2 : 14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          senderNama,
                          style: const TextStyle(
                              color: Color(0xFF60A5FA),
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    Text(
                      feedback.komentar,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 6),
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
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
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tulis pesan...',
                hintStyle: const TextStyle(color: Color(0xFF475569)),
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
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: sending
                    ? const Color(0xFF334155)
                    : const Color(0xFF1D4ED8),
                shape: BoxShape.circle,
              ),
              child: sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
