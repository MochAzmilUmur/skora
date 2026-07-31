import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/widgets/protected_screen.dart';
import '../../../../features/auth/data/models/models.dart';
import '../../../../features/room/data/models/websocket_message_model.dart';
import '../../data/repositories/ujian_repository_impl.dart';
import '../../data/datasources/ujian_remote_datasource_impl.dart';
import '../providers/exam_session_notifier.dart';
import 'exam_result_screen.dart';

/// Entry point — wraps the screen in its own ChangeNotifierProvider so the
/// notifier lifetime matches the screen lifetime.
class ExamSessionScreen extends StatelessWidget {
  final String roomId;
  final String roomName;
  final int durasiMenit;
  final int userId;

  const ExamSessionScreen({
    Key? key,
    required this.roomId,
    required this.roomName,
    required this.durasiMenit,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExamSessionNotifier(
        UjianRepositoryImpl(
          remoteDataSource: UjianRemoteDataSourceImpl(),
        ),
      )..init(
          roomId: roomId,
          userId: userId,
          durasiMenit: durasiMenit,
        ),
      child: _ExamSessionView(roomName: roomName),
    );
  }
}

class _ExamSessionView extends StatefulWidget {
  final String roomName;
  const _ExamSessionView({required this.roomName});

  @override
  State<_ExamSessionView> createState() => _ExamSessionViewState();
}

