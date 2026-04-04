import 'package:flutter/material.dart';

import '../features/navigation/presentation/student_main_shell.dart';

class StudentAppHome extends StatelessWidget {
  const StudentAppHome({
    super.key,
    required this.studentId,
    this.studentName = 'Student',
    this.classSection,
    this.username,
  });

  final String studentId;
  final String studentName;
  final String? classSection;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return StudentMainShell(
      studentId: studentId,
      studentName: studentName,
      classSection: classSection,
      username: username,
    );
  }
}
