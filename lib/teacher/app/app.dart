import 'package:flutter/material.dart';

import '../../auth/login_screen.dart';
import 'theme/app_theme.dart';

class AskulaApp extends StatelessWidget {
  const AskulaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Askula',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const LoginScreen(),
    );
  }
}
