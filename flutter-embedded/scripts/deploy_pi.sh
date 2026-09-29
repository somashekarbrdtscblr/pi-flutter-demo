#!/usr/bin/env bash
# Copy the built bundle to the Pi and (re)start it.
# Usage: scripts/deploy_pi.sh pi@raspberrypi.local [--service]
#   --service  restart the chota-pos systemd service instead of running in foreground
set -euo pipefail
cd "$(dirname "$0")/.."

HOST="${1:?usage: $0 user@pi-host [--service]}"
BUNDLE=build/flutter-pi/pi3-64
REMOTE_DIR="${REMOTE_DIR:-/home/$(echo "$HOST" | cut -d@ -f1)/chota_pos}"

[[ -d "$BUNDLE" ]] || { echo "No bundle. Run scripts/build_pi.sh first."; exit 1; }

rsync -az --delete "$BUNDLE/" "$HOST:$REMOTE_DIR/"
echo "Deployed to $HOST:$REMOTE_DIR"

if [[ "${2:-}" == "--service" ]]; then
  ssh "$HOST" "sudo systemctl restart chota-pos && systemctl --no-pager status chota-pos | head -5"
else
  echo "Starting in foreground (Ctrl+C to stop)…"
  ssh -t "$HOST" "sudo systemctl stop chota-pos 2>/dev/null; cd $REMOTE_DIR && LD_LIBRARY_PATH=$REMOTE_DIR ./flutter-pi --release $REMOTE_DIR"
fi
