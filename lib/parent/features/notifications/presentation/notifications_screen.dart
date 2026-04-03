import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../shared/presentation/parent_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.notifications,
  });

  final List<ParentNotificationRecord> notifications;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: notifications.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const ParentSectionHeader(
            title: 'Notifications',
            subtitle: 'Low scores, improvement alerts, teacher feedback, and weekly summaries.',
          );
        }

        return NotificationItem(notification: notifications[index - 1]);
      },
    );
  }
}
