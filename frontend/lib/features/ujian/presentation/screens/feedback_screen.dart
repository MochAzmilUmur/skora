import 'package:flutter/material.dart';
import 'package:skora/core/services/auth_storage_service.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'package:skora/features/feedback/data/datasources/feedback_remote_datasource_impl.dart';
import 'package:skora/features/feedback/data/repositories/feedback_repository_impl.dart';

class FeedbackScreen extends StatefulWidget {
  final HasilUjianModel hasil;
  final String pesertaNama;

  const FeedbackScreen({
    super.key,
    required this.hasil,
    required this.pesertaNama,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _repo = FeedbackRepositoryImpl(
    remoteDataSource: FeedbackRemoteDataSourceImpl(),
  );
  final _textCtrl = TextEditingController();

  List<FeedbackModel> _feedbacks = [];
  bool _loading = true;
  bool _sending = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _currentUserId = await AuthStorageService.getUserId();
    await _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    setState(() => _loading = true);
    final result = await _repo.getFeedbackByHasil(widget.hasil.id);
    result.fold(
      (f) => setState(() => _loading = false),
      (list) => setState(() {
        _feedbacks = list;
        _loading = false;
      }),
    );
  }

  Future<void> _send() async {
    final komentar = _textCtrl.text.trim();
    if (komentar.isEmpty || _currentUserId == null) return;

    setState(() => _sending = true);
    final result = await _repo.sendFeedback(
      hasilId: widget.hasil.id,
      asesorId: _currentUserId!,
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
        setState(() => _feedbacks = [fb, ..._feedbacks]);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Feedback terkirim'),
              backgroundColor: Colors.green),
        );
      },
    );
  }

  Future<void> _delete(FeedbackModel fb) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Feedback',
            style: TextStyle(color: Colors.white)),
        content: const Text('Yakin ingin menghapus feedback ini?',
            style: TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
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
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Score summary banner
          _ScoreBanner(hasil: widget.hasil),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue))
                : _feedbacks.isEmpty
                    ? const Center(
                        child: Text(
                          'Belum ada feedback',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _feedbacks.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (ctx, i) =>
                            _FeedbackTile(
                          feedback: _feedbacks[i],
                          isOwner:
                              _feedbacks[i].asesorId == _currentUserId,
                          onDelete: () => _delete(_feedbacks[i]),
                        ),
                      ),
          ),
          // Input area
          _FeedbackInput(
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF1A2942),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Skor: ${hasil.skor.toStringAsFixed(1)}',
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 16),
          Text(
            '${hasil.jawabanBenar}/${hasil.totalQuestions} benar',
            style:
                const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          ),
          const Spacer(),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  final FeedbackModel feedback;
  final bool isOwner;
  final VoidCallback onDelete;
  const _FeedbackTile({
    required this.feedback,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final asesorNama =
        feedback.asesor?.nama ?? 'Asesor #${feedback.asesorId}';
    final dt = feedback.createdAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    asesorNama[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(asesorNama,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    Text(
                      '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Color(0xFF64748B), size: 18),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            feedback.komentar,
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _FeedbackInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  const _FeedbackInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A2942),
        border: Border(top: BorderSide(color: Color(0xFF334155))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Tulis feedback...',
                hintStyle:
                    const TextStyle(color: Color(0xFF475569)),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Colors.blue),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blue),
                  )
                : const Icon(Icons.send_rounded, color: Colors.blue),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.withValues(alpha: 0.12),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
