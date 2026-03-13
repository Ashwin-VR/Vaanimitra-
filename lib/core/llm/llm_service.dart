import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:llama_sdk/llama_sdk.dart';
import '../../models/parsed_command.dart';
import '../../models/v_intent.dart';
import '../../app/constants.dart';
import '../stt/language_detector.dart';

class LlmService {
  static final instance = LlmService._();
  LlmService._();

  Llama? _llama;
  String? _modelPath;
  bool _ready = false;
  bool _warm = false;

  bool get isReady => _ready;
  bool get isWarm => _warm;

  // ─── Find model on device ─────────────────────────────────────────────────
  Future<void> findModel() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      // Try primary name first, then fallback
      for (final name in [
        VConstants.modelFileName,
        VConstants.fallbackModelFileName,
      ]) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) {
          _modelPath = file.path;
          _ready = true;
          return;
        }
      }
      // Model not present — rule-engine-only mode
      _ready = false;
    } catch (_) {
      _ready = false;
    }
  }

  // ─── Load model into RAM ──────────────────────────────────────────────────
  Future<void> warmUp() async {
    if (!_ready || _modelPath == null) return;
    try {
      _llama = Llama(
        _modelPath!,
        nCtx: VConstants.nCtx,
        nBatch: 256,
        nThreads: 4,
      );
      _warm = true;
    } catch (e) {
      _ready = false;
      _warm = false;
    }
  }

  // ─── Run inference ────────────────────────────────────────────────────────
  Future<ParsedCommand> infer(String transcript, String cacheContext) async {
    final language = LanguageDetector.detect(transcript);

    if (!_warm || _llama == null) {
      // LLM unavailable — return unknown so DialogueController can clarify
      return ParsedCommand.unknown(transcript, language);
    }

    final prompt = _buildPrompt(transcript, cacheContext);

    try {
      final rawOutput = await _runInference(prompt);
      return _parseOutput(rawOutput, transcript, language);
    } catch (_) {
      return ParsedCommand.unknown(transcript, language);
    }
  }

  // ─── Prompt construction ──────────────────────────────────────────────────
  String _buildPrompt(String transcript, String cacheContext) {
    return '<|im_start|>system\n'
        '${VConstants.systemPrompt}'
        '$cacheContext'
        '<|im_end|>\n'
        '<|im_start|>user\n'
        '$transcript'
        '<|im_end|>\n'
        '<|im_start|>assistant\n';
  }

  // ─── Inference (blocking isolate-safe call) ───────────────────────────────
  Future<String> _runInference(String prompt) async {
    final llama = _llama!;
    llama.setPrompt(prompt);

    final buffer = StringBuffer();
    final stopTokens = {'<|im_end|>', '</s>', '\n'};

    // Iterate through tokens until stop token or max tokens reached
    for (var i = 0; i < VConstants.maxTokens; i++) {
        final token = await llama.getNextToken();
        if (token == null || stopTokens.any((st) => token.contains(st))) break;
        buffer.write(token);
    }
    
    return buffer.toString().trim();
  }

  // ─── JSON Parsing ─────────────────────────────────────────────────────────
  ParsedCommand _parseOutput(String raw, String transcript, String language) {
    try {
      // Find JSON block if model gets chatty
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1) throw Exception('No JSON');
      
      final jsonStr = raw.substring(start, end + 1);
      final json = jsonDecode(jsonStr);

      final intentStr = (json['intent'] as String? ?? 'UNKNOWN').toUpperCase();
      final intent = VIntentX.fromString(intentStr);
      final params = json['params'] as Map<String, dynamic>? ?? {};

      return ParsedCommand(
        intent: intent,
        params: params,
        language: language,
        source: 'llm',
        rawTranscript: transcript,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      return ParsedCommand.unknown(transcript, language);
    }
  }
}
