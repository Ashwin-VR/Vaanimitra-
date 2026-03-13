// STUB — lib/core/analytics/analytics_service.dart
// Owner: Dev 2. Replace with production implementation.
// Returns zeroed report until Dev 2 wires SQLite.

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
    required this.totalCommands,
    required this.accuracyPct,
    required this.ruleEnginePct,
    required this.llmPct,
    required this.doubleMissPct,
    required this.avgLatencyMs,
    required this.p95LatencyMs,
    required this.topIntents,
  });
}

class AnalyticsService {
  static final instance = AnalyticsService._internal();
  AnalyticsService._internal();

  /// STUB: returns zeroed data until Dev 2 implements SQLite logging.
  AnalyticsReport getReport() {
    return const AnalyticsReport(
      totalCommands: 0,
      accuracyPct: 0.0,
      ruleEnginePct: 0.0,
      llmPct: 0.0,
      doubleMissPct: 0.0,
      avgLatencyMs: 0.0,
      p95LatencyMs: 0.0,
      topIntents: [],
    );
  }
}
