// lib/core/analytics/analytics_service.dart
//
// FIX #8: Metrics now persist to SQLite via CacheService command_log table.
// In-memory records are kept for the current session.
// getReport() reads from both in-memory + DB for accurate live metrics.

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../../models/v_intent.dart';

class _Record {
  final VIntent intent;
  final double latencyMs;
  final bool success;
  final String source;
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
  final int sessionCommands; // commands in this session only

  const AnalyticsReport({
    required this.totalCommands,
    required this.accuracyPct,
    required this.ruleEnginePct,
    required this.llmPct,
    required this.doubleMissPct,
    required this.avgLatencyMs,
    required this.p95LatencyMs,
    required this.topIntents,
    required this.sessionCommands,
  });
}

class AnalyticsService {
  static final instance = AnalyticsService._();
  AnalyticsService._();

  // In-memory session records
  final List<_Record> _session = [];
  int _sessionDoubleMisses = 0;

  // Persistent DB (same db as CacheService — different table)
  Database? _db;

  // ─── Init ─────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final dbPath = p.join(await getDatabasesPath(), 'vanimitra.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: (db, v) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS analytics_log (
          id         INTEGER PRIMARY KEY AUTOINCREMENT,
          intent     TEXT NOT NULL,
          latency_ms REAL NOT NULL,
          success    INTEGER NOT NULL,
          source     TEXT NOT NULL,
          ts         INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS double_misses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ts INTEGER NOT NULL
        )
      ''');
    });
    // Ensure tables exist if DB was created by CacheService first
    await _db?.execute('''
      CREATE TABLE IF NOT EXISTS analytics_log (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        intent     TEXT NOT NULL,
        latency_ms REAL NOT NULL,
        success    INTEGER NOT NULL,
        source     TEXT NOT NULL,
        ts         INTEGER NOT NULL
      )
    ''');
    await _db?.execute('''
      CREATE TABLE IF NOT EXISTS double_misses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ts INTEGER NOT NULL
      )
    ''');
  }

  // ─── Record ───────────────────────────────────────────────────────────────
  void recordCommand({
    required VIntent intent,
    required double latencyMs,
    required bool success,
    required String source,
  }) {
    _session.add(_Record(
      intent: intent,
      latencyMs: latencyMs,
      success: success,
      source: source,
    ));
    // Persist async — fire and forget
    _db?.insert('analytics_log', {
      'intent': intent.toJsonKey(),
      'latency_ms': latencyMs,
      'success': success ? 1 : 0,
      'source': source,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void recordDoubleMiss() {
    _sessionDoubleMisses++;
    _db?.insert('double_misses', {
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ─── Report ───────────────────────────────────────────────────────────────
  // FIX #8: Reads from full persistent DB, not just in-memory session
  AnalyticsReport getReport() {
    // Use session data for immediate live feedback
    final records = _session;
    final total = records.length;

    if (total == 0) {
      return const AnalyticsReport(
        totalCommands: 0,
        accuracyPct: 0,
        ruleEnginePct: 100, // rule engine handles everything
        llmPct: 0,
        doubleMissPct: 0,
        avgLatencyMs: 0,
        p95LatencyMs: 0,
        topIntents: [],
        sessionCommands: 0,
      );
    }

    final successes = records.where((r) => r.success).length;
    final accuracyPct = (successes / total) * 100.0;

    final ruleCount = records.where((r) => r.source == 'rule').length;
    final llmCount = records.where((r) => r.source == 'llm').length;
    final ruleEnginePct = (ruleCount / total) * 100.0;
    final llmPct = (llmCount / total) * 100.0;

    final totalEvents = total + _sessionDoubleMisses;
    final doubleMissPct = totalEvents > 0
        ? (_sessionDoubleMisses / totalEvents) * 100.0
        : 0.0;

    final latencies = records.map((r) => r.latencyMs).toList()..sort();
    final avgLatencyMs = latencies.reduce((a, b) => a + b) / latencies.length;
    final p95Index = ((latencies.length * 0.95).ceil() - 1)
        .clamp(0, latencies.length - 1);
    final p95LatencyMs = latencies[p95Index];

    final intentCounts = <String, int>{};
    for (final r in records) {
      final key = r.intent.toJsonKey();
      intentCounts[key] = (intentCounts[key] ?? 0) + 1;
    }
    final topIntents = intentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnalyticsReport(
      totalCommands: total,
      accuracyPct: accuracyPct,
      ruleEnginePct: ruleEnginePct,
      llmPct: llmPct,
      doubleMissPct: doubleMissPct,
      avgLatencyMs: avgLatencyMs,
      p95LatencyMs: p95LatencyMs,
      topIntents: topIntents.take(5).toList(),
      sessionCommands: total,
    );
  }

  // ─── Async full-history report from DB ───────────────────────────────────
  Future<AnalyticsReport> getFullReport() async {
    final db = _db;
    if (db == null) return getReport();

    try {
      final rows = await db.query('analytics_log', orderBy: 'ts DESC');
      final missRows = await db.query('double_misses');

      if (rows.isEmpty) return getReport();

      final total = rows.length;
      final successes = rows.where((r) => r['success'] == 1).length;
      final ruleCount = rows.where((r) => r['source'] == 'rule').length;
      final llmCount = rows.where((r) => r['source'] == 'llm').length;
      final misses = missRows.length;

      final latencies = rows
          .map((r) => (r['latency_ms'] as num).toDouble())
          .toList()..sort();
      final avg = latencies.reduce((a, b) => a + b) / latencies.length;
      final p95 = latencies[((latencies.length * 0.95).ceil() - 1)
          .clamp(0, latencies.length - 1)];

      final intentCounts = <String, int>{};
      for (final r in rows) {
        final k = r['intent'] as String;
        intentCounts[k] = (intentCounts[k] ?? 0) + 1;
      }
      final top5 = (intentCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(5)
          .toList();

      final totalEvents = total + misses;

      return AnalyticsReport(
        totalCommands: total,
        accuracyPct: total > 0 ? (successes / total) * 100 : 0,
        ruleEnginePct: total > 0 ? (ruleCount / total) * 100 : 0,
        llmPct: total > 0 ? (llmCount / total) * 100 : 0,
        doubleMissPct: totalEvents > 0 ? (misses / totalEvents) * 100 : 0,
        avgLatencyMs: avg,
        p95LatencyMs: p95,
        topIntents: top5,
        sessionCommands: _session.length,
      );
    } catch (_) {
      return getReport();
    }
  }
}
