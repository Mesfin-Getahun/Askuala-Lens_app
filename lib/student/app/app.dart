import 'package:flutter/material.dart';

class StudentAppHome extends StatelessWidget {
  const StudentAppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleLandingScreen(
      title: 'Student Home',
      subtitle:
          'This is the student folder entry screen. Student functionality can now be built from here.',
      accent: Color(0xFF1D4ED8),
      icon: Icons.menu_book_rounded,
    );
  }
}

class _RoleLandingScreen extends StatelessWidget {
  const _RoleLandingScreen({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: accent.withValues(alpha: 0.14),
                    child: Icon(icon, color: accent, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
