// DEV 2 — implement per PDR Section 9.9
import '../../models/v_intent.dart';

class AnalyticsReport {
  final int totalCommands;
  final double accuracyPct;
  final double ruleEnginePct;
  final double llmPct;
  final double doubleMissPct;
  final double avgLatencyMs;
  final double p95LatencyMs;
  final List<MapEntry<String, int>> topIntents;
  const AnalyticsReport({
    required this.totalCommands, required this.accuracyPct,
    required this.ruleEnginePct, required this.llmPct,
    required this.doubleMissPct, required this.avgLatencyMs,
    required this.p95LatencyMs, required this.topIntents,
  });
}

class AnalyticsService {
  static final instance = AnalyticsService._();
  AnalyticsService._();
  void recordCommand({required VIntent intent, required double latencyMs, required bool success, required String source}) {}
  void recordDoubleMiss() {}
  AnalyticsReport getReport() => const AnalyticsReport(
    totalCommands: 0, accuracyPct: 0, ruleEnginePct: 0, llmPct: 0,
    doubleMissPct: 0, avgLatencyMs: 0, p95LatencyMs: 0, topIntents: [],
  );
}
