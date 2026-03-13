// DEV 3 — implement per PDR Section 12.1
import 'package:flutter/material.dart';
import '../../core/dialogue/dialogue_state.dart';
import '../../core/personalisation/personalisation_service.dart';

class HomeController extends ChangeNotifier {
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
  String get statusText => _dialogueState.name;

  Stream<MappingProposal> get proposalStream =>
      PersonalisationService.instance.proposalStream;

  void setLanguage(String lang) { _language = lang; notifyListeners(); }
  void onMicButtonTapped() {
    // TODO: if listening → stop | else → trigger wake word flow
  }
}
