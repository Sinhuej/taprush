import 'package:taprush/taprush_core/debug/debug_panel.dart';
import 'package:flutter/material.dart';
import '../app/app_state.dart';
import '../engine/models.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  void _unlock(GameMode m) {
    final ok = appState.tryUnlock(m);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Unlocked!' : 'Not enough coins.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Store', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(
              title: 'Reverse Mode Unlock',
              subtitle: 'Bottom → top. Double coins.',
              trailing: appState.reverseUnlocked ? 'OWNED' : '20,000',
              onTap: appState.reverseUnlocked ? null : () => _unlock(GameMode.reverse),
            ),
            const SizedBox(height: 10),
            _card(
              title: 'Epic Mode Unlock',
              subtitle: 'Both directions. Highest difficulty.',
              trailing: appState.epicUnlocked ? 'OWNED' : '50,000',
              onTap: appState.epicUnlocked ? null : () => _unlock(GameMode.epic),
            ),
            const SizedBox(height: 18),
            _card(
              title: 'Cosmetics (Coming Soon)',
              subtitle: 'Skins • Planets • Animals • Foods',
              trailing: 'SOON',
              onTap: null,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: _pill('Coins', appState.coins)),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // ship-now dev button: simulate earned coins
                    appState.coins += 2500;
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                  child: const Text('+2500 (test)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String subtitle,
    required String trailing,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.9),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.black.withOpacity(0.65), fontWeight: FontWeight.w600)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.black,
              ),
              child: Text(trailing, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Object value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.85),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}
