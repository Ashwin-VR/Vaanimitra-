import '../../models/v_intent.dart';

class _Record {
  final VIntent intent;
  final double latencyMs;
  final bool success;
  final String source; // 'rule' | 'llm'
  const _Record({
    required this.intent,
    required this.latencyMs,
    required this.success,
    required this.source,
  });
}

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
  static final instance = AnalyticsService._();
  AnalyticsService._();

  final List<_Record> _records = [];
  int _doubleMisses = 0;

  void recordCommand({
    required VIntent intent,
    required double latencyMs,
    required bool success,
    required String source,
  }) {
    _records.add(_Record(
      intent: intent,
      latencyMs: latencyMs,
      success: success,
      source: source,
    ));
  }

  void recordDoubleMiss() {
    _doubleMisses++;
  }

  AnalyticsReport getReport() {
    final total = _records.length;
    if (total == 0) {
      return const AnalyticsReport(
        totalCommands: 0,
        accuracyPct: 0,
        ruleEnginePct: 0,
        llmPct: 0,
        doubleMissPct: 0,
        avgLatencyMs: 0,
        p95LatencyMs: 0,
        topIntents: [],
      );
    }

    // Accuracy
    final successes = _records.where((r) => r.success).length;
    final accuracyPct = (successes / total) * 100.0;

    // Source split
    final ruleCount = _records.where((r) => r.source == 'rule').length;
    final llmCount = _records.where((r) => r.source == 'llm').length;
    final ruleEnginePct = (ruleCount / total) * 100.0;
    final llmPct = (llmCount / total) * 100.0;

    // Double-miss rate (per total events including misses)
    final totalEvents = total + _doubleMisses;
    final doubleMissPct =
        totalEvents > 0 ? (_doubleMisses / totalEvents) * 100.0 : 0.0;

    // Latency
    final latencies = _records.map((r) => r.latencyMs).toList()..sort();
    final avgLatencyMs =
        latencies.reduce((a, b) => a + b) / latencies.length;
    final p95Index = ((latencies.length * 0.95).ceil() - 1)
        .clamp(0, latencies.length - 1);
    final p95LatencyMs = latencies[p95Index];

    // Top intents
    final intentCounts = <String, int>{};
    for (final r in _records) {
      final key = r.intent.toJsonKey();
      intentCounts[key] = (intentCounts[key] ?? 0) + 1;
    }
    final topIntents = intentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topIntents.take(5).toList();

    return AnalyticsReport(
      totalCommands: total,
      accuracyPct: accuracyPct,
      ruleEnginePct: ruleEnginePct,
      llmPct: llmPct,
      doubleMissPct: doubleMissPct,
      avgLatencyMs: avgLatencyMs,
      p95LatencyMs: p95LatencyMs,
      topIntents: top5,
    );
  }
}
