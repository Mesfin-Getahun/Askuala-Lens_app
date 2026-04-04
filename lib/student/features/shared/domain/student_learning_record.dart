import 'package:cloud_firestore/cloud_firestore.dart';

class StudentLearningRecord {
  const StudentLearningRecord({
    this.id,
    required this.topic,
    this.subject,
    this.language,
    required this.savedAt,
    this.explanation,
    this.example,
    this.imageLabel,
    this.questionText,
  });

  final String? id;
  final String topic;
  final String? subject;
  final String? language;
  final DateTime savedAt;
  final String? explanation;
  final String? example;
  final String? imageLabel;
  final String? questionText;

  String get resolvedSubject => subject ?? 'General';
  String get resolvedLanguage => language ?? 'English';
  String get resolvedExplanation =>
      explanation ?? 'Explanation will appear here after the student saves a lesson.';
  String get resolvedExample =>
      example ?? 'An example will appear here after the student saves a lesson.';
  String get resolvedImageLabel => imageLabel ?? topic;
  String get resolvedQuestionText => questionText ?? resolvedImageLabel;

  StudentLearningRecord copyWith({
    String? id,
    String? topic,
    String? subject,
    String? language,
    DateTime? savedAt,
    String? explanation,
    String? example,
    String? imageLabel,
    String? questionText,
  }) {
    return StudentLearningRecord(
      id: id ?? this.id,
      topic: topic ?? this.topic,
      subject: subject ?? this.subject,
      language: language ?? this.language,
      savedAt: savedAt ?? this.savedAt,
      explanation: explanation ?? this.explanation,
      example: example ?? this.example,
      imageLabel: imageLabel ?? this.imageLabel,
      questionText: questionText ?? this.questionText,
    );
  }

  Map<String, dynamic> toFirestore({
    required String studentId,
    required String studentName,
    String? classSection,
  }) {
    return {
      'topic': topic,
      'subject': resolvedSubject,
      'language': resolvedLanguage,
      'savedAt': Timestamp.fromDate(savedAt),
      'explanation': resolvedExplanation,
      'example': resolvedExample,
      'imageLabel': resolvedImageLabel,
      'questionText': resolvedQuestionText,
      'studentId': studentId,
      'studentName': studentName,
      'classSection': classSection,
    };
  }

  factory StudentLearningRecord.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return StudentLearningRecord(
      id: id,
      topic: data['topic']?.toString().trim().isNotEmpty == true
          ? data['topic'].toString().trim()
          : 'Untitled topic',
      subject: data['subject']?.toString().trim(),
      language: data['language']?.toString().trim(),
      savedAt: _readSavedAt(data['savedAt']),
      explanation: data['explanation']?.toString().trim(),
      example: data['example']?.toString().trim(),
      imageLabel: data['imageLabel']?.toString().trim(),
      questionText: data['questionText']?.toString().trim(),
    );
  }

  static DateTime _readSavedAt(Object? rawValue) {
    if (rawValue is Timestamp) {
      return rawValue.toDate();
    }

    if (rawValue is DateTime) {
      return rawValue;
    }

    if (rawValue is String) {
      return DateTime.tryParse(rawValue) ?? DateTime.now();
    }

    return DateTime.now();
  }
}
