import 'package:flutter/foundation.dart';
import '../../core/dialogue/dialogue_state.dart';
import '../../core/dialogue/dialogue_controller.dart';
import '../../core/personalisation/personalisation_service.dart';
import '../../core/analytics/analytics_service.dart';
import '../../core/llm/llm_service.dart';

class HomeController extends ChangeNotifier {
  HomeController() {
    DialogueController.instance.addListener(_onCoreChanged);
  }

  @override
  void dispose() {
    DialogueController.instance.removeListener(_onCoreChanged);
    super.dispose();
  }

  void _onCoreChanged() {
    notifyListeners();
  }

  // Proxies to DialogueController
  DialogueState get dialogueState => DialogueController.instance.state;
  String get transcript => DialogueController.instance.transcript;
  String get intentJson => DialogueController.instance.lastIntent ?? '';
  String get statusText => DialogueController.instance.statusText;
  String get language => DialogueController.instance.preferredLanguage;

  // LLM not ready is fine — rule engine handles all 15 intents
  bool get llmReady => LlmService.instance.isReady;

  void setLanguage(String lang) {
    // Wires directly to DialogueController so STT locale updates too
    DialogueController.instance.setPreferredLanguage(lang);
    notifyListeners();
  }

  void onMicButtonTapped() {
    DialogueController.instance.onMicButtonTapped();
  }

  Stream<MappingProposal> get proposalStream =>
      PersonalisationService.instance.proposalStream;

  AnalyticsReport getAnalyticsReport() =>
      AnalyticsService.instance.getReport();
}
