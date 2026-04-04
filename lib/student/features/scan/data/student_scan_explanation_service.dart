import '../domain/student_explanation.dart';

class StudentScanExplanationService {
  const StudentScanExplanationService();

  StudentExplanation buildExplanation({
    required String questionText,
    required String language,
    required bool simplifyMore,
  }) {
    final normalized = questionText.trim();
    final lower = normalized.toLowerCase();
    final subject = _detectSubject(lower);
    final topic = _detectTopic(lower, subject);
    final questionLabel = normalized.length > 80
        ? '${normalized.substring(0, 80).trim()}...'
        : normalized;

    return StudentExplanation(
      topic: topic,
      subject: subject,
      questionLabel: questionLabel,
      explanation: _buildExplanationText(
        questionText: normalized,
        subject: subject,
        topic: topic,
        language: language,
        simplifyMore: simplifyMore,
      ),
      example: _buildExample(
        subject: subject,
        topic: topic,
        questionText: normalized,
      ),
    );
  }

  String _detectSubject(String lower) {
    if (lower.contains('fraction') || RegExp(r'\b\d+\s*/\s*\d+\b').hasMatch(lower)) {
      return 'Mathematics';
    }
    if (lower.contains('plant') ||
        lower.contains('leaf') ||
        lower.contains('root') ||
        lower.contains('photosynthesis')) {
      return 'Biology';
    }
    if (lower.contains('map') ||
        lower.contains('river') ||
        lower.contains('mountain') ||
        lower.contains('symbol')) {
      return 'Geography';
    }
    if (lower.contains('noun') ||
        lower.contains('verb') ||
        lower.contains('sentence') ||
        lower.contains('grammar')) {
      return 'English';
    }
    return 'General Studies';
  }

  String _detectTopic(String lower, String subject) {
    if (subject == 'Mathematics' &&
        (lower.contains('fraction') || RegExp(r'\b\d+\s*/\s*\d+\b').hasMatch(lower))) {
      return 'Fractions';
    }
    if (subject == 'Biology' && lower.contains('plant')) {
      return 'Plant Parts and Functions';
    }
    if (subject == 'Geography' && lower.contains('map')) {
      return 'Map Symbols';
    }
    if (subject == 'English' && lower.contains('sentence')) {
      return 'Sentence Structure';
    }
    return subject;
  }

  String _buildExplanationText({
    required String questionText,
    required String subject,
    required String topic,
    required String language,
    required bool simplifyMore,
  }) {
    final styleLead = switch (language) {
      'Amharic' => 'Amharic learning mode selected. ',
      'Afaan Oromoo' => 'Afaan Oromoo learning mode selected. ',
      'Tigrinya' => 'Tigrinya learning mode selected. ',
      _ => '',
    };

    if (topic == 'Fractions') {
      return simplifyMore
          ? '${styleLead}This question is about parts of one whole. The top number tells how many parts are taken, and the bottom number tells how many equal parts the whole has.'
          : '${styleLead}This question is about fractions. A fraction shows part of a whole object or group. When you see something like 3/4, the denominator 4 means the whole is split into 4 equal parts, and the numerator 3 means 3 of those parts are chosen. Read the question, identify the fraction, and compare the part taken with the total equal parts.';
    }

    if (topic == 'Plant Parts and Functions') {
      return simplifyMore
          ? '${styleLead}Think about what each plant part does. Roots take in water, stems support the plant, and leaves help make food.'
          : '${styleLead}This question is asking about how plant parts work together. Roots absorb water and minerals from the soil, the stem supports the plant and carries water upward, and the leaves use sunlight to make food. Match each part to its job before choosing your answer.';
    }

    if (topic == 'Map Symbols') {
      return simplifyMore
          ? '${styleLead}Map symbols are small signs that stand for real places or things. Look at the symbol and remember what place it usually represents.'
          : '${styleLead}This question is about reading map symbols. Maps use simple signs and pictures to represent places like schools, roads, rivers, and health centers. First identify the symbol, then connect it to the real place or feature it stands for.';
    }

    return simplifyMore
        ? '${styleLead}Start by finding the main idea in the question. Look for important words, decide what the question wants, and answer in one clear step.'
        : '${styleLead}This question is stored from the scan text: "$questionText". To answer it well, first identify the key idea, then pick out the important words, and finally explain or solve the problem step by step using the topic "$topic" from $subject.';
  }

  String _buildExample({
    required String subject,
    required String topic,
    required String questionText,
  }) {
    if (topic == 'Fractions') {
      return 'If one injera is cut into 4 equal pieces and you eat 3 pieces, you ate 3/4 of the injera.';
    }
    if (topic == 'Plant Parts and Functions') {
      return 'A maize plant in the school garden uses roots to take in water after rain and leaves to make food from sunlight.';
    }
    if (topic == 'Map Symbols') {
      return 'A small cross on a town map can represent a clinic near the market.';
    }
    if (subject == 'English') {
      return 'If the question asks for the verb in a sentence, look for the action word like "run" or "write".';
    }

    return 'Example from your scan: break the question into smaller parts, answer each part clearly, and then check that your final answer matches what was asked.';
  }
}
