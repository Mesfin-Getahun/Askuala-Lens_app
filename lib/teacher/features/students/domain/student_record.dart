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

  factory StudentRecord.fromFirestore(Map<String, dynamic> data) {
    final firstName = data['firstName']?.toString().trim();
    final lastName = data['lastName']?.toString().trim();
    final fullName = [firstName, lastName]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' ');

    final feedbackItems = (data['feedbackHistory'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => FeedbackEntry(
            title: item['title']?.toString() ?? 'Feedback',
            comment: item['comment']?.toString() ?? '',
            dateLabel: item['dateLabel']?.toString() ?? 'Recent',
          ),
        )
        .toList();

    return StudentRecord(
      name:
          fullName.isNotEmpty
              ? fullName
              : data['displayName']?.toString() ??
                    data['name']?.toString() ??
                    data['username']?.toString() ??
                    'Student',
      className:
          data['classAssigned']?.toString() ??
          data['class']?.toString() ??
          'Unassigned',
      section:
          data['section']?.toString() ??
          data['sectionAssigned']?.toString() ??
          'Unknown',
      quiz: _readScore(data, ['quiz', 'quizScore']),
      mid: _readScore(data, ['mid', 'midScore', 'midExam']),
      assignment: _readScore(data, ['assignment', 'assignmentScore']),
      finalExam: _readScore(data, ['finalExam', 'final', 'finalScore']),
      feedbackHistory: feedbackItems,
    );
  }

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

  static int _readScore(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final rawValue = data[key];
      if (rawValue is num) {
        return rawValue.round();
      }

      final parsedValue = int.tryParse(rawValue?.toString() ?? '');
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return 0;
  }
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
