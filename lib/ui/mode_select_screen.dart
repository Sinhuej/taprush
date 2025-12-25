import 'package:flutter/material.dart';
import '../modes/game_mode.dart';
import '../storage/mode_unlock_store.dart';
import '../economy/coin_manager.dart';

class ModeSelectResult {
  final GameMode mode;
  const ModeSelectResult(this.mode);
}

class ModeSelectScreen extends StatefulWidget {
  final CoinManager coins;
  final ModeUnlockStore unlocks;
  final GameMode current;

  const ModeSelectScreen({
    super.key,
    required this.coins,
    required this.unlocks,
    required this.current,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool reverseUnlocked = false;
  bool epicUnlocked = false;

  static const int reverseCost = 20000;
  static const int epicCost = 50000;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    reverseUnlocked = await widget.unlocks.isUnlocked(GameMode.reverse);
    epicUnlocked = await widget.unlocks.isUnlocked(GameMode.epic);
    if (mounted) setState(() {});
  }

  Future<void> _unlock(GameMode mode) async {
    final cost = mode == GameMode.reverse ? reverseCost : epicCost;
    final ok = await widget.coins.spend(cost);
    if (!ok) return;
    await widget.unlocks.unlock(mode);
    await _load();
  }

  Widget _row(GameMode mode, bool unlocked, int cost, String subtitle) {
    return Card(
      child: ListTile(
        title: Text(mode.label),
        subtitle: Text(subtitle),
        trailing: unlocked
          ? ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ModeSelectResult(mode)),
              child: const Text('Select'),
            )
          : OutlinedButton(
              onPressed: widget.coins.coins >= cost ? () => _unlock(mode) : null,
              child: Text('Unlock $cost'),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Modes')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coins: ${widget.coins.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _row(GameMode.classic, true, 0, 'Tiles fall • 5 strikes • 1× coins'),
            _row(GameMode.reverse, reverseUnlocked, reverseCost, 'Tiles rise • 5 strikes • 2× coins • separate high score'),
            _row(GameMode.epic, epicUnlocked, epicCost, 'Up + Down • escape = loss • 3× coins • 1 ad retry per run • separate high score'),
          ],
        ),
      ),
    );
  }
}
