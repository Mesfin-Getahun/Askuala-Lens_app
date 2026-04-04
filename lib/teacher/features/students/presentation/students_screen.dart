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
  String _selectedClass = '';
  String _selectedSection = '';
  bool _isSavingToDatabase = false;
  String? _databaseStatus;
  List<_StudentRosterEntry> _cachedStudents = const [];

  List<String> _resolveClassOptions({
    required _TeacherAssignment teacherProfile,
    required List<_StudentRosterEntry> students,
  }) {
    final classes = <String>{
      ...teacherProfile.classOptions.where((value) => value.trim().isNotEmpty),
      ...students
          .map((student) => student.className.trim())
          .where((value) => value.isNotEmpty),
    }.toList()
      ..sort();

    if (classes.isNotEmpty) {
      return classes;
    }

    return const ['Grade 7'];
  }

  List<String> _resolveSectionOptions({
    required _TeacherAssignment teacherProfile,
    required String selectedClass,
    required List<_StudentRosterEntry> students,
  }) {
    final teacherSections = teacherProfile.sectionsForClass(selectedClass);
    final studentSections = students
        .where(
          (student) =>
              _normalizeClassValue(student.className) ==
              _normalizeClassValue(selectedClass),
        )
        .map((student) => student.section.trim())
        .where((value) => value.isNotEmpty)
        .toSet();

    final sections = <String>{
      ...teacherSections,
      ...studentSections,
    }.toList()
      ..sort();

    if (sections.isNotEmpty) {
      return sections;
    }

    return const ['A'];
  }

  _TeacherAssignment _fallbackTeacherAssignment() {
    final rawClassSection = widget.teacher.classSection?.trim() ?? '';
    if (rawClassSection.isEmpty) {
      return const _TeacherAssignment(
        classes: ['Grade 7'],
        sectionsByClass: {'Grade 7': ['A', 'B', 'C']},
      );
    }

    final match = RegExp(r'(.+?)([A-Za-z])$').firstMatch(rawClassSection);
    if (match == null) {
      return _TeacherAssignment(
        classes: [rawClassSection],
        sectionsByClass: {rawClassSection: const ['A', 'B', 'C']},
      );
    }

    final className = match.group(1)?.trim() ?? rawClassSection;
    final section = match.group(2)?.trim().toUpperCase() ?? 'A';
    return _TeacherAssignment(
      classes: [className],
      sectionsByClass: {
        className: [section],
      },
    );
  }

  String _studentConnectionLabel({
    required bool hasError,
    required bool isFromCache,
    required bool hasRows,
  }) {
    if (hasError && hasRows) {
      return 'Showing cached student rows while Firestore is offline.';
    }
    if (hasError) {
      return 'Firestore offline. No live student rows available right now.';
    }
    if (isFromCache && hasRows) {
      return 'Showing cached Firestore data.';
    }
    if (hasRows) {
      return 'Connected to Firestore.';
    }
    return 'No student rows available for the selected class and section.';
  }

  Future<void> _saveStudentsToDatabase(
    List<_StudentRosterEntry> students,
  ) async {
    if (students.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No student rows available to save.')),
      );
      setState(() {
        _databaseStatus = 'No student rows available to save.';
      });
      return;
    }

    setState(() {
      _isSavingToDatabase = true;
      _databaseStatus = null;
    });

    try {
      final batch = FirebaseFirestore.instance.batch();

      for (final student in students) {
        batch.set(student.reference, {
          'name': student.record.name,
          'className': student.record.className,
          'section': student.record.section,
          'quiz': student.record.quiz,
          'mid': student.record.mid,
          'assignment': student.record.assignment,
          'finalExam': student.record.finalExam,
          'total': student.record.total,
          'grade': student.record.grade,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) {
        return;
      }

      final message =
          'Database saved successfully for ${students.length} students.';
      setState(() {
        _isSavingToDatabase = false;
        _databaseStatus = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = 'Database save failed: $error';
      setState(() {
        _isSavingToDatabase = false;
        _databaseStatus = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
        final resolvedTeacherProfile = _TeacherAssignment.fromFirestore(teacherData);
        final teacherProfile = resolvedTeacherProfile.classes.isNotEmpty
            ? resolvedTeacherProfile
            : _fallbackTeacherAssignment();

        final studentsStream = FirebaseFirestore.instance
            .collection('students')
            .snapshots(includeMetadataChanges: true);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: studentsStream,
          builder: (context, studentsSnapshot) {
            final studentLoadError = studentsSnapshot.error?.toString();
            final liveStudents = (studentsSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .map(_StudentRosterEntry.fromDocument)
                .toList();
            if (liveStudents.isNotEmpty) {
              _cachedStudents = liveStudents;
            }
            final allStudents =
                liveStudents.isNotEmpty ? liveStudents : _cachedStudents;
            final isFromCache = studentsSnapshot.data?.metadata.isFromCache ?? false;
            final connectionLabel = _studentConnectionLabel(
              hasError: studentLoadError != null,
              isFromCache: isFromCache,
              hasRows: allStudents.isNotEmpty,
            );

            final classOptions = _resolveClassOptions(
              teacherProfile: teacherProfile,
              students: allStudents,
            );
            final resolvedClass = classOptions.contains(_selectedClass)
                ? _selectedClass
                : classOptions.first;
            if (resolvedClass != _selectedClass) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) {
                  return;
                }
                setState(() {
                  _selectedClass = resolvedClass;
                });
              });
            }

            final sectionOptions = _resolveSectionOptions(
              teacherProfile: teacherProfile,
              selectedClass: resolvedClass,
              students: allStudents,
            );
            final resolvedSection = sectionOptions.contains(_selectedSection)
                ? _selectedSection
                : sectionOptions.first;
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

            final filteredStudents = allStudents.where((student) {
              final matchesClass =
                  _normalizeClassValue(student.className) ==
                  _normalizeClassValue(resolvedClass);
              final matchesSection =
                  _normalizeSectionValue(student.section) ==
                  _normalizeSectionValue(resolvedSection);
              return matchesClass && matchesSection;
            }).toList();

            final students = filteredStudents
                .map((entry) => entry.record)
                .toList();

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
                        _selectedSection = _resolveSectionOptions(
                          teacherProfile: teacherProfile,
                          selectedClass: value,
                          students: allStudents,
                        ).first;
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Students Table',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              FilledButton.icon(
                                onPressed: _isSavingToDatabase
                                    ? null
                                    : () =>
                                        _saveStudentsToDatabase(filteredStudents),
                                icon: Icon(
                                  _isSavingToDatabase
                                      ? Icons.hourglass_top
                                      : Icons.cloud_upload_outlined,
                                ),
                                label: Text(
                                  _isSavingToDatabase
                                      ? 'Saving...'
                                      : 'Add Database',
                                ),
                              ),
                            ],
                          ),
                          if (_databaseStatus != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                _databaseStatus!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: studentLoadError != null
                                  ? const Color(0xFFFEF2F2)
                                  : isFromCache
                                  ? const Color(0xFFFFFBEB)
                                  : const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: studentLoadError != null
                                    ? const Color(0xFFFECACA)
                                    : isFromCache
                                    ? const Color(0xFFFDE68A)
                                    : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              connectionLabel,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: studentLoadError != null
                                        ? const Color(0xFF991B1B)
                                        : isFromCache
                                        ? const Color(0xFF92400E)
                                        : const Color(0xFF166534),
                                  ),
                            ),
                          ),
                          if (studentLoadError != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                'Students could not load from Firestore right now: $studentLoadError',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF991B1B),
                                    ),
                              ),
                            ),
                          ],
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
                              rows: students.isEmpty
                                  ? const [
                                      DataRow(
                                        cells: [
                                          DataCell(Text('No student data')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                          DataCell(Text('-')),
                                        ],
                                      ),
                                    ]
                                  : students
                                        .map(
                                          (student) => DataRow(
                                            onSelectChanged: (selected) {
                                              if (selected ?? false) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        StudentDetailScreen(
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
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      student.classLabel,
                                                      style: const TextStyle(
                                                        color:
                                                            Color(0xFF64748B),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text('${student.quiz}')),
                                              DataCell(Text('${student.mid}')),
                                              DataCell(
                                                Text('${student.assignment}'),
                                              ),
                                              DataCell(
                                                Text('${student.finalExam}'),
                                              ),
                                              DataCell(Text('${student.total}')),
                                              DataCell(
                                                _GradeBadge(grade: student.grade),
                                              ),
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
        .followedBy(data['sectionAssignments'] as List? ?? const [])
        .followedBy(data['sectionsAssigned'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();

    final singleSection = data['sectionAssigned']?.toString().trim();
    if (singleSection != null && singleSection.isNotEmpty) {
      sections.add(singleSection);
    }

    if (classAssigned != null && classAssigned.isNotEmpty) {
      sectionsByClass[classAssigned] = sections;
    }

    for (final className in classAssignments) {
      sectionsByClass.putIfAbsent(className, () => sections);
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

  List<String> get classOptions => classes;

  List<String> sectionsForClass(String selectedClass) {
    final sections = sectionsByClass.entries
        .firstWhere(
          (entry) =>
              _normalizeClassValue(entry.key) ==
              _normalizeClassValue(selectedClass),
          orElse: () => const MapEntry('', <String>[]),
        )
        .value;
    final sortedSections = [...sections]..where((value) => value.isNotEmpty).toList()
      ..sort();

    if (sortedSections.isNotEmpty) {
      return sortedSections;
    }

    return const [];
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
    required this.reference,
    required this.record,
    required this.className,
    required this.section,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final StudentRecord record;
  final String className;
  final String section;

  factory _StudentRosterEntry.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return _StudentRosterEntry(
      reference: doc.reference,
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
