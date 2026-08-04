import 'package:flutter/material.dart';
import '../../data/models/room_model.dart';
import 'create_exam_room_screen.dart';

/// Step 1 of room creation: pick the exam type.
/// Navigated to from the dashboard; pushes CreateExamRoomScreen with the chosen type.
class RoomTypePickerScreen extends StatelessWidget {
  const RoomTypePickerScreen({super.key});

  static const _types = [
    _RoomTypeInfo(
      type: RoomType.pilihanGanda,
      label: 'Pilihan Ganda',
      description: 'Ujian teori pilihan ganda. Durasi pendek — hitungan menit.',
      icon: Icons.quiz_outlined,
      accent: Color(0xFF3B82F6),
      durationHint: '30 – 180 menit',
      tags: ['MCQ', 'Auto-graded', 'Timer'],
    ),
    _RoomTypeInfo(
      type: RoomType.hybrid,
      label: 'Hybrid',
      description: 'Kombinasi pilihan ganda dan essay. Durasi pendek hingga menengah.',
      icon: Icons.merge_type_outlined,
      accent: Color(0xFF8B5CF6),
      durationHint: '60 – 180 menit',
      tags: ['MCQ + Essay', 'Mixed', 'Timer'],
    ),
    _RoomTypeInfo(
      type: RoomType.praktikum,
      label: 'Praktikum',
      description: 'Ujian praktik dengan upload file. Deadline bisa berhari-hari hingga berbulan-bulan.',
      icon: Icons.upload_file_outlined,
      accent: Color(0xFF10B981),
      durationHint: 'Hari / Minggu / Bulan',
      tags: ['File Upload', 'Deadline', 'Long-term'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pilih Tipe Exam',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Setiap tipe memiliki konfigurasi yang berbeda.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, i) => _TypeCard(
                    info: _types[i],
                    onTap: () => _proceed(context, _types[i].type),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceed(BuildContext context, RoomType type) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateExamRoomScreen(roomType: type),
      ),
    );
    // Bubble true back to dashboard so it can refresh
    if (result == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _RoomTypeInfo {
  final RoomType type;
  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final String durationHint;
  final List<String> tags;

  const _RoomTypeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    required this.durationHint,
    required this.tags,
  });
}

class _TypeCard extends StatelessWidget {
  final _RoomTypeInfo info;
  final VoidCallback onTap;

  const _TypeCard({required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: info.accent.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: info.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(info.icon, color: info.accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        info.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_ios, color: info.accent, size: 14),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    info.description,
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  // Duration hint
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, color: Color(0xFF64748B), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        info.durationHint,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: info.tags
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: info.accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  color: info.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
