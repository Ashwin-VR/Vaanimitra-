// DEV 2 — implement per PDR Section 9.4
import '../../models/parsed_command.dart';
class LlmService {
  static final instance = LlmService._();
  LlmService._();
  bool get isReady => false;
  bool get isWarm => false;
  Future<void> findModel() async {}
  Future<void> warmUp() async {}
  Future<ParsedCommand> infer(String transcript, String cacheContext) async =>
      ParsedCommand.unknown(transcript, 'en');
}
