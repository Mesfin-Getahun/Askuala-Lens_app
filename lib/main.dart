import 'package:flutter/material.dart';

import 'teacher/app/app.dart';
import 'teacher/features/scan/data/scan_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScanLocalStorage.initialize();
  runApp(const AskulaApp());
}
