import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/data/models/models.dart';
import '../providers/soal_notifier.dart';

/// Used for both Create and Edit.
/// Pass [soal] to enter edit mode.
class SoalFormScreen extends StatefulWidget {
  final String roomId;
  final PertanyaanModel? soal;

  const SoalFormScreen({super.key, required this.roomId, this.soal});

  @override
  State<SoalFormScreen> createState() => _SoalFormScreenState();
}

class _SoalFormScreenState extends State<SoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _textCtrl = TextEditingController();
  TypePertanyaan _type = TypePertanyaan.multipleChoice;

  // Options for multiple choice
  final List<_OptionEntry> _options = [];

  bool get _isEdit => widget.soal != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final s = widget.soal!;
      _textCtrl.text = s.pertanyaanText;
      _type = s.typePertanyaan;
      _options.addAll(s.questionOptions.map((o) => _OptionEntry(
            textCtrl: TextEditingController(text: o.optionText),
            isCorrect: o.isCorrect,
          )));
    }
    if (_type == TypePertanyaan.multipleChoice && _options.isEmpty) {
      _options.add(_OptionEntry(textCtrl: TextEditingController()));
      _options.add(_OptionEntry(textCtrl: TextEditingController()));
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    for (final o in _options) {
      o.textCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = context.read<SoalNotifier>();

    List<QuestionOptionModel>? options;
    if (_type == TypePertanyaan.multipleChoice) {
      options = _options
          .where((o) => o.textCtrl.text.trim().isNotEmpty)
          .map((o) => QuestionOptionModel(
                id: 0,
                questionId: 0,
                optionText: o.textCtrl.text.trim(),
                isCorrect: o.isCorrect,
              ))
          .toList();
      if (options.isEmpty) {
        _showSnack('Tambahkan minimal satu pilihan jawaban');
        return;
      }
    }

    bool ok;
    if (_isEdit) {
      ok = await notifier.updateSoal(
        pertanyaanId: widget.soal!.id,
        pertanyaanText: _textCtrl.text.trim(),
        typePertanyaan: _type,
      );
    } else {
      ok = await notifier.createSoal(
        roomId: widget.roomId,
        pertanyaanText: _textCtrl.text.trim(),
        typePertanyaan: _type,
        options: options,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _showSnack(notifier.errorMessage.isNotEmpty
          ? notifier.errorMessage
          : 'Terjadi kesalahan');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _addOption() {
    setState(() => _options.add(_OptionEntry(textCtrl: TextEditingController())));
  }

  void _removeOption(int index) {
    setState(() {
      _options[index].textCtrl.dispose();
      _options.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<SoalNotifier>().isSaving;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2942),
        foregroundColor: Colors.white,
        title: Text(_isEdit ? 'Edit Soal' : 'Tambah Soal'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('Tipe Soal'),
            const SizedBox(height: 8),
            _typeSelector(),
            const SizedBox(height: 20),
            _label('Pertanyaan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _textCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: _inputDecoration('Tulis pertanyaan di sini...'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Pertanyaan tidak boleh kosong' : null,
            ),
            if (_type == TypePertanyaan.multipleChoice) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  _label('Pilihan Jawaban'),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(Icons.add, color: Colors.blue, size: 18),
                    label: const Text('Tambah', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._options.asMap().entries.map((e) => _optionTile(e.key, e.value)),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Simpan Perubahan' : 'Tambah Soal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );

  Widget _typeSelector() {
    return Row(
      children: TypePertanyaan.values.map((t) {
        final selected = t == _type;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() {
              _type = t;
              if (t == TypePertanyaan.multipleChoice && _options.isEmpty) {
                _options.add(_OptionEntry(textCtrl: TextEditingController()));
                _options.add(_OptionEntry(textCtrl: TextEditingController()));
              }
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? Colors.blue : const Color(0xFF1A2942),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: selected ? Colors.blue : Colors.grey.shade700,
                ),
              ),
              child: Text(
                t == TypePertanyaan.multipleChoice ? 'Pilihan Ganda' : 'Essay',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _optionTile(int index, _OptionEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Correct answer toggle
          GestureDetector(
            onTap: () => setState(() => entry.isCorrect = !entry.isCorrect),
            child: Icon(
              entry.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
              color: entry.isCorrect ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: entry.textCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Pilihan ${index + 1}'),
            ),
          ),
          if (_options.length > 1) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _removeOption(index),
              child: const Icon(Icons.close, color: Colors.red, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFF1A2942),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.blue),
      ),
    );
  }
}

class _OptionEntry {
  final TextEditingController textCtrl;
  bool isCorrect;

  _OptionEntry({required this.textCtrl, this.isCorrect = false});
}
