import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skora/features/ujian/data/models/hasil_ujian_model.dart';

/// Generates a SIAKAD-friendly CSV rekap nilai and triggers OS share sheet.
class GradeExportService {
  static Future<void> exportCsv({
    required String roomName,
    required List<HasilUjianModel> hasils,
  }) async {
    final buf = StringBuffer();
    buf.writeln('No,ID Peserta,Nama Peserta,Nilai Ujian,Status Lulus');

    for (var i = 0; i < hasils.length; i++) {
      final h = hasils[i];
      final nama = _escape(h.sesiUjian?.user?.nama ?? 'Peserta #${h.sessionId}');
      final userId = h.sesiUjian?.userId ?? h.sessionId;
      final status = h.isPassed ? 'Lulus' : 'Tidak Lulus';
      buf.writeln('${i + 1},$userId,$nama,${h.skor.toStringAsFixed(0)},$status');
    }

    final dir = await getTemporaryDirectory();
    final safe = roomName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final file = File('${dir.path}/rekap_${safe}_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buf.toString());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Rekap Nilai – $roomName',
    );
  }

  static String _escape(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
