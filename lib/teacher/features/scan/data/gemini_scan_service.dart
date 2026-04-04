import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiAssessmentAnswer {
  const GeminiAssessmentAnswer({
    required this.questionNumber,
    required this.answer,
  });

  final int questionNumber;
  final String answer;
}

class GeminiAssessmentComparison {
  const GeminiAssessmentComparison({
    required this.questionNumber,
    required this.detectedAnswer,
    required this.expectedAnswer,
    required this.isCorrect,
    required this.awardedMarks,
    required this.availableMarks,
  });

  final int questionNumber;
  final String detectedAnswer;
  final String expectedAnswer;
  final bool isCorrect;
  final double awardedMarks;
  final double availableMarks;
}

class GeminiAssessmentResult {
  const GeminiAssessmentResult({
    required this.cleanedText,
    required this.feedback,
    required this.answers,
    required this.comparisons,
    required this.awardedMarks,
    required this.totalMarks,
  });

  final String cleanedText;
  final String feedback;
  final List<GeminiAssessmentAnswer> answers;
  final List<GeminiAssessmentComparison> comparisons;
  final double awardedMarks;
  final double totalMarks;
}

class GeminiScanService {
  GeminiScanService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String _model = 'gemini-2.5-flash';

  final http.Client _client;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<GeminiAssessmentResult?> analyzeScan({
    required String assessmentType,
    required String selectedClass,
    required String selectedSection,
    required String rawOcrText,
    required List<Map<String, Object?>> answerKey,
  }) async {
    if (!isConfigured || rawOcrText.trim().isEmpty || answerKey.isEmpty) {
      return null;
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt = '''
You are helping grade a scanned student assessment.

Task:
1. Clean and structure the OCR text.
2. Extract the student's answers by question number.
3. Compare those answers with the answer key.
4. Return marks awarded per question and total marks.
5. Return a short teacher-ready feedback summary.

Assessment type: $assessmentType
Class: $selectedClass
Section: $selectedSection

Answer key JSON:
${jsonEncode(answerKey)}

Raw OCR text:
$rawOcrText

Return ONLY valid JSON with this exact shape:
{
  "cleanedText": "string",
  "feedback": "string",
  "answers": [
    {"questionNumber": 1, "answer": "string"}
  ],
  "comparisons": [
    {
      "questionNumber": 1,
      "detectedAnswer": "string",
      "expectedAnswer": "string",
      "isCorrect": true,
      "awardedMarks": 2,
      "availableMarks": 2
    }
  ],
  "awardedMarks": 6,
  "totalMarks": 10
}
''';

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List? ?? const [];
    if (candidates.isEmpty) {
      throw Exception('Gemini returned no candidates.');
    }

    final content = (candidates.first as Map<String, dynamic>)['content']
        as Map<String, dynamic>?;
    final parts = content?['parts'] as List? ?? const [];
    if (parts.isEmpty) {
      throw Exception('Gemini returned no content parts.');
    }

    final text = (parts.first as Map<String, dynamic>)['text']?.toString() ?? '';
    if (text.trim().isEmpty) {
      throw Exception('Gemini returned empty content.');
    }

    final payload = jsonDecode(text) as Map<String, dynamic>;
    final answers = (payload['answers'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => GeminiAssessmentAnswer(
            questionNumber: (item['questionNumber'] as num?)?.toInt() ?? 0,
            answer: item['answer']?.toString().trim() ?? '',
          ),
        )
        .where((item) => item.questionNumber > 0)
        .toList();

    final comparisons = (payload['comparisons'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => GeminiAssessmentComparison(
            questionNumber: (item['questionNumber'] as num?)?.toInt() ?? 0,
            detectedAnswer: item['detectedAnswer']?.toString().trim() ?? '',
            expectedAnswer: item['expectedAnswer']?.toString().trim() ?? '',
            isCorrect: item['isCorrect'] == true,
            awardedMarks: (item['awardedMarks'] as num?)?.toDouble() ?? 0,
            availableMarks: (item['availableMarks'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((item) => item.questionNumber > 0)
        .toList();

    return GeminiAssessmentResult(
      cleanedText: payload['cleanedText']?.toString().trim().isNotEmpty == true
          ? payload['cleanedText']!.toString().trim()
          : rawOcrText,
      feedback: payload['feedback']?.toString().trim() ?? '',
      answers: answers,
      comparisons: comparisons,
      awardedMarks: (payload['awardedMarks'] as num?)?.toDouble() ?? 0,
      totalMarks: (payload['totalMarks'] as num?)?.toDouble() ?? 0,
    );
  }
}
