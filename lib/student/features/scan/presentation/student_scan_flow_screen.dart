import 'package:flutter/material.dart';

import '../../shared/domain/student_learning_record.dart';

enum StudentScanStep { capture, processing, explanation }

class StudentScanFlowScreen extends StatefulWidget {
  const StudentScanFlowScreen({
    super.key,
    required this.selectedLanguage,
    required this.onLanguageChanged,
    required this.onSaveToHistory,
  });

  final String selectedLanguage;
  final ValueChanged<String> onLanguageChanged;
  final ValueChanged<StudentLearningRecord> onSaveToHistory;

  @override
  State<StudentScanFlowScreen> createState() => _StudentScanFlowScreenState();
}

class _StudentScanFlowScreenState extends State<StudentScanFlowScreen> {
  StudentScanStep _currentStep = StudentScanStep.capture;
  bool _flashEnabled = false;
  late String _selectedLanguage;
  late String _explanationLanguage;

  final List<String> _languages = const [
    'Amharic',
    'Afaan Oromoo',
    'Tigrinya',
    'English',
  ];

  final StudentExplanation _sampleExplanation = const StudentExplanation(
    topic: 'Fractions',
    subject: 'Mathematics',
    questionLabel: 'What is 3/4?',
    explanation:
        'Three-fourths means the whole is divided into 4 equal parts and you are taking 3 of those parts. It is more than one-half and less than one whole.',
    example:
        'If a family cuts one injera into 4 equal pieces and you eat 3 pieces, you have eaten 3/4 of the injera.',
  );

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
    _explanationLanguage = widget.selectedLanguage;
  }

  @override
  void didUpdateWidget(covariant StudentScanFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.selectedLanguage != widget.selectedLanguage) {
      _selectedLanguage = widget.selectedLanguage;
      _explanationLanguage = widget.selectedLanguage;
    }
  }

  Future<void> _startProcessing() async {
    setState(() {
      _currentStep = StudentScanStep.processing;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      return;
    }

    setState(() {
      _currentStep = StudentScanStep.explanation;
    });
  }

  void _saveToHistory() {
    widget.onSaveToHistory(
      StudentLearningRecord(
        topic: _sampleExplanation.topic,
        subject: _sampleExplanation.subject,
        language: _explanationLanguage,
        savedAt: DateTime.now(),
        explanation: _sampleExplanation.explanation,
        example: _sampleExplanation.example,
        imageLabel: _sampleExplanation.questionLabel,
      ),
    );
  }

  void _resetFlow() {
    setState(() {
      _currentStep = StudentScanStep.capture;
      _explanationLanguage = _selectedLanguage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (_currentStep) {
          StudentScanStep.capture => _ScanCaptureStep(
              selectedLanguage: _selectedLanguage,
              flashEnabled: _flashEnabled,
              languages: _languages,
              onLanguageChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                  _explanationLanguage = value;
                });
                widget.onLanguageChanged(value);
              },
              onToggleFlash: () {
                setState(() {
                  _flashEnabled = !_flashEnabled;
                });
              },
              onCapture: _startProcessing,
              onUpload: _startProcessing,
            ),
          StudentScanStep.processing => const _ScanProcessingStep(),
          StudentScanStep.explanation => _ExplanationStep(
              explanation: _sampleExplanation,
              selectedLanguage: _explanationLanguage,
              languages: _languages,
              onLanguageChanged: (value) {
                setState(() {
                  _explanationLanguage = value;
                });
                widget.onLanguageChanged(value);
              },
              onSave: _saveToHistory,
              onAskFollowUp: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Follow-up chat is ready in Chat tab.')),
                );
              },
              onListen: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voice Explanation',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Playing explanation in $_explanationLanguage.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(_sampleExplanation.explanation),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                FilledButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Voice playback started in $_explanationLanguage.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play'),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text('Close'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              onSimplify: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Explanation simplified one level more.')),
                );
              },
              onScanAnother: _resetFlow,
            ),
        },
      ),
    );
  }
}

