import 'package:flutter/material.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../features/auth/data/models/models.dart';
import 'feedback_screen.dart';

class ExamResultScreen extends StatelessWidget {
  final HasilUjianModel hasil;

  const ExamResultScreen({Key? key, required this.hasil}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final passed = hasil.isPassed;
    final scoreColor = passed ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Result badge
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 3),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        passed ? Icons.emoji_events : Icons.refresh,
                        color: scoreColor,
                        size: 40,
                      ),
                      Text(
                        '${hasil.skor.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                passed ? 'Selamat! Anda Lulus' : 'Belum Lulus',
                style: TextStyle(
                  color: scoreColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                passed
                    ? 'Anda berhasil melewati batas kelulusan.'
                    : 'Terus berlatih untuk meningkatkan nilai Anda.',
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Stats cards
              Row(
                children: [
                  _StatCard(
                    label: 'Total Soal',
                    value: '${hasil.totalQuestions}',
                    icon: Icons.quiz_outlined,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Benar',
                    value: '${hasil.jawabanBenar}',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Salah',
                    value: '${hasil.jawabanSalah}',
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Score bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Skor Anda',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 14)),
                        Text(
                          '${hasil.skor.toStringAsFixed(1)} / 100',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hasil.skor / 100,
                        backgroundColor: const Color(0xFF334155),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Batas Lulus: 60',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 12)),
                        Text(
                          passed ? '✓ LULUS' : '✗ TIDAK LULUS',
                          style: TextStyle(
                            color: scoreColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Buka feedback — asesorId dari createdBy room
                    final asesorId =
                        hasil.sesiUjian?.room?.createdBy ?? 0;
                    final currentUser =
                        await AuthStorageService.getCurrentUser();
                    if (currentUser == null) return;
                    // ignore: use_build_context_synchronously
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FeedbackScreen(
                          hasil: hasil,
                          pesertaNama: currentUser.nama,
                          asesorId: asesorId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.feedback_outlined),
                  label: const Text('Lihat Feedback Asesor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context)
                        .popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Kembali ke Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
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
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
