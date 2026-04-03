import 'package:flutter/material.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _questionController = TextEditingController();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: 'Why is 3/4 bigger than 1/2?',
      isStudent: true,
    ),
    _ChatMessage(
      text:
          'Because 1/2 is the same as 2/4. When you compare 3/4 and 2/4, 3/4 has one more equal part, so it is bigger.',
      isStudent: false,
    ),
  ];

  final List<String> _suggestions = const [
    'Explain again',
    'Give example',
    'Translate',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  void _sendMessage([String? preset]) {
    final input = (preset ?? _questionController.text).trim();
    if (input.isEmpty) {
      return;
    }

    setState(() {
      _messages.add(_ChatMessage(text: input, isStudent: true));
      _messages.add(
        _ChatMessage(
          text: _buildReply(input),
          isStudent: false,
        ),
      );
      _questionController.clear();
    });
  }

  String _buildReply(String prompt) {
    final lower = prompt.toLowerCase();

    if (lower.contains('explain again')) {
      return 'A fraction compares parts of the same whole. Since 3/4 means 3 out of 4 equal parts and 1/2 means 2 out of 4 equal parts, 3/4 is larger.';
    }

    if (lower.contains('example')) {
      return 'Think of one injera cut into 4 equal pieces. If one student eats 3 pieces and another eats 2 pieces, the student who ate 3 pieces ate more.';
    }

    if (lower.contains('translate')) {
      return 'Translation mode can show this explanation in Amharic, Afaan Oromoo, Tigrinya, or English depending on the student preference.';
    }

    return 'That question connects to the current topic on fractions. The key idea is to compare equal parts of the same whole step by step until the answer feels clear.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _ChatHeader(),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat Messages',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: ListView.separated(
                        itemCount: _messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _ChatBubble(message: message);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Suggestions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _suggestions
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion),
                      onPressed: () => _sendMessage(suggestion),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Type question',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mic input can be connected next.'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chat Header',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Topic: Fractions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Ask follow-up questions and keep the lesson going.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isStudent
              ? const Color(0xFFDBEAFE)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isStudent ? 'Student' : 'AI Tutor',
              style: TextStyle(
                color: message.isStudent
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(message.text),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isStudent,
  });

  final String text;
  final bool isStudent;
}
