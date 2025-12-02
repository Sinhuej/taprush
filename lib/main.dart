import 'package:flutter/material.dart';
import 'theme.dart'; // ⬅️ add this import

void main() {
  runApp(const TapRushApp());
}

class TapRushApp extends StatelessWidget {
  const TapRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapRush',
      debugShowCheckedModeBanner: false,
      theme: tapRushTheme, // ⬅️ use the theme we just made
      home: const TapRushHome(),
    );
  }
}

class TapRushHome extends StatelessWidget {
  const TapRushHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TapRushColors.backgroundDark,
            TapRushColors.backgroundLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('TapRush'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap to Rush!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TapRushColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Bars inspired by the icon
              _TapRushBars(),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: hook up game start logic
                },
                child: const Text('Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapRushBars extends StatelessWidget {
  const _TapRushBars();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        _TapBar(height: 80, color: TapRushColors.secondary),
        SizedBox(width: 8),
        _TapBar(height: 110, color: TapRushColors.primary),
        SizedBox(width: 8),
        _TapBar(height: 60, color: TapRushColors.tertiary),
      ],
    );
  }
}

class _TapBar extends StatelessWidget {
  final double height;
  final Color color;

  const _TapBar({
    required this.height,
    required this.color,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: add tap animation / score increment
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 32,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }
}
