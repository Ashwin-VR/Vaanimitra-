// STUB — lib/app/app.dart
// Owner: Lead. Replace with production implementation.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vanimitra/ui/home/home_controller.dart';
import 'package:vanimitra/ui/home/home_screen.dart';
import 'package:vanimitra/ui/theme/app_theme.dart';

class VanimitraApp extends StatelessWidget {
  const VanimitraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeController()),
      ],
      child: MaterialApp(
        title: 'Vanimitra',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}
