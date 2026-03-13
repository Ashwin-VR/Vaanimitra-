// lib/ui/home/home_controller.dart

import 'package:flutter/foundation.dart';
import 'package:vanimitra/core/analytics/analytics_service.dart';
import 'package:vanimitra/core/dialogue/dialogue_state.dart';
import 'package:vanimitra/core/dialogue/dialogue_controller.dart';
import 'package:vanimitra/core/stt/stt_service.dart';
import 'package:vanimitra/core/personalisation/personalisation_service.dart';
import 'package:vanimitra/models/v_intent.dart';

class HomeController extends ChangeNotifier {
  // ── Observable state ──────────────────────────────────────────────────────
  DialogueState _dialogueState = DialogueState.idle;
  String _transcript = '';
  String _intentJson = '';
  String _language = 'en';
  bool _llmReady = false;

  DialogueState get dialogueState => _dialogueState;
  String get transcript => _transcript;
  String get intentJson => _intentJson;
  String get language => _language;
  bool get llmReady => _llmReady;

  String get statusText {
    switch (_dialogueState) {
      case DialogueState.idle:
        return "Say 'Vaani' to start";
      case DialogueState.listening:
        return 'Listening...';
      case DialogueState.processing:
        return 'Thinking...';
      case DialogueState.clarifying:
        return 'Please answer...';
      case DialogueState.executing:
        return 'Doing it...';
      case DialogueState.confirming:
        return 'Waiting for your answer...';
    }
  }

  // ── Setters called by Dev 2 DialogueController ───────────────────────────

  void updateState(DialogueState state) {
    _dialogueState = state;
    notifyListeners();
  }

  void updateTranscript(String text) {
    _transcript = text;
    notifyListeners();
  }

  void updateIntent(VIntent intent, Map<String, dynamic> params) {
    _intentJson =
        '{"intent":"${intent.toJsonKey()}","params":${_encodeParams(params)}}';
    notifyListeners();
  }

  void setLlmReady(bool ready) {
    _llmReady = ready;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
    // Connect to Dev 2's dialogue controller pipeline
    // Assuming DialogueController handles language switching logic internally
  }

  void onMicButtonTapped() {
    if (_dialogueState == DialogueState.listening) {
      // User tapped while listening -> cancel/stop STT
      DialogueController.instance.sttService.stop();
    } else if (_dialogueState == DialogueState.idle) {
      // User tapped while idle -> manual trigger
      DialogueController.instance.start();
    }
  }

  // ── Proposal stream forwarded from PersonalisationService ─────────────────
  Stream<MappingProposal> get proposalStream =>
      PersonalisationService.instance.proposalStream;

  // ── Analytics shortcut ────────────────────────────────────────────────────
  AnalyticsReport getAnalyticsReport() =>
      AnalyticsService.instance.getReport();

  // ── Internal helpers ──────────────────────────────────────────────────────
  String _encodeParams(Map<String, dynamic> params) {
    if (params.isEmpty) return '{}';
    final entries =
        params.entries.map((e) => '"${e.key}":"${e.value}"').join(',');
    return '{$entries}';
  }
}
