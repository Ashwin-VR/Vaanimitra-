import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vanimitra/app/app.dart';
import 'package:vanimitra/core/init/app_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Full init: permissions → DB → contacts → STT → TTS → ActionExecutor → DialogueController
  await AppInitializer.instance.initialize();

  runApp(const VanimitraApp());
}
