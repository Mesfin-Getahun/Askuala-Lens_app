import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../shared/presentation/parent_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    super.key,
    required this.children,
  });

  final List<ParentChildRecord> children;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late ParentChildRecord _selectedChild;

  @override
  void initState() {
    super.initState();
    _selectedChild = widget.children.first;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ParentSectionHeader(
            title: 'Reports',
            subtitle: 'Simple analytics for parents in clear language.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<ParentChildRecord>(
            initialValue: _selectedChild,
            decoration: const InputDecoration(
              labelText: 'Select Child',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
                borderSide: BorderSide.none,
              ),
            ),
            items: widget.children
                .map(
                  (child) => DropdownMenuItem<ParentChildRecord>(
                    value: child,
                    child: Text('${child.name} | ${child.classSection}'),
                  ),
                )
                .toList(),
            onChanged: (child) {
              if (child == null) {
                return;
              }
              setState(() {
                _selectedChild = child;
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Average Score',
                  value: '${_selectedChild.averageScore}%',
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Highest Score',
                  value: '${_selectedChild.highestSubjectScore}%',
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Lowest Score',
                  value: '${_selectedChild.lowestSubjectScore}%',
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SubjectScoreBarChart(child: _selectedChild),
          const SizedBox(height: 20),
          GradeDistributionChart(child: _selectedChild),
          const SizedBox(height: 20),
          Text('Insights', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          ..._selectedChild.insights.map(
            (insight) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InsightCard(text: insight),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recommendation Section',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          ..._selectedChild.recommendations.map(
            (recommendation) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RecommendationCard(text: recommendation),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
