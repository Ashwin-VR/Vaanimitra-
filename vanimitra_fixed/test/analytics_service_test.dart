import 'package:flutter_test/flutter_test.dart';
import 'package:vanimitra/core/analytics/analytics_service.dart';
import 'package:vanimitra/models/v_intent.dart';

void main() {
  test('AnalyticsService report math', () {
    final service = AnalyticsService.instance;

    // Record some commands
    service.recordCommand(
      intent: VIntent.flashlightOn,
      latencyMs: 100,
      success: true,
      source: 'rule',
    );
    service.recordCommand(
      intent: VIntent.volumeUp,
      latencyMs: 3000,
      success: true,
      source: 'llm',
    );
    service.recordCommand(
      intent: VIntent.unknown,
      latencyMs: 50,
      success: false,
      source: 'rule',
    );
    service.recordDoubleMiss();

    final report = service.getReport();

    expect(report.totalCommands, 3);
    expect(report.accuracyPct, closeTo(66.6, 0.1));
    expect(report.ruleEnginePct, closeTo(66.6, 0.1));
    expect(report.llmPct, closeTo(33.3, 0.1));
    
    // totalEvents = 3 + 1 = 4. doubleMisses = 1. doubleMissPct = 1/4 = 25%
    expect(report.doubleMissPct, 25.0);
    
    expect(report.avgLatencyMs, (100 + 3000 + 50) / 3);
    expect(report.p95LatencyMs, 3000); // with 3 elements, index 2
    expect(report.topIntents.first.key, 'FLASHLIGHT_ON');
  });
}
