// DEV 2 — abstract interface per PDR Section 9.3
abstract class SttService {
  Future<bool> initialize();
  Future<String?> listen({required String localeId, Duration listenFor = const Duration(seconds: 8)});
  Future<void> stop();
  bool get isListening;
  bool get isAvailable;
}
