import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/data/models/models.dart';
import '../../../../features/ujian/data/datasources/ujian_remote_datasource_impl.dart';
import '../../../../features/ujian/data/repositories/ujian_repository_impl.dart';
import '../providers/soal_notifier.dart';
import 'soal_form_screen.dart';

/// Entry point: wraps the screen with its own ChangeNotifierProvider
/// so the notifier's lifecycle matches the screen.
class SoalManagementScreen extends StatelessWidget {
  final RoomModel room;

  const SoalManagementScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SoalNotifier(
        UjianRepositoryImpl(
          remoteDataSource: UjianRemoteDataSourceImpl(),
        ),
      )..loadSoal(room.idRoom),
      child: _SoalManagementBody(room: room),
    );
  }
}

class _SoalManagementBody extends StatefulWidget {
  final RoomModel room;
  const _SoalManagementBody({required this.room});

  @override
  State<_SoalManagementBody> createState() => _SoalManagementBodyState();
}

class _SoalManagementBodyState extends State<_SoalManagementBody> {
  final _scrollCtrl = ScrollController();
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<SoalNotifier>().loadMore();
    }
  }

  Future<void> _navigateToForm({PertanyaanModel? soal}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<SoalNotifier>(),
          child: SoalFormScreen(roomId: widget.room.idRoom, soal: soal),
        ),
      ),
    );
    if (result == true && mounted) {
      // Notifier already updated list in-place
    }
  }

  Future<void> _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    setState(() => _isImporting = true);

    final notifier = context.read<SoalNotifier>();
    final count = await notifier.importExcel(widget.room.idRoom, file);

    if (!mounted) return;
    setState(() => _isImporting = false);

    if (count != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil mengimpor $count soal dari Excel'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(notifier.errorMessage.isNotEmpty
              ? notifier.errorMessage
              : 'Gagal mengimpor file Excel'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(PertanyaanModel soal) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2942),
        title: const Text('Hapus Soal', style: TextStyle(color: Colors.white)),
        content: Text(
          'Soal "${soal.pertanyaanText}" akan dihapus. Riwayat jawaban peserta tetap tersimpan.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final success = await context.read<SoalNotifier>().deleteSoal(soal.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Soal dihapus' : 'Gagal menghapus soal'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<SoalNotifier>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2942),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manajemen Soal', style: TextStyle(fontSize: 16)),
            Text(
              widget.room.roomName,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import Excel (.xlsx)',
            onPressed: _isImporting ? null : _importExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.loadSoal(widget.room.idRoom),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
      ),
      body: Stack(
        children: [
          _buildBody(notifier),
          if (_isImporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blue),
                    SizedBox(height: 16),
                    Text('Mengimpor soal dari Excel...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(SoalNotifier notifier) {
    if (notifier.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (notifier.status == SoalStatus.error && notifier.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(notifier.errorMessage, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadSoal(widget.room.idRoom),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (notifier.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey.shade700),
            const SizedBox(height: 16),
            const Text('Belum ada soal', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Tap + untuk buat soal atau tombol upload untuk import Excel',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.blue,
      onRefresh: () => notifier.loadSoal(widget.room.idRoom),
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: notifier.items.length + (notifier.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == notifier.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: Colors.blue)),
            );
          }
          return _SoalCard(
            soal: notifier.items[index],
            index: index,
            onEdit: () => _navigateToForm(soal: notifier.items[index]),
            onDelete: () => _confirmDelete(notifier.items[index]),
          );
        },
      ),
    );
  }
}

class _SoalCard extends StatelessWidget {
  final PertanyaanModel soal;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SoalCard({
    required this.soal,
    required this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMultiple = soal.typePertanyaan == TypePertanyaan.multipleChoice;
    final hasImage = soal.gambarUrl != null && soal.gambarUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2942),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isMultiple
                        ? Colors.purple.withValues(alpha: 0.2)
                        : Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isMultiple ? 'Pilihan Ganda' : 'Essay',
                    style: TextStyle(
                      color: isMultiple ? Colors.purpleAccent : Colors.tealAccent,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image, size: 12, color: Colors.amberAccent),
                        SizedBox(width: 4),
                        Text('Gambar', style: TextStyle(color: Colors.amberAccent, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54, size: 20),
                  color: const Color(0xFF1E293B),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Edit', style: TextStyle(color: Colors.white)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Question image thumbnail if present
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiClient.resolveImageUrl(soal.gambarUrl),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          // Question text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              soal.pertanyaanText,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
          // Options preview (multiple choice only)
          if (isMultiple && soal.questionOptions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: soal.questionOptions.map((o) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: o.isCorrect
                          ? Colors.green.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: o.isCorrect ? Colors.green : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (o.isCorrect)
                          const Icon(Icons.check, color: Colors.green, size: 13),
                        if (o.isCorrect) const SizedBox(width: 4),
                        Text(
                          o.optionText,
                          style: TextStyle(
                            color: o.isCorrect ? Colors.greenAccent : Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
