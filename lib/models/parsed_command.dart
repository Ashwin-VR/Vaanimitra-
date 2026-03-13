import 'v_intent.dart';

class ParsedCommand {
  final VIntent intent;
  final Map<String, dynamic> params;
  final String language;   // 'en' | 'hi' | 'ta'
  final String source;     // 'rule' | 'llm'
  final String rawTranscript;
  final DateTime timestamp;

  const ParsedCommand({
    required this.intent,
    required this.params,
    required this.language,
    required this.source,
    required this.rawTranscript,
    required this.timestamp,
  });

  factory ParsedCommand.unknown(String transcript, String language) =>
      ParsedCommand(
        intent: VIntent.unknown,
        params: {},
        language: language,
        source: 'rule',
        rawTranscript: transcript,
        timestamp: DateTime.now(),
      );
}
