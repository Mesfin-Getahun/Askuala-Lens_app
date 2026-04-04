import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../../auth/data/firestore_login_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _showEmailToParents = false;
  bool _showPhoneToParents = false;
  String _language = 'English';
  bool _preferencesSeeded = false;

  @override
  Widget build(BuildContext context) {
    final teacherStream = FirebaseFirestore.instance
        .collection('teachers')
        .doc(widget.teacher.id)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: teacherStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final profile = _TeacherProfileData.fromFirestore(
          teacher: widget.teacher,
          data: data,
        );

        if (!_preferencesSeeded) {
          _seedPreferences(profile);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                profile: profile,
                isLoading: snapshot.connectionState == ConnectionState.waiting,
                onEditPressed: () => _showInfo(
                  'Edit mode can be connected next to Firestore update actions.',
                ),
                onEditPhotoPressed: () => _showInfo(
                  'Photo upload is not connected yet in this build.',
                ),
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Contact Info',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: profile.email,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: profile.phone,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: profile.address,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'School & Teaching',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.apartment_outlined,
                      label: 'School',
                      value: profile.schoolName,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Department',
                      value: profile.department,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.class_outlined,
                      label: 'Assigned Classes',
                      value: profile.classesLabel,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: profile.sections
                          .map(
                            (section) => Chip(
                              avatar: const Icon(
                                Icons.groups_2_outlined,
                                size: 18,
                                color: Color(0xFF0F766E),
                              ),
                              label: Text('Section $section'),
                              backgroundColor: const Color(0xFFD1FAE5),
                            ),
                          )
                          .toList(),
                    ),
                    if (profile.subjects.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: profile.subjects
                            .map(
                              (subject) => Chip(
                                label: Text(subject),
                                backgroundColor: const Color(0xFFDBEAFE),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Account & Role',
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Role',
                      value: profile.roleLabel,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.perm_identity_outlined,
                      label: 'Account ID',
                      value: profile.uid,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Created',
                      value: profile.createdAtLabel,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.update_outlined,
                      label: 'Updated',
                      value: profile.updatedAtLabel,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.sync_outlined,
                      label: 'Last Sync',
                      value: profile.updatedAtLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Preferences',
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Push Notifications'),
                      subtitle: const Text(
                        'Receive grading and student activity updates.',
                      ),
                      value: _pushNotifications,
                      onChanged: (value) =>
                          setState(() => _pushNotifications = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Email Notifications'),
                      subtitle: const Text(
                        'Receive profile and workflow summaries by email.',
                      ),
                      value: _emailNotifications,
                      onChanged: (value) =>
                          setState(() => _emailNotifications = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Email to Parents'),
                      value: _showEmailToParents,
                      onChanged: (value) =>
                          setState(() => _showEmailToParents = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Show Phone to Parents'),
                      value: _showPhoneToParents,
                      onChanged: (value) =>
                          setState(() => _showPhoneToParents = value),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'English',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'Amharic',
                          child: Text('Amharic'),
                        ),
                        DropdownMenuItem(
                          value: 'Afaan Oromoo',
                          child: Text('Afaan Oromoo'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _language = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Activity Snapshot',
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Classes',
                        value: '${profile.classes.length}',
                        color: const Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Sections',
                        value: '${profile.sections.length}',
                        color: const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniStatCard(
                        label: 'Subjects',
                        value: '${profile.subjects.length}',
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Support & Legal',
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.help_outline,
                      title: 'Help & Feedback',
                      subtitle: 'Open support and send feedback.',
                      onTap: () => _showInfo('Support flow can be connected next.'),
                    ),
                    const Divider(height: 24),
                    _ActionTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy & Terms',
                      subtitle: 'Review app privacy and policy links.',
                      onTap: () => _showInfo('Legal links can be connected next.'),
                    ),
                    const Divider(height: 24),
                    _ActionTile(
                      icon: Icons.report_problem_outlined,
                      title: 'Report a Problem',
                      subtitle: 'Share a bug or workflow issue.',
                      onTap: () => _showInfo('Bug reporting can be connected next.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showInfo(
                        'Save flow can be connected to update the teacher document.',
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showInfo(
                        'Refresh the page to reload the current Firestore profile.',
                      ),
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Refresh'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  onPressed: () => _showInfo(
                    'Logout flow can be connected next to your auth/session handling.',
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _seedPreferences(_TeacherProfileData profile) {
    _preferencesSeeded = true;
    _pushNotifications = profile.pushNotifications;
    _emailNotifications = profile.emailNotifications;
    _showEmailToParents = profile.showEmailToParents;
    _showPhoneToParents = profile.showPhoneToParents;
    _language = profile.language;
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TeacherProfileData {
  const _TeacherProfileData({
    required this.uid,
    required this.displayName,
    required this.roleLabel,
    required this.email,
    required this.phone,
    required this.address,
    required this.schoolName,
    required this.department,
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.createdAtLabel,
    required this.updatedAtLabel,
    required this.language,
    required this.pushNotifications,
    required this.emailNotifications,
    required this.showEmailToParents,
    required this.showPhoneToParents,
  });

  final String uid;
  final String displayName;
  final String roleLabel;
  final String email;
  final String phone;
  final String address;
  final String schoolName;
  final String department;
  final List<String> classes;
  final List<String> sections;
  final List<String> subjects;
  final String createdAtLabel;
  final String updatedAtLabel;
  final String language;
  final bool pushNotifications;
  final bool emailNotifications;
  final bool showEmailToParents;
  final bool showPhoneToParents;

  String get initials {
    final parts = displayName
        .split(' ')
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'T';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get classesLabel => classes.isEmpty ? 'No classes assigned' : classes.join(', ');

  factory _TeacherProfileData.fromFirestore({
    required AppUser teacher,
    required Map<String, dynamic> data,
  }) {
    final firstName = data['firstName']?.toString().trim();
    final lastName = data['lastName']?.toString().trim();
    final fullName = [firstName, lastName]
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' ');

    final preferences = data['preferences'] as Map? ?? const {};
    final classAssigned = data['classAssigned']?.toString().trim();
    final classes = <String>{};
    if (classAssigned != null && classAssigned.isNotEmpty) {
      classes.add(classAssigned);
    }
    classes.addAll(
      (data['classAssignments'] as List? ?? const [])
          .followedBy(data['classesAssigned'] as List? ?? const [])
          .followedBy(data['assignedClasses'] as List? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty),
    );

    return _TeacherProfileData(
      uid: teacher.id,
      displayName: fullName.isNotEmpty ? fullName : teacher.displayName,
      roleLabel: data['role']?.toString().trim() ?? 'Teacher',
      email: data['email']?.toString().trim() ?? 'No email',
      phone: data['phone']?.toString().trim() ?? 'No phone',
      address: data['address']?.toString().trim() ?? 'No address',
      schoolName: data['schoolName']?.toString().trim() ?? 'Askula School',
      department: data['department']?.toString().trim() ?? 'General Department',
      classes: classes.toList()..sort(),
      sections: (data['sections'] as List? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      subjects: (data['subjects'] as List? ?? const [])
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      createdAtLabel: _formatDate(data['createdAt']),
      updatedAtLabel: _formatDate(data['updatedAt']),
      language:
          preferences['language']?.toString().trim().isNotEmpty == true
              ? preferences['language'].toString().trim()
              : 'English',
      pushNotifications: preferences['pushNotifications'] == true,
      emailNotifications: preferences['emailNotifications'] == true,
      showEmailToParents: preferences['showEmailToParents'] == true,
      showPhoneToParents: preferences['showPhoneToParents'] == true,
    );
  }

  static String _formatDate(Object? value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }

    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return 'Not available';
    }
    return text;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.profile,
    required this.isLoading,
    required this.onEditPressed,
    required this.onEditPhotoPressed,
  });

  final _TeacherProfileData profile;
  final bool isLoading;
  final VoidCallback onEditPressed;
  final VoidCallback onEditPhotoPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Profile',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEditPressed,
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFD1FAE5),
                    child: Text(
                      profile.initials,
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        onPressed: onEditPhotoPressed,
                        icon: const Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.roleLabel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isLoading
                            ? 'Syncing teacher profile...'
                            : 'Last synced ${profile.updatedAtLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: const Color(0xFF0F766E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF0F172A)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
