import 'package:flutter/material.dart';
import 'background_store.dart';

class BackgroundManager {
  final BackgroundStore store;
  BackgroundManager({required this.store});

  Future<void> init() async {}

  Widget buildForStage(int stage) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.deepPurple],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
