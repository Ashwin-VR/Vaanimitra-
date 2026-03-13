import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:llama_sdk/llama_sdk.dart'; // Commented out for now
import '../../models/parsed_command.dart';
import '../../models/v_intent.dart';
import '../../app/constants.dart';
import '../stt/language_detector.dart';

class LlmService {
  static final instance = LlmService._();
  LlmService._();

  // Llama? _llama; // Commented out for now
  String? _modelPath;
  bool _ready = false;
  bool _warm = false;

  bool get isReady => _ready;
  bool get isWarm => _warm;

  // ─── Find model on device ─────────────────────────────────────────────────
  Future<void> findModel() async {
    // STUB: skip model check for now
    _ready = false;
  }

  // ─── Load model into RAM ──────────────────────────────────────────────────
  Future<void> warmUp() async {
    // STUB: nothing to warm up
    _warm = false;
  }

  // ─── Run inference ────────────────────────────────────────────────────────
  Future<ParsedCommand> infer(String transcript, String cacheContext) async {
    // STUB: model not loaded yet — always returns unknown
    // TODO: replace with real llama_sdk calls when GGUF arrives
    return ParsedCommand.unknown(transcript, 'en');
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
    return ""; // Stub
  }

  // ─── JSON Parsing ─────────────────────────────────────────────────────────
  ParsedCommand _parseOutput(String raw, String transcript, String language) {
    return ParsedCommand.unknown(transcript, language); // Stub
  }
}
