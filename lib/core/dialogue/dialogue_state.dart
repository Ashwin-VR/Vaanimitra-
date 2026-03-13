// DEV 2 — per PDR Section 9.7
import 'dart:async';
enum DialogueState { idle, listening, processing, clarifying, confirming, executing }

class DialogueContext {
  DialogueState state;
  String? pendingIntent;
  Map<String, dynamic> pendingParams;
  String? missingParam;
  int clarificationAttempts;
  int consecutiveMisses;
  Timer? clarificationTimer;
  String language;

  DialogueContext({
    this.state = DialogueState.idle,
    this.pendingIntent,
    Map<String, dynamic>? pendingParams,
    this.missingParam,
    this.clarificationAttempts = 0,
    this.consecutiveMisses = 0,
    this.clarificationTimer,
    this.language = 'en',
  }) : pendingParams = pendingParams ?? {};
}
