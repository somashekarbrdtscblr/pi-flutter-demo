#!/usr/bin/env bash
# Build a flutter-pi release bundle for Raspberry Pi Zero 2 W (aarch64, Cortex-A53).
# Output: build/flutter-pi/pi3-64/  +  dist/chota_pos-pi3-64.tar.gz
set -euo pipefail
cd "$(dirname "$0")/.."

TOOL="${FLUTTERPI_TOOL:-$HOME/.pub-cache/bin/flutterpi_tool}"
if [[ ! -x "$TOOL" ]]; then
  echo "flutterpi_tool not found. Install with:"
  echo "  flutter pub global activate -s git https://github.com/ardera/flutterpi_tool"
  exit 1
fi

MODE="${1:-release}"   # release | profile | debug
flutter pub get
"$TOOL" build --arch=arm64 --cpu=pi3 "--$MODE"

mkdir -p dist
tar -C build/flutter-pi -czf dist/chota_pos-pi3-64.tar.gz pi3-64
echo "Bundle: build/flutter-pi/pi3-64  ($(du -sh build/flutter-pi/pi3-64 | cut -f1))"
echo "Tarball: dist/chota_pos-pi3-64.tar.gz"
