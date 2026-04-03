import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../shared/presentation/parent_widgets.dart';
import 'child_detail_screen.dart';

class ChildrenScreen extends StatelessWidget {
  const ChildrenScreen({
    super.key,
    required this.children,
  });

  final List<ParentChildRecord> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: children.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const ParentSectionHeader(
            title: 'Children',
            subtitle: 'Tap any child to open score breakdown, teacher feedback, and the full report.',
          );
        }

        final child = children[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChildCard(
              child: child,
              onTap: () => _openDetail(context, child),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(child: Text(child.classSection)),
                    Text(
                      'Grade ${child.grade}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _openDetail(BuildContext context, ParentChildRecord child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildDetailScreen(child: child),
      ),
    );
  }
}
