import 'package:flutter/material.dart';

class StudentAssessmentsScreen extends StatelessWidget {
  const StudentAssessmentsScreen({super.key});

  static const _items = [
    _AssessmentItem(
      title: 'Quiz',
      subtitle: 'Check your latest quiz results and teacher feedback.',
      icon: Icons.quiz_rounded,
      accent: Color(0xFF2563EB),
    ),
    _AssessmentItem(
      title: 'Mid Exam',
      subtitle: 'Review mid exam progress and preparation notes.',
      icon: Icons.menu_book_rounded,
      accent: Color(0xFF0F766E),
    ),
    _AssessmentItem(
      title: 'Assignment',
      subtitle: 'Track assignments shared by your class teachers.',
      icon: Icons.assignment_rounded,
      accent: Color(0xFFEA580C),
    ),
    _AssessmentItem(
      title: 'Final Exam',
      subtitle: 'See final exam updates and upcoming class expectations.',
      icon: Icons.workspace_premium_rounded,
      accent: Color(0xFF7C3AED),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Assessments')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: const [
          _AssessmentsHeroCard(),
          SizedBox(height: 20),
          ..._items,
        ],
      ),
    );
  }
}

class _AssessmentsHeroCard extends StatelessWidget {
  const _AssessmentsHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your class assessments',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Open quizzes, mid exams, assignments, and final exam updates from one place.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentItem extends StatelessWidget {
  const _AssessmentItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
