import 'package:flutter/material.dart';

import '../../navigation/presentation/student_main_shell.dart';

class StudentLearnScreen extends StatefulWidget {
  const StudentLearnScreen({
    super.key,
    required this.learningHistory,
    required this.onDeleteRecord,
  });

  final List<StudentLearningRecord> learningHistory;
  final ValueChanged<StudentLearningRecord> onDeleteRecord;

  @override
  State<StudentLearnScreen> createState() => _StudentLearnScreenState();
}

class _StudentLearnScreenState extends State<StudentLearnScreen> {
  String _selectedSubject = 'All';
  String _selectedDate = 'All Time';

  @override
  void didUpdateWidget(covariant StudentLearnScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_subjects.contains(_selectedSubject)) {
      _selectedSubject = 'All';
    }
  }

  List<String> get _subjects {
    final values = widget.learningHistory
        .map((item) => item.resolvedSubject)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<StudentLearningRecord> get _filteredHistory {
    return widget.learningHistory.where((item) {
      final matchesSubject =
          _selectedSubject == 'All' || item.resolvedSubject == _selectedSubject;
      final matchesDate = switch (_selectedDate) {
        'Today' => _isToday(item.savedAt),
        'This Week' => DateTime.now().difference(item.savedAt).inDays < 7,
        _ => true,
      };
      return matchesSubject && matchesDate;
    }).toList();
  }

  bool _isToday(DateTime value) {
    final now = DateTime.now();
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  String _formatSavedAt(DateTime value) {
    final hour = value.hour == 0
        ? 12
        : value.hour > 12
            ? value.hour - 12
            : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.month}/${value.day} $hour:$minute $period';
  }

  Future<void> _openDetail(StudentLearningRecord item) async {
    String selectedLanguage = item.resolvedLanguage;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.84,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 54,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(item.topic, style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${item.resolvedSubject} - $selectedLanguage - ${_formatSavedAt(item.savedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 18),
                      Text('Image', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Text(
                            item.resolvedImageLabel,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailCard(
                                title: 'Explanation',
                                color: const Color(0xFFE0F2FE),
                                text: item.resolvedExplanation,
                              ),
                              const SizedBox(height: 14),
                              _DetailCard(
                                title: 'Example',
                                color: const Color(0xFFDCFCE7),
                                text: item.resolvedExample,
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Actions',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Re-explaining ${item.topic}.'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Re-explain'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final nextLanguage = await showModalBottomSheet<String>(
                                        context: context,
                                        builder: (context) {
                                          final languages = [
                                            'English',
                                            'Amharic',
                                            'Afaan Oromoo',
                                            'Tigrinya',
                                          ];
                                          return SafeArea(
                                            child: Padding(
                                              padding: const EdgeInsets.all(20),
                                              child: Wrap(
                                                spacing: 10,
                                                runSpacing: 10,
                                                children: languages
                                                    .map(
                                                      (language) => ChoiceChip(
                                                        label: Text(language),
                                                        selected: selectedLanguage == language,
                                                        onSelected: (_) {
                                                          Navigator.of(context).pop(language);
                                                        },
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ),
                                          );
                                        },
                                      );

                                      if (nextLanguage != null) {
                                        setModalState(() {
                                          selectedLanguage = nextLanguage;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.translate_rounded),
                                    label: const Text('Change language'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      widget.onDeleteRecord(item);
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                    ),
                                    icon: const Icon(Icons.delete_outline_rounded),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = _filteredHistory;
    final subjectValue =
        _subjects.contains(_selectedSubject) ? _selectedSubject : 'All';

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Learning History', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Review saved explanations, filter them quickly, and open any item for more detail.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<String>(
                      value: subjectValue,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                      ),
                      items: _subjects
                          .map(
                            (subject) => DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSubject = value;
                          });
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: DropdownButtonFormField<String>(
                      value: _selectedDate,
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'All Time', child: Text('All Time')),
                        DropdownMenuItem(value: 'Today', child: Text('Today')),
                        DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDate = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: Text('Image', style: TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(flex: 3, child: Text('Topic', style: TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(flex: 2, child: Text('Language', style: TextStyle(fontWeight: FontWeight.w700))),
                  Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('No saved explanations match the selected filters.'),
              )
            else
              ...history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _openDetail(item),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              height: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                item.resolvedImageLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Text(
                              item.topic,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(item.resolvedLanguage),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatSavedAt(item.savedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.title,
    required this.color,
    required this.text,
  });

  final String title;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
