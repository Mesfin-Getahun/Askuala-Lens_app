import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../shared/presentation/parent_widgets.dart';

class ChildDetailScreen extends StatelessWidget {
  const ChildDetailScreen({
    super.key,
    required this.child,
  });

  final ParentChildRecord child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(child.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Student Info', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 14),
                    _DetailRow(label: 'Name', value: child.name),
                    _DetailRow(label: 'Class / Section', value: child.classSection),
                    _DetailRow(label: 'Total Score', value: '${child.totalScore}%'),
                    _DetailRow(label: 'Grade', value: child.grade),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Score Breakdown', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: ScoreBreakdown(items: child.scoreBreakdown),
              ),
            ),
            const SizedBox(height: 20),
            ProgressChart(child: child),
            const SizedBox(height: 20),
            Text('Teacher Feedback', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...child.teacherFeedback.map(
              (feedback) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.comment_outlined, color: Color(0xFF2563EB)),
                    ),
                    title: Text(feedback),
                    subtitle: const Text('Latest comments from teacher'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full report opened from the reports tab view.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('View Full Report'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${child.contactTeacherLabel} coming soon.')),
                    );
                  },
                  icon: const Icon(Icons.sms_outlined),
                  label: Text(child.contactTeacherLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
