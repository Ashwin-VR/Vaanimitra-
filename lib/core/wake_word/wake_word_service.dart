// DEV 2 — implement per PDR Section 9.2
class WakeWordService {
  static final instance = WakeWordService._internal();
  WakeWordService._internal();
  Function()? onWakeWordDetected;
  Future<void> start() async {}
  Future<void> stop() async {}
  Future<void> dispose() async {}
}
