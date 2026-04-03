class StudentRecord {
  const StudentRecord({
    required this.name,
    required this.className,
    required this.section,
    required this.quiz,
    required this.mid,
    required this.assignment,
    required this.finalExam,
    required this.feedbackHistory,
  });

  final String name;
  final String className;
  final String section;
  final int quiz;
  final int mid;
  final int assignment;
  final int finalExam;
  final List<FeedbackEntry> feedbackHistory;

  int get total => quiz + mid + assignment + finalExam;

  String get grade {
    if (total >= 80) return 'A';
    if (total >= 70) return 'B';
    if (total >= 60) return 'C';
    if (total >= 50) return 'D';
    return 'F';
  }

  String get classLabel => '$className$section';
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.title,
    required this.comment,
    required this.dateLabel,
  });

  final String title;
  final String comment;
  final String dateLabel;
}
