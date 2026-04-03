import 'package:flutter/material.dart';

class ParentProfile {
  const ParentProfile({
    required this.name,
    required this.phone,
    required this.language,
    required this.smsEnabled,
    required this.weeklySummary,
    required this.children,
    required this.notifications,
  });

  final String name;
  final String phone;
  final String language;
  final bool smsEnabled;
  final String weeklySummary;
  final List<ParentChildRecord> children;
  final List<ParentNotificationRecord> notifications;
}

class ParentChildRecord {
  const ParentChildRecord({
    required this.name,
    required this.className,
    required this.section,
    required this.totalScore,
    required this.grade,
    required this.statusLabel,
    required this.statusColor,
    required this.statusIcon,
    required this.averageScore,
    required this.lastExamScore,
    required this.teacherFeedback,
    required this.recentUpdates,
    required this.scoreBreakdown,
    required this.assessmentTrend,
    required this.subjectScores,
    required this.gradeDistribution,
    required this.insights,
    required this.recommendations,
    required this.contactTeacherLabel,
  });

  final String name;
  final String className;
  final String section;
  final int totalScore;
  final String grade;
  final String statusLabel;
  final Color statusColor;
  final IconData statusIcon;
  final int averageScore;
  final int lastExamScore;
  final List<String> teacherFeedback;
  final List<String> recentUpdates;
  final List<ScoreBreakdownItem> scoreBreakdown;
  final List<TrendPoint> assessmentTrend;
  final List<SubjectScore> subjectScores;
  final List<GradeSlice> gradeDistribution;
  final List<String> insights;
  final List<String> recommendations;
  final String contactTeacherLabel;

  String get classSection => '$className - $section';
  int get highestSubjectScore =>
      subjectScores.map((score) => score.score).reduce((a, b) => a > b ? a : b);
  int get lowestSubjectScore =>
      subjectScores.map((score) => score.score).reduce((a, b) => a < b ? a : b);
}

class ScoreBreakdownItem {
  const ScoreBreakdownItem({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.score});

  final String label;
  final int score;
}

class SubjectScore {
  const SubjectScore({
    required this.subject,
    required this.score,
    required this.color,
  });

  final String subject;
  final int score;
  final Color color;
}