class StudentExplanation {
  const StudentExplanation({
    required this.topic,
    required this.subject,
    required this.questionLabel,
    required this.explanation,
    required this.example,
  });

  final String topic;
  final String subject;
  final String questionLabel;
  final String explanation;
  final String example;
}

class _ScanCaptureStep extends StatelessWidget {
  const _ScanCaptureStep({
    required this.selectedLanguage,
    required this.flashEnabled,
    required this.languages,
    required this.onLanguageChanged,
    required this.onToggleFlash,
    required this.onCapture,
    required this.onUpload,
  });

  final String selectedLanguage;
  final bool flashEnabled;
  final List<String> languages;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onToggleFlash;
  final VoidCallback onCapture;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('scan-capture'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scan Question',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<String>(
                  value: selectedLanguage,
                  decoration: const InputDecoration(
                    labelText: 'Language',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: languages
                      .map(
                        (language) => DropdownMenuItem(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onLanguageChanged(value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 410,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 240,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 24,
                  left: 24,
                  child: _CameraTag(label: 'Camera Preview'),
                ),
                const Positioned(
                  bottom: 28,
                  left: 24,
                  right: 24,
                  child: Text(
                    'Align the question inside the frame so the explanation is clear and easy to read.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 170,
                child: OutlinedButton.icon(
                  onPressed: onUpload,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text('Upload Image'),
                ),
              ),
              SizedBox(
                width: 150,
                child: FilledButton.icon(
                  onPressed: onCapture,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Capture'),
                ),
              ),
              IconButton.filledTonal(
                onPressed: onToggleFlash,
                icon: Icon(
                  flashEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CameraTag extends StatelessWidget {
  const _CameraTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
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

class _ScanProcessingStep extends StatelessWidget {
  const _ScanProcessingStep();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('scan-processing'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Understanding your question...',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationStep extends StatelessWidget {
  const _ExplanationStep({
    required this.explanation,
    required this.selectedLanguage,
    required this.languages,
    required this.onLanguageChanged,
    required this.onSave,
    required this.onAskFollowUp,
    required this.onListen,
    required this.onSimplify,
    required this.onScanAnother,
  });

  final StudentExplanation explanation;
  final String selectedLanguage;
  final List<String> languages;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onSave;
  final VoidCallback onAskFollowUp;
  final VoidCallback onListen;
  final VoidCallback onSimplify;
  final VoidCallback onScanAnother;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('scan-explanation'),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Explanation',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onScanAnother,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Again'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Original Image Preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      explanation.questionLabel,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Language', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages
                .map(
                  (language) => ChoiceChip(
                    label: Text(language),
                    selected: selectedLanguage == language,
                    onSelected: (_) => onLanguageChanged(language),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          _InfoCard(
            title: 'Simple explanation',
            color: const Color(0xFFE0F2FE),
            text: explanation.explanation,
          ),
          const SizedBox(height: 14),
          _InfoCard(
            title: 'Real-Life Example',
            color: const Color(0xFFDCFCE7),
            text: explanation.example,
          ),
          const SizedBox(height: 18),
          Text('Actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 170,
                child: OutlinedButton.icon(
                  onPressed: onListen,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: const Text('Listen'),
                ),
              ),
              SizedBox(
                width: 170,
                child: OutlinedButton.icon(
                  onPressed: onSimplify,
                  icon: const Icon(Icons.sync_alt_rounded),
                  label: const Text('Simplify More'),
                ),
              ),
              SizedBox(
                width: 190,
                child: FilledButton.icon(
                  onPressed: onAskFollowUp,
                  icon: const Icon(Icons.help_outline_rounded),
                  label: const Text('Ask Follow-up'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0F766E),
              ),
              child: const Text('Save to Learning History'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.color,
    required this.text,
  });

  final String title;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
