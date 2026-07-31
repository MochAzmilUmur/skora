import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../data/datasources/ujian_remote_datasource_impl.dart';
import '../../data/models/hasil_ujian_model.dart';
import '../../data/models/sesi_ujian_model.dart';
import 'exam_result_screen.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _ds = UjianRemoteDataSourceImpl();
  List<HasilUjianModel> _results = [];
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

      // Fetch all sessions for user, then fetch hasil for completed ones
      final sessions = await _ds.getSesiUjianByUser(user.idUsers);
      final completed = sessions.where((s) =>
        s.status == SesiUjianStatus.completed || s.status == SesiUjianStatus.timeout,
      ).toList();

      final results = <HasilUjianModel>[];
      for (final s in completed) {
        try {
          final hasil = await _ds.getHasilUjian(s.id);
          results.add(hasil);
        } catch (_) {
          // session completed but hasil not yet calculated — skip
        }
      }

      if (mounted) setState(() => _results = results);
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
        title: const Text('Hasil Ujian', style: TextStyle(color: Colors.white)),
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
              : _results.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _ResultCard(
                          hasil: _results[i],
                          onTap: () => _openDetail(_results[i]),
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
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('Belum ada hasil ujian', style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Selesaikan ujian untuk melihat hasilnya di sini', style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  void _openDetail(HasilUjianModel hasil) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamResultScreen(hasil: hasil),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final HasilUjianModel hasil;
  final VoidCallback onTap;

  const _ResultCard({required this.hasil, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final passed = hasil.isPassed;
    final statusColor = passed ? Colors.green : Colors.red;
    final roomName = hasil.sesiUjian?.room?.roomName ?? 'Ujian #${hasil.sessionId}';
    final date = hasil.sesiUjian?.startTime;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2942),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
        ),
        child: Row(
          children: [
            // Score circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: Center(
                child: Text(
                  '${hasil.skor.toStringAsFixed(0)}',
                  style: TextStyle(color: statusColor, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(roomName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 13),
                      const SizedBox(width: 3),
                      Text('${hasil.jawabanBenar} benar', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                      const SizedBox(width: 10),
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 13),
                      const SizedBox(width: 3),
                      Text('${hasil.jawabanSalah} salah', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                  if (date != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(passed ? 'LULUS' : 'TIDAK LULUS', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
