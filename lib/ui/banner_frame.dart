import 'package:flutter/material.dart';

class BannerFrame extends StatelessWidget {
  final Widget child;
  const BannerFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          color: Colors.black26,
          alignment: Alignment.center,
          child: const Text("Banner Ad Placeholder"),
        ),
        Expanded(child: child),
      ],
    );
  }
}
