// lib/ui/dialogs/analytics_dialog.dart
// FIX #8: Shows real live metrics. Uses async getFullReport() from DB.

import 'package:flutter/material.dart';
import 'package:vanimitra/core/analytics/analytics_service.dart';

class AnalyticsDialog extends StatefulWidget {
  const AnalyticsDialog({super.key});

  @override
  State<AnalyticsDialog> createState() => _AnalyticsDialogState();
}

class _AnalyticsDialogState extends State<AnalyticsDialog> {
  AnalyticsReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await AnalyticsService.instance.getFullReport();
    if (mounted) setState(() { _report = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.2), width: 1.5),
        ),
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(color: Colors.greenAccent)),
              )
            : _buildContent(_report!),
      ),
    );
  }

  Widget _buildContent(AnalyticsReport report) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              const Text('LIVE TELEMETRY',
                style: TextStyle(color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w700, letterSpacing: 2)),
              const Spacer(),
              if (report.sessionCommands > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${report.sessionCommands} this session',
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10)),
                ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(children: [
                _Tile(label: 'TOTAL COMMANDS', value: '${report.totalCommands}'),
                const SizedBox(width: 10),
                _Tile(label: 'ACCURACY',
                  value: report.totalCommands > 0
                    ? '${report.accuracyPct.toStringAsFixed(1)}%'
                    : '—'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _Tile(label: 'AVG LATENCY',
                  value: report.totalCommands > 0
                    ? '${(report.avgLatencyMs / 1000).toStringAsFixed(2)}s'
                    : '—'),
                const SizedBox(width: 10),
                _Tile(label: 'P95 LATENCY',
                  value: report.totalCommands > 0
                    ? '${(report.p95LatencyMs / 1000).toStringAsFixed(2)}s'
                    : '—'),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _Tile(label: 'RULE ENGINE',
                  value: report.totalCommands > 0
                    ? '${report.ruleEnginePct.toStringAsFixed(0)}%'
                    : '100%'),
                const SizedBox(width: 10),
                _Tile(label: 'DOUBLE MISS',
                  value: '${report.doubleMissPct.toStringAsFixed(1)}%'),
              ]),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Divider(color: Colors.white12, height: 1),
        ),

        if (report.topIntents.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOP INTENTS',
                  style: TextStyle(color: Colors.white.withOpacity(0.38),
                      fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                ...report.topIntents.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key,
                        style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 12)),
                      Text('${entry.value}',
                        style: const TextStyle(color: Colors.greenAccent,
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Divider(color: Colors.white12, height: 1),
          ),
        ],

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              const Icon(Icons.attach_money_rounded, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 6),
              Text('Operational cost: ',
                style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 13)),
              const Text('\$0.00',
                style: TextStyle(color: Colors.greenAccent, fontSize: 14,
                    fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label, value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF232323),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: TextStyle(color: Colors.white.withOpacity(0.38),
                  fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(value,
              style: const TextStyle(color: Colors.greenAccent,
                  fontSize: 20, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
