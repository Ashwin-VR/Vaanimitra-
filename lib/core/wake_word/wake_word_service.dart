import 'dart:async';

class WakeWordService {
  static final instance = WakeWordService._internal();
  WakeWordService._internal();

  Function()? onWakeWordDetected;

  Future<void> start() async {
    // Wake word disabled as per user request
  }

  Future<void> stop() async {
    // No-op
  }

  Future<void> dispose() async {
    // No-op
  }
}

