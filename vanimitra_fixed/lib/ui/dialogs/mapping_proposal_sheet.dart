// lib/ui/dialogs/mapping_proposal_sheet.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vanimitra/core/cache/cache_service.dart';
import 'package:vanimitra/core/personalisation/personalisation_service.dart';

class MappingProposalSheet extends StatefulWidget {
  final MappingProposal proposal;

  const MappingProposalSheet({super.key, required this.proposal});

  @override
  State<MappingProposalSheet> createState() => _MappingProposalSheetState();
}

class _MappingProposalSheetState extends State<MappingProposalSheet> {
  int _countdown = 6;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).pop(false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onNo() {
    _timer?.cancel();
    Navigator.of(context).pop(false);
  }

  Future<void> _onYes() async {
    _timer?.cancel();
    await CacheService.instance
        .confirm(widget.proposal.trigger, widget.proposal.type);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.30),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.memory_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Remember this?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Countdown circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.30),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_countdown',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Proposal text ─────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, height: 1.5),
              children: [
                const TextSpan(
                  text: '"',
                  style: TextStyle(color: Colors.white70),
                ),
                TextSpan(
                  text: widget.proposal.trigger,
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const TextSpan(
                  text: '" means "',
                  style: TextStyle(color: Colors.white70),
                ),
                TextSpan(
                  text: widget.proposal.resolved,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const TextSpan(
                  text: '"?',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _onNo,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.24),
                    ),
                    foregroundColor: Colors.white.withOpacity(0.60),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('No thanks'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onYes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Yes, remember',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
