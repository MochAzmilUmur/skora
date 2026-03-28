import 'package:frontend/features/ujian/data/models/hasil_ujian_model.dart';
import 'package:frontend/features/auth/data/models/auth/user.dart';

class FeedbackModel {
  final int id;
  final int hasilId;
  final int asesorId;
  final String komentar;
  final DateTime createdAt;
  final HasilUjianModel? hasilUjian;
  final User? asesor;

  const FeedbackModel({
    required this.id,
    required this.hasilId,
    required this.asesorId,
    required this.komentar,
    required this.createdAt,
    this.hasilUjian,
    this.asesor,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as int,
      hasilId: json['hasil_id'] as int,
      asesorId: json['asesor_id'] as int,
      komentar: json['komentar'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      hasilUjian: json['hasil_ujian'] != null
          ? HasilUjianModel.fromJson(json['hasil_ujian'] as Map<String, dynamic>)
          : null,
      asesor: json['asesor'] != null
          ? User.fromJson(json['asesor'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hasil_id': hasilId,
      'asesor_id': asesorId,
      'komentar': komentar,
      'created_at': createdAt.toIso8601String(),
      if (hasilUjian != null) 'hasil_ujian': hasilUjian!.toJson(),
      if (asesor != null) 'asesor': asesor!.toJson(),
    };
  }

  FeedbackModel copyWith({
    int? id,
    int? hasilId,
    int? asesorId,
    String? komentar,
    DateTime? createdAt,
    HasilUjianModel? hasilUjian,
    User? asesor,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      hasilId: hasilId ?? this.hasilId,
      asesorId: asesorId ?? this.asesorId,
      komentar: komentar ?? this.komentar,
      createdAt: createdAt ?? this.createdAt,
      hasilUjian: hasilUjian ?? this.hasilUjian,
      asesor: asesor ?? this.asesor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FeedbackModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FeedbackModel(id: $id, asesorId: $asesorId, komentar: ${komentar.substring(0, komentar.length > 50 ? 50 : komentar.length)}...)';
  }
}
