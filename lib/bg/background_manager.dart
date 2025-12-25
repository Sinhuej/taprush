import 'dart:io';
import 'package:flutter/material.dart';
import 'background_store.dart';

class BackgroundManager {
  final BackgroundStore store;

  // Stored image paths (user-selected)
  final List<String> _paths = [];

  BackgroundManager({required this.store});

  Future<void> init() async {
    final saved = await store.load();
    _paths
      ..clear()
      ..addAll(saved);
  }

  // === API expected by BackgroundSettingsScreen ===

  List<String> get paths => List.unmodifiable(_paths);

  Future<void> addPath(String path) async {
    _paths.add(path);
    await store.save(_paths);
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _paths.length) return;
    _paths.removeAt(index);
    await store.save(_paths);
  }

  // === Rendering ===

  Widget buildForStage(int stage) {
    // If user supplied images exist AND file exists, render it
    if (_paths.isNotEmpty) {
      final idx = stage % _paths.length;
      final file = File(_paths[idx]);

      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
        );
      }
    }

    // Fallback gradient (always safe)
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
