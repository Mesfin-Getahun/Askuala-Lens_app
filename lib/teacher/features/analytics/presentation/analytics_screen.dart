import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../students/data/mock_student_records.dart';
import '../../students/domain/student_record.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

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

  List<StudentRecord> get _filteredStudents {
    return mockStudentRecords.where((student) {
      final matchesClass =
          _selectedClass == 'All Classes' ||
          student.className == _selectedClass;
      final matchesSection =
          _selectedSection == 'All Sections' ||
          student.section == _selectedSection;
      return matchesClass && matchesSection;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final students = _filteredStudents;
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
                selectedClass: _selectedClass,
                selectedSection: _selectedSection,
                onClassChanged: (value) =>
                    setState(() => _selectedClass = value),
                onSectionChanged: (value) =>
                    setState(() => _selectedSection = value),
              ),
              const SizedBox(height: 20),
              if (isNarrow) ...[
                _MetricCard(
                  label: 'Average Score',
                  value: average.toStringAsFixed(1),
                  accent: const Color(0xFF0F766E),
                  icon: Icons.show_chart,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  label: 'Highest Score',
                  value: '$highest',
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.keyboard_double_arrow_up,
                ),
                const SizedBox(height: 12),
                _MetricCard(
                  label: 'Lowest Score',
                  value: '$lowest',
                  accent: const Color(0xFFEA580C),
                  icon: Icons.keyboard_double_arrow_down,
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
                              xValueMapper: (_BarPoint point, _) => point.label,
                              yValueMapper: (_BarPoint point, _) => point.value,
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
                              xValueMapper: (_PiePoint point, _) => point.label,
                              yValueMapper: (_PiePoint point, _) => point.value,
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
                                  style: Theme.of(context).textTheme.bodyMedium,
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
        'No records match the selected filters yet.',
        'Run a scan for this class and section to generate insights.',
      ];
    }

    final weakFinals = students
        .where((student) => student.finalExam < 35)
        .length;
    final weakQuiz = students.where((student) => student.quiz < 9).length;
    final average =
        students.map((student) => student.total).reduce((a, b) => a + b) /
        students.length;

    return [
      'Most students struggled on Question 3 style items in the final section.',
      weakQuiz >= students.length / 2
          ? 'Weak area: fractions and foundational fluency need reinforcement.'
          : 'Class confidence is stronger in short quizzes than in long-form papers.',
      average < 70
          ? '$weakFinals students fell below 35 in the final section, so revision should focus on exam pacing.'
          : 'The class average is healthy, with room to push more students into the A band.',
    ];
  }
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
            'Spot trends fast with score cards, distributions, and teaching insights.',
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
    required this.onClassChanged,
    required this.onSectionChanged,
  });

  final String selectedClass;
  final String selectedSection;
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
                items: const ['All Classes', 'Grade 7', 'Grade 8'],
                onChanged: onClassChanged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FilterDropdown(
                label: 'Section',
                value: selectedSection,
                items: const ['All Sections', 'A', 'B', 'C'],
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
