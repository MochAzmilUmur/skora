import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../data/datasources/assignment_remote_datasource.dart';
import '../../data/repositories/assignment_repository_impl.dart';
import '../../domain/entities/assignment.dart';
import '../providers/assignment_notifier.dart';
import 'pdf_preview_screen.dart';

/// Entry point — wraps the screen with its own ChangeNotifierProvider.
class AssignmentDetailScreen extends StatelessWidget {
  final int assignmentId;

  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AssignmentNotifier(
        AssignmentRepositoryImpl(
          remoteDataSource: AssignmentRemoteDataSourceImpl(),
        ),
      )..load(assignmentId),
      child: const _AssignmentDetailView(),
    );
  }
}

class _AssignmentDetailView extends StatefulWidget {
  const _AssignmentDetailView();

  @override
  State<_AssignmentDetailView> createState() => _AssignmentDetailViewState();
}

class _AssignmentDetailViewState extends State<_AssignmentDetailView> {
  File? _pickedFile;
  String? _pickedFileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;
    setState(() {
      _pickedFile = File(path);
      _pickedFileName = result.files.single.name;
    });
  }

  Future<void> _submit(AssignmentNotifier notifier) async {
    if (_pickedFile == null) {
      _showSnack('Pilih file PDF terlebih dahulu', isError: true);
      return;
    }
    final user = await AuthStorageService.getCurrentUser();
    if (user == null || !mounted) return;

    final error = await notifier.submitPdf(
      userId: user.idUsers,
      file: _pickedFile!,
    );

    if (!mounted) return;
    if (error != null) {
      _showSnack(error, isError: true);
    } else {
      _showSnack('Tugas berhasil dikirim!');
      setState(() { _pickedFile = null; _pickedFileName = null; });
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.green,
    ));
  }

  void _openPdf(String url, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfPreviewScreen(
          pdfUrl: ApiClient.resolveImageUrl(url),
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AssignmentNotifier>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Detail Tugas',
                style: TextStyle(color: Colors.white)),
          ),
          body: notifier.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.blue))
              : notifier.assignment == null
                  ? _buildError(notifier)
                  : _buildBody(notifier),
        ),
        // Upload barrier — blocks interaction during upload
        if (notifier.isUploading)
          const ModalBarrier(dismissible: false, color: Colors.black54),
        if (notifier.isUploading)
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.blue),
                SizedBox(height: 14),
                Text('Mengunggah tugas...',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildError(AssignmentNotifier notifier) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(notifier.error,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.load(
                context.read<AssignmentNotifier>().assignment?.id ?? 0),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AssignmentNotifier notifier) {
    final assignment = notifier.assignment!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(assignment),
          const SizedBox(height: 24),
          _buildDescription(assignment),
          const SizedBox(height: 24),
          assignment.isSubmitted
              ? _buildSubmissionResult(assignment.mySubmission!)
              : _buildSubmissionArea(notifier),
        ],
      ),
    );
  }

  Widget _buildHeader(Assignment assignment) {
    final overdue = assignment.isOverdue;
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
          Row(
            children: [
              const Icon(Icons.assignment_outlined,
                  color: Colors.blue, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  assignment.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (assignment.deadline != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule,
                    size: 16,
                    color: overdue ? Colors.red : Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'Deadline: ${_formatDate(assignment.deadline!)}',
                  style: TextStyle(
                      color: overdue ? Colors.red : Colors.orange,
                      fontSize: 13),
                ),
                if (overdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text('Terlambat',
                        style: TextStyle(color: Colors.red, fontSize: 10)),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescription(Assignment assignment) {
    if (assignment.description.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deskripsi',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(assignment.description,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSubmissionArea(AssignmentNotifier notifier) {
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
          const Text('Kumpulkan Tugas',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Dropzone / file picker area
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _pickedFile != null
                      ? Colors.blue
                      : const Color(0xFF475569),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _pickedFile != null
                        ? Icons.picture_as_pdf
                        : Icons.upload_file_outlined,
                    color: _pickedFile != null ? Colors.blue : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _pickedFile != null
                        ? _pickedFileName ?? 'File dipilih'
                        : 'Ketuk untuk memilih file PDF',
                    style: TextStyle(
                      color: _pickedFile != null
                          ? Colors.blue
                          : const Color(0xFF94A3B8),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Maks. 5 MB • Format: PDF',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          if (_pickedFile != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () =>
                  setState(() { _pickedFile = null; _pickedFileName = null; }),
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              label: const Text('Hapus pilihan',
                  style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  _pickedFile != null ? () => _submit(notifier) : null,
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('Kirim Tugas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF334155),
                disabledForegroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionResult(AssignmentSubmission submission) {
    final isGraded = submission.status == SubmissionStatus.graded;
    final statusColor = isGraded ? Colors.green : Colors.orange;
    final statusLabel = isGraded ? 'Sudah Dinilai' : 'Menunggu Penilaian';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: statusColor, size: 22),
              const SizedBox(width: 8),
              const Text('Tugas Sudah Dikumpulkan',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 16),
          // Preview button
          OutlinedButton.icon(
            onPressed: () => _openPdf(submission.pdfUrl, submission.fileName),
            icon: const Icon(Icons.picture_as_pdf_outlined,
                size: 18, color: Colors.blue),
            label: Text(
              submission.fileName.isNotEmpty
                  ? submission.fileName
                  : 'Lihat PDF Tugas',
              style: const TextStyle(color: Colors.blue),
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          // Score & feedback (only when graded)
          if (isGraded) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 12),
            if (submission.score != null)
              _buildInfoRow(
                icon: Icons.star_outline,
                label: 'Nilai',
                value: submission.score!.toStringAsFixed(1),
                valueColor: submission.score! >= 60
                    ? Colors.green
                    : Colors.red,
              ),
            if (submission.feedback != null &&
                submission.feedback!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Feedback Asesor',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  submission.feedback!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(
                color: Color(0xFF94A3B8), fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month]} ${dt.year}, '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
