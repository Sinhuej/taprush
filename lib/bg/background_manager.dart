import 'dart:io';
import 'package:flutter/material.dart';
import 'background_store.dart';

class BackgroundManager extends ChangeNotifier {
  final BackgroundStore store;

  List<String> _paths = [];
  List<String> get paths => List.unmodifiable(_paths);

  BackgroundManager({required this.store});

  Future<void> init() async {
    _paths = await store.loadPaths();
    notifyListeners();
  }

  Future<void> setPaths(List<String> newPaths) async {
    _paths = newPaths.take(6).toList();
    await store.savePaths(_paths);
    notifyListeners();
  }

  Future<void> addPath(String path) async {
    if (_paths.length >= 6) return;
    _paths = [..._paths, path];
    await store.savePaths(_paths);
    notifyListeners();
  }

  Future<void> removeAt(int idx) async {
    if (idx < 0 || idx >= _paths.length) return;
    _paths = [..._paths]..removeAt(idx);
    await store.savePaths(_paths);
    notifyListeners();
  }

  Widget buildBackgroundForStage(int stage) {
    if (_paths.isEmpty) {
      // Fallback: gradient rotation by stage (copyright-safe, zero assets)
      final gradients = <List<Color>>[
        [const Color(0xFF0D1117), const Color(0xFF1A1E2E)],
        [const Color(0xFF0B1020), const Color(0xFF2A1B3D)],
        [const Color(0xFF081A14), const Color(0xFF1B2A3D)],
        [const Color(0xFF140B1F), const Color(0xFF2E1A1A)],
        [const Color(0xFF0A122A), const Color(0xFF2A2A0A)],
        [const Color(0xFF101010), const Color(0xFF2A163D)],
      ];
      final g = gradients[stage % gradients.length];
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: g,
          ),
        ),
      );
    }

    final idx = stage % _paths.length;
    final file = File(_paths[idx]);

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        // If path becomes invalid, fallback safely
        return Container(color: const Color(0xFF0D1117));
      },
    );
  }
}
