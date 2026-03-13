// DEV 2 — implement per PDR Section 9.3 (uses speech_to_text)
import 'stt_service.dart';
class NativeSttService extends SttService {
  @override Future<bool> initialize() async => false;
  @override Future<String?> listen({required String localeId, Duration listenFor = const Duration(seconds: 8)}) async => null;
  @override Future<void> stop() async {}
  @override bool get isListening => false;
  @override bool get isAvailable => false;
}
