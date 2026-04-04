import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../auth/data/firestore_login_service.dart';
import '../domain/student_record.dart';
import 'student_detail_screen.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String _selectedClass = 'All Classes';
  String _selectedSection = 'All Sections';

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
            final allStudents = (studentsSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map(_StudentRosterEntry.fromDocument)
                .where(
                  (entry) => teacherProfile.matchesClassAndSection(
                    entry.className,
                    entry.section,
                  ),
                )
                .toList();

            final students = allStudents.where((student) {
              final matchesClass =
                  resolvedClass == 'All Classes' ||
                  _normalizeClassValue(student.className) ==
                      _normalizeClassValue(resolvedClass);
              final matchesSection =
                  resolvedSection == 'All Sections' ||
                  _normalizeSectionValue(student.section) ==
                      _normalizeSectionValue(resolvedSection);
              return matchesClass && matchesSection;
            }).map((entry) => entry.record).toList();

            final average = students.isEmpty
                ? 0
                : students.map((student) => student.total).reduce((a, b) => a + b) ~/
                      students.length;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StudentsHeroCard(studentCount: students.length, average: average),
                  const SizedBox(height: 20),
                  _FilterCard(
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Students Table',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Live Firestore data',
                                  style: TextStyle(
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFFF8FAFC),
                              ),
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Quiz')),
                                DataColumn(label: Text('Mid')),
                                DataColumn(label: Text('Assign')),
                                DataColumn(label: Text('Final')),
                                DataColumn(label: Text('Total')),
                                DataColumn(label: Text('Grade')),
                              ],
                              rows: students
                                  .map(
                                    (student) => DataRow(
                                      onSelectChanged: (selected) {
                                        if (selected ?? false) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) => StudentDetailScreen(
                                                student: student,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      cells: [
                                        DataCell(
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                student.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                student.classLabel,
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text('${student.quiz}')),
                                        DataCell(Text('${student.mid}')),
                                        DataCell(Text('${student.assignment}')),
                                        DataCell(Text('${student.finalExam}')),
                                        DataCell(Text('${student.total}')),
                                        DataCell(_GradeBadge(grade: student.grade)),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                          if (students.isEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'No students found for the selected teacher filters.',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
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

class _StudentsHeroCard extends StatelessWidget {
  const _StudentsHeroCard({required this.studentCount, required this.average});

  final int studentCount;
  final int average;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Students',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'Track scores, open student details, and review feedback history.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Visible Students',
                  value: '$studentCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStat(label: 'Average Total', value: '$average%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 520;

            final classDropdown = _FilterDropdown(
              label: 'Class',
              value: selectedClass,
              items: classItems,
              onChanged: onClassChanged,
            );

            final sectionDropdown = _FilterDropdown(
              label: 'Section',
              value: selectedSection,
              items: sectionItems,
              onChanged: onSectionChanged,
            );

            if (isNarrow) {
              return Column(
                children: [
                  classDropdown,
                  const SizedBox(height: 12),
                  sectionDropdown,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: classDropdown),
                const SizedBox(width: 12),
                Expanded(child: sectionDropdown),
              ],
            );
          },
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

class _GradeBadge extends StatelessWidget {
  const _GradeBadge({required this.grade});

  final String grade;

  @override
  Widget build(BuildContext context) {
    final color = switch (grade) {
      'A' => const Color(0xFF0F766E),
      'B' => const Color(0xFF1D4ED8),
      'C' => const Color(0xFFCA8A04),
      'D' => const Color(0xFFEA580C),
      _ => const Color(0xFFDC2626),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        grade,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
