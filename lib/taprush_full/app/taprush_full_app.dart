import 'package:flutter/material.dart';
import 'app_state.dart';
import '../game/taprush_full_game_screen.dart';
import '../store/store_screen.dart';

class TapRushFullApp extends StatefulWidget {
  const TapRushFullApp({super.key});

  @override
  State<TapRushFullApp> createState() => _TapRushFullAppState();
}

enum _View { game, store }

class _TapRushFullAppState extends State<TapRushFullApp> {
  final AppState _state = AppState();
  _View _view = _View.game;

  void _openStore() => setState(() => _view = _View.store);
  void _backToGame() => setState(() => _view = _View.game);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _view == _View.game
          ? TapRushFullGameScreen(
              state: _state,
              onOpenStore: _openStore,
              onStateChanged: () => setState(() {}),
            )
          : StoreScreen(
              state: _state,
              onBack: _backToGame,
              onStateChanged: () => setState(() {}),
            ),
    );
  }
}
