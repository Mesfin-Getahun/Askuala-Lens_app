import 'package:flutter/material.dart';

import '../features/navigation/presentation/student_main_shell.dart';

class StudentAppHome extends StatelessWidget {
  const StudentAppHome({
    super.key,
    this.studentName = 'Student',
    this.classSection,
  });

  final String studentName;
  final String? classSection;

  @override
  Widget build(BuildContext context) {
    return StudentMainShell(
      studentName: studentName,
      classSection: classSection,
    );
  }
}
