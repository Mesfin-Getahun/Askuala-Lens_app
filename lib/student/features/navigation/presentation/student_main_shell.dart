import 'package:flutter/material.dart';

import '../../chat/presentation/student_chat_screen.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../learn/presentation/student_learn_screen.dart';
import '../../profile/presentation/student_profile_screen.dart';
import '../../scan/presentation/student_scan_flow_screen.dart';

class StudentLearningRecord {
  const StudentLearningRecord({
    required this.topic,
    this.subject,
    this.language,
    required this.savedAt,
    this.explanation,
    this.example,
    this.imageLabel,
  });

  final String topic;
  final String? subject;
  final String? language;
  final DateTime savedAt;
  final String? explanation;
  final String? example;
  final String? imageLabel;

  String get resolvedSubject => subject ?? 'General';
  String get resolvedLanguage => language ?? 'English';
  String get resolvedExplanation =>
      explanation ?? 'Explanation will appear here after the student saves a lesson.';
  String get resolvedExample =>
      example ?? 'An example will appear here after the student saves a lesson.';
  String get resolvedImageLabel => imageLabel ?? topic;
}

class StudentMainShell extends StatefulWidget {
  const StudentMainShell({
    super.key,
    required this.studentName,
    this.classSection,
  });

  final String studentName;
  final String? classSection;

  @override
  State<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends State<StudentMainShell> {
  int _currentIndex = 0;
  String _currentLanguage = 'English';
  final List<StudentLearningRecord> _history = [
    StudentLearningRecord(
      topic: 'Fractions on a Number Line',
      subject: 'Mathematics',
      language: 'English',
      savedAt: DateTime.now().subtract(const Duration(minutes: 20)),
      explanation:
          'A fraction shows a part of a whole, and the number line helps you see where that part sits between 0 and 1.',
      example:
          'If one injera is shared into 4 equal pieces and you take 3 pieces, that is 3/4.',
      imageLabel: 'Fractions Question',
    ),
    StudentLearningRecord(
      topic: 'Plant Parts and Functions',
      subject: 'Biology',
      language: 'Amharic',
      savedAt: DateTime.now().subtract(const Duration(hours: 2)),
      explanation:
          'Roots hold the plant and take in water, while leaves make food using sunlight.',
      example:
          'A maize plant in the school garden uses roots to absorb water after rain.',
      imageLabel: 'Plant Parts Diagram',
    ),
    StudentLearningRecord(
      topic: 'Map Symbols',
      subject: 'Geography',
      language: 'Afaan Oromoo',
      savedAt: DateTime.now().subtract(const Duration(hours: 5)),
      explanation:
          'Map symbols use small pictures and shapes to represent real places like schools, roads, and rivers.',
      example:
          'A small cross on a town map can represent a clinic near the market.',
      imageLabel: 'Map Symbols Exercise',
    ),
  ];

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _updateLanguage(String language) {
    setState(() {
      _currentLanguage = language;
    });
  }

  void _saveLearningRecord(StudentLearningRecord record) {
    setState(() {
      _history.insert(0, record);
      _currentIndex = 2;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${record.topic} saved to Learning History.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      StudentHomeScreen(
        studentName: widget.studentName,
        classSection: widget.classSection ?? 'Class section not assigned',
        learningHistory: _history,
        onOpenScan: () => _selectTab(1),
        onOpenChat: () => _selectTab(3),
        onOpenLearning: () => _selectTab(2),
      ),
      StudentScanFlowScreen(
        selectedLanguage: _currentLanguage,
        onLanguageChanged: _updateLanguage,
        onSaveToHistory: _saveLearningRecord,
      ),
      StudentLearnScreen(
        learningHistory: _history,
        onDeleteRecord: (record) {
          setState(() {
            _history.remove(record);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${record.topic} removed from Learning History.')),
          );
        },
      ),
      const StudentChatScreen(),
      StudentProfileScreen(
        defaultLanguage: _currentLanguage,
        onLanguageChanged: _updateLanguage,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'student-language-fab',
            onPressed: () async {
              final selected = await showModalBottomSheet<String>(
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
                                selected: _currentLanguage == language,
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

              if (selected != null) {
                _updateLanguage(selected);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language switched to $selected.')),
                  );
                }
              }
            },
            child: const Icon(Icons.translate_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'student-scan-fab',
            onPressed: () => _selectTab(1),
            icon: const Icon(Icons.document_scanner_rounded),
            label: const Text('Scan'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.document_scanner_outlined),
            activeIcon: Icon(Icons.document_scanner_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_edu_outlined),
            activeIcon: Icon(Icons.history_edu_rounded),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
