import 'package:flutter/material.dart';
import '../../data/models/models.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../data/datasources/room_remote_datasource.dart';
import '../../../../core/services/auth_storage_service.dart';
import '../../../../core/utils/app_toast.dart';

/// Form screen for creating or editing a room.
///
/// For **create**: always supply [roomType] (provided by RoomTypePickerScreen).
/// For **edit**: supply [editRoom]; [roomType] is ignored (locked to existing type).
class CreateExamRoomScreen extends StatefulWidget {
  final RoomType roomType;
  final RoomModel? editRoom;

  const CreateExamRoomScreen({
    super.key,
    this.roomType = RoomType.pilihanGanda,
    this.editRoom,
  });

  @override
  State<CreateExamRoomScreen> createState() => _CreateExamRoomScreenState();
}

// ── Duration config per room type ─────────────────────────────────────────

/// Short-duration options for PG and Hybrid (in minutes).
const _shortDurations = [30, 45, 60, 90, 120, 150, 180];

/// Long-duration options for Praktikum (in minutes).
const _longDurations = [
  (label: '1 Hari',     minutes: 1440),
  (label: '2 Hari',     minutes: 2880),
  (label: '3 Hari',     minutes: 4320),
  (label: '1 Minggu',   minutes: 10080),
  (label: '2 Minggu',   minutes: 20160),
  (label: '1 Bulan',    minutes: 43200),
  (label: '2 Bulan',    minutes: 86400),
  (label: '3 Bulan',    minutes: 129600),
];

// ── Type meta ─────────────────────────────────────────────────────────────

const _typeMeta = {
  RoomType.pilihanGanda: (
    label: 'Pilihan Ganda',
    icon: Icons.quiz_outlined,
    accent: Color(0xFF3B82F6),
    durationLabel: 'Durasi Ujian',
    dateLabel: 'Tanggal Mulai',
    dateHint: 'Kapan ujian dibuka',
  ),
  RoomType.hybrid: (
    label: 'Hybrid',
    icon: Icons.merge_type_outlined,
    accent: Color(0xFF8B5CF6),
    durationLabel: 'Durasi Ujian',
    dateLabel: 'Tanggal Mulai',
    dateHint: 'Kapan ujian dibuka',
  ),
  RoomType.praktikum: (
    label: 'Praktikum',
    icon: Icons.upload_file_outlined,
    accent: Color(0xFF10B981),
    durationLabel: 'Batas Waktu Pengumpulan',
    dateLabel: 'Tanggal Dibuka',
    dateHint: 'Kapan tugas mulai bisa dikerjakan',
  ),
};

// ── State ─────────────────────────────────────────────────────────────────

