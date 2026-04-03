import '../domain/student_record.dart';

const mockStudentRecords = <StudentRecord>[
  StudentRecord(
    name: 'Abel Otieno',
    className: 'Grade 7',
    section: 'A',
    quiz: 10,
    mid: 20,
    assignment: 15,
    finalExam: 40,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Fractions Quiz',
        comment:
            'Strong correction work. Keep showing full steps in simplification.',
        dateLabel: 'Apr 2',
      ),
      FeedbackEntry(
        title: 'Midterm Review',
        comment: 'Good recovery in algebra. Revise word problems carefully.',
        dateLabel: 'Mar 25',
      ),
    ],
  ),
  StudentRecord(
    name: 'Hana Bekele',
    className: 'Grade 7',
    section: 'A',
    quiz: 8,
    mid: 18,
    assignment: 14,
    finalExam: 35,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Fractions Quiz',
        comment: 'Neat work. Focus on equivalent fractions and final checks.',
        dateLabel: 'Apr 2',
      ),
      FeedbackEntry(
        title: 'Assignment Feedback',
        comment: 'Consistent effort. Add clearer workings for multistep items.',
        dateLabel: 'Mar 19',
      ),
    ],
  ),
  StudentRecord(
    name: 'Amina Hassan',
    className: 'Grade 7',
    section: 'A',
    quiz: 9,
    mid: 22,
    assignment: 16,
    finalExam: 31,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Scanned Script Review',
        comment: 'Great structure. Watch unit conversions in question 4.',
        dateLabel: 'Apr 3',
      ),
      FeedbackEntry(
        title: 'Midterm Review',
        comment: 'Solid reasoning. Practice speed on longer sections.',
        dateLabel: 'Mar 25',
      ),
    ],
  ),
  StudentRecord(
    name: 'Liya Tesfaye',
    className: 'Grade 8',
    section: 'B',
    quiz: 12,
    mid: 21,
    assignment: 17,
    finalExam: 38,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Final Mock',
        comment: 'Excellent progression. Continue revising geometry proofs.',
        dateLabel: 'Apr 1',
      ),
      FeedbackEntry(
        title: 'Assignment Feedback',
        comment: 'Strong accuracy. Explain final answers more clearly.',
        dateLabel: 'Mar 20',
      ),
    ],
  ),
  StudentRecord(
    name: 'Noah Kiptoo',
    className: 'Grade 8',
    section: 'B',
    quiz: 7,
    mid: 15,
    assignment: 13,
    finalExam: 29,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Final Mock',
        comment: 'You improved in computation. Spend extra time on fractions.',
        dateLabel: 'Apr 1',
      ),
      FeedbackEntry(
        title: 'Quiz Reflection',
        comment: 'Practice basic operations daily for better confidence.',
        dateLabel: 'Mar 16',
      ),
    ],
  ),
  StudentRecord(
    name: 'Marta Alemu',
    className: 'Grade 8',
    section: 'C',
    quiz: 11,
    mid: 19,
    assignment: 16,
    finalExam: 34,
    feedbackHistory: [
      FeedbackEntry(
        title: 'Assignment Feedback',
        comment: 'Creative approach. Check final arithmetic before submitting.',
        dateLabel: 'Apr 2',
      ),
      FeedbackEntry(
        title: 'Midterm Review',
        comment: 'Better pacing this time. Keep revising decimal operations.',
        dateLabel: 'Mar 25',
      ),
    ],
  ),
];
