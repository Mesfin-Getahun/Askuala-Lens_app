import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../auth/data/firestore_login_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.teacher,
    required this.onOpenScan,
    required this.onOpenStudents,
    required this.onOpenAnalytics,
    required this.onOpenAttendance,
  });

  final AppUser teacher;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenStudents;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenAttendance;

  @override
  Widget build(BuildContext context) {
    final teacherDocStream = FirebaseFirestore.instance
        .collection('teachers')
        .doc(teacher.id)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: teacherDocStream,
      builder: (context, teacherSnapshot) {
        final teacherData = teacherSnapshot.data?.data() ?? <String, dynamic>{};
        final teacherProfile = _TeacherProfile.fromFirestore(
          teacher,
          teacherData,
        );

        final studentsStream = FirebaseFirestore.instance
            .collection('students')
            .where(
              'classAssigned',
              isEqualTo: teacherProfile.classAssigned,
            )
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: studentsStream,
          builder: (context, studentsSnapshot) {
            final studentDocs =
                studentsSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final matchedStudents = studentDocs
                .where(
                  (doc) => teacherProfile.matchesSection(
                    doc.data()['section']?.toString() ??
                        doc.data()['sectionAssigned']?.toString(),
                  ),
                )
                .toList();
            final dashboardData = _DashboardData.fromFirestore(
              teacherProfile: teacherProfile,
              students: matchedStudents,
            );

            return _DashboardContent(
              teacherProfile: teacherProfile,
              dashboardData: dashboardData,
              isLoading:
                  teacherSnapshot.connectionState == ConnectionState.waiting ||
                  studentsSnapshot.connectionState == ConnectionState.waiting,
              onOpenScan: onOpenScan,
              onOpenStudents: onOpenStudents,
              onOpenAnalytics: onOpenAnalytics,
              onOpenAttendance: onOpenAttendance,
            );
          },
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.teacherProfile,
    required this.dashboardData,
    required this.isLoading,
    required this.onOpenScan,
    required this.onOpenStudents,
    required this.onOpenAnalytics,
    required this.onOpenAttendance,
  });

  final _TeacherProfile teacherProfile;
  final _DashboardData dashboardData;
  final bool isLoading;
  final VoidCallback onOpenScan;
  final VoidCallback onOpenStudents;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onOpenAttendance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Color(0xFF0F766E),
                  Color(0xFF115E59),
                  Color(0xFF1D4ED8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${teacherProfile.displayName}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  teacherProfile.heroSubtitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isLoading
                              ? 'Syncing teacher and student dashboard data...'
                              : dashboardData.syncMessage,
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
          Text('Quick Actions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              _QuickActionCard(
                title: 'Scan Papers',
                subtitle: 'Start a grading session',
                icon: Icons.document_scanner,
                accent: const Color(0xFF0F766E),
                onTap: onOpenScan,
              ),
              _QuickActionCard(
                title: 'View Students',
                subtitle: 'Open class roster',
                icon: Icons.groups_2,
                accent: const Color(0xFF1D4ED8),
                onTap: onOpenStudents,
              ),
              _QuickActionCard(
                title: 'Analytics',
                subtitle: 'Check trends',
                icon: Icons.insights,
                accent: const Color(0xFFEA580C),
                onTap: onOpenAnalytics,
              ),
              _QuickActionCard(
                title: 'Attendance',
                subtitle: 'Track class presence',
                icon: Icons.fact_check_outlined,
                accent: const Color(0xFF7C3AED),
                onTap: onOpenAttendance,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent Activity', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          ...dashboardData.recentActivities.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _InfoCard(
                icon: item.icon,
                title: item.title,
                subtitle: item.subtitle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Class Summary Cards', style: theme.textTheme.titleLarge),
          const SizedBox(height: 14),
          if (dashboardData.classSummaries.isEmpty)
            const _InfoCard(
              icon: Icons.info_outline,
              title: 'No class summary data',
              subtitle:
                  'No student documents currently match this teacher assignment in Firestore.',
            )
          else
            ...dashboardData.classSummaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ClassSummaryCard(summary: summary),
              ),
            ),
        ],
      ),
    );
  }
}

class _TeacherProfile {
  const _TeacherProfile({
    required this.id,
    required this.displayName,
    required this.classAssigned,
    required this.sections,
    required this.subjects,
    required this.status,
  });

  final String id;
  final String displayName;
  final String classAssigned;
  final List<String> sections;
  final List<String> subjects;
  final String status;

  factory _TeacherProfile.fromFirestore(
    AppUser teacher,
    Map<String, dynamic> data,
  ) {
    final firstName = data['firstName']?.toString().trim();
    final lastName = data['lastName']?.toString().trim();
    final fullName = [firstName, lastName]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' ');

    return _TeacherProfile(
      id: teacher.id,
      displayName: fullName.isNotEmpty ? fullName : teacher.displayName,
      classAssigned: data['classAssigned']?.toString().trim() ?? 'Class not set',
      sections: (data['sections'] as List? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      subjects: (data['subjects'] as List? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      status: data['status']?.toString().trim() ?? 'unknown',
    );
  }

  String get heroSubtitle {
    final subjectLabel = subjects.isEmpty ? 'No subject assigned' : subjects.join(', ');
    final sectionLabel = sections.isEmpty ? 'All sections' : sections.join(', ');
    return '$classAssigned | Sections $sectionLabel | $subjectLabel';
  }

  bool matchesSection(String? value) {
    if (sections.isEmpty) {
      return true;
    }

    final normalizedValue = value?.trim().toLowerCase();
    if (normalizedValue == null || normalizedValue.isEmpty) {
      return false;
    }

    return sections.any((section) => section.toLowerCase() == normalizedValue);
  }
}

class _DashboardData {
  const _DashboardData({
    required this.syncMessage,
    required this.recentActivities,
    required this.classSummaries,
  });

