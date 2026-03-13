// DEV 3 — implement per PDR Section 12.2
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_controller.dart';
import 'widgets/mic_button.dart';
import 'widgets/transcript_box.dart';
import 'widgets/intent_box.dart';
import 'widgets/language_chip_row.dart';
import 'widgets/status_text.dart';
import 'widgets/model_warning_banner.dart';
import '../dialogs/analytics_dialog.dart';
import '../dialogs/mapping_proposal_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeController(),
      child: Consumer<HomeController>(
        builder: (context, ctrl, _) => Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {}, // TODO: triple-tap counter → AnalyticsDialog
                  child: const Text('वाणीमित्र', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ),
                LanguageChipRow(controller: ctrl),
                const Spacer(),
                if (ctrl.transcript.isNotEmpty) TranscriptBox(text: ctrl.transcript),
                if (ctrl.intentJson.isNotEmpty) IntentBox(json: ctrl.intentJson),
                const Spacer(),
                if (!ctrl.llmReady) const ModelWarningBanner(),
                MicButton(controller: ctrl),
                StatusText(text: ctrl.statusText),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
