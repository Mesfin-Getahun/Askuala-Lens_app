import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../../auth/data/firestore_login_service.dart';
import '../data/gemini_scan_service.dart';
import '../data/scan_local_storage.dart';

enum ScanStep { context, camera, processing, review }

enum QuestionType {
  trueFalse('True / False'),
  matching('Matching'),
  multipleChoice('Multiple Choice'),
  fillInBlank('Fill in the Blank'),
  shortAnswer('Short Answer');

  const QuestionType(this.label);

  final String label;
}

class QuestionKeyItem {
  const QuestionKeyItem({
    this.number,
    this.type,
    this.description,
    this.correctAnswer,
    this.marks,
  });

  final int? number;
  final QuestionType? type;
  final String? description;
  final String? correctAnswer;
  final double? marks;

  QuestionType get resolvedType => type ?? QuestionType.multipleChoice;
  String get resolvedDescription {
    final value = description?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return _defaultDescriptionForType(resolvedType);
  }

  String get resolvedAnswer => correctAnswer?.trim() ?? '';
  double get resolvedMarks => marks ?? 1;

  int resolvedNumber(int fallbackNumber) => number ?? fallbackNumber;

  QuestionKeyItem copyWith({
    int? number,
    QuestionType? type,
    String? description,
    String? correctAnswer,
    double? marks,
  }) {
    return QuestionKeyItem(
      number: number ?? this.number,
      type: type ?? this.type,
      description: description ?? this.description,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      marks: marks ?? this.marks,
    );
  }

  QuestionKeyItem normalized({required int fallbackNumber}) {
    return QuestionKeyItem(
      number: resolvedNumber(fallbackNumber),
      type: resolvedType,
      description: resolvedDescription,
      correctAnswer: resolvedAnswer,
      marks: resolvedMarks,
    );
  }
}

class AssessmentKey {
  const AssessmentKey({required this.assessmentType, required this.questions});

  final String assessmentType;
  final List<QuestionKeyItem> questions;

  int get totalQuestions => questions.length;
  double get totalMarks =>
      questions.fold(0, (sum, question) => sum + question.resolvedMarks);

  AssessmentKey copyWith({
    String? assessmentType,
    List<QuestionKeyItem>? questions,
  }) {
    return AssessmentKey(
      assessmentType: assessmentType ?? this.assessmentType,
      questions: questions ?? this.questions,
    );
  }
}

String _defaultDescriptionForType(QuestionType type) {
  return switch (type) {
    QuestionType.trueFalse =>
      'Decide whether the statement is true or false.',
    QuestionType.matching => 'Match each item in Column A with Column B.',
    QuestionType.multipleChoice =>
      'Choose the correct option from A, B, C, or D.',
    QuestionType.fillInBlank => 'Fill in the missing word or number.',
    QuestionType.shortAnswer => 'Write the expected short answer.',
  };
}

// ignore: unused_element
String _answerHintForType(QuestionType type) {
  return switch (type) {
    QuestionType.trueFalse => 'Correct Answer (True / False)',
    QuestionType.matching => 'Correct Matches',
    QuestionType.multipleChoice => 'Correct Option',
    QuestionType.fillInBlank => 'Correct Blank Answer',
    QuestionType.shortAnswer => 'Expected Short Answer',
  };
}

AssessmentKey _sanitizeAssessmentKey(AssessmentKey key) {
  return key.copyWith(
    assessmentType: key.assessmentType,
    questions: key.questions
        .asMap()
        .entries
        .map((entry) => entry.value.normalized(fallbackNumber: entry.key + 1))
        .toList(),
  );
}

class ScanComparisonItem {
  const ScanComparisonItem({
    required this.questionNumber,
    required this.expectedAnswer,
    required this.detectedAnswer,
    required this.isCorrect,
    required this.awardedMarks,
    required this.availableMarks,
  });

  final int questionNumber;
  final String expectedAnswer;
  final String detectedAnswer;
  final bool isCorrect;
  final double awardedMarks;
  final double availableMarks;

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'expectedAnswer': expectedAnswer,
      'detectedAnswer': detectedAnswer,
      'isCorrect': isCorrect,
      'awardedMarks': awardedMarks,
      'availableMarks': availableMarks,
    };
  }
}

class ScanEvaluation {
  const ScanEvaluation({
    required this.sessionId,
    required this.rawOcrText,
    required this.combinedOcrText,
    required this.comparisons,
    required this.scorePercent,
    required this.awardedMarks,
    required this.totalMarks,
    required this.feedback,
    required this.usedAi,
    this.aiExtractedAnswers = const [],
  });

  final String sessionId;
  final String rawOcrText;
  final String combinedOcrText;
  final List<ScanComparisonItem> comparisons;
  final double scorePercent;
  final double awardedMarks;
  final double totalMarks;
  final String feedback;
  final bool usedAi;
  final List<Map<String, dynamic>> aiExtractedAnswers;

  Map<String, dynamic> toMap({
    required String selectedClass,
    required String selectedSection,
    required String assessmentType,
    required String? imagePath,
  }) {
    return {
      'sessionId': sessionId,
      'class': selectedClass,
      'section': selectedSection,
      'assessmentType': assessmentType,
      'imagePath': imagePath,
      'rawOcrText': rawOcrText,
      'combinedOcrText': combinedOcrText,
      'scorePercent': scorePercent,
      'awardedMarks': awardedMarks,
      'totalMarks': totalMarks,
      'feedback': feedback,
      'usedAi': usedAi,
      'aiExtractedAnswers': aiExtractedAnswers,
      'comparisons': comparisons.map((item) => item.toMap()).toList(),
      'savedAt': DateTime.now().toIso8601String(),
    };
  }
}

AssessmentKey _assessmentKeyFromMap(Map<String, dynamic> data) {
  final storedQuestions = (data['questions'] as List? ?? const [])
      .whereType<Map>()
      .map(
        (question) => QuestionKeyItem(
          number: (question['number'] as num?)?.toInt(),
          type: _parseQuestionType(question['type']?.toString()),
          description: question['description']?.toString(),
          correctAnswer: question['correctAnswer']?.toString(),
          marks: (question['marks'] as num?)?.toDouble(),
        ),
      )
      .toList();

  return _sanitizeAssessmentKey(
    AssessmentKey(
      assessmentType: data['assessmentType']?.toString() ?? 'Quiz',
      questions: storedQuestions,
    ),
  );
}

