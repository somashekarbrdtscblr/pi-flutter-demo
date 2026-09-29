#!/usr/bin/env bash
# Build a release flutter-pi bundle for Raspberry Pi Zero 2W (Cortex-A53, arm64).
# Output: build/flutter-pi/pi3-64/
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:---release}"   # --release | --profile | --debug
FLUTTERPI_TOOL="${FLUTTERPI_TOOL:-$HOME/.pub-cache/bin/flutterpi_tool}"

if [[ ! -x "$FLUTTERPI_TOOL" ]]; then
  echo "flutterpi_tool not found. Install with: flutter pub global activate flutterpi_tool" >&2
  exit 1
fi

"$FLUTTERPI_TOOL" build --arch=arm64 --cpu=pi3 "$MODE"
echo "Bundle: $(pwd)/build/flutter-pi/pi3-64 ($(du -sh build/flutter-pi/pi3-64 | cut -f1))"
