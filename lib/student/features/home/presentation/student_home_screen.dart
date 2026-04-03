import 'package:flutter/material.dart';

import '../../navigation/presentation/student_main_shell.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({
    super.key,
    required this.studentName,
    required this.classSection,
    required this.learningHistory,
    required this.onOpenScan,
    required this.onOpenChat,
    required this.onOpenLearning,
  });

  final String studentName;
  final String classSection;
  final List<StudentLearningRecord> learningHistory;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenLearning;

  @override
  Widget build(BuildContext context) {
    final recentItems = learningHistory.take(3).toList();
    final latestTopic = learningHistory.isEmpty
        ? 'Start with your first scan'
        : learningHistory.first.topic;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(studentName: studentName, classSection: classSection),
            const SizedBox(height: 20),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: _QuickActionCard(
                    title: 'Scan & Explain',
                    subtitle: 'Capture a question and get help fast.',
                    icon: Icons.document_scanner_rounded,
                    accent: const Color(0xFF0F766E),
                    onTap: onOpenScan,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _QuickActionCard(
                    title: 'Ask Question',
                    subtitle: 'Chat with the tutor for follow-up help.',
                    icon: Icons.chat_bubble_rounded,
                    accent: const Color(0xFF2563EB),
                    onTap: onOpenChat,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: _QuickActionCard(
                    title: 'My Learning',
                    subtitle: 'Return to saved lessons and explanations.',
                    icon: Icons.auto_stories_rounded,
                    accent: const Color(0xFFEA580C),
                    onTap: onOpenLearning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _ContinueLearningCard(
              topic: latestTopic,
              onContinue: onOpenLearning,
            ),
            const SizedBox(height: 20),
            const _DailyInsightCard(),
            const SizedBox(height: 20),
            Text(
              'Recent Explanations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...recentItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecentExplanationTile(item: item),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.studentName,
    required this.classSection,
  });

  final String studentName;
  final String classSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF0EA5A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.school_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  studentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  classSection,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({
    required this.topic,
    required this.onContinue,
  });

  final String topic;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Continue Learning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            topic,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF111827),
            ),
            onPressed: onContinue,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _DailyInsightCard extends StatelessWidget {
  const _DailyInsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Insight',
            style: TextStyle(
              color: Color(0xFF92400E),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'You learned 3 topics today',
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Focus: Fractions',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _RecentExplanationTile extends StatelessWidget {
  const _RecentExplanationTile({required this.item});

  final StudentLearningRecord item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.topic, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  '${item.resolvedSubject} - ${item.resolvedLanguage}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
