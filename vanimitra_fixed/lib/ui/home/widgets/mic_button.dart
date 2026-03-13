// lib/ui/home/widgets/mic_button.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:vanimitra/core/dialogue/dialogue_state.dart';
import 'package:vanimitra/ui/home/home_controller.dart';

class MicButton extends StatefulWidget {
  const MicButton({super.key});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _updateAnimation(DialogueState state) {
    final shouldPulse =
        state == DialogueState.listening || state == DialogueState.processing;
    if (shouldPulse && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!shouldPulse && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.animateTo(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        _updateAnimation(controller.dialogueState);

        final config = _resolveConfig(controller.dialogueState, controller.llmReady);

        return ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              controller.onMicButtonTapped();
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: config.color,
                boxShadow: [
                  BoxShadow(
                    color: config.color.withOpacity(0.5),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                config.icon,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }

  _MicConfig _resolveConfig(DialogueState state, bool llmReady) {
    switch (state) {
      case DialogueState.listening:
        return _MicConfig(
          color: const Color(0xFFB71C1C),
          icon: Icons.stop_rounded,
        );
      case DialogueState.processing:
        return _MicConfig(
          color: const Color(0xFFE65100),
          icon: Icons.hourglass_bottom_rounded,
        );
      case DialogueState.clarifying:
        return _MicConfig(
          color: const Color(0xFFF57F17),
          icon: Icons.help_outline_rounded,
        );
      case DialogueState.executing:
        return _MicConfig(
          color: const Color(0xFF1B5E20),
          icon: Icons.check_circle_outline_rounded,
        );
      case DialogueState.confirming:
        return _MicConfig(
          color: const Color(0xFF4A148C),
          icon: Icons.check_circle_outline_rounded,
        );
      case DialogueState.idle:
      default:
        // Rule engine works without LLM — mic is always enabled.
        // Only show a subtle difference: deep blue (full) vs indigo (rule-only mode)
        return _MicConfig(
          color: llmReady ? const Color(0xFF1A237E) : const Color(0xFF283593),
          icon: Icons.mic_rounded,
        );
    }
  }
}

class _MicConfig {
  final Color color;
  final IconData icon;
  const _MicConfig({required this.color, required this.icon});
}
