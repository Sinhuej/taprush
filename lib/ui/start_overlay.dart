import 'package:flutter/material.dart';

class StartOverlay extends StatelessWidget {
  final void Function() onStart;

  const StartOverlay({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onStart,
        child: const Text('START'),
      ),
    );
  }
}
