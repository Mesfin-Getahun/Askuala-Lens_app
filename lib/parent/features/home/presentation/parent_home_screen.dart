import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../shared/presentation/parent_widgets.dart';

class ParentHomeScreen extends StatelessWidget {
  const ParentHomeScreen({
    super.key,
    required this.profile,
    required this.onOpenReports,
    required this.onOpenNotifications,
    required this.onOpenChildDetail,
  });

  final ParentProfile profile;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenNotifications;
  final ValueChanged<ParentChildRecord> onOpenChildDetail;

  @override
  Widget build(BuildContext context) {
    final featuredChild = profile.children.first;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEA580C),
                  Color(0xFFF59E0B),
                  Color(0xFF0F766E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${profile.name}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Track results, feedback, alerts, and practical next steps for your children.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms_outlined, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          profile.smsEnabled
                              ? 'SMS alerts are turned on for scores, feedback, and low-score warnings.'
                              : 'SMS alerts are currently turned off.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const ParentSectionHeader(
            title: 'Child Summary Cards',
            subtitle: 'Swipe if you have more than one child.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: profile.children.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final child = profile.children[index];
                return SizedBox(
                  width: 320,
                  child: ChildCard(
                    child: child,
                    onTap: () => onOpenChildDetail(child),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ParentSectionHeader(
            title: 'Quick Actions',
            action: FilledButton.tonalIcon(
              onPressed: () => onOpenChildDetail(featuredChild),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open Child'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  title: 'View Reports',
                  subtitle: 'See charts and simple insights',
                  icon: Icons.bar_chart_rounded,
                  color: const Color(0xFF2563EB),
                  onTap: onOpenReports,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  title: 'Check Alerts',
                  subtitle: 'Review low scores and feedback',
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFDC2626),
                  onTap: onOpenNotifications,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ParentSectionHeader(title: 'Performance Snapshot'),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ParentInfoCard(
                  title: 'Average Score',
                  value: '${featuredChild.averageScore}%',
                  icon: Icons.analytics_outlined,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ParentInfoCard(
                  title: 'Last Exam Score',
                  value: '${featuredChild.lastExamScore}%',
                  icon: Icons.fact_check_outlined,
                  color: const Color(0xFFEA580C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ParentSectionHeader(title: 'Recent Updates'),
          const SizedBox(height: 14),
          ...featuredChild.recentUpdates.map(
            (update) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEDD5),
                    child: Icon(Icons.update_rounded, color: Color(0xFFEA580C)),
                  ),
                  title: Text(update),
                  subtitle: const Text('Shared from the latest school activity feed'),
                ),
              ),
            ),
          ),
          ParentActionPrompt(child: featuredChild),
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
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
