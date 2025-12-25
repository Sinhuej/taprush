#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PUB="pubspec.yaml"
if [ ! -f "$PUB" ]; then
  echo "❌ pubspec.yaml not found in $(pwd)"
  exit 1
fi

ensure_dep () {
  local dep="$1"
  if grep -qE "^[[:space:]]*$dep:" "$PUB"; then
    echo "✅ $dep already present"
  else
    echo "➕ Adding $dep to pubspec.yaml"
    if grep -q "^dependencies:" "$PUB"; then
      awk -v dep="$dep" '
        BEGIN{added=0}
        /^dependencies:/{print; if(!added){print "  "dep": any"; added=1; next}}
        {print}
      ' "$PUB" > "$PUB.tmp"
      mv "$PUB.tmp" "$PUB"
    else
      echo "" >> "$PUB"
      echo "dependencies:" >> "$PUB"
      echo "  $dep: any" >> "$PUB"
    fi
  fi
}

ensure_dep "shared_preferences"
ensure_dep "image_picker"

echo "✅ Dependencies updated."
echo "➡️ Next step: git add, commit, and push. CI will handle pub get & builds."
