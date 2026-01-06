#!/usr/bin/env bash
set -e

echo "🐞 Adding Debug Overlay Toggle..."

FILE="lib/taprush_core/ui/play_screen.dart"

# Add state var
grep -q "_showDebug" "$FILE" || \
sed -i "/bool _initialized = false;/a\\
  bool _showDebug = false;
" "$FILE"

# Replace DebugOverlay usage with conditional
sed -i "s/const DebugOverlay()/if (_showDebug) const DebugOverlay()/g" "$FILE"

# Inject floating toggle button
grep -q "DEBUG TOGGLE" "$FILE" || \
sed -i "/children: \[/a\\
              // DEBUG TOGGLE\\
              Positioned(\\
                bottom: 20,\\
                right: 20,\\
                child: FloatingActionButton(\\
                  mini: true,\\
                  onPressed: () {\\
                    setState(() => _showDebug = !_showDebug);\\
                  },\\
                  child: const Icon(Icons.bug_report),\\
                ),\\
              ),
" "$FILE"

echo "✅ Debug toggle button added"
