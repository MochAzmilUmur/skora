import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:skora/core/network/api_client.dart';
import 'package:skora/features/auth/data/models/models.dart';
import 'package:skora/features/room/data/models/room_model.dart';
import 'feedback_screen.dart';

class RekamNilaiScreen extends StatefulWidget {
  final RoomModel room;
  const RekamNilaiScreen({super.key, required this.room});

  @override
  State<RekamNilaiScreen> createState() => _RekamNilaiScreenState();
}

class _RekamNilaiScreenState extends State<RekamNilaiScreen> {
  List<HasilUjianModel> _hasils = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ApiClient.get('/rooms/${widget.room.idRoom}/hasil');
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        setState(() {
          _hasils = list.map((e) => HasilUjianModel.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal memuat data (${response.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Stats helpers
  int get _total => _hasils.length;
  int get _lulus => _hasils.where((h) => h.isPassed).length;
  double get _avgSkor =>
      _total == 0 ? 0 : _hasils.fold(0.0, (s, h) => s + h.skor) / _total;
  double get _passRate => _total == 0 ? 0 : _lulus / _total * 100;

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
            const Text('Rekap Nilai',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(widget.room.roomName,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blue))
          : _error != null
              ? _buildError()
              : _hasils.isEmpty
                  ? _buildEmpty()
                  : _buildContent(),
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
              style: const TextStyle(color: Color(0xFF94A3B8))),
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
          const Icon(Icons.inbox_outlined,
              color: Color(0xFF334155), size: 64),
          const SizedBox(height: 16),
          const Text('Belum ada peserta yang menyelesaikan ujian',
              style: TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('Nama Peserta',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                  const Spacer(),
                  const Text('Skor',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(width: 60),
                  const Text('Status',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildRow(_hasils[i]),
              childCount: _hasils.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatTile(
                  label: 'Peserta',
                  value: '$_total',
                  icon: Icons.people_outline,
                  color: Colors.blue),
              const SizedBox(width: 10),
              _StatTile(
                  label: 'Lulus',
                  value: '$_lulus',
                  icon: Icons.check_circle_outline,
                  color: Colors.green),
              const SizedBox(width: 10),
              _StatTile(
                  label: 'Tidak Lulus',
                  value: '${_total - _lulus}',
                  icon: Icons.cancel_outlined,
                  color: Colors.red),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2942),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rata-rata Nilai',
                        style: TextStyle(
                            color: Color(0xFF94A3B8), fontSize: 13)),
                    Text(
                      _avgSkor.toStringAsFixed(1),
                      style: TextStyle(
                        color: _avgSkor >= 60 ? Colors.green : Colors.orange,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _avgSkor / 100,
                    backgroundColor: const Color(0xFF334155),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _avgSkor >= 60 ? Colors.green : Colors.orange),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pass Rate: ${_passRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12)),
                    const Text('Batas Lulus: 60',
                        style: TextStyle(
                            color: Color(0xFF64748B), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(HasilUjianModel hasil) {
    final passed = hasil.isPassed;
    final pesertaNama =
        hasil.sesiUjian?.user?.nama ?? 'Peserta #${hasil.sessionId}';
    final pesertaEmail = hasil.sesiUjian?.user?.email ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: passed ? Colors.green : Colors.red,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar initial
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Center(
              child: Text(
                pesertaNama.isNotEmpty ? pesertaNama[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pesertaNama,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14)),
                if (pesertaEmail.isNotEmpty)
                  Text(pesertaEmail,
                      style: const TextStyle(
                          color: Color(0xFF64748B), fontSize: 11)),
              ],
            ),
          ),
          // Score
          Text(
            hasil.skor.toStringAsFixed(0),
            style: TextStyle(
              color: passed ? Colors.green : Colors.red,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: passed
                  ? Colors.green.withValues(alpha: 0.12)
                  : Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: passed
                      ? Colors.green.withValues(alpha: 0.5)
                      : Colors.red.withValues(alpha: 0.5)),
            ),
            child: Text(
              passed ? 'Lulus' : 'Tidak',
              style: TextStyle(
                  color: passed ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 4),
          // Feedback button
          IconButton(
            icon: const Icon(Icons.feedback_outlined,
                color: Color(0xFF64748B), size: 18),
            tooltip: 'Beri Feedback',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FeedbackScreen(
                  hasil: hasil,
                  pesertaNama: pesertaNama,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2942),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
