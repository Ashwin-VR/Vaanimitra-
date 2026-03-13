// DEV 3 — implement dark theme
import 'package:flutter/material.dart';
class AppTheme {
  static ThemeData get dark => ThemeData.dark(useMaterial3: true).copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A237E), brightness: Brightness.dark),
  );
}