  final String syncMessage;
  final List<_ActivityItem> recentActivities;
  final List<_ClassSummaryData> classSummaries;

  factory _DashboardData.fromFirestore({
    required _TeacherProfile teacherProfile,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  }) {
    final totalStudents = students.length;
    final activeStudents = students.where((doc) {
      final status = doc.data()['status']?.toString().trim().toLowerCase();
      return status == null || status.isEmpty || status == 'active';
    }).length;

    final summaries = _buildClassSummaries(students);
    final sectionLabel = teacherProfile.sections.isEmpty
        ? 'all sections'
        : teacherProfile.sections.join(', ');
    final subjectLabel = teacherProfile.subjects.isEmpty
        ? 'assigned subjects not listed'
        : teacherProfile.subjects.join(', ');

    return _DashboardData(
      syncMessage:
          '$activeStudents active students loaded from Firestore for ${teacherProfile.classAssigned}.',
      recentActivities: [
        _ActivityItem(
          icon: Icons.person_outline_rounded,
          title: 'Current teacher profile',
          subtitle:
              '${teacherProfile.displayName} is marked ${teacherProfile.status} and assigned to ${teacherProfile.classAssigned}.',
        ),
        _ActivityItem(
          icon: Icons.menu_book_rounded,
          title: 'Assigned teaching load',
          subtitle:
              'Teaching $subjectLabel across $sectionLabel in ${teacherProfile.classAssigned}.',
        ),
        _ActivityItem(
          icon: Icons.groups_rounded,
          title: 'Live student roster',
          subtitle:
              '$totalStudents students matched this teacher assignment, with $activeStudents currently active.',
        ),
      ],
      classSummaries: summaries,
    );
  }

  static List<_ClassSummaryData> _buildClassSummaries(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> students,
  ) {
    final grouped = <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
    for (final doc in students) {
      final data = doc.data();
      final className =
          data['classAssigned']?.toString().trim() ??
          data['class']?.toString().trim() ??
          'Unassigned class';
      final section =
          data['section']?.toString().trim() ??
          data['sectionAssigned']?.toString().trim() ??
          'Unknown section';
      final key = '$className|$section';
      grouped.putIfAbsent(key, () => []).add(doc);
    }

    const accents = [
      Color(0xFF0F766E),
      Color(0xFF1D4ED8),
      Color(0xFFEA580C),
      Color(0xFF7C3AED),
    ];

    final summaries = <_ClassSummaryData>[];
    var colorIndex = 0;

    for (final entry in grouped.entries) {
      final items = entry.value;
      final first = items.first.data();
      final className =
          first['classAssigned']?.toString().trim() ??
          first['class']?.toString().trim() ??
          'Unassigned class';
      final section =
          first['section']?.toString().trim() ??
          first['sectionAssigned']?.toString().trim() ??
          'Unknown section';
      final scores = items
          .map((doc) => _extractScore(doc.data()))
          .whereType<double>()
          .toList();
      final averageScore = scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length;

      summaries.add(
        _ClassSummaryData(
          className: '$className $section',
          studentCount: items.length,
          averageScore: averageScore,
          accent: accents[colorIndex % accents.length],
        ),
      );
      colorIndex++;
    }

    summaries.sort((a, b) => a.className.compareTo(b.className));
    return summaries;
  }

  static double? _extractScore(Map<String, dynamic> data) {
    const scoreFields = [
      'averageScore',
      'score',
      'resultAverage',
      'totalScore',
      'teacherAdjustedScore',
    ];

    for (final field in scoreFields) {
      final rawValue = data[field];
      if (rawValue is num) {
        return rawValue.toDouble();
      }

      final parsedValue = double.tryParse(rawValue?.toString() ?? '');
      if (parsedValue != null) {
        return parsedValue;
      }
    }

    return null;
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class _ClassSummaryData {
  const _ClassSummaryData({
    required this.className,
    required this.studentCount,
    required this.averageScore,
    required this.accent,
  });

  final String className;
  final int studentCount;
  final double? averageScore;
  final Color accent;
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(height: 18),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(subtitle, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassSummaryCard extends StatelessWidget {
  const _ClassSummaryCard({required this.summary});

  final _ClassSummaryData summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final average = summary.averageScore;
    final normalizedAverage = average == null
        ? 0.0
        : (average.clamp(0, 100) / 100).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: summary.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(summary.className, style: theme.textTheme.titleMedium),
                const Spacer(),
                Text(
                  average == null
                      ? 'Avg: N/A'
                      : 'Avg: ${average.toStringAsFixed(0)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: summary.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: normalizedAverage,
                minHeight: 10,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(summary.accent),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              average == null
                  ? '${summary.studentCount} students found in Firestore. No score field is stored yet for average calculation.'
                  : '${summary.studentCount} students included in this Firestore class summary.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
