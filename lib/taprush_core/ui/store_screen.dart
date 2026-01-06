import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../debug/debug_log.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool debugEnabled = DebugLog.enabled;

  void _copyLogs() {
    final text = DebugLog.snapshot().join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = DebugLog.snapshot();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          Switch(
            value: debugEnabled,
            onChanged: (v) {
              setState(() {
                debugEnabled = v;
                DebugLog.enabled = v;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Store Items Coming Soon',
              style: TextStyle(fontSize: 18),
            ),
          ),

          const Divider(),

          // --- Debug Log Panel ---
          Expanded(
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                reverse: true,
                itemCount: logs.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      logs[logs.length - 1 - i],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // --- Controls ---
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _copyLogs,
                  child: const Text('Copy Logs'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      DebugLog.clear();
                    });
                  },
                  child: const Text('Clear Logs'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
