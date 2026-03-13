// lib/ui/home/widgets/transcript_box.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanimitra/ui/home/home_controller.dart';

class TranscriptBox extends StatelessWidget {
  const TranscriptBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, _) {
        final transcript = controller.transcript;
        if (transcript.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HEARD',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    transcript,
                    key: ValueKey(transcript),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