Map<String, dynamic> _assessmentKeyToMap(AssessmentKey key) {
  return {
    'assessmentType': key.assessmentType,
    'questions': key.questions
        .asMap()
        .entries
        .map(
          (entry) => {
            'number': entry.value.resolvedNumber(entry.key + 1),
            'type': entry.value.resolvedType.name,
            'description': entry.value.resolvedDescription,
            'correctAnswer': entry.value.resolvedAnswer,
            'marks': entry.value.resolvedMarks,
          },
        )
        .toList(),
  };
}

QuestionType? _parseQuestionType(String? rawValue) {
  for (final type in QuestionType.values) {
    if (type.name == rawValue) {
      return type;
    }
  }
  return null;
}

String _normalizeForComparison(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String _extractAnswerForQuestion(String ocrText, int questionNumber) {
  final questionPrefix = RegExp(
    '^(?:q(?:uestion)?\\s*)?$questionNumber[\\)\\.\\:\\-\\s]+',
    caseSensitive: false,
  );
  final anyQuestionPrefix = RegExp(
    r'^(?:q(?:uestion)?\s*)?\d+[\)\.\:\-\s]+',
    caseSensitive: false,
  );
  final lines = ocrText.split('\n');

  for (var index = 0; index < lines.length; index++) {
    final trimmedLine = lines[index].trim();
    if (!questionPrefix.hasMatch(trimmedLine)) {
      continue;
    }

    final buffer = <String>[
      trimmedLine.replaceFirst(questionPrefix, '').trim(),
    ];

    for (var nextIndex = index + 1; nextIndex < lines.length; nextIndex++) {
      final nextLine = lines[nextIndex].trim();
      if (nextLine.isEmpty) {
        continue;
      }
      if (anyQuestionPrefix.hasMatch(nextLine)) {
        break;
      }
      buffer.add(nextLine);
    }

    return buffer.where((line) => line.isNotEmpty).join(' ').trim();
  }

  return '';
}

bool _isAnswerMatch(String expected, String detected) {
  final normalizedExpected = _normalizeForComparison(expected);
  final normalizedDetected = _normalizeForComparison(detected);
  if (normalizedExpected.isEmpty || normalizedDetected.isEmpty) {
    return false;
  }
  return normalizedDetected.contains(normalizedExpected) ||
      normalizedExpected.contains(normalizedDetected);
}

String _buildFeedback({
  required double scorePercent,
  required List<ScanComparisonItem> comparisons,
}) {
  final missedQuestions = comparisons
      .where((item) => !item.isCorrect)
      .map((item) => 'Q${item.questionNumber}')
      .toList();

  if (comparisons.every((item) => item.isCorrect)) {
    return 'Strong work. All stored answers matched the current answer key.';
  }

  if (scorePercent >= 75) {
    return 'Good progress overall. Review ${missedQuestions.join(', ')} to improve the final score.';
  }

  if (scorePercent >= 40) {
    return 'Several answers matched, but ${missedQuestions.join(', ')} still need attention. A second OCR pass or teacher review may help.';
  }

  return 'Most answers still need review. The stored scan text can be sent to the OCR API next for a stronger extraction pass.';
}

class ScanFlowScreen extends StatefulWidget {
  const ScanFlowScreen({super.key, required this.teacher});

  final AppUser teacher;

  @override
  State<ScanFlowScreen> createState() => _ScanFlowScreenState();
}

class _ScanFlowScreenState extends State<ScanFlowScreen> {
  final GeminiScanService _geminiScanService = GeminiScanService();
  ScanStep _currentStep = ScanStep.context;
  String _selectedClass = 'Grade 7';
  String _selectedSection = 'A';
  String _assessmentType = 'Quiz';
  bool _batchMode = true;
  bool _flashEnabled = false;
  double _score = 0;
  late AssessmentKey _assessmentKey;
  ScanEvaluation? _latestEvaluation;
  bool _isProcessing = false;
  String? _processingError;
  String? _activeSessionId;
  String? _lastProcessedImagePath;
  String _combinedExtractedText = '';
  final List<String> _capturedImagePaths = [];
  final TextEditingController _feedbackController = TextEditingController(
    text: 'No scan processed yet.',
  );

  @override
  void initState() {
    super.initState();
    _assessmentKey = _sanitizeAssessmentKey(
      _buildDefaultAssessmentKey(_assessmentType),
    );
    _restorePersistedAnswerKey();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _goToStep(ScanStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _resetCaptureSession() {
    _capturedImagePaths.clear();
    _flashEnabled = false;
    _processingError = null;
    _isProcessing = false;
    _latestEvaluation = null;
    _combinedExtractedText = '';
    _lastProcessedImagePath = null;
    _score = 0;
    _feedbackController.text = 'No scan processed yet.';
  }

  void _startScanSession() {
    setState(() {
      _resetCaptureSession();
      _activeSessionId = _buildSessionId();
      _currentStep = ScanStep.camera;
    });
  }

  void _startNextScan() {
    setState(() {
      _resetCaptureSession();
      _activeSessionId = _buildSessionId();
      _currentStep = ScanStep.camera;
    });
  }

  Future<void> _handlePaperCaptured(String path) async {
    try {
      final sessionId = _activeSessionId ?? _buildSessionId();
      final persistedPath = await ScanLocalStorage.persistCapturedImage(path);
      final id = await ScanLocalStorage.addCapturedImage({
        'sessionId': sessionId,
        'path': persistedPath,
        'capturedAt': DateTime.now().toIso8601String(),
        'class': _selectedClass,
        'section': _selectedSection,
        'assessmentType': _assessmentType,
        'ocrText': '',
        'processed': false,
        'ocrProvider': 'google_mlkit_local',
        'ocrApiReady': true,
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _activeSessionId = sessionId;
        _capturedImagePaths.add(persistedPath);
        _lastProcessedImagePath = persistedPath;
      });

      unawaited(_processSingleImage(id));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Capture could not be stored. $error')),
      );
      return;
    }

    if (_batchMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Page ${_capturedImagePaths.length} captured. Capture more or process the batch.',
          ),
        ),
      );
      return;
    }

    _processBatchCapture();
  }

  Future<void> _processSingleImage(int key) async {
    try {
      final data = ScanLocalStorage.getCapturedImage(key);
      if (data == null) return;
      if (data['processed'] == true) return;

      final path = data['path'] as String?;
      if (path == null) return;
      final file = File(path);
      if (!file.existsSync()) {
        await ScanLocalStorage.updateCapturedImage(key, {
          ...data,
          'processed': true,
          'ocrText': '',
          'ocrFailed': true,
        });
        return;
      }

      final inputImage = InputImage.fromFilePath(path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      try {
        final recognized = await textRecognizer.processImage(inputImage);
        final extracted = recognized.text;
        await ScanLocalStorage.updateCapturedImage(key, {
          ...data,
          'ocrText': extracted,
          'processed': true,
          'ocrFailed': false,
          'processedAt': DateTime.now().toIso8601String(),
        });
      } catch (_) {
        await ScanLocalStorage.updateCapturedImage(key, {
          ...data,
          'processed': false,
          'ocrFailed': true,
        });
      } finally {
        textRecognizer.close();
      }
    } catch (_) {
      // Keep capture flow resilient even if OCR is temporarily unavailable.
    }
  }

  void _processBatchCapture() {
    if (_capturedImagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capture at least one paper first.')),
      );
      return;
    }

    setState(() {
      _currentStep = ScanStep.processing;
      _isProcessing = true;
      _processingError = null;
    });
    unawaited(_processCurrentSession());
  }

  Future<void> _processCurrentSession() async {
    final sessionId = _activeSessionId;
    if (sessionId == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isProcessing = false;
        _processingError = 'No active scan session was found.';
      });
      return;
    }

    try {
      var storedImages = ScanLocalStorage.getCapturedImagesForSession(sessionId);
      if (storedImages.isEmpty) {
        throw Exception('No captured pages are stored for this session.');
      }

      for (final storedImage in storedImages) {
        final storageKey = storedImage['storageKey'];
        if (storageKey is int && storedImage['processed'] != true) {
          await _processSingleImage(storageKey);
        }
      }

      storedImages = ScanLocalStorage.getCapturedImagesForSession(sessionId);
      final rawCombinedOcrText = storedImages
          .map((image) => image['ocrText']?.toString().trim() ?? '')
          .where((text) => text.isNotEmpty)
          .join('\n\n');

      final evaluation = await _evaluateScan(
        sessionId: sessionId,
        combinedOcrText: rawCombinedOcrText,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latestEvaluation = evaluation;
        _combinedExtractedText = evaluation.combinedOcrText;
        _score = evaluation.scorePercent;
        _feedbackController.text = evaluation.feedback;
        _lastProcessedImagePath =
            storedImages.isNotEmpty ? storedImages.last['path']?.toString() : null;
        _isProcessing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isProcessing = false;
        _processingError = error.toString();
      });
    }
  }

  AssessmentKey _buildDefaultAssessmentKey(String assessmentType) {
    return AssessmentKey(
      assessmentType: assessmentType,
      questions: List.generate(
        5,
        (index) => QuestionKeyItem(
          number: index + 1,
          type: switch (index) {
            0 => QuestionType.trueFalse,
            1 => QuestionType.multipleChoice,
            2 => QuestionType.matching,
            3 => QuestionType.fillInBlank,
            _ => QuestionType.shortAnswer,
          },
          description: switch (index) {
            0 => 'Decide whether the statement is true or false.',
            1 => 'Choose the correct option from A, B, C, or D.',
            2 => 'Match each item in Column A with Column B.',
            3 => 'Fill in the missing word or number.',
            _ => 'Write the expected short answer.',
          },
          correctAnswer: switch (index) {
            0 => 'True',
            1 => 'B',
            2 => '1-C, 2-A, 3-B',
            3 => 'denominator',
            _ => 'A fraction represents part of a whole.',
          },
          marks: switch (index) {
            2 => 4,
            4 => 5,
            _ => 2,
          }.toDouble(),
        ),
      ),
    );
  }

  void _restorePersistedAnswerKey() {
    final storedKey = ScanLocalStorage.loadCurrentAnswerKey();
    if (storedKey == null) {
      return;
    }

    final restoredKey = _assessmentKeyFromMap(storedKey);
    _assessmentType = restoredKey.assessmentType;
    _assessmentKey = restoredKey;
  }

  String _buildSessionId() {
    return 'scan_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<ScanEvaluation> _evaluateScan({
    required String sessionId,
    required String combinedOcrText,
  }) async {
    final answerKey = _assessmentKey.questions.asMap().entries.map((entry) {
      final question = entry.value.normalized(fallbackNumber: entry.key + 1);
      return <String, Object?>{
        'questionNumber': question.resolvedNumber(entry.key + 1),
        'questionType': question.resolvedType.name,
        'correctAnswer': question.resolvedAnswer,
        'marks': question.resolvedMarks,
      };
    }).toList();

    try {
      final aiResult = await _geminiScanService.analyzeScan(
        assessmentType: _assessmentType,
        selectedClass: _selectedClass,
        selectedSection: _selectedSection,
        rawOcrText: combinedOcrText,
        answerKey: answerKey,
      );

      if (aiResult != null && aiResult.comparisons.isNotEmpty) {
        final aiComparisons = aiResult.comparisons
            .map(
              (item) => ScanComparisonItem(
                questionNumber: item.questionNumber,
                expectedAnswer: item.expectedAnswer,
                detectedAnswer: item.detectedAnswer,
                isCorrect: item.isCorrect,
                awardedMarks: item.awardedMarks,
                availableMarks: item.availableMarks,
              ),
            )
            .toList();
        final aiTotalMarks = aiResult.totalMarks > 0
            ? aiResult.totalMarks
            : aiComparisons.fold<double>(
                0,
                (sum, item) => sum + item.availableMarks,
              );
        final aiAwardedMarks = aiResult.awardedMarks
            .clamp(0, aiTotalMarks)
            .toDouble();
        final aiScorePercent = aiTotalMarks == 0
            ? 0.0
            : (aiAwardedMarks / aiTotalMarks) * 100;

        return ScanEvaluation(
          sessionId: sessionId,
          rawOcrText: combinedOcrText,
          combinedOcrText: aiResult.cleanedText,
          comparisons: aiComparisons,
          scorePercent: aiScorePercent.clamp(0, 100).toDouble(),
          awardedMarks: aiAwardedMarks,
          totalMarks: aiTotalMarks,
          feedback: aiResult.feedback.isNotEmpty
              ? aiResult.feedback
              : _buildFeedback(
                  scorePercent: aiScorePercent,
                  comparisons: aiComparisons,
                ),
          usedAi: true,
          aiExtractedAnswers: aiResult.answers
              .map(
                (item) => {
                  'questionNumber': item.questionNumber,
                  'answer': item.answer,
                },
              )
              .toList(),
        );
      }
    } catch (_) {
      // Keep local grading available if Gemini is not configured or fails.
    }

    final comparisons = _assessmentKey.questions.asMap().entries.map((entry) {
      final question = entry.value.normalized(fallbackNumber: entry.key + 1);
      final detectedAnswer = _extractAnswerForQuestion(
        combinedOcrText,
        question.resolvedNumber(entry.key + 1),
      );
      final isCorrect = _isAnswerMatch(
        question.resolvedAnswer,
        detectedAnswer,
      );

      return ScanComparisonItem(
        questionNumber: question.resolvedNumber(entry.key + 1),
        expectedAnswer: question.resolvedAnswer,
        detectedAnswer: detectedAnswer,
        isCorrect: isCorrect,
        awardedMarks: isCorrect ? question.resolvedMarks : 0,
        availableMarks: question.resolvedMarks,
      );
    }).toList();

    final totalMarks = comparisons.fold<double>(
      0,
      (sum, item) => sum + item.availableMarks,
    );
    final awardedMarks = comparisons.fold<double>(
      0,
      (sum, item) => sum + item.awardedMarks,
    );
    final double scorePercent = totalMarks == 0
        ? 0.0
        : (awardedMarks / totalMarks) * 100;

    return ScanEvaluation(
      sessionId: sessionId,
      rawOcrText: combinedOcrText,
      combinedOcrText: combinedOcrText,
      comparisons: comparisons,
      scorePercent: scorePercent.clamp(0, 100).toDouble(),
      awardedMarks: awardedMarks,
      totalMarks: totalMarks,
      feedback: _buildFeedback(
        scorePercent: scorePercent,
        comparisons: comparisons,
      ),
      usedAi: false,
    );
  }

  Future<void> _saveCurrentResult() async {
    final evaluation = _latestEvaluation;
    if (evaluation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Process a scan before saving the result.')),
      );
      return;
    }

    await ScanLocalStorage.addScanResult(
      evaluation.toMap(
        selectedClass: _selectedClass,
        selectedSection: _selectedSection,
        assessmentType: _assessmentType,
        imagePath: _lastProcessedImagePath,
      )..addAll({
          'teacherAdjustedScore': _score,
          'teacherFeedback': _feedbackController.text.trim(),
        }),
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Result saved successfully in local Hive storage.')),
    );
  }

  Future<void> _openAnswerKeyEditor() async {
    final updatedKey = await showModalBottomSheet<AssessmentKey>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _AnswerKeyEditorSheetV2(
          assessmentType: _assessmentType,
          initialKey: _assessmentKey.copyWith(assessmentType: _assessmentType),
        );
      },
    );

    if (updatedKey != null) {
      setState(() {
        _assessmentKey = _sanitizeAssessmentKey(updatedKey);
      });
      try {
        await ScanLocalStorage.saveCurrentAnswerKey(
          _assessmentKeyToMap(_assessmentKey),
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer key could not be saved to local storage.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacherStream = FirebaseFirestore.instance
        .collection('teachers')
        .doc(widget.teacher.id)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: teacherStream,
      builder: (context, teacherSnapshot) {
        final theme = Theme.of(context);
        final assessmentKey = _assessmentKey;
        final teacherData = teacherSnapshot.data?.data() ?? <String, dynamic>{};
        final teacherAssignment = _TeacherAssignment.fromFirestore(teacherData);
        final classOptions = teacherAssignment.classes;
        final resolvedClass = classOptions.contains(_selectedClass)
            ? _selectedClass
            : classOptions.first;

        if (resolvedClass != _selectedClass) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedClass = resolvedClass;
              _selectedSection = teacherAssignment
                  .sectionsForClass(resolvedClass)
                  .first;
            });
          });
        }

        final sectionOptions = teacherAssignment.sectionsForClass(resolvedClass);
        final resolvedSection = sectionOptions.contains(_selectedSection)
            ? _selectedSection
            : sectionOptions.first;

        if (resolvedSection != _selectedSection) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            setState(() {
              _selectedSection = resolvedSection;
            });
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scan Papers', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Move from setup to review in one guided workflow.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _StepProgressHeader(currentStep: _currentStep),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (_currentStep) {
                  ScanStep.context => _ContextSelectionView(
                    key: const ValueKey('context-step'),
                    selectedClass: resolvedClass,
                    selectedSection: resolvedSection,
                    classItems: classOptions,
                    sectionItems: sectionOptions,
                    assessmentType: _assessmentType,
                    onClassChanged: (value) => setState(() {
                      _selectedClass = value;
                      _selectedSection =
                          teacherAssignment.sectionsForClass(value).first;
                    }),
                    onSectionChanged: (value) =>
                        setState(() => _selectedSection = value),
                    onAssessmentTypeChanged: (value) => setState(() {
                      _assessmentType = value;
                      _assessmentKey = _assessmentKey.assessmentType == value
                          ? assessmentKey
                          : _sanitizeAssessmentKey(
                              _buildDefaultAssessmentKey(value),
                            );
                    }),
                    assessmentKey: assessmentKey,
                    onUpdateKey: _openAnswerKeyEditor,
                    onStartScanning: _startScanSession,
                  ),
                  ScanStep.camera => _CameraScanView(
                    key: const ValueKey('camera-step'),
                    selectedClass: resolvedClass,
                    selectedSection: resolvedSection,
                    assessmentType: _assessmentType,
                    batchMode: _batchMode,
                    flashEnabled: _flashEnabled,
                    onBack: () => _goToStep(ScanStep.context),
                    onBatchModeChanged: (value) =>
                        setState(() => _batchMode = value),
                    onFlashChanged: (value) =>
                        setState(() => _flashEnabled = value),
                    capturedCount: _capturedImagePaths.length,
                    onCapture: _handlePaperCaptured,
                    onProcessBatch: _processBatchCapture,
                  ),
                  ScanStep.processing => _ProcessingView(
                    key: const ValueKey('processing-step'),
                    imagePath: _lastProcessedImagePath,
                    capturedCount: _capturedImagePaths.length,
                    isProcessing: _isProcessing,
                    processingError: _processingError,
                    extractedText: _combinedExtractedText,
                    onContinue: () => _goToStep(ScanStep.review),
                    onRetry: _processBatchCapture,
                  ),
                  ScanStep.review => _ReviewResultView(
                    key: const ValueKey('review-step'),
                    score: _score,
                    imagePath: _lastProcessedImagePath,
                    capturedCount: _capturedImagePaths.length,
                    feedbackController: _feedbackController,
                    evaluation: _latestEvaluation,
                    onScoreChanged: (value) => setState(() => _score = value),
                    onEditScore: () => _showEditScoreSheet(context),
                    onSave: _saveCurrentResult,
                    onNextScan: _startNextScan,
                  ),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditScoreSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Score',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_score.round()} / 100',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Slider(
                    min: 0,
                    max: 100,
                    value: _score,
                    onChanged: (value) {
                      setSheetState(() => _score = value);
                      setState(() => _score = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Apply Score'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StepProgressHeader extends StatelessWidget {
  const _StepProgressHeader({required this.currentStep});

  final ScanStep currentStep;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Setup', ScanStep.context),
      ('Camera', ScanStep.camera),
      ('Processing', ScanStep.processing),
      ('Review', ScanStep.review),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Row(
                    children: [
                      _StepBadge(
                        label: item.$1,
                        isActive: currentStep == item.$2,
                        isComplete: currentStep.index > item.$2.index,
                      ),
                      if (item != items.last)
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Divider(thickness: 1.2),
                          ),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  final String label;
  final bool isActive;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final color = isComplete || isActive
        ? const Color(0xFF0F766E)
        : const Color(0xFF94A3B8);

    return Column(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withOpacity(0.14),
          child: Icon(
            isComplete ? Icons.check : Icons.circle,
            size: isComplete ? 18 : 10,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ContextSelectionView extends StatelessWidget {
  const _ContextSelectionView({
    super.key,
    required this.selectedClass,
    required this.selectedSection,
    required this.classItems,
    required this.sectionItems,
    required this.assessmentType,
    required this.assessmentKey,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onAssessmentTypeChanged,
    required this.onUpdateKey,
    required this.onStartScanning,
  });

  final String selectedClass;
  final String selectedSection;
  final List<String> classItems;
  final List<String> sectionItems;
  final String assessmentType;
  final AssessmentKey assessmentKey;
  final ValueChanged<String> onClassChanged;
  final ValueChanged<String> onSectionChanged;
  final ValueChanged<String> onAssessmentTypeChanged;
  final VoidCallback onUpdateKey;
  final VoidCallback onStartScanning;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Context',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _DropdownField(
                    label: 'Class',
                    value: selectedClass,
                    items: classItems,
                    onChanged: onClassChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DropdownField(
                    label: 'Section',
                    value: selectedSection,
                    items: sectionItems,
                    onChanged: onSectionChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Assessment Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.8,
              ),
              itemBuilder: (context, index) {
                const assessmentTypes = [
                  'Quiz',
                  'Mid',
                  'Final',
                  'Assignment',
                ];
                final type = assessmentTypes[index];
                final isSelected = assessmentType == type;

                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onAssessmentTypeChanged(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F766E).withValues(alpha: 0.12)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF0F766E)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        type,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: isSelected
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFF334155),
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.key_outlined, color: Color(0xFF0F766E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Answer Key Ready',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${assessmentKey.totalQuestions} questions • ${assessmentKey.totalMarks.toStringAsFixed(0)} total marks',
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Includes T/F, matching, choice, blank space, and short-answer items.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: onUpdateKey,
                    child: const Text('Update Key'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _AssessmentKeyPreviewPanel(assessmentKey: assessmentKey),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStartScanning,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Scanning'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraScanView extends StatefulWidget {
  const _CameraScanView({
    super.key,
    required this.selectedClass,
    required this.selectedSection,
    required this.assessmentType,
    required this.batchMode,
    required this.flashEnabled,
    required this.onBack,
    required this.onBatchModeChanged,
    required this.onFlashChanged,
    required this.capturedCount,
    required this.onCapture,
    required this.onProcessBatch,
  });

  final String selectedClass;
  final String selectedSection;
  final String assessmentType;
  final bool batchMode;
  final bool flashEnabled;
  final VoidCallback onBack;
  final ValueChanged<bool> onBatchModeChanged;
  final ValueChanged<bool> onFlashChanged;
  final int capturedCount;
  final Future<void> Function(String path) onCapture;
  final VoidCallback onProcessBatch;

  @override
  State<_CameraScanView> createState() => _CameraScanViewState();
}

class _CameraScanViewState extends State<_CameraScanView> {
  CameraController? _controller;
  Future<void>? _controllerFuture;
  String? _cameraError;
  bool _isCapturing = false;
  bool _flashPulseVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void didUpdateWidget(covariant _CameraScanView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.flashEnabled != widget.flashEnabled) {
      _applyFlashMode(widget.flashEnabled);
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera found on this device.';
        });
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      setState(() {
        _controller = controller;
        _controllerFuture = controller.initialize();
        _cameraError = null;
      });

      await _controllerFuture;
      await _applyFlashMode(widget.flashEnabled);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Camera could not be initialized. ${error.toString()}';
      });
    }
  }

  Future<void> _applyFlashMode(bool enabled) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    try {
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError =
            'Flash could not be changed on this device. Camera capture still works.';
      });
    }
  }

  Future<void> _toggleFlash(bool value) async {
    widget.onFlashChanged(value);
    await _applyFlashMode(value);
  }

  Future<void> _capturePaper() async {
    final controller = _controller;
    final controllerFuture = _controllerFuture;
    if (_isCapturing || controller == null || controllerFuture == null) {
      return;
    }

    setState(() {
      _isCapturing = true;
      _cameraError = null;
    });

    try {
      await controllerFuture;
      final image = await controller.takePicture();

      if (mounted && widget.flashEnabled) {
        setState(() => _flashPulseVisible = true);
        await Future<void>.delayed(const Duration(milliseconds: 130));
        if (mounted) {
          setState(() => _flashPulseVisible = false);
        }
      }

      await widget.onCapture(image.path);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Capture failed. ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.selectedClass} ${widget.selectedSection}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(widget.assessmentType),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                ),
              ],
            ),
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: _buildCameraPreview(),
            ),
            if (_cameraError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Text(
                  _cameraError!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: const Color(0xFF991B1B)),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _ToggleTile(
                    title: 'Batch Mode',
                    value: widget.batchMode,
                    icon: Icons.layers_outlined,
                    onChanged: widget.onBatchModeChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleTile(
                    title: 'Flash',
                    value: widget.flashEnabled,
                    icon: Icons.flash_on_outlined,
                    onChanged: _toggleFlash,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _CaptureInfoChip(
                    icon: Icons.photo_library_outlined,
                    label: widget.batchMode
                        ? '${widget.capturedCount} pages queued'
                        : '${widget.capturedCount} page captured',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CaptureInfoChip(
                    icon: widget.flashEnabled
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    label: widget.flashEnabled ? 'Flash On' : 'Flash Off',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCapturing ? null : _capturePaper,
                icon: Icon(
                  _isCapturing ? Icons.hourglass_top : Icons.camera_alt_outlined,
                ),
                label: Text(
                  _isCapturing
                      ? 'Capturing...'
                      : widget.batchMode
                      ? 'Capture Page'
                      : 'Capture Paper',
                ),
              ),
            ),
            if (widget.batchMode && widget.capturedCount > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onProcessBatch,
                  icon: const Icon(Icons.playlist_add_check_circle_outlined),
                  label: Text('Process Batch (${widget.capturedCount})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final previewFrame = ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: ColoredBox(
        color: const Color(0xFF0F172A),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_controllerFuture != null && _controller != null)
              FutureBuilder<void>(
                future: _controllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      _controller!.value.isInitialized) {
                    return CameraPreview(_controller!);
                  }

                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Opening camera...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner,
                      color: Colors.white,
                      size: 54,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Preparing camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xCCFFFFFF),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
            if (_flashPulseVisible)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withOpacity(0.34),
                ),
              ),
            const Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Text(
                'Align the paper inside the frame and keep the camera steady.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return previewFrame;
  }
}

