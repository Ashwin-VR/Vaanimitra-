import 'package:permission_handler/permission_handler.dart';
import '../cache/cache_service.dart';
import '../llm/llm_service.dart';
import '../stt/native_stt_service.dart';
import '../dialogue/dialogue_controller.dart';
import '../../features/tts/tts_service.dart';
import '../../features/actions/action_executor.dart';

class AppInitializer {
  static final instance = AppInitializer._();
  AppInitializer._();

  Future<void> initialize() async {
    // 1. Request all permissions upfront
    await [
      Permission.microphone,
      Permission.contacts,
      Permission.phone,
      Permission.camera,
    ].request();

    // 2. Open SQLite DB
    await CacheService.instance.init();

    // 3. Import contacts into cache (one-time, skipped if already done)
    await CacheService.instance.importContactsIfNeeded();

    // 4. LLM: check for model file (will be false — no GGUF yet)
    await LlmService.instance.findModel();

    // 5. STT: initialize speech_to_text engine
    await NativeSttService.instance.initialize();

    // 6. LLM warmup — skipped automatically since isReady=false
    if (LlmService.instance.isReady) {
      await LlmService.instance.warmUp();
    }

    // 7. TTS: configure flutter_tts
    await TtsService.instance.init();

    // 8. ActionExecutor: inject TTS dependency
    ActionExecutor.instance.init(TtsService.instance);

    // 9. DialogueController: wire services, start wake word stub
    DialogueController.instance.start();

    // 10. Evict stale cache entries
    await CacheService.instance.evict();
  }
}
