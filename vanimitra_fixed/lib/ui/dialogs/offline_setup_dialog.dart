// lib/ui/dialogs/offline_setup_dialog.dart
//
// FIX #1 + #6: Shown at startup if device does not have the required
// offline speech recognition pack. Guides user to install it.
// Once installed, STT works fully offline with much better WER.

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

class OfflineSetupDialog extends StatelessWidget {
  final List<String> missingLocales; // e.g. ['hi_IN', 'ta_IN']

  const OfflineSetupDialog({super.key, required this.missingLocales});

  static const Map<String, String> _localeNames = {
    'en_IN': 'English (India)',
    'hi_IN': 'Hindi (हिंदी)',
    'ta_IN': 'Tamil (தமிழ்)',
  };

  Future<void> _openSpeechSettings() async {
    try {
      // Opens the text-to-speech/voice input settings where offline packs live
      await AndroidIntent(
        action: 'com.android.settings.TTS_SETTINGS',
      ).launch();
    } catch (_) {
      try {
        await AndroidIntent(action: 'android.settings.SETTINGS').launch();
      } catch (_) {}
    }
  }

  Future<void> _openLanguageSettings() async {
    try {
      await AndroidIntent(
        action: 'android.settings.LOCALE_SETTINGS',
      ).launch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.orangeAccent, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Offline Speech Setup Required',
                    style: TextStyle(color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'For fully offline voice recognition, you need to download speech packs for:',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
            ),

            const SizedBox(height: 12),

            ...missingLocales.map((loc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.orangeAccent),
                  ),
                  const SizedBox(width: 10),
                  Text(_localeNames[loc] ?? loc,
                    style: const TextStyle(color: Colors.white, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                ],
              ),
            )),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to install:',
                    style: TextStyle(color: Colors.white.withOpacity(0.5),
                        fontSize: 11, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _Step(n: '1', text: 'Settings → General Management → Language'),
                  _Step(n: '2', text: 'Add Hindi / Tamil language'),
                  _Step(n: '3', text: 'Settings → Apps → default apps → Voice input → Download offline speech'),
                  _Step(n: '4', text: 'Restart Vanimitra'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      foregroundColor: Colors.white54,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Skip for now'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _openLanguageSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Open Settings',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String n, text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.orangeAccent.withOpacity(0.2),
            ),
            alignment: Alignment.center,
            child: Text(n,
              style: const TextStyle(color: Colors.orangeAccent,
                  fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
