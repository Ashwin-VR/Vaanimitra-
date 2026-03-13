// lib/ui/home/widgets/status_text.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanimitra/core/dialogue/dialogue_state.dart';
import 'package:vanimitra/ui/home/home_controller.dart';

class StatusText extends StatelessWidget {
  const StatusText({super.key});

  Color _colorForState(DialogueState state, bool llmReady) {
    switch (state) {
      case DialogueState.listening:
        return const Color(0xFFB71C1C);   // matches MicButton
      case DialogueState.processing:
        return const Color(0xFFE65100);   // matches MicButton
      case DialogueState.clarifying:
        return const Color(0xFFF57F17);   // matches MicButton
      case DialogueState.executing:
        return const Color(0xFF1B5E20);   // matches MicButton (deep green)
      case DialogueState.confirming:
        return const Color(0xFF4A148C);   // matches MicButton (deep purple)
      case DialogueState.idle:
      default:
        return Colors.white.withOpacity(0.54);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final color =
            _colorForState(controller.dialogueState, controller.llmReady);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            controller.statusText,
            key: ValueKey(controller.statusText),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
