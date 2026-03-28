import 'sesi_ujian_model.dart';
import 'pertanyaan_model.dart';
import 'question_option_model.dart';

class AnswerModel {
  final int id;
  final int sessionId;
  final int questionId;
  final String? answerText;
  final int? selectedOptionId;
  final DateTime answeredAt;
  final SesiUjianModel? sesiUjian;
  final PertanyaanModel? pertanyaan;
  final QuestionOptionModel? questionOption;

  const AnswerModel({
    required this.id,
    required this.sessionId,
    required this.questionId,
    this.answerText,
    this.selectedOptionId,
    required this.answeredAt,
    this.sesiUjian,
    this.pertanyaan,
    this.questionOption,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      questionId: json['question_id'] as int,
      answerText: json['answer_text'] as String?,
      selectedOptionId: json['selected_option_id'] as int?,
      answeredAt: DateTime.parse(json['answered_at'] as String),
      sesiUjian: json['sesi_ujian'] != null
          ? SesiUjianModel.fromJson(json['sesi_ujian'] as Map<String, dynamic>)
          : null,
      pertanyaan: json['pertanyaan'] != null
          ? PertanyaanModel.fromJson(json['pertanyaan'] as Map<String, dynamic>)
          : null,
      questionOption: json['question_option'] != null
          ? QuestionOptionModel.fromJson(json['question_option'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'question_id': questionId,
      if (answerText != null) 'answer_text': answerText,
      if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
      'answered_at': answeredAt.toIso8601String(),
      if (sesiUjian != null) 'sesi_ujian': sesiUjian!.toJson(),
      if (pertanyaan != null) 'pertanyaan': pertanyaan!.toJson(),
      if (questionOption != null) 'question_option': questionOption!.toJson(),
    };
  }

  AnswerModel copyWith({
    int? id,
    int? sessionId,
    int? questionId,
    String? answerText,
    int? selectedOptionId,
    DateTime? answeredAt,
    SesiUjianModel? sesiUjian,
    PertanyaanModel? pertanyaan,
    QuestionOptionModel? questionOption,
  }) {
    return AnswerModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      questionId: questionId ?? this.questionId,
      answerText: answerText ?? this.answerText,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      answeredAt: answeredAt ?? this.answeredAt,
      sesiUjian: sesiUjian ?? this.sesiUjian,
      pertanyaan: pertanyaan ?? this.pertanyaan,
      questionOption: questionOption ?? this.questionOption,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AnswerModel(id: $id, sessionId: $sessionId, questionId: $questionId)';
  }
}
