import 'package:flutter/material.dart';
import '../game/taprush_game_screen.dart';

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TapRushGameScreen(),
    );
  }
}
