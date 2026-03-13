// STUB — lib/main.dart
// Owner: Lead. Replace with production implementation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vanimitra/app/app.dart';
import 'package:vanimitra/features/actions/action_executor.dart';
import 'package:vanimitra/features/tts/tts_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait per typical voice assistant requirements
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // STUB: Initialize Dev 3 singletons so compilation & testing works
  await TtsService.instance.init();
  ActionExecutor.instance.init(TtsService.instance);

  runApp(const VanimitraApp());
}