class GradeSlice {
  const GradeSlice({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;
}

enum ParentNotificationType { lowScore, improvement, feedback, summary }

class ParentNotificationRecord {
  const ParentNotificationRecord({
    required this.type,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.childName,
    this.subject,
  });

  final ParentNotificationType type;
  final String title;
  final String message;
  final String timeLabel;
  final String? childName;
  final String? subject;

  IconData get icon => switch (type) {
    ParentNotificationType.lowScore => Icons.warning_amber_rounded,
    ParentNotificationType.improvement => Icons.trending_up_rounded,
    ParentNotificationType.feedback => Icons.mail_outline_rounded,
    ParentNotificationType.summary => Icons.summarize_outlined,
  };

  Color get color => switch (type) {
    ParentNotificationType.lowScore => const Color(0xFFDC2626),
    ParentNotificationType.improvement => const Color(0xFF16A34A),
    ParentNotificationType.feedback => const Color(0xFF2563EB),
    ParentNotificationType.summary => const Color(0xFFF59E0B),
  };
}

const ParentProfile mockParentProfile = ParentProfile(
  name: 'Mrs. Rahel Bekele',
  phone: '+251 91 223 4455',
  language: 'English',
  smsEnabled: true,
  weeklySummary:
      'This week: Average 72%, quiz results improved, and assignments need more attention.',
  children: [
    ParentChildRecord(
      name: 'Abel Bekele',
      className: 'Grade 7',
      section: 'Section A',
      totalScore: 78,
      grade: 'B',
      statusLabel: 'Improving',
      statusColor: Color(0xFF16A34A),
      statusIcon: Icons.trending_up_rounded,
      averageScore: 76,
      lastExamScore: 81,
      teacherFeedback: [
        'Abel is participating more in class discussions.',
        'Needs a little more support when solving long math questions.',
      ],
      recentUpdates: [
        'Mid exam result added',
        'New feedback from teacher',
      ],
      scoreBreakdown: [
        ScoreBreakdownItem(
          label: 'Quiz',
          score: 80,
          color: Color(0xFF16A34A),
        ),
        ScoreBreakdownItem(
          label: 'Assignment',
          score: 69,
          color: Color(0xFFF59E0B),
        ),
        ScoreBreakdownItem(
          label: 'Mid',
          score: 75,
          color: Color(0xFF2563EB),
        ),
        ScoreBreakdownItem(
          label: 'Final',
          score: 88,
          color: Color(0xFF7C3AED),
        ),
      ],
      assessmentTrend: [
        TrendPoint(label: 'Jan', score: 67),
        TrendPoint(label: 'Feb', score: 72),
        TrendPoint(label: 'Mar', score: 75),
        TrendPoint(label: 'Apr', score: 78),
      ],
      subjectScores: [
        SubjectScore(
          subject: 'Math',
          score: 64,
          color: Color(0xFFDC2626),
        ),
        SubjectScore(
          subject: 'English',
          score: 82,
          color: Color(0xFF16A34A),
        ),
        SubjectScore(
          subject: 'Science',
          score: 79,
          color: Color(0xFF2563EB),
        ),
        SubjectScore(
          subject: 'Social',
          score: 86,
          color: Color(0xFFF59E0B),
        ),
      ],
      gradeDistribution: [
        GradeSlice(label: 'A', value: 20, color: Color(0xFF16A34A)),
        GradeSlice(label: 'B', value: 45, color: Color(0xFF2563EB)),
        GradeSlice(label: 'C', value: 25, color: Color(0xFFF59E0B)),
        GradeSlice(label: 'D', value: 10, color: Color(0xFFDC2626)),
      ],
      insights: [
        'Needs support in Mathematics.',
        'Improving in English.',
      ],
      recommendations: [
        'Practice basic fraction problems at home.',
        'Ask the teacher for one extra math exercise sheet.',
      ],
      contactTeacherLabel: 'Contact Math Teacher',
    ),
    ParentChildRecord(
      name: 'Mahi Bekele',
      className: 'Grade 4',
      section: 'Section C',
      totalScore: 84,
      grade: 'A-',
      statusLabel: 'Steady',
      statusColor: Color(0xFFF59E0B),
      statusIcon: Icons.horizontal_rule_rounded,
      averageScore: 82,
      lastExamScore: 84,
      teacherFeedback: [
        'Mahi reads well and completes classwork on time.',
        'Encourage more practice in writing longer answers.',
      ],
      recentUpdates: [
        'Quiz score improved to 85%',
        'Weekly summary generated',
      ],
      scoreBreakdown: [
        ScoreBreakdownItem(
          label: 'Quiz',
          score: 85,
          color: Color(0xFF16A34A),
        ),
        ScoreBreakdownItem(
          label: 'Assignment',
          score: 78,
          color: Color(0xFFF59E0B),
        ),
        ScoreBreakdownItem(
          label: 'Mid',
          score: 83,
          color: Color(0xFF2563EB),
        ),
        ScoreBreakdownItem(
          label: 'Final',
          score: 90,
          color: Color(0xFF7C3AED),
        ),
      ],
      assessmentTrend: [
        TrendPoint(label: 'Jan', score: 79),
        TrendPoint(label: 'Feb', score: 81),
        TrendPoint(label: 'Mar', score: 82),
        TrendPoint(label: 'Apr', score: 84),
      ],
      subjectScores: [
        SubjectScore(
          subject: 'Math',
          score: 77,
          color: Color(0xFFF59E0B),
        ),
        SubjectScore(
          subject: 'English',
          score: 88,
          color: Color(0xFF16A34A),
        ),
        SubjectScore(
          subject: 'Science',
          score: 83,
          color: Color(0xFF2563EB),
        ),
        SubjectScore(
          subject: 'Civics',
          score: 86,
          color: Color(0xFF7C3AED),
        ),
      ],
      gradeDistribution: [
        GradeSlice(label: 'A', value: 35, color: Color(0xFF16A34A)),
        GradeSlice(label: 'B', value: 40, color: Color(0xFF2563EB)),
        GradeSlice(label: 'C', value: 20, color: Color(0xFFF59E0B)),
        GradeSlice(label: 'D', value: 5, color: Color(0xFFDC2626)),
      ],
      insights: [
        'Strong reading performance in English.',
        'Math is average and can improve with extra practice.',
      ],
      recommendations: [
        'Read one short passage together every evening.',
        'Practice three word problems each weekend.',
      ],
      contactTeacherLabel: 'Contact Class Teacher',
    ),
  ],
  notifications: [
    ParentNotificationRecord(
      type: ParentNotificationType.lowScore,
      title: 'Low Score Alert',
      message: 'Abel\'s math mid exam dropped to 45%.',
      timeLabel: 'Today, 10:20 AM',
      childName: 'Abel Bekele',
      subject: 'Mathematics',
    ),
    ParentNotificationRecord(
      type: ParentNotificationType.improvement,
      title: 'Improvement',
      message: 'Mahi\'s quiz score improved to 85%.',
      timeLabel: 'Today, 8:10 AM',
      childName: 'Mahi Bekele',
      subject: 'English',
    ),
    ParentNotificationRecord(
      type: ParentNotificationType.feedback,
      title: 'Teacher Feedback',
      message: 'Abel needs help with algebra this week.',
      timeLabel: 'Yesterday',
      childName: 'Abel Bekele',
      subject: 'Mathematics',
    ),
    ParentNotificationRecord(
      type: ParentNotificationType.summary,
      title: 'Weekly Summary',
      message:
          'Average is 72%. Quizzes improved, but assignments need more focus.',
      timeLabel: 'Monday',
    ),
  ],
);
