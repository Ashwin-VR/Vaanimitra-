import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../models/v_intent.dart';
import '../../models/parsed_command.dart';
import '../../models/action_result.dart';
import '../wake_word/wake_word_service.dart';
import '../stt/stt_service.dart';
import '../stt/native_stt_service.dart';
import '../stt/language_detector.dart';
import '../llm/llm_service.dart';
import '../llm/rule_engine.dart';
import '../cache/cache_service.dart';
import '../analytics/analytics_service.dart';
import '../personalisation/personalisation_service.dart';
import '../../features/tts/tts_service.dart';
import 'package:vanimitra/features/actions/action_executor.dart';
import 'package:vanimitra/app/constants.dart';
import 'dialogue_state.dart';

class DialogueController extends ChangeNotifier {
  static final instance = DialogueController._();
  DialogueController._();

  // Services
  final WakeWordService _wakeWord = WakeWordService.instance;
  final SttService _stt = NativeSttService.instance;
  final LlmService _llm = LlmService.instance;
  final CacheService _cache = CacheService.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final PersonalisationService _personalisation = PersonalisationService.instance;
  final TtsService _tts = TtsService.instance;
  final ActionExecutor _executor = ActionExecutor.instance;

  // State
  DialogueState _state = DialogueState.idle;
  DialogueState get state => _state;

  String _transcript = '';
  String get transcript => _transcript;

  String _statusText = 'Tap mic to speak';
  String get statusText => _statusText;

  String? _lastIntent;
  String? get lastIntent => _lastIntent;

  int _clarificationCount = 0;

  // Selected language from UI chip (influences STT locale)
  String _preferredLanguage = 'en';
  String get preferredLanguage => _preferredLanguage;

  void setPreferredLanguage(String lang) {
    _preferredLanguage = lang;
    notifyListeners();
  }

  // ─── Initialization ───────────────────────────────────────────────────────
  void start() {
    _wakeWord.onWakeWordDetected = _onWakeWord;
    _setState(DialogueState.idle);
    _wakeWord.start(); // no-op stub, mic button is the trigger
  }

  // ─── Event Handlers ───────────────────────────────────────────────────────
  void _onWakeWord() {
    if (_state != DialogueState.idle) return;
    _wakeWord.stop();
    _tts.speakEarcon();
    _startListening();
  }

  Future<void> _startListening({bool isWakeWordTriggered = false}) async {
    if (isWakeWordTriggered) {
      MethodChannel('com.vanimitra.app/screenshot').invokeMethod('beep', {'type': 'start'});
    }
    
    _setState(DialogueState.listening);
    _setTranscript('');
    _statusText = 'Listening...';
    notifyListeners();

    if (!_stt.isAvailable) {
      _handleSttMissing();
      return;
    }

    // Map preferred language to STT locale.
    // Hindi and Tamil STT requires those voice packs installed on device.
    // en_IN is the most reliable fallback and still captures transliterated text.
    final localeMap = {'en': 'en_IN', 'hi': 'hi_IN', 'ta': 'ta_IN'};
    final localeId = localeMap[_preferredLanguage] ?? 'en_IN';

    // Increased pauseFor for better silence detection during typing
    final text = await _stt.listen(
      localeId: localeId, 
      listenFor: const Duration(seconds: 15),
    );

    if (text == null || text.trim().isEmpty) {
      _handleSilence();
    } else {
      await _process(text);
    }
  }

  // ─── Pipeline ─────────────────────────────────────────────────────────────
  Future<void> _process(String rawText) async {
    _setState(DialogueState.processing);
    _setTranscript(rawText);
    _statusText = 'Processing...';
    notifyListeners();

    final startTime = DateTime.now();

    // Detect language from script — overrides STT locale for downstream use
    final language = LanguageDetector.detect(rawText);

    // 1. Rule Engine — fast path (<50ms)
    var cmd = RuleEngine.quickParse(rawText, language);

    // 2. LLM — slow path (3–6s), only if rule engine returned null/unknown
    // LLM is currently stubbed (returns UNKNOWN) — rule engine handles all
    if (cmd == null || cmd.intent == VIntent.unknown) {
      final cacheCtx = await _cache.getContextString();
      cmd = await _llm.infer(rawText, cacheCtx);
    }

    final latency = DateTime.now().difference(startTime).inMilliseconds;

    if (cmd.intent == VIntent.unknown) {
      _handleUnknown(rawText, language);
    } else {
      await _execute(cmd, latency.toDouble());
    }
  }

