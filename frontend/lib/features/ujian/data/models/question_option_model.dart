class QuestionOptionModel {
  final int id;
  final int questionId;
  final String optionText;
  final bool isCorrect;

  const QuestionOptionModel({
    required this.id,
    required this.questionId,
    required this.optionText,
    required this.isCorrect,
  });

  factory QuestionOptionModel.fromJson(Map<String, dynamic> json) {
    return QuestionOptionModel(
      id: json['id'] as int,
      questionId: json['question_id'] as int,
      optionText: json['option_text'] as String,
      isCorrect: json['is_correct'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'option_text': optionText,
      'is_correct': isCorrect,
    };
  }

  QuestionOptionModel copyWith({
    int? id,
    int? questionId,
    String? optionText,
    bool? isCorrect,
  }) {
    return QuestionOptionModel(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      optionText: optionText ?? this.optionText,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionOptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'QuestionOptionModel(id: $id, optionText: $optionText, isCorrect: $isCorrect)';
  }
}