class _ProcessingView extends StatelessWidget {
  const _ProcessingView({
    super.key,
    required this.imagePath,
    required this.capturedCount,
    required this.isProcessing,
    required this.processingError,
    required this.extractedText,
    required this.onContinue,
    required this.onRetry,
  });

  final String? imagePath;
  final int capturedCount;
  final bool isProcessing;
  final String? processingError;
  final String extractedText;
  final VoidCallback onContinue;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            if (isProcessing)
              const CircularProgressIndicator()
            else
              Icon(
                processingError == null
                    ? Icons.task_alt_rounded
                    : Icons.error_outline_rounded,
                size: 44,
                color: processingError == null
                    ? const Color(0xFF0F766E)
                    : const Color(0xFFB91C1C),
              ),
            const SizedBox(height: 20),
            Text(
              isProcessing ? 'Analyzing paper...' : 'Processing complete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              processingError ??
                  (isProcessing
                      ? 'Reading stored pages from Hive, running OCR, then sending the extracted text to Gemini for cleanup, answer extraction, and grading.'
                      : 'Processed scan text is ready for review, including Gemini cleanup when available.'),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (capturedCount > 0) ...[
              _CaptureInfoChip(
                icon: Icons.layers_outlined,
                label: capturedCount == 1
                    ? '1 captured paper ready for analysis'
                    : '$capturedCount captured pages ready for analysis',
              ),
              const SizedBox(height: 14),
            ],
            Container(
              height: 180,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: imagePath == null
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 42,
                            color: Color(0xFF64748B),
                          ),
                          SizedBox(height: 10),
                          Text('Preview appears after capture'),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(imagePath!), fit: BoxFit.cover),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                capturedCount > 1
                                    ? 'Latest page preview'
                                    : 'Captured paper preview',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            if (extractedText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stored OCR Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      extractedText.length > 280
                          ? '${extractedText.substring(0, 280)}...'
                          : extractedText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isProcessing || processingError != null
                    ? null
                    : onContinue,
                child: Text(isProcessing ? 'Processing...' : 'View Result'),
              ),
            ),
            if (processingError != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: const Text('Retry Processing'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewResultView extends StatelessWidget {
  const _ReviewResultView({
    super.key,
    required this.score,
    required this.imagePath,
    required this.capturedCount,
    required this.feedbackController,
    required this.evaluation,
    required this.onScoreChanged,
    required this.onEditScore,
    required this.onSave,
    required this.onNextScan,
  });

  final double score;
  final String? imagePath;
  final int capturedCount;
  final TextEditingController feedbackController;
  final ScanEvaluation? evaluation;
  final ValueChanged<double> onScoreChanged;
  final VoidCallback onEditScore;
  final VoidCallback onSave;
  final VoidCallback onNextScan;

  @override
  Widget build(BuildContext context) {
    final evaluation = this.evaluation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Result',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(Icons.person, color: Color(0xFF1D4ED8)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Info',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 4),
                        Text('Amina Hassan - Admission No. 2031 - Grade 7A'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Score Display',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${score.round()} / 100',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                  Slider(
                    min: 0,
                    max: 100,
                    value: score,
                    onChanged: onScoreChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (evaluation != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        evaluation.usedAi
                            ? 'Awarded ${evaluation.awardedMarks.toStringAsFixed(0)} of ${evaluation.totalMarks.toStringAsFixed(0)} marks from Gemini-assisted comparison.'
                            : 'Awarded ${evaluation.awardedMarks.toStringAsFixed(0)} of ${evaluation.totalMarks.toStringAsFixed(0)} marks from stored OCR comparison.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (evaluation != null && evaluation.usedAi) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gemini Cleaned Text',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      evaluation.combinedOcrText.length > 420
                          ? '${evaluation.combinedOcrText.substring(0, 420)}...'
                          : evaluation.combinedOcrText,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            TextField(
              controller: feedbackController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Feedback Box',
                hintText: 'Editable AI comment',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            if (capturedCount > 0) ...[
              _CaptureInfoChip(
                icon: Icons.fact_check_outlined,
                label: capturedCount == 1
                    ? 'Scored from 1 captured paper'
                    : 'Scored from $capturedCount captured pages',
              ),
              const SizedBox(height: 14),
            ],
            if (evaluation != null && evaluation.comparisons.isNotEmpty) ...[
              if (evaluation.usedAi &&
                  evaluation.aiExtractedAnswers.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gemini Extracted Answers',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...evaluation.aiExtractedAnswers.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Q${item['questionNumber']}: ${item['answer']?.toString().trim().isNotEmpty == true ? item['answer'] : 'Not found'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer Comparison',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...evaluation.comparisons.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isCorrect
                                  ? Icons.check_circle
                                  : Icons.cancel_outlined,
                              color: item.isCorrect
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFFB91C1C),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Q${item.questionNumber}: expected "${item.expectedAnswer.isEmpty ? '-' : item.expectedAnswer}" | detected "${item.detectedAnswer.isEmpty ? 'Not found' : item.detectedAnswer}"',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
            Container(
              height: 190,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                children: [
                  if (imagePath != null)
                    Positioned.fill(
                      child: Image.file(File(imagePath!), fit: BoxFit.cover),
                    )
                  else
                    const Center(
                      child: Text(
                        'Annotated Image Preview',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  Positioned(
                    top: 28,
                    right: 42,
                    child: _MistakeMarker(label: 'Q4'),
                  ),
                  Positioned(
                    bottom: 32,
                    left: 36,
                    child: _MistakeMarker(label: 'Units'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onEditScore,
                    child: const Text('Edit Score'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onSave,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onNextScan,
                child: const Text('Next Scan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: unused_element
class _AssessmentKeyPreview extends StatelessWidget {
  const _AssessmentKeyPreview({required this.assessmentKey});

  final AssessmentKey assessmentKey;

  @override
  Widget build(BuildContext context) {
    final previewQuestions = assessmentKey.questions.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Key Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...previewQuestions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${question.resolvedNumber(1)}'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.resolvedType.label),
                        const SizedBox(height: 2),
                        Text(
                          'Ans: ${question.resolvedAnswer} • ${question.resolvedMarks.toStringAsFixed(0)} marks',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (assessmentKey.totalQuestions > previewQuestions.length)
            Text(
              '+ ${assessmentKey.totalQuestions - previewQuestions.length} more questions configured',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _AnswerKeyEditorSheet extends StatefulWidget {
  const _AnswerKeyEditorSheet({
    required this.assessmentType,
    required this.initialKey,
  });

  final String assessmentType;
  final AssessmentKey initialKey;

  @override
  State<_AnswerKeyEditorSheet> createState() => _AnswerKeyEditorSheetState();
}

class _AnswerKeyEditorSheetState extends State<_AnswerKeyEditorSheet> {
  late List<QuestionKeyItem> _questions;
  late int _questionCount;

  @override
  void initState() {
    super.initState();
    _questions = widget.initialKey.questions
        .asMap()
        .entries
        .map((entry) => entry.value.normalized(fallbackNumber: entry.key + 1))
        .toList();
    _questionCount = _questions.length;
  }

  void _updateQuestionCount(int count) {
    setState(() {
      _questionCount = count;
      if (_questions.length < count) {
        final start = _questions.length;
        _questions = [
          ..._questions,
          ...List.generate(
            count - start,
            (index) => QuestionKeyItem(
              number: start + index + 1,
              type: QuestionType.multipleChoice,
              description: 'Choose the correct option from A, B, C, or D.',
              correctAnswer: '',
              marks: 1,
            ),
          ),
        ];
      } else {
        _questions = _questions.take(count).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Answer Key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.assessmentType} setup for numbering, question type, answers, and marks.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                value: _questionCount,
                decoration: const InputDecoration(
                  labelText: 'Total Number of Questions',
                  border: OutlineInputBorder(),
                ),
                items: List.generate(
                  20,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} Questions'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) _updateQuestionCount(value);
                },
              ),
              const SizedBox(height: 18),
              ..._questions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QuestionEditorCard(
                    item: entry.value,
                    onTypeChanged: (type) {
                      setState(() {
                        _questions[entry.key] = _questions[entry.key].copyWith(
                          type: type,
                        );
                      });
                    },
                    onAnswerChanged: (answer) {
                      _questions[entry.key] = _questions[entry.key].copyWith(
                        correctAnswer: answer,
                      );
                    },
                    onMarksChanged: (marks) {
                      final parsed = double.tryParse(marks);
                      if (parsed != null) {
                        _questions[entry.key] = _questions[entry.key].copyWith(
                          marks: parsed,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      AssessmentKey(
                        assessmentType: widget.assessmentType,
                        questions: _questions,
                      ),
                    );
                  },
                  child: const Text('Save Answer Key'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionEditorCard extends StatelessWidget {
  const _QuestionEditorCard({
    required this.item,
    required this.onTypeChanged,
    required this.onAnswerChanged,
    required this.onMarksChanged,
  });

  final QuestionKeyItem item;
  final ValueChanged<QuestionType> onTypeChanged;
  final ValueChanged<String> onAnswerChanged;
  final ValueChanged<String> onMarksChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${item.resolvedNumber(1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QuestionType>(
            value: item.resolvedType,
            decoration: const InputDecoration(
              labelText: 'Question Type',
              border: OutlineInputBorder(),
            ),
            items: QuestionType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.resolvedAnswer,
            decoration: InputDecoration(
              labelText: _answerHintForType(item.resolvedType),
              border: const OutlineInputBorder(),
            ),
            onChanged: onAnswerChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.resolvedMarks.toStringAsFixed(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Marks',
              border: OutlineInputBorder(),
            ),
            onChanged: onMarksChanged,
          ),
        ],
      ),
    );
  }

  String _answerHintForType(QuestionType type) {
    return switch (type) {
      QuestionType.trueFalse => 'Correct Answer (True / False)',
      QuestionType.matching => 'Correct Matches',
      QuestionType.multipleChoice => 'Correct Option',
      QuestionType.fillInBlank => 'Correct Blank Answer',
      QuestionType.shortAnswer => 'Expected Short Answer',
    };
  }
}

class _AssessmentKeyPreviewPanel extends StatelessWidget {
  const _AssessmentKeyPreviewPanel({required this.assessmentKey});

  final AssessmentKey assessmentKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Answer Key Preview',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          ...assessmentKey.questions.map(
            (question) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${question.resolvedNumber(1)}'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.resolvedType.label),
                        const SizedBox(height: 2),
                        Text(
                          question.resolvedDescription,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ans: ${question.resolvedAnswer} | ${question.resolvedMarks.toStringAsFixed(0)} marks',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerKeyEditorSheetV2 extends StatefulWidget {
  const _AnswerKeyEditorSheetV2({
    required this.assessmentType,
    required this.initialKey,
  });

  final String assessmentType;
  final AssessmentKey initialKey;

  @override
  State<_AnswerKeyEditorSheetV2> createState() =>
      _AnswerKeyEditorSheetV2State();
}

class _AnswerKeyEditorSheetV2State extends State<_AnswerKeyEditorSheetV2> {
  late List<QuestionKeyItem> _questions;
  late final TextEditingController _questionCountController;

  @override
  void initState() {
    super.initState();
    _questions = widget.initialKey.questions
        .asMap()
        .entries
        .map((entry) => entry.value.normalized(fallbackNumber: entry.key + 1))
        .toList();
    _questionCountController = TextEditingController(
      text: _questions.length.toString(),
    );
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  void _updateQuestionCount(int count) {
    setState(() {
      _questionCountController.text = count.toString();
      if (_questions.length < count) {
        final start = _questions.length;
        _questions = [
          ..._questions,
          ...List.generate(
            count - start,
            (index) => QuestionKeyItem(
              number: start + index + 1,
              type: QuestionType.multipleChoice,
              description: 'Choose the correct option from A, B, C, or D.',
              correctAnswer: '',
              marks: 1,
            ),
          ),
        ];
      } else {
        _questions = _questions.take(count).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Answer Key',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.assessmentType} setup for numbering, question type, answers, and marks.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _questionCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Number of Questions',
                  hintText: 'Enter total questions manually',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null && parsed > 0) {
                    _updateQuestionCount(parsed);
                  }
                },
              ),
              const SizedBox(height: 18),
              ..._questions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _QuestionEditorCardV2(
                    item: entry.value,
                    onTypeChanged: (type) {
                      setState(() {
                        _questions[entry.key] = _questions[entry.key].copyWith(
                          type: type,
                        );
                      });
                    },
                    onAnswerChanged: (answer) {
                      _questions[entry.key] = _questions[entry.key].copyWith(
                        correctAnswer: answer,
                      );
                    },
                    onMarksChanged: (marks) {
                      final parsed = double.tryParse(marks);
                      if (parsed != null) {
                        _questions[entry.key] = _questions[entry.key].copyWith(
                          marks: parsed,
                        );
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      AssessmentKey(
                        assessmentType: widget.assessmentType,
                        questions: _questions,
                      ),
                    );
                  },
                  child: const Text('Save Answer Key'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestionEditorCardV2 extends StatelessWidget {
  const _QuestionEditorCardV2({
    required this.item,
    required this.onTypeChanged,
    required this.onAnswerChanged,
    required this.onMarksChanged,
  });

  final QuestionKeyItem item;
  final ValueChanged<QuestionType> onTypeChanged;
  final ValueChanged<String> onAnswerChanged;
  final ValueChanged<String> onMarksChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question ${item.resolvedNumber(1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<QuestionType>(
            value: item.resolvedType,
            decoration: const InputDecoration(
              labelText: 'Question Type',
              border: OutlineInputBorder(),
            ),
            items: QuestionType.values
                .map(
                  (type) =>
                      DropdownMenuItem(value: type, child: Text(type.label)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.resolvedAnswer,
            decoration: InputDecoration(
              labelText: _answerHintForType(item.resolvedType),
              border: const OutlineInputBorder(),
            ),
            onChanged: onAnswerChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.resolvedMarks.toStringAsFixed(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Marks',
              border: OutlineInputBorder(),
            ),
            onChanged: onMarksChanged,
          ),
        ],
      ),
    );
  }

  String _answerHintForType(QuestionType type) {
    return switch (type) {
      QuestionType.trueFalse => 'Correct Answer (True / False)',
      QuestionType.matching => 'Correct Matches',
      QuestionType.multipleChoice => 'Correct Option',
      QuestionType.fillInBlank => 'Correct Blank Answer',
      QuestionType.shortAnswer => 'Expected Short Answer',
    };
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _TeacherAssignment {
  const _TeacherAssignment({
    required this.classes,
    required this.sectionsByClass,
  });

  final List<String> classes;
  final Map<String, List<String>> sectionsByClass;

  factory _TeacherAssignment.fromFirestore(Map<String, dynamic> data) {
    final classes = <String>{};
    final sectionsByClass = <String, List<String>>{};

    final classAssigned = data['classAssigned']?.toString().trim();
    if (classAssigned != null && classAssigned.isNotEmpty) {
      classes.add(classAssigned);
    }

    final classAssignments = (data['classAssignments'] as List? ?? const [])
        .followedBy(data['classesAssigned'] as List? ?? const [])
        .followedBy(data['assignedClasses'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty);
    classes.addAll(classAssignments);

    final sections = (data['sections'] as List? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList();

    if (sections.isNotEmpty) {
      if (classAssigned != null && classAssigned.isNotEmpty) {
        sectionsByClass[classAssigned] = sections;
      }

      for (final className in classes) {
        sectionsByClass.putIfAbsent(className, () => sections);
      }
    }

    final rawSectionsByClass = data['sectionsByClass'];
    if (rawSectionsByClass is Map) {
      for (final entry in rawSectionsByClass.entries) {
        final className = entry.key.toString().trim();
        if (className.isEmpty) {
          continue;
        }

        final sectionList = (entry.value as List? ?? const [])
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList();
        classes.add(className);
        sectionsByClass[className] = sectionList;
      }
    }

    final sortedClasses = classes.toList()..sort();
    return _TeacherAssignment(
      classes: sortedClasses.isEmpty ? const ['Grade 7'] : sortedClasses,
      sectionsByClass: sectionsByClass,
    );
  }

  List<String> sectionsForClass(String selectedClass) {
    final sections = sectionsByClass.entries
        .firstWhere(
          (entry) =>
              _normalizeClassValue(entry.key) ==
              _normalizeClassValue(selectedClass),
          orElse: () => const MapEntry('', <String>[]),
        )
        .value;

    final sortedSections = [...sections]..sort();
    return sortedSections.isEmpty ? const ['A'] : sortedSections;
  }
}

String _normalizeClassValue(String value) {
  final trimmed = value.trim().toLowerCase();
  if (trimmed.isEmpty) {
    return '';
  }

  final gradeMatch = RegExp(r'(\d+)').firstMatch(trimmed);
  if (gradeMatch != null) {
    return 'grade${gradeMatch.group(1)}';
  }

  return trimmed.replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final IconData icon;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0F766E)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CaptureInfoChip extends StatelessWidget {
  const _CaptureInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0F766E), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeMarker extends StatelessWidget {
  const _MistakeMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDC2626),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