class _CreateExamRoomScreenState extends State<CreateExamRoomScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _repo = RoomRepositoryImpl(remoteDataSource: RoomRemoteDataSourceImpl());

  late RoomType _roomType;

  // Short-duration picker (PG / Hybrid)
  int _selectedShortMinutes = 60;

  // Long-duration picker (Praktikum) — index into _longDurations
  int _selectedLongIdx = 0;

  DateTime? _startDate;
  bool _isLoading = false;

  bool get _isEditMode => widget.editRoom != null;
  bool get _isPraktikum => _roomType == RoomType.praktikum;

  // ponytail: shuffle is automatic — no UI toggle needed
  bool get _shuffleQ => !_isPraktikum;

  int get _resolvedDurationMinutes =>
      _isPraktikum ? _longDurations[_selectedLongIdx].minutes : _selectedShortMinutes;

  @override
  void initState() {
    super.initState();
    _roomType = _isEditMode ? widget.editRoom!.roomType : widget.roomType;

    if (_isEditMode) {
      final r = widget.editRoom!;
      _titleCtrl.text = r.roomName;
      _descCtrl.text = r.description;
      _startDate = r.startDate;
      _roomType = r.roomType;

      if (_isPraktikum) {
        // Pick closest long-duration slot
        final idx = _longDurations.indexWhere((d) => d.minutes >= r.durasi);
        _selectedLongIdx = idx < 0 ? 0 : idx;
      } else {
        _selectedShortMinutes = _shortDurations.contains(r.durasi) ? r.durasi : 60;
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final meta = _typeMeta[_roomType]!;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(meta),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeBadge(roomType: _roomType, meta: meta),
            const SizedBox(height: 24),
            _buildSection('Detail Exam', [
              _buildTextField(_titleCtrl, 'Judul', 'Masukkan judul exam...'),
              const SizedBox(height: 16),
              _buildTextField(_descCtrl, 'Deskripsi', 'Jelaskan tentang exam ini...', maxLines: 4),
            ]),
            const SizedBox(height: 24),
            _buildSection('Waktu', [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDurationPicker(meta)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatePicker(meta)),
                ],
              ),
            ]),
            const SizedBox(height: 24),
            _buildSection('Konfigurasi', [
              if (_isPraktikum)
                _buildPraktikumHint()
              else
                _buildShuffleInfo(),
            ]),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(dynamic meta) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        _isEditMode ? 'Edit Room' : 'Buat Room Baru',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        ...children,
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF475569)),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: _inputBorder(const Color(0xFF334155)),
            enabledBorder: _inputBorder(const Color(0xFF334155)),
            focusedBorder: _inputBorder(_typeMeta[_roomType]!.accent),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _inputBorder(Color color) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color));

  Widget _buildDurationPicker(dynamic meta) {
    final accent = _typeMeta[_roomType]!.accent;
    final label = meta.durationLabel as String;
    final displayValue = _isPraktikum
        ? _longDurations[_selectedLongIdx].label
        : ' Menit';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showDurationPicker,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer_outlined, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(displayValue,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _isPraktikum ? _longDurationSheet() : _shortDurationSheet(),
    );
  }

  Widget _shortDurationSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Pilih Durasi',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ..._shortDurations.map((m) => ListTile(
              leading: const Icon(Icons.timer_outlined, color: Color(0xFF64748B), size: 18),
              title: Text('$m Menit', style: const TextStyle(color: Colors.white)),
              trailing: _selectedShortMinutes == m
                  ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                  : null,
              onTap: () {
                setState(() => _selectedShortMinutes = m);
                Navigator.pop(context);
              },
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _longDurationSheet() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text('Batas Waktu Pengumpulan',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ..._longDurations.asMap().entries.map((e) => ListTile(
              leading: const Icon(Icons.schedule_outlined, color: Color(0xFF64748B), size: 18),
              title: Text(e.value.label, style: const TextStyle(color: Colors.white)),
              trailing: _selectedLongIdx == e.key
                  ? const Icon(Icons.check, color: Color(0xFF10B981))
                  : null,
              onTap: () {
                setState(() => _selectedLongIdx = e.key);
                Navigator.pop(context);
              },
            )),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDatePicker(dynamic meta) {
    final accent = _typeMeta[_roomType]!.accent;
    final label = meta.dateLabel as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Pilih Tanggal',
                    style: TextStyle(
                      color: _startDate != null ? Colors.white : const Color(0xFF475569),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final accent = _typeMeta[_roomType]!.accent;
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: ColorScheme.dark(
            primary: accent,
            onPrimary: Colors.white,
            surface: const Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  // Replaces the old toggle — shows a static info chip instead
  Widget _buildShuffleInfo() {
    final accent = _typeMeta[_roomType]!.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(Icons.shuffle, color: accent, size: 18),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Acak Soal Aktif',
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                Text('Urutan soal diacak otomatis untuk setiap peserta',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: accent, size: 18),
        ],
      ),
    );
  }

  Widget _buildPraktikumHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Color(0xFF10B981), size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Peserta dapat mengupload file dalam rentang waktu yang ditentukan.',
              style: TextStyle(color: Color(0xFF10B981), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final accent = _typeMeta[_roomType]!.accent;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
                _isEditMode ? 'Simpan Perubahan' : 'Buat Room',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  // ── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (title.isEmpty) {
      _snack('Masukkan judul room', Colors.red);
      return;
    }
    if (desc.isEmpty) {
      _snack('Masukkan deskripsi', Colors.red);
      return;
    }
    if (_startDate == null) {
      _snack('Pilih tanggal mulai', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = await AuthStorageService.getUserId();
      if (userId == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _snack('Sesi habis, silakan login ulang', Colors.red);
        return;
      }

      final duration = _resolvedDurationMinutes;

      late final dynamic result;
      if (_isEditMode) {
        result = await _repo.updateRoom(
          roomId: widget.editRoom!.idRoom,
          roomName: title,
          description: desc,
          durasi: duration,
          startDate: _startDate,
          roomType: _roomType.value,
          shuffleQuestions: _shuffleQ,
        );
      } else {
        result = await _repo.createRoom(
          roomName: title,
          description: desc,
          durasi: duration,
          startDate: _startDate,
          roomType: _roomType.value,
          shuffleQuestions: _shuffleQ,
          createdBy: userId,
        );
      }

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() => _isLoading = false);
          _snack('Gagal: ${failure.message}', Colors.red);
        },
        (room) {
          setState(() => _isLoading = false);
          _snack(
            _isEditMode
                ? 'Room berhasil diperbarui!'
                : 'Room "${room.roomName}" berhasil dibuat!',
            Colors.green,
          );
          Future.delayed(
            const Duration(milliseconds: 500),
            () { if (mounted) Navigator.of(context).pop(true); },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('Error: $e', Colors.red);
    }
  }

  void _snack(String msg, Color bg) {
    if (!mounted) return;
    if (bg == Colors.red || bg.r > 0.8) {
      AppToast.showError(context, msg);
    } else {
      AppToast.showSuccess(context, msg);
    }
  }
}

// ── Type badge shown at the top of the form ────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final RoomType roomType;
  final dynamic meta;

  const _TypeBadge({required this.roomType, required this.meta});

  @override
  Widget build(BuildContext context) {
    final accent = meta.accent as Color;
    final icon = meta.icon as IconData;
    final label = meta.label as String;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
                color: accent, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
