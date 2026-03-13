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
    final stopwatch = Stopwatch()..start();

    // 1. Request permissions (Record Audio, Contacts, Phone, Camera)
    await [
      Permission.microphone,
      Permission.contacts,
      Permission.phone,
      Permission.camera,
    ].request();

    // 2. CacheService.init() — open SQLite DB
    await CacheService.instance.init();

    // 3. CacheService.importContactsIfNeeded() — one-time contact import
    await CacheService.instance.importContactsIfNeeded();

    // 4. LlmService.findModel() — locate GGUF file
    await LlmService.instance.findModel();

    // 5. Initialise NativeSttService
    await NativeSttService.instance.initialize();

    // 6. LlmService.warmUp() — load model into RAM (if found)
    if (LlmService.instance.isReady) {
      await LlmService.instance.warmUp();
    }

    // 7. TtsService.init() (Dev 3 owns implementation)
    await TtsService.instance.init();

    // 8. ActionExecutor.init(ttsService) (Dev 3 owns implementation)
    await ActionExecutor.instance.init(TtsService.instance);

    // 9. DialogueController.start() — wire all services + start wake word
    DialogueController.instance.start();

    // 10. Final setup logic (e.g. log boot time)
    stopwatch.stop();
    // print('VaaniMitra initialized in ${stopwatch.elapsedMilliseconds}ms');

    // 11. Evict old cache entries to maintain target size
    await CacheService.instance.evict();
  }
}
