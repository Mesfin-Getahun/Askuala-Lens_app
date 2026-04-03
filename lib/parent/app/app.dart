import 'package:flutter/material.dart';

class ParentAppHome extends StatelessWidget {
  const ParentAppHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const _RoleLandingScreen(
      title: 'Parent Home',
      subtitle:
          'This is the parent folder entry screen. Parent functionality can now be added here.',
      accent: Color(0xFFEA580C),
      icon: Icons.family_restroom,
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
