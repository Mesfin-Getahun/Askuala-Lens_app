import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../../auth/data/firestore_login_service.dart';
import '../../students/domain/student_record.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedClass = 'All Classes';
  String _selectedSection = 'All Sections';
  late TooltipBehavior _tooltipBehavior;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  @override
  Widget build(BuildContext context) {
    final teacherStream = FirebaseFirestore.instance
        .collection('teachers')
        .doc(widget.teacher.id)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: teacherStream,
      builder: (context, teacherSnapshot) {
        final teacherData = teacherSnapshot.data?.data() ?? <String, dynamic>{};
        final teacherProfile = _TeacherAssignment.fromFirestore(teacherData);

        final classOptions = teacherProfile.classOptions;
        final resolvedClass = classOptions.contains(_selectedClass)
            ? _selectedClass
            : 'All Classes';
        if (resolvedClass != _selectedClass) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedClass = resolvedClass;
              _selectedSection = 'All Sections';
            });
          });
        }

        final sectionOptions = teacherProfile.sectionOptionsFor(resolvedClass);
        final resolvedSection = sectionOptions.contains(_selectedSection)
            ? _selectedSection
            : 'All Sections';
        if (resolvedSection != _selectedSection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedSection = resolvedSection;
            });
          });
        }

        final studentsStream = FirebaseFirestore.instance
            .collection('students')
            .snapshots();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: studentsStream,
          builder: (context, studentsSnapshot) {
            final roster = (studentsSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map(_StudentRosterEntry.fromDocument)
                .where(
                  (entry) => teacherProfile.matchesClassAndSection(
                    entry.className,
                    entry.section,
                  ),
                )
                .where((entry) {
                  final matchesClass =
                      resolvedClass == 'All Classes' ||
                      _normalizeClassValue(entry.className) ==
                          _normalizeClassValue(resolvedClass);
                  final matchesSection =
                      resolvedSection == 'All Sections' ||
                      _normalizeSectionValue(entry.section) ==
                          _normalizeSectionValue(resolvedSection);
                  return matchesClass && matchesSection;
                })
                .toList();

            final students = roster.map((entry) => entry.record).toList();
            final average = students.isEmpty
                ? 0
                : students.map((student) => student.total).reduce((a, b) => a + b) /
                      students.length;
            final highest = students.isEmpty
                ? 0
                : students
                      .map((student) => student.total)
                      .reduce((a, b) => a > b ? a : b);
            final lowest = students.isEmpty
                ? 0
                : students
                      .map((student) => student.total)
                      .reduce((a, b) => a < b ? a : b);

            final scoreDistribution = _buildScoreDistribution(students);
            final gradeDistribution = _buildGradeDistribution(students);

            return LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 720;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnalyticsHeroCard(studentCount: students.length),
                      const SizedBox(height: 20),
                      _AnalyticsFilters(
                        selectedClass: resolvedClass,
                        selectedSection: resolvedSection,
                        classItems: classOptions,
                        sectionItems: sectionOptions,
                        onClassChanged: (value) {
                          setState(() {
                            _selectedClass = value;
                            _selectedSection = 'All Sections';
                          });
                        },
                        onSectionChanged: (value) =>
                            setState(() => _selectedSection = value),
                      ),
                      const SizedBox(height: 20),
                      if (isNarrow) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Highest Score',
                                value: '$highest',
                                accent: const Color(0xFF1D4ED8),
                                icon: Icons.keyboard_double_arrow_up,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'Lowest Score',
                                value: '$lowest',
                                accent: const Color(0xFFEA580C),
                                icon: Icons.keyboard_double_arrow_down,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.62,
                            child: _MetricCard(
                              label: 'Average Score',
                              value: average.toStringAsFixed(1),
                              accent: const Color(0xFF0F766E),
                              icon: Icons.show_chart,
                            ),
                          ),
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Average Score',
                                value: average.toStringAsFixed(1),
                                accent: const Color(0xFF0F766E),
                                icon: Icons.show_chart,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'Highest Score',
                                value: '$highest',
                                accent: const Color(0xFF1D4ED8),
                                icon: Icons.keyboard_double_arrow_up,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MetricCard(
                                label: 'Lowest Score',
                                value: '$lowest',
                                accent: const Color(0xFFEA580C),
                                icon: Icons.keyboard_double_arrow_down,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      if (isNarrow) ...[
                        _ChartCard(
                          title: 'Score Distribution',
                          child: SfCartesianChart(
                            tooltipBehavior: _tooltipBehavior,
                            primaryXAxis: CategoryAxis(),
                            series: <CartesianSeries<_BarPoint, String>>[
                              ColumnSeries<_BarPoint, String>(
                                dataSource: scoreDistribution,
                                xValueMapper: (_BarPoint point, _) => point.label,
                                yValueMapper: (_BarPoint point, _) => point.value,
                                pointColorMapper: (_BarPoint point, _) => point.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ChartCard(
                          title: 'Grade Distribution',
                          child: SfCircularChart(
                            tooltipBehavior: _tooltipBehavior,
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                            ),
                            series: <CircularSeries<_PiePoint, String>>[
                              PieSeries<_PiePoint, String>(
                                dataSource: gradeDistribution,
                                xValueMapper: (_PiePoint point, _) => point.label,
                                yValueMapper: (_PiePoint point, _) => point.value,
                                pointColorMapper: (_PiePoint point, _) => point.color,
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ChartCard(
                                title: 'Score Distribution',
                                child: SfCartesianChart(
                                  tooltipBehavior: _tooltipBehavior,
                                  primaryXAxis: CategoryAxis(),
                                  series: <CartesianSeries<_BarPoint, String>>[
                                    ColumnSeries<_BarPoint, String>(
                                      dataSource: scoreDistribution,
                                      xValueMapper: (_BarPoint point, _) =>
                                          point.label,
                                      yValueMapper: (_BarPoint point, _) =>
                                          point.value,
                                      pointColorMapper: (_BarPoint point, _) =>
                                          point.color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ChartCard(
                                title: 'Grade Distribution',
                                child: SfCircularChart(
                                  tooltipBehavior: _tooltipBehavior,
                                  legend: const Legend(
                                    isVisible: true,
                                    position: LegendPosition.bottom,
                                  ),
                                  series: <CircularSeries<_PiePoint, String>>[
                                    PieSeries<_PiePoint, String>(
                                      dataSource: gradeDistribution,
                                      xValueMapper: (_PiePoint point, _) =>
                                          point.label,
                                      yValueMapper: (_PiePoint point, _) =>
                                          point.value,
                                      pointColorMapper: (_PiePoint point, _) =>
                                          point.color,
                                      dataLabelSettings: const DataLabelSettings(
                                        isVisible: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Insights',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 14),
                              ..._buildInsights(students).map(
                                (insight) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 3),
                                        child: Icon(
                                          Icons.auto_awesome,
                                          size: 18,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          insight,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<_BarPoint> _buildScoreDistribution(List<StudentRecord> students) {
    final bands = <String, int>{
      '0-49': 0,
      '50-59': 0,
      '60-69': 0,
      '70-79': 0,
      '80-100': 0,
    };

    for (final student in students) {
      final total = student.total;
      if (total < 50) {
        bands['0-49'] = bands['0-49']! + 1;
      } else if (total < 60) {
        bands['50-59'] = bands['50-59']! + 1;
      } else if (total < 70) {
        bands['60-69'] = bands['60-69']! + 1;
      } else if (total < 80) {
        bands['70-79'] = bands['70-79']! + 1;
      } else {
        bands['80-100'] = bands['80-100']! + 1;
      }
    }

    const colors = [
      Color(0xFFDC2626),
      Color(0xFFEA580C),
      Color(0xFFCA8A04),
      Color(0xFF1D4ED8),
      Color(0xFF0F766E),
    ];

    return bands.entries
        .toList()
        .asMap()
        .entries
        .map(
          (entry) => _BarPoint(
            entry.value.key,
            entry.value.value.toDouble(),
            colors[entry.key],
          ),
        )
        .toList();
  }

  List<_PiePoint> _buildGradeDistribution(List<StudentRecord> students) {
    final counts = <String, int>{'A': 0, 'B': 0, 'C': 0, 'D': 0, 'F': 0};

    for (final student in students) {
      counts[student.grade] = counts[student.grade]! + 1;
    }

    const palette = <String, Color>{
      'A': Color(0xFF0F766E),
      'B': Color(0xFF1D4ED8),
      'C': Color(0xFFCA8A04),
      'D': Color(0xFFEA580C),
      'F': Color(0xFFDC2626),
    };

    return counts.entries
        .map(
          (entry) =>
              _PiePoint(entry.key, entry.value.toDouble(), palette[entry.key]!),
        )
        .toList();
  }

  List<String> _buildInsights(List<StudentRecord> students) {
    if (students.isEmpty) {
      return const [
        'No Firestore student records match the selected filters yet.',
        'Select another class or section, or add student scores in the students collection.',
      ];
    }

    final weakFinals = students.where((student) => student.finalExam < 35).length;
    final weakQuiz = students.where((student) => student.quiz < 9).length;
    final average =
        students.map((student) => student.total).reduce((a, b) => a + b) /
        students.length;

    return [
      'These analytics are built from live student documents in Firestore for the selected teacher filters.',
      weakQuiz >= students.length / 2
          ? 'Most students need extra support in quiz performance and foundational fluency.'
          : 'Quiz performance is steadier than long-form assessment performance in this filtered group.',
      average < 70
          ? '$weakFinals students are below 35 in the final component, so revision should focus on exam pacing and reinforcement.'
          : 'The class average is healthy, with room to move more students into the A band.',
    ];
  }
}

class _TeacherAssignment {
  const _TeacherAssignment({
    required this.classes,
    required this.sectionsByClass,
  });

  final List<String> classes;
  final Map<String, List<String>> sectionsByClass;

  factory _TeacherAssignment.fromFirestore(Map<String, dynamic> data) {
    final classes = <String>{};
    final sectionsByClass = <String, List<String>>{};

    final classAssigned = data['classAssigned']?.toString().trim();
    if (classAssigned != null && classAssigned.isNotEmpty) {
      classes.add(classAssigned);
    }

    final classAssignments = (data['classAssignments'] as List? ?? const [])
        .followedBy(data['classesAssigned'] as List? ?? const [])
        .followedBy(data['assignedClasses'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty);
    classes.addAll(classAssignments);

    final sections = (data['sections'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (classAssigned != null && classAssigned.isNotEmpty) {
      sectionsByClass[classAssigned] = sections;
    }

    final rawSectionsByClass = data['sectionsByClass'];
    if (rawSectionsByClass is Map) {
      for (final entry in rawSectionsByClass.entries) {
        final className = entry.key.toString().trim();
        if (className.isEmpty) {
          continue;
        }

        final sectionList = (entry.value as List? ?? const [])
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList();
        classes.add(className);
        sectionsByClass[className] = sectionList;
      }
    }

    final sortedClasses = classes.toList()..sort();
    return _TeacherAssignment(
      classes: sortedClasses,
      sectionsByClass: sectionsByClass,
    );
  }

  List<String> get classOptions => ['All Classes', ...classes];

  List<String> sectionOptionsFor(String selectedClass) {
    if (selectedClass == 'All Classes') {
      final allSections = sectionsByClass.values
          .expand((sections) => sections)
          .toSet()
          .toList()
        ..sort();
      return ['All Sections', ...allSections];
    }

    final sections = sectionsByClass.entries
        .firstWhere(
          (entry) =>
              _normalizeClassValue(entry.key) ==
              _normalizeClassValue(selectedClass),
          orElse: () => const MapEntry('', <String>[]),
        )
        .value;
    final sortedSections = [...sections]..sort();
    return ['All Sections', ...sortedSections];
  }

  bool matchesClassAndSection(String className, String section) {
    if (classes.isNotEmpty &&
        !classes.any(
          (value) =>
              _normalizeClassValue(value) == _normalizeClassValue(className),
        )) {
      return false;
    }

    final normalizedEntry = sectionsByClass.entries.firstWhere(
      (entry) =>
          _normalizeClassValue(entry.key) == _normalizeClassValue(className),
      orElse: () => const MapEntry('', <String>[]),
    );
    final allowedSections = normalizedEntry.value;
    if (allowedSections.isEmpty) {
      return true;
    }

    return allowedSections.any(
      (value) =>
          _normalizeSectionValue(value) == _normalizeSectionValue(section),
    );
  }
}

class _StudentRosterEntry {
  const _StudentRosterEntry({
    required this.record,
    required this.className,
    required this.section,
  });

  final StudentRecord record;
  final String className;
  final String section;

  factory _StudentRosterEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _StudentRosterEntry(
      record: StudentRecord.fromFirestore(data),
      className: _readFirstString(data, const [
            'classAssigned',
            'class',
            'className',
            'grade',
          ]) ??
          'Unassigned',
      section: _readFirstString(data, const [
            'section',
            'sectionAssigned',
            'sectionName',
          ]) ??
          'Unknown',
    );
  }

  static String? _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }
}

String _normalizeClassValue(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }

  final gradeMatch = RegExp(r'(\d+)').firstMatch(trimmed);
  if (gradeMatch != null) {
    return 'grade${gradeMatch.group(1)}';
  }

  return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _normalizeSectionValue(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _AnalyticsHeroCard extends StatelessWidget {
  const _AnalyticsHeroCard({required this.studentCount});

  final int studentCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Spot trends fast with live Firestore score cards, distributions, and teaching insights.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              '$studentCount student records powering these analytics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsFilters extends StatelessWidget {
  const _AnalyticsFilters({
    required this.selectedClass,
    required this.selectedSection,
    required this.classItems,
    required this.sectionItems,
    required this.onClassChanged,
    required this.onSectionChanged,
  });

  final String selectedClass;
  final String selectedSection;
  final List<String> classItems;
  final List<String> sectionItems;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: 'Class',
                value: selectedClass,
                items: classItems,
                onChanged: onClassChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown(
                label: 'Section',
                value: selectedSection,
                items: sectionItems,
                onChanged: onSectionChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(height: 260, child: child),
          ],
        ),
      ),
    );
  }
}

class _BarPoint {
  const _BarPoint(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}

class _PiePoint {
  const _PiePoint(this.label, this.value, this.color);

  final String label;
  final double value;
  final Color color;
}
