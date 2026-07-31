enum SubmissionStatus { pending, graded }

class AssignmentSubmission {
  final int id;
  final int assignmentId;
  final String pdfUrl;
  final String fileName;
  final SubmissionStatus status;
  final double? score;
  final String? feedback;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.pdfUrl,
    required this.fileName,
    required this.status,
    this.score,
    this.feedback,
  });
}

class Assignment {
  final int id;
  final String title;
  final String description;
  final DateTime? deadline;
  final AssignmentSubmission? mySubmission;

  const Assignment({
    required this.id,
    required this.title,
    required this.description,
    this.deadline,
    this.mySubmission,
  });

  bool get isSubmitted => mySubmission != null;
  bool get isOverdue => deadline != null && DateTime.now().isAfter(deadline!);
}
