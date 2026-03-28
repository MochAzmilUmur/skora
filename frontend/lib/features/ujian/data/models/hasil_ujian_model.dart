import 'sesi_ujian_model.dart';

class HasilUjianModel {
  final int id;
  final int sessionId;
  final int totalQuestions;
  final int jawabanBenar;
  final int jawabanSalah;
  final double skor;
  final SesiUjianModel? sesiUjian;

  const HasilUjianModel({
    required this.id,
    required this.sessionId,
    required this.totalQuestions,
    required this.jawabanBenar,
    required this.jawabanSalah,
    required this.skor,
    this.sesiUjian,
  });

  factory HasilUjianModel.fromJson(Map<String, dynamic> json) {
    return HasilUjianModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      totalQuestions: json['total_questions'] as int,
      jawabanBenar: json['jawaban_benar'] as int,
      jawabanSalah: json['jawaban_salah'] as int,
      skor: (json['skor'] as num).toDouble(),
      sesiUjian: json['sesi_ujian'] != null
          ? SesiUjianModel.fromJson(json['sesi_ujian'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'total_questions': totalQuestions,
      'jawaban_benar': jawabanBenar,
      'jawaban_salah': jawabanSalah,
      'skor': skor,
      if (sesiUjian != null) 'sesi_ujian': sesiUjian!.toJson(),
    };
  }

  HasilUjianModel copyWith({
    int? id,
    int? sessionId,
    int? totalQuestions,
    int? jawabanBenar,
    int? jawabanSalah,
    double? skor,
    SesiUjianModel? sesiUjian,
  }) {
    return HasilUjianModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      jawabanBenar: jawabanBenar ?? this.jawabanBenar,
      jawabanSalah: jawabanSalah ?? this.jawabanSalah,
      skor: skor ?? this.skor,
      sesiUjian: sesiUjian ?? this.sesiUjian,
    );
  }

  double get persentaseBenar {
    if (totalQuestions == 0) return 0.0;
    return (jawabanBenar / totalQuestions) * 100;
  }

  double get persentaseSalah {
    if (totalQuestions == 0) return 0.0;
    return (jawabanSalah / totalQuestions) * 100;
  }

  bool get isPassed => skor >= 60.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HasilUjianModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'HasilUjianModel(id: $id, skor: $skor, benar: $jawabanBenar/$totalQuestions)';
  }
}
