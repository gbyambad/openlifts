#!/usr/bin/env bash
# Regenerate the README screenshots from the real app running on a device or
# emulator (authentic rendering — not headless goldens). On demand, local.
#
# Usage:
#   tool/screenshots.sh [device-id]
#
# With no argument it targets the first booted Android emulator. Boot one first
# (e.g. `flutter emulators --launch <id>`), then run this from the repo root.
#
# Screenshots are captured via RepaintBoundary at a fixed 3x pixel ratio, so
# they're crisp regardless of the emulator's own resolution.
set -euo pipefail

cd "$(dirname "$0")/.."

device="${1:-}"
if [ -z "$device" ]; then
  device=$(flutter devices --machine 2>/dev/null \
    | grep -oE '"id"[[:space:]]*:[[:space:]]*"emulator-[0-9]+"' \
    | grep -oE 'emulator-[0-9]+' | head -1 || true)
fi
if [ -z "$device" ]; then
  echo "No emulator found. Boot one with: flutter emulators --launch <id>" >&2
  exit 1
fi

echo "Capturing on $device → docs/screenshots/"
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshots_test.dart \
  -d "$device"

echo "✓ Wrote docs/screenshots/{today,workout,programs,settings}.png"
