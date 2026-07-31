import '../../domain/entities/assignment.dart';

class AssignmentSubmissionModel extends AssignmentSubmission {
  const AssignmentSubmissionModel({
    required super.id,
    required super.assignmentId,
    required super.pdfUrl,
    required super.fileName,
    required super.status,
    super.score,
    super.feedback,
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id'] as int,
      assignmentId: json['assignment_id'] as int,
      pdfUrl: json['pdf_url'] as String,
      fileName: json['file_name'] as String? ?? '',
      status: json['status'] == 'graded'
          ? SubmissionStatus.graded
          : SubmissionStatus.pending,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'assignment_id': assignmentId,
        'pdf_url': pdfUrl,
        'file_name': fileName,
        'status': status.name,
        if (score != null) 'score': score,
        if (feedback != null) 'feedback': feedback,
      };
}

class AssignmentModel extends Assignment {
  const AssignmentModel({
    required super.id,
    required super.title,
    required super.description,
    super.deadline,
    super.mySubmission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      mySubmission: json['my_submission'] != null
          ? AssignmentSubmissionModel.fromJson(
              json['my_submission'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        if (deadline != null) 'deadline': deadline!.toIso8601String(),
        if (mySubmission != null)
          'my_submission':
              (mySubmission as AssignmentSubmissionModel).toJson(),
      };
}
