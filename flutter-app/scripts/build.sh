#!/usr/bin/env bash
# Build the app for a deploy target and copy the result to dist/<target>/.
#
#   scripts/build.sh pi  [release|profile|debug]   Raspberry Pi Zero 2 W (Pi OS 64-bit, flutter-pi)
#   scripts/build.sh web [release|profile|debug]   Static site, served at /
#
# Mode defaults to release.
set -euo pipefail

usage() {
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
  exit 1
}

TARGET="${1:-}"
MODE="${2:-release}"

[[ "$TARGET" == pi || "$TARGET" == web ]] || usage
[[ "$MODE" == release || "$MODE" == profile || "$MODE" == debug ]] || usage

cd "$(dirname "$0")/.."

build_pi() {
  local tool="${FLUTTERPI_TOOL:-$HOME/.pub-cache/bin/flutterpi_tool}"
  if [[ ! -x "$tool" ]]; then
    echo "flutterpi_tool not found at $tool" >&2
    echo "Install it with:  flutter pub global activate flutterpi_tool" >&2
    exit 1
  fi

  # Pi Zero 2 W = Cortex-A53, same tuning as the Pi 3.
  "$tool" build --arch=arm64 --cpu=pi3 "--$MODE"
  SRC=build/flutter-pi/pi3-64
}

build_web() {
  # Path URLs (/products): the web server must serve index.html for unknown paths.
  flutter build web "--$MODE" --base-href /
  SRC=build/web
}

flutter pub get
"build_$TARGET"

OUT="dist/$TARGET"
rm -rf "$OUT"
mkdir -p "$OUT"
cp -a "$SRC/." "$OUT/"
# flutter-pi leaves its CMake cache in the bundle; not needed on the device.
[[ "$TARGET" == pi ]] && rm -rf "$OUT/linux"

echo
echo "Built $TARGET ($MODE): $OUT ($(du -sh "$OUT" | cut -f1))"
