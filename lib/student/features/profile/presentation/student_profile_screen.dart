import 'package:flutter/material.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String _defaultLanguage = 'English';
  bool _voiceEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            const _StudentInfoCard(),
            const SizedBox(height: 18),
            _PreferencesCard(
              defaultLanguage: _defaultLanguage,
              voiceEnabled: _voiceEnabled,
              onLanguageChanged: (value) {
                setState(() {
                  _defaultLanguage = value;
                });
              },
              onVoiceChanged: (value) {
                setState(() {
                  _voiceEnabled = value;
                });
              },
            ),
            const SizedBox(height: 18),
            const _StatsCard(),
            const SizedBox(height: 18),
            _ActionsCard(
              onLogout: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout action is ready to connect.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentInfoCard extends StatelessWidget {
  const _StudentInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Info',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bethel Alemu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Grade 7 / Section B',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.defaultLanguage,
    required this.voiceEnabled,
    required this.onLanguageChanged,
    required this.onVoiceChanged,
  });

  final String defaultLanguage;
  final bool voiceEnabled;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<bool> onVoiceChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: defaultLanguage,
            decoration: const InputDecoration(
              labelText: 'Default Language',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English')),
              DropdownMenuItem(value: 'Amharic', child: Text('Amharic')),
              DropdownMenuItem(value: 'Afaan Oromoo', child: Text('Afaan Oromoo')),
              DropdownMenuItem(value: 'Tigrinya', child: Text('Tigrinya')),
            ],
            onChanged: (value) {
              if (value != null) {
                onLanguageChanged(value);
              }
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice On/Off',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Turn voice playback for explanations on or off.',
                        style: TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: voiceEnabled,
                  onChanged: onVoiceChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stats', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          const Row(
            children: [
              Expanded(
                child: _StatTile(
                  title: 'Topics Learned',
                  value: '12',
                  accent: Color(0xFF0F766E),
                  icon: Icons.auto_stories_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  title: 'Questions Asked',
                  value: '28',
                  accent: Color(0xFF2563EB),
                  icon: Icons.quiz_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionsCard extends StatelessWidget {
  const _ActionsCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onLogout,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}
