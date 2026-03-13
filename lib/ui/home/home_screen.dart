// lib/ui/home/home_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:vanimitra/core/personalisation/personalisation_service.dart';
import 'package:vanimitra/ui/dialogs/analytics_dialog.dart';
import 'package:vanimitra/ui/dialogs/offline_setup_dialog.dart';
import 'package:vanimitra/core/stt/native_stt_service.dart';
import 'package:vanimitra/ui/dialogs/mapping_proposal_sheet.dart';
import 'package:vanimitra/ui/home/home_controller.dart';
import 'package:vanimitra/core/dialogue/dialogue_state.dart';
import 'package:vanimitra/ui/home/widgets/intent_box.dart';
import 'package:vanimitra/ui/home/widgets/language_chip_row.dart';
import 'package:vanimitra/ui/home/widgets/mic_button.dart';
import 'package:vanimitra/ui/home/widgets/model_warning_banner.dart';
import 'package:vanimitra/ui/home/widgets/status_text.dart';
import 'package:vanimitra/ui/home/widgets/transcript_box.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Triple-tap counter ────────────────────────────────────────────────────
  int _tapCount = 0;
  Timer? _tapResetTimer;

  // ── Proposal stream subscription ──────────────────────────────────────────
  StreamSubscription<MappingProposal>? _proposalSub;

  @override
  void initState() {
    super.initState();
    // Check for offline STT packs after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOfflineSTT());
    _proposalSub = PersonalisationService.instance.proposalStream.listen(
      (proposal) {
        if (!mounted) return;
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MappingProposalSheet(proposal: proposal),
        );
      },
    );
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    _proposalSub?.cancel();
    super.dispose();
  }

  Future<void> _checkOfflineSTT() async {
    if (!mounted) return;
    final available = await NativeSttService.instance.availableLocales();
    // Check which required locales are missing
    final required = ['en_IN', 'hi_IN', 'ta_IN'];
    final missing = required.where((loc) {
      final langCode = loc.split('_')[0];
      return !available.any((a) => a.startsWith(langCode));
    }).toList();
    // Only show if Hindi or Tamil is missing (English usually present)
    final importantMissing = missing.where((l) => l != 'en_IN').toList();
    if (importantMissing.isNotEmpty && mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => OfflineSetupDialog(missingLocales: importantMissing),
      );
    }
  }

  void _onTitleTap() {
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(const Duration(milliseconds: 600), () {
      _tapCount = 0;
    });

    if (_tapCount >= 3) {
      _tapCount = 0;
      _tapResetTimer?.cancel();
      showDialog<void>(
        context: context,
        builder: (_) => const AnalyticsDialog(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // App title — triple-tap → analytics
            GestureDetector(
              onTap: _onTitleTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'वाणीमित्र',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '·',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.30),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'VANIMITRA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Language chips
            const LanguageChipRow(),

            const Spacer(),

            // Transcript (only when non-empty)
            const TranscriptBox(),

            const SizedBox(height: 12),

            // Intent JSON (only when non-empty)
            const IntentBox(),

            const Spacer(),

            // Model not ready warning
            const ModelWarningBanner(),

            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Floating Listening Overlay
                Consumer<HomeController>(
                  builder: (context, controller, _) {
                    if (controller.dialogueState == DialogueState.listening) {
                      return Positioned(
                        top: -60,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                          child: const Text(
                            'Listening...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                
                const MicButton(),
              ],
            ),

            const SizedBox(height: 16),

            // Status text
            const StatusText(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