class _ExamSessionViewState extends State<_ExamSessionView> {
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to WS stream for real-time feedback
    final wsService = context.read<WebSocketService>();
    _wsSub = wsService.messageStream.listen((msg) {
      if (!mounted) return;
      if (msg.type == WebSocketMessageType.feedback) {
        final payload = FeedbackWebSocketPayload.fromJson(msg.data);
        context.read<ExamSessionNotifier>().addFeedback(payload);
        _showFeedbackSnackbar(payload);
      }
    });
  }

  void _showFeedbackSnackbar(FeedbackWebSocketPayload payload) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.comment_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Feedback dari Asesor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    payload.komentar,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E40AF),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ExamSessionNotifier>();

    // Navigate to result when done
    if (notifier.status == ExamStatus.completed && notifier.hasil != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ExamResultScreen(hasil: notifier.hasil!),
          ),
        );
      });
    }

    return ProtectedScreen(
      enableScreenshotProtection: true,
      enableDataLeakageProtection: true,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final exit = await _showExitDialog(context);
          if (exit == true && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: _buildAppBar(context, notifier, widget.roomName),
          body: switch (notifier.status) {
            ExamStatus.loading => const Center(
                child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
              ),
            ExamStatus.error => _ErrorView(message: notifier.errorMessage),
            _ => Column(
                children: [
                  _ProgressBar(notifier: notifier),
                  Expanded(child: _QuestionBody(notifier: notifier)),
                  _BottomBar(notifier: notifier),
                ],
              ),
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ExamSessionNotifier notifier,
    String name,
  ) {
    final timeCritical = notifier.isTimeCritical;
    return AppBar(
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.red),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.security, size: 12, color: Colors.red),
                SizedBox(width: 4),
                Text('Protected', style: TextStyle(color: Colors.red, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (timeCritical ? Colors.red : Colors.blue).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timeCritical ? Colors.red : Colors.blue),
          ),
          child: Row(
            children: [
              Icon(Icons.timer,
                  size: 18, color: timeCritical ? Colors.red : Colors.blue),
              const SizedBox(width: 6),
              Text(
                notifier.formattedTime,
                style: TextStyle(
                  color: timeCritical ? Colors.red : Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Exit Exam?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Your answers are saved. The timer will continue running.',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final ExamSessionNotifier notifier;
  const _ProgressBar({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final total = notifier.totalQuestions;
    final current = notifier.currentIndex + 1;
    final progress = total == 0 ? 0.0 : current / total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question $current of $total',
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              Text(
                '${notifier.answeredCount}/$total Answered',
                style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFF334155),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Question body ──────────────────────────────────────────────────────────

class _QuestionBody extends StatelessWidget {
  final ExamSessionNotifier notifier;
  const _QuestionBody({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final soal = notifier.currentSoal;
    if (soal == null) {
      return const Center(
        child: Text('Tidak ada soal.', style: TextStyle(color: Colors.white)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionCard(soal: soal, notifier: notifier),
          const SizedBox(height: 24),
          _NavigationButtons(notifier: notifier),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final PertanyaanModel soal;
  final ExamSessionNotifier notifier;
  const _QuestionCard({required this.soal, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final isBookmarked = notifier.isBookmarked(soal.id);

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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  soal.typePertanyaan == TypePertanyaan.multipleChoice
                      ? 'Pilihan Ganda'
                      : 'Essay',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? Colors.amber : const Color(0xFF94A3B8),
                ),
                onPressed: () => notifier.toggleBookmark(soal.id),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            soal.pertanyaanText,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (soal.gambarUrl != null && soal.gambarUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ApiClient.resolveImageUrl(soal.gambarUrl),
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (soal.typePertanyaan == TypePertanyaan.multipleChoice)
            _MultipleChoiceOptions(soal: soal, notifier: notifier)
          else
            _EssayInput(soal: soal, notifier: notifier),
        ],
      ),
    );
  }
}

class _MultipleChoiceOptions extends StatelessWidget {
  final PertanyaanModel soal;
  final ExamSessionNotifier notifier;
  const _MultipleChoiceOptions({required this.soal, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final selected = notifier.selectedOption(soal.id);
    const labels = ['A', 'B', 'C', 'D', 'E'];

    return Column(
      children: [
        for (int i = 0; i < soal.questionOptions.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _OptionTile(
            label: labels[i % labels.length],
            text: soal.questionOptions[i].optionText,
            isSelected: selected == soal.questionOptions[i].id,
            onTap: () =>
                notifier.selectOption(soal.id, soal.questionOptions[i].id),
          ),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.15)
              : const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected ? Colors.blue : const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : const Color(0xFF334155),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontSize: 14),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }
}

class _EssayInput extends StatefulWidget {
  final PertanyaanModel soal;
  final ExamSessionNotifier notifier;
  const _EssayInput({required this.soal, required this.notifier});

  @override
  State<_EssayInput> createState() => _EssayInputState();
}

class _EssayInputState extends State<_EssayInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.notifier.textAnswer(widget.soal.id) ?? '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      maxLines: 5,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Tulis jawaban Anda di sini...',
        hintStyle: const TextStyle(color: Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFF0F172A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      ),
      onChanged: (v) => widget.notifier.setTextAnswer(widget.soal.id, v),
    );
  }
}

// ── Navigation buttons ─────────────────────────────────────────────────────

class _NavigationButtons extends StatelessWidget {
  final ExamSessionNotifier notifier;
  const _NavigationButtons({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: notifier.currentIndex > 0 ? notifier.previous : null,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Sebelumnya'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF334155)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                notifier.currentIndex < notifier.totalQuestions - 1
                    ? notifier.next
                    : null,
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: const Text('Selanjutnya'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom bar (grid + submit) ─────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final ExamSessionNotifier notifier;
  const _BottomBar({required this.notifier});

  @override
  Widget build(BuildContext context) {
    final submitting = notifier.status == ExamStatus.submitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showQuestionGrid(context, notifier),
              icon: const Icon(Icons.grid_view, size: 18),
              label: const Text('Question Grid'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF334155)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: submitting
                  ? null
                  : () => _showSubmitDialog(context, notifier),
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle, size: 18),
              label: Text(submitting ? 'Menyimpan...' : 'Submit Ujian'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
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

  void _showQuestionGrid(
      BuildContext context, ExamSessionNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _QuestionGridSheet(notifier: notifier),
    );
  }

  Future<void> _showSubmitDialog(
      BuildContext context, ExamSessionNotifier notifier) async {
    final unanswered =
        notifier.totalQuestions - notifier.answeredCount;
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Submit Ujian?',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Anda tidak dapat mengubah jawaban setelah submit.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
            if (unanswered > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber,
                        color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$unanswered soal belum dijawab.',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Review'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      notifier.submitExam();
    }
  }
}

// ── Question grid bottom sheet ─────────────────────────────────────────────

class _QuestionGridSheet extends StatelessWidget {
  final ExamSessionNotifier notifier;
  const _QuestionGridSheet({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: notifier,
      child: Consumer<ExamSessionNotifier>(
        builder: (ctx, n, _) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Question Grid',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildLegend(),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: n.soal.length,
                itemBuilder: (_, i) {
                  final s = n.soal[i];
                  final answered = n.isAnswered(s.id);
                  final bookmarked = n.isBookmarked(s.id);
                  final isCurrent = n.currentIndex == i;

                  Color bg;
                  if (isCurrent) {
                    bg = Colors.blue;
                  } else if (answered) {
                    bg = Colors.green;
                  } else if (bookmarked) {
                    bg = Colors.amber;
                  } else {
                    bg = const Color(0xFF334155);
                  }

                  return GestureDetector(
                    onTap: () {
                      n.goTo(i);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    const items = [
      (Colors.green, 'Dijawab'),
      (Colors.blue, 'Sekarang'),
      (Colors.amber, 'Ditandai'),
      (Color(0xFF334155), 'Belum'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: items
          .map((item) => Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: item.$1, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(item.$2,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 11)),
                ],
              ))
          .toList(),
    );
  }
}

// ── Error view ─────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Terjadi Kesalahan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
