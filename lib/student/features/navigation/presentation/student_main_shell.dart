import 'package:flutter/material.dart';

import '../../assessments/presentation/student_assessments_screen.dart';
import '../../chat/presentation/student_chat_screen.dart';
import '../../home/presentation/student_home_screen.dart';
import '../../learn/data/student_learning_history_repository.dart';
import '../../learn/presentation/student_learn_screen.dart';
import '../../profile/presentation/student_profile_screen.dart';
import '../../scan/presentation/student_scan_flow_screen.dart';
import '../../shared/domain/student_learning_record.dart';

class StudentMainShell extends StatefulWidget {
  const StudentMainShell({
    super.key,
    required this.studentId,
    required this.studentName,
    this.classSection,
    this.username,
  });

  final String studentId;
  final String studentName;
  final String? classSection;
  final String? username;

  @override
  State<StudentMainShell> createState() => _StudentMainShellState();
}

class _StudentMainShellState extends State<StudentMainShell> {
  final StudentLearningHistoryRepository _historyRepository =
      StudentLearningHistoryRepository();
  int _currentIndex = 0;
  String _currentLanguage = 'English';

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

  Future<void> _saveLearningRecord(StudentLearningRecord record) async {
    try {
      await _historyRepository.saveLearningRecord(
        studentId: widget.studentId,
        studentName: widget.studentName,
        classSection: widget.classSection,
        record: record,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentIndex = 2;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.topic} saved to Learning History.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save learning history. $error')),
      );
    }
  }

  Future<void> _deleteLearningRecord(StudentLearningRecord record) async {
    final recordId = record.id;
    if (recordId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This record is missing a database id.')),
      );
      return;
    }

    try {
      await _historyRepository.deleteLearningRecord(
        studentId: widget.studentId,
        recordId: recordId,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${record.topic} removed from Learning History.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete that record. $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentLearningRecord>>(
      stream: _historyRepository.watchLearningHistory(widget.studentId),
      builder: (context, snapshot) {
        final history = snapshot.data ?? const <StudentLearningRecord>[];

        final screens = <Widget>[
          StudentHomeScreen(
            studentName: widget.studentName,
            classSection: widget.classSection ?? 'Class section not assigned',
            learningHistory: history,
            onOpenScan: () => _selectTab(1),
            onOpenChat: () => _selectTab(3),
            onOpenLearning: () => _selectTab(2),
            onOpenAssessments: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StudentAssessmentsScreen(),
                ),
              );
            },
          ),
          StudentScanFlowScreen(
            selectedLanguage: _currentLanguage,
            onLanguageChanged: _updateLanguage,
            onSaveToHistory: (record) {
              _saveLearningRecord(record);
            },
          ),
          StudentLearnScreen(
            learningHistory: history,
            onDeleteRecord: _deleteLearningRecord,
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
      },
    );
  }
}
