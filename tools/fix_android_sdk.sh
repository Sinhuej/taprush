#!/usr/bin/env bash
set -euo pipefail

FILE="android/app/build.gradle.kts"

if ! grep -q "compileSdk = 35" "$FILE"; then
  sed -i 's/compileSdk = [0-9]\+/compileSdk = 35/' "$FILE"
  echo "✅ Updated compileSdk to 35"
else
  echo "✅ compileSdk already 35"
fi
