import 'package:skora/features/room/data/models/room_model.dart';
import 'question_option_model.dart';

enum TypePertanyaan {
  multipleChoice('multiple_choice'),
  text('text');

  final String value;
  const TypePertanyaan(this.value);

  static TypePertanyaan fromString(String type) {
    return TypePertanyaan.values.firstWhere(
      (e) => e.value == type,
      orElse: () => TypePertanyaan.text,
    );
  }

  String toJson() => value;
}

class PertanyaanModel {
  final int id;
  final String roomId;
  final String pertanyaanText;
  final TypePertanyaan typePertanyaan;
  final RoomModel? room;
  final List<QuestionOptionModel> questionOptions;

  const PertanyaanModel({
    required this.id,
    required this.roomId,
    required this.pertanyaanText,
    required this.typePertanyaan,
    this.room,
    this.questionOptions = const [],
  });

  factory PertanyaanModel.fromJson(Map<String, dynamic> json) {
    return PertanyaanModel(
      id: json['id'] as int,
      roomId: json['room_id'] as String,
      pertanyaanText: json['pertanyaan_text'] as String,
      typePertanyaan: TypePertanyaan.fromString(json['type_pertanyaan'] as String),
      room: json['room'] != null
          ? RoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      questionOptions: json['question_options'] != null
          ? (json['question_options'] as List)
              .map((e) => QuestionOptionModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'pertanyaan_text': pertanyaanText,
      'type_pertanyaan': typePertanyaan.toJson(),
      if (room != null) 'room': room!.toJson(),
      'question_options': questionOptions.map((e) => e.toJson()).toList(),
    };
  }

  PertanyaanModel copyWith({
    int? id,
    String? roomId,
    String? pertanyaanText,
    TypePertanyaan? typePertanyaan,
    RoomModel? room,
    List<QuestionOptionModel>? questionOptions,
  }) {
    return PertanyaanModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      pertanyaanText: pertanyaanText ?? this.pertanyaanText,
      typePertanyaan: typePertanyaan ?? this.typePertanyaan,
      room: room ?? this.room,
      questionOptions: questionOptions ?? this.questionOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PertanyaanModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PertanyaanModel(id: $id, pertanyaanText: $pertanyaanText, type: $typePertanyaan)';
  }
}
