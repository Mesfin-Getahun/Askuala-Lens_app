import 'package:flutter/material.dart';

import '../../../data/mock_parent_data.dart';
import '../../children/presentation/child_detail_screen.dart';
import '../../children/presentation/children_screen.dart';
import '../../home/presentation/parent_home_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../reports/presentation/reports_screen.dart';

class ParentMainShell extends StatefulWidget {
  const ParentMainShell({super.key});

  @override
  State<ParentMainShell> createState() => _ParentMainShellState();
}

class _ParentMainShellState extends State<ParentMainShell> {
  int _currentIndex = 0;
  final ParentProfile _profile = mockParentProfile;

  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openChildDetail(ParentChildRecord child) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildDetailScreen(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      ParentHomeScreen(
        profile: _profile,
        onOpenReports: () => _selectTab(2),
        onOpenNotifications: () => _selectTab(3),
        onOpenChildDetail: _openChildDetail,
      ),
      ChildrenScreen(children: _profile.children),
      ReportsScreen(children: _profile.children),
      NotificationsScreen(notifications: _profile.notifications),
      ParentProfileScreen(profile: _profile),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: screens),
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
            icon: Icon(Icons.family_restroom_outlined),
            activeIcon: Icon(Icons.family_restroom),
            label: 'Children',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            activeIcon: Icon(Icons.notifications_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
