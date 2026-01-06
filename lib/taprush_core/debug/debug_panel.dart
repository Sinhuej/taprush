import 'package:flutter/material.dart';
import 'debug_log.dart';

class DebugPanel extends StatefulWidget {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  @override
  Widget build(BuildContext context) {
    final logs = DebugLog.snapshot();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Debug', style: TextStyle(fontSize: 18)),
            const Spacer(),
            Switch(
              value: DebugLog.enabled,
              onChanged: (v) => setState(() => DebugLog.enabled = v),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await DebugLog.copyAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logs copied')),
                  );
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => setState(DebugLog.clear),
            ),
          ],
        ),
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            reverse: true,
            itemCount: logs.length,
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                logs[logs.length - 1 - i],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
