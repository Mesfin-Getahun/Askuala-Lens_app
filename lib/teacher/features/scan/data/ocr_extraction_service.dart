import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

class OcrExtractionResult {
  const OcrExtractionResult({
    required this.text,
    required this.provider,
  });

  final String text;
  final String provider;
}

class OcrExtractionService {
  OcrExtractionService({http.Client? client}) : _client = client ?? http.Client();

  static const String _googleVisionApiKey = String.fromEnvironment(
    'GOOGLE_VISION_API_KEY',
  );
  static const String _azureVisionEndpoint = String.fromEnvironment(
    'AZURE_VISION_ENDPOINT',
  );
  static const String _azureVisionApiKey = String.fromEnvironment(
    'AZURE_VISION_API_KEY',
  );

  final http.Client _client;

  Future<OcrExtractionResult> extractText(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      return const OcrExtractionResult(text: '', provider: 'missing_file');
    }

    if (_googleVisionApiKey.trim().isNotEmpty) {
      try {
        final result = await _extractWithGoogleVision(file);
        if (result.text.trim().isNotEmpty) {
          return result;
        }
      } catch (_) {
        // Fall through to next OCR provider.
      }
    }

    if (_azureVisionEndpoint.trim().isNotEmpty &&
        _azureVisionApiKey.trim().isNotEmpty) {
      try {
        final result = await _extractWithAzureVision(file);
        if (result.text.trim().isNotEmpty) {
          return result;
        }
      } catch (_) {
        // Fall through to local OCR.
      }
    }

    return _extractWithMlKit(imagePath);
  }

  Future<OcrExtractionResult> _extractWithGoogleVision(File file) async {
    final imageBytes = await file.readAsBytes();
    final uri = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$_googleVisionApiKey',
    );
    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Encode(imageBytes)},
            'features': [
              {'type': 'DOCUMENT_TEXT_DETECTION'},
            ],
            'imageContext': {
              'languageHints': ['en'],
            },
          },
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Google Vision OCR failed (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final responses = decoded['responses'] as List? ?? const [];
    if (responses.isEmpty) {
      return const OcrExtractionResult(text: '', provider: 'google_vision');
    }

    final first = responses.first as Map<String, dynamic>;
    final text =
        first['fullTextAnnotation']?['text']?.toString().trim().isNotEmpty == true
        ? first['fullTextAnnotation']!['text'].toString().trim()
        : ((first['textAnnotations'] as List? ?? const []).isNotEmpty
              ? ((first['textAnnotations'] as List).first
                        as Map<String, dynamic>)['description']
                    ?.toString()
                    .trim() ??
                ''
              : '');

    return OcrExtractionResult(text: text, provider: 'google_vision');
  }

  Future<OcrExtractionResult> _extractWithAzureVision(File file) async {
    final endpoint = _azureVisionEndpoint.trim().replaceAll(RegExp(r'/$'), '');
    final analyzeUri = Uri.parse('$endpoint/vision/v3.2/read/analyze');
    final imageBytes = await file.readAsBytes();

    final analyzeResponse = await _client.post(
      analyzeUri,
      headers: {
        'Ocp-Apim-Subscription-Key': _azureVisionApiKey,
        'Content-Type': 'application/octet-stream',
      },
      body: imageBytes,
    );

    if (analyzeResponse.statusCode != 202) {
      throw Exception('Azure OCR analyze failed (${analyzeResponse.statusCode}).');
    }

    final operationLocation = analyzeResponse.headers['operation-location'];
    if (operationLocation == null || operationLocation.trim().isEmpty) {
      throw Exception('Azure OCR did not return an operation URL.');
    }

    final resultUri = Uri.parse(operationLocation);
    for (var attempt = 0; attempt < 8; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final resultResponse = await _client.get(
        resultUri,
        headers: {
          'Ocp-Apim-Subscription-Key': _azureVisionApiKey,
        },
      );

      if (resultResponse.statusCode < 200 || resultResponse.statusCode >= 300) {
        throw Exception(
          'Azure OCR result polling failed (${resultResponse.statusCode}).',
        );
      }

      final decoded = jsonDecode(resultResponse.body) as Map<String, dynamic>;
      final status = decoded['status']?.toString().toLowerCase();
      if (status == 'succeeded') {
        final readResults =
            decoded['analyzeResult']?['readResults'] as List? ?? const [];
        final lines = readResults
            .whereType<Map>()
            .expand((page) => (page['lines'] as List? ?? const []).whereType<Map>())
            .map((line) => line['text']?.toString().trim() ?? '')
            .where((line) => line.isNotEmpty)
            .toList();

        return OcrExtractionResult(
          text: lines.join('\n'),
          provider: 'azure_vision',
        );
      }

      if (status == 'failed') {
        throw Exception('Azure OCR processing failed.');
      }
    }

    throw Exception('Azure OCR timed out while waiting for results.');
  }

  Future<OcrExtractionResult> _extractWithMlKit(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await textRecognizer.processImage(inputImage);
      return OcrExtractionResult(
        text: recognized.text,
        provider: 'google_mlkit_local',
      );
    } finally {
      textRecognizer.close();
    }
  }
}
