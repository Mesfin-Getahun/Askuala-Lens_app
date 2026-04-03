import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ScanLocalStorage {
  ScanLocalStorage._();

  static const String answerKeysBoxName = 'answer_keys';
  static const String capturedImagesBoxName = 'captured_images';
  static const String scanResultsBoxName = 'scan_results';

  static late Box _answerKeysBox;
  static late Box _capturedImagesBox;
  static late Box _scanResultsBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _answerKeysBox = await Hive.openBox(answerKeysBoxName);
    _capturedImagesBox = await Hive.openBox(capturedImagesBoxName);
    _scanResultsBox = await Hive.openBox(scanResultsBoxName);
  }

  static Box get answerKeysBox => _answerKeysBox;
  static Box get capturedImagesBox => _capturedImagesBox;
  static Box get scanResultsBox => _scanResultsBox;

  static Map<String, dynamic>? loadCurrentAnswerKey() {
    final stored = _answerKeysBox.get('current_key');
    if (stored is Map) {
      return Map<String, dynamic>.from(stored);
    }
    return null;
  }

  static Future<void> saveCurrentAnswerKey(Map<String, dynamic> data) {
    return _answerKeysBox.put('current_key', data);
  }

  static Future<String> persistCapturedImage(String sourcePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final captureDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}scan_captures',
    );

    if (!captureDirectory.existsSync()) {
      await captureDirectory.create(recursive: true);
    }

    final sourceFile = File(sourcePath);
    final extension = _extractFileExtension(sourcePath);
    final fileName =
        'capture_${DateTime.now().millisecondsSinceEpoch}$extension';
    final targetPath =
        '${captureDirectory.path}${Platform.pathSeparator}$fileName';

    final persistedFile = await sourceFile.copy(targetPath);
    return persistedFile.path;
  }

  static Future<int> addCapturedImage(Map<String, dynamic> data) async {
    final key = await _capturedImagesBox.add(data);
    return key as int;
  }

  static Map<String, dynamic>? getCapturedImage(int key) {
    final stored = _capturedImagesBox.get(key);
    if (stored is Map) {
      return Map<String, dynamic>.from(stored);
    }
    return null;
  }

  static Future<void> updateCapturedImage(
    int key,
    Map<String, dynamic> data,
  ) async {
    await _capturedImagesBox.put(key, data);
  }

  static List<Map<String, dynamic>> getCapturedImagesForSession(
    String sessionId,
  ) {
    return _capturedImagesBox.keys
        .map((key) {
          final stored = _capturedImagesBox.get(key);
          if (stored is! Map) {
            return null;
          }

          final record = Map<String, dynamic>.from(stored);
          record['storageKey'] = key;
          return record;
        })
        .whereType<Map<String, dynamic>>()
        .where((record) => record['sessionId'] == sessionId)
        .toList()
      ..sort(
        (left, right) => left['capturedAt'].toString().compareTo(
          right['capturedAt'].toString(),
        ),
      );
  }

  static Future<int> addScanResult(Map<String, dynamic> data) async {
    final key = await _scanResultsBox.add(data);
    return key as int;
  }

  static String _extractFileExtension(String sourcePath) {
    final lastDotIndex = sourcePath.lastIndexOf('.');
    final lastSeparatorIndex = sourcePath.lastIndexOf(RegExp(r'[\\/]'));
    if (lastDotIndex == -1 || lastDotIndex < lastSeparatorIndex) {
      return '.jpg';
    }
    return sourcePath.substring(lastDotIndex);
  }
}
