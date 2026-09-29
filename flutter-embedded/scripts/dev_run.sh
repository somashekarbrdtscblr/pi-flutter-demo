#!/usr/bin/env bash
# Run on the dev machine (Linux desktop) with hot reload.
# Requires clang (Fedora: sudo dnf install clang). Resize the window to ~800x480
# to preview Pi-display layouts.
set -euo pipefail
cd "$(dirname "$0")/.."
flutter config --enable-linux-desktop >/dev/null
flutter pub get
exec flutter run -d linux "$@"
