#!/usr/bin/env bash
# Build, copy to the Pi over SSH and (re)start the app.
#   PI_HOST=pi@raspberrypi.local ./scripts/deploy_pi.sh           # build + copy + run
#   PI_HOST=pi@192.168.1.50 ./scripts/deploy_pi.sh --no-build     # copy + run only
set -euo pipefail
cd "$(dirname "$0")/.."

PI_HOST="${PI_HOST:-pi@raspberrypi.local}"
PI_DIR="${PI_DIR:-pi_demo}"            # relative to the Pi user's home
BUNDLE=build/flutter-pi/pi3-64

[[ "${1:-}" == "--no-build" ]] || ./scripts/build_pi.sh --release

echo "==> Syncing $BUNDLE -> $PI_HOST:~/$PI_DIR"
rsync -az --delete "$BUNDLE/" "$PI_HOST:$PI_DIR/"

echo "==> Restarting app on $PI_HOST (Ctrl+C to stop streaming logs)"
# If the systemd service is installed, restart it; otherwise run in foreground.
ssh -t "$PI_HOST" "
  if systemctl list-unit-files pi-demo.service >/dev/null 2>&1 && systemctl is-enabled pi-demo.service >/dev/null 2>&1; then
    sudo systemctl restart pi-demo.service && journalctl -u pi-demo.service -f -n 30
  else
    pkill -x flutter-pi || true
    cd ~/$PI_DIR && LD_LIBRARY_PATH=\$PWD ./flutter-pi --release \$PWD
  fi
"
