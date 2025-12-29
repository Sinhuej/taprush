import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../engine/models.dart'; // <-- THIS MUST BE taprush_core models
import 'store_screen.dart';
import 'play_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  void _start() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PlayScreen(mode: appState.selectedMode),
          ),
        )
        .then((_) => setState(() {}));
  }

  void _openStore() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const StoreScreen()),
        )
        .then((_) => setState(() {}));
  }

  Widget _modeCard(String title, String desc, GameMode mode) {
    final selected = appState.selectedMode == mode;
    final locked = !appState.canPlay(mode);
    final cost = appState.unlockCost(mode);

    return GestureDetector(
      onTap: () {
        if (!locked) {
          setState(() => appState.selectedMode = mode);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Locked — unlock in Store ($cost coins).'),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.85),
          border: Border.all(
            color: selected ? Colors.black : Colors.black.withOpacity(0.12),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (locked)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: Colors.black,
                          ),
                          child: Text(
                            'LOCKED $cost',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.70),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                'TapRush',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Games by SlimNation',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _pill('Coins', appState.coins),
                  const SizedBox(width: 10),
                  _pill(
                    'Mode',
                    appState.selectedMode.name.toUpperCase(),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _openStore,
                    child: const Text(
                      'Store',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _modeCard('Normal', 'Top → bottom. Pure flow.', GameMode.normal),
              const SizedBox(height: 10),
              _modeCard(
                'Reverse',
                'Bottom → top. Double coins.',
                GameMode.reverse,
              ),
              const SizedBox(height: 10),
              _modeCard(
                'Epic',
                'Both directions. Ramp-in chaos.',
                GameMode.epic,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'PLAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
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
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}
