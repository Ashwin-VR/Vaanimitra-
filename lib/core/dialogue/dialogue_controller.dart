// DEV 2 — implement per PDR Section 9.8 (this is the brain)
import '../wake_word/wake_word_service.dart';
import '../stt/stt_service.dart';
import '../llm/llm_service.dart';
import '../cache/cache_service.dart';
import '../analytics/analytics_service.dart';
import '../personalisation/personalisation_service.dart';
import '../../features/tts/tts_service.dart';
import '../../features/actions/action_executor.dart';

class DialogueController {
  static final instance = DialogueController._();
  DialogueController._();

  late WakeWordService wakeWordService;
  late SttService sttService;
  late LlmService llmService;
  late CacheService cacheService;
  late AnalyticsService analyticsService;
  late PersonalisationService personalisationService;
  late TtsService ttsService;
  late ActionExecutor actionExecutor;

  void start() {
    // TODO: wire up per PDR Section 9.8
  }
}