  Future<void> _execute(ParsedCommand cmd, double latencyMs) async {
    _setState(DialogueState.executing);
    _statusText = cmd.intent.toJsonKey();
    _lastIntent = cmd.intent.toJsonKey();
    notifyListeners();

    final result = await _executor.processIntent(cmd);

    if (result.needsClarification) {
      _setState(DialogueState.clarifying);
      final optionsStr = result.options?.join(', ') ?? '';
      _statusText = 'Which one? $optionsStr';
      notifyListeners();
      await _tts.speakDynamic('I found multiple contacts: $optionsStr. Which one should I call?', cmd.language);
      // In a real app we'd wait for a follow-up STT restricted to these names.
      // For now, let's keep it simple: the user will tap mic and say the name again.
      _clarificationCount = 0;
      await _onComplete();
      return;
    }
    await _cache.log(
      cmd.rawTranscript,
      cmd.intent,
      cmd.params,
      result.success,
      cmd.source,
      latencyMs.toInt(),
      cmd.language,
    );
    _analytics.recordCommand(
      intent: cmd.intent,
      latencyMs: latencyMs,
      success: result.success,
      source: cmd.source,
    );

    _clarificationCount = 0;
    await _onComplete();
  }

  // ─── Error / Silence Handling ─────────────────────────────────────────────
  void _handleSilence() async {
    _clarificationCount++;
    if (_clarificationCount >= VConstants.maxClarificationAttempts) {
      _onDoubleMiss();
    } else {
      _setState(DialogueState.clarifying);
      _statusText = "Didn't catch that...";
      notifyListeners();
      // Clarify in detected/preferred language
      final lang = _preferredLanguage;
      final msgs = {
        'en': "Sorry, I didn't catch that. Please try again.",
        'hi': 'माफ करना, फिर से बोलें।',
        'ta': 'மன்னிக்கவும், மீண்டும் சொல்லுங்கள்.',
      };
      await _tts.speakDynamic(msgs[lang] ?? msgs['en']!, lang);
      _startListening();
    }
  }

  void _handleUnknown(String rawText, String language) async {
    _clarificationCount++;
    if (_clarificationCount >= VConstants.maxClarificationAttempts) {
      _onDoubleMiss();
    } else {
      _setState(DialogueState.clarifying);
      _statusText = 'Try again differently';
      notifyListeners();
      final msgs = {
        'en': "I'm not sure I understood. Try saying it differently.",
        'hi': 'समझ नहीं आया। दूसरे तरीके से बोलें।',
        'ta': 'புரியவில்லை. வேறு விதமாக சொல்லுங்கள்.',
      };
      await _tts.speakDynamic(msgs[language] ?? msgs['en']!, language);
      _startListening();
    }
  }

  void _onDoubleMiss() async {
    _analytics.recordDoubleMiss();
    _clarificationCount = 0;
    _statusText = 'Tap mic to try again';
    notifyListeners();
    final lang = _preferredLanguage;
    final msgs = {
      'en': 'Unable to understand. Please try again.',
      'hi': 'समझ नहीं पाई। फिर कोशिश करें।',
      'ta': 'புரியவில்லை. மீண்டும் முயற்சி செய்யுங்கள்.',
    };
    await _tts.speakDynamic(msgs[lang] ?? msgs['en']!, lang);
    await _onComplete();
  }

  Future<void> _onComplete() async {
    await Future.delayed(
        const Duration(milliseconds: VConstants.postExecutionResumeDelayMs));
    _setState(DialogueState.idle);
    _statusText = 'Tap mic to speak';
    notifyListeners();
    _wakeWord.start(); // no-op stub
  }

  // ─── UI Helpers ──────────────────────────────────────────────────────────
  void _setState(DialogueState s) {
    _state = s;
    notifyListeners();
  }

  void _setTranscript(String t) {
    _transcript = t;
    notifyListeners();
  }

  // Manual trigger from UI mic button - Toggle Logic
  void onMicButtonTapped() {
    if (_state == DialogueState.idle) {
      _startListening();
    } else if (_state == DialogueState.listening) {
      // Transition to processing state immediately
      // The awaited _stt.listen in _startListening will return with partial text
      _stt.stop();
    } else {
      // Cancel mid-processing — return to idle
      _stt.stop();
      _setState(DialogueState.idle);
      _statusText = 'Tap mic to speak';
      notifyListeners();
    }
  }
  void _handleSttMissing() async {
    _statusText = 'Model missing';
    notifyListeners();
    final lang = _preferredLanguage;
    final msgs = {
      'en': 'Speech recognition model is missing. Please connect to internet to download it.',
      'hi': 'भाषण पहचान मॉडल मौजूद नहीं है। कृपया इसे डाउनलोड करने के लिए इंटरनेट से जुड़ें।',
      'ta': 'பேச்சு அங்கீகார மாதிரி இல்லை. அதைப் பதிவிறக்க இணையத்தில் இணையவும்.',
    };
    await _tts.speakDynamic(msgs[lang] ?? msgs['en']!, lang);
    _setState(DialogueState.idle);
  }
}
