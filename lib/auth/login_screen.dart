import 'package:flutter/material.dart';

import '../parent/app/app.dart';
import '../student/app/app.dart';
import '../teacher/features/navigation/presentation/main_shell.dart';

enum UserRole { teacher, student, parent }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.teacher;

  void _continueToRole() {
    final destination = switch (_selectedRole) {
      UserRole.teacher => const MainShell(),
      UserRole.student => const StudentAppHome(),
      UserRole.parent => const ParentAppHome(),
    };

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6FFFA), Color(0xFFEFF6FF), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFBF1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Login First',
                            style: TextStyle(
                              color: Color(0xFF115E59),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Choose your role',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The app now opens here first, then routes you to the correct folder based on the role you select manually.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        _RoleTile(
                          title: 'Teacher',
                          subtitle:
                              'Open the teacher dashboard, scan flow, analytics, and profile.',
                          icon: Icons.school,
                          value: UserRole.teacher,
                          groupValue: _selectedRole,
                          onChanged: _updateRole,
                        ),
                        const SizedBox(height: 12),
                        _RoleTile(
                          title: 'Student',
                          subtitle:
                              'Open the student folder and student-facing home screen.',
                          icon: Icons.menu_book,
                          value: UserRole.student,
                          groupValue: _selectedRole,
                          onChanged: _updateRole,
                        ),
                        const SizedBox(height: 12),
                        _RoleTile(
                          title: 'Parent',
                          subtitle:
                              'Open the parent folder and parent-facing home screen.',
                          icon: Icons.family_restroom,
                          value: UserRole.parent,
                          groupValue: _selectedRole,
                          onChanged: _updateRole,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _continueToRole,
                            child: Text(
                              'Continue as ${_selectedRole.name[0].toUpperCase()}${_selectedRole.name.substring(1)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _updateRole(UserRole? role) {
    if (role == null) {
      return;
    }

    setState(() {
      _selectedRole = role;
    });
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final UserRole value;
  final UserRole groupValue;
  final ValueChanged<UserRole?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFECFDF5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<UserRole>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFF1D4ED8)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
