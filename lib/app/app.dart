import 'package:flutter/material.dart';
import '../ui/home/home_screen.dart';
import '../ui/theme/app_theme.dart';
import '../core/init/app_initializer.dart';

class VanimitraApp extends StatefulWidget {
  const VanimitraApp({super.key});
  @override
  State<VanimitraApp> createState() => _VanimitraAppState();
}

class _VanimitraAppState extends State<VanimitraApp> {
  @override
  void initState() {
    super.initState();
    AppInitializer.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vanimitra',
      theme: AppTheme.dark,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
