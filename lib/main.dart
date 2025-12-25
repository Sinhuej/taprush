import 'package:flutter/material.dart';
import 'game/taprush_game_screen.dart';

Future<void> main() async {
  // REQUIRED for plugins & platform channels in release builds
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const TapRushApp());
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TapRushGameScreen(),
    );
  }
}
