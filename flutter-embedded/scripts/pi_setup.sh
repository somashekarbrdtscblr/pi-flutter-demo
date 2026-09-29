#!/usr/bin/env bash
# Run ONCE on the Raspberry Pi Zero 2 W (Raspberry Pi OS Lite 64-bit, Bookworm or newer).
# Installs runtime libs for flutter-pi and optionally a systemd service for kiosk boot.
# Usage: bash pi_setup.sh [--service]
set -euo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
  libdrm2 libgbm1 libegl1 libgles2 libvulkan1 \
  libinput10 libxkbcommon0 libudev1 libsystemd0 \
  libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
  fontconfig fonts-dejavu-core rsync

# flutter-pi needs DRM/KMS + input device access.
sudo usermod -aG render,video,input "$USER"

# KMS driver must be enabled (default on Bookworm).
if ! grep -qE '^dtoverlay=vc4-kms-v3d' /boot/firmware/config.txt 2>/dev/null; then
  echo "WARNING: dtoverlay=vc4-kms-v3d not found in /boot/firmware/config.txt — add it and reboot."
fi

if [[ "${1:-}" == "--service" ]]; then
  APP_DIR="$HOME/chota_pos"
  sudo tee /etc/systemd/system/chota-pos.service >/dev/null <<UNIT
[Unit]
Description=Chota POS (flutter-pi)
After=systemd-user-sessions.service network-online.target
Conflicts=getty@tty1.service

[Service]
User=$USER
WorkingDirectory=$APP_DIR
Environment=LD_LIBRARY_PATH=$APP_DIR
ExecStart=$APP_DIR/flutter-pi --release $APP_DIR
Restart=on-failure
RestartSec=3
TTYPath=/dev/tty1
StandardInput=tty-force

[Install]
WantedBy=multi-user.target
UNIT
  sudo systemctl daemon-reload
  sudo systemctl enable chota-pos
  echo "Service installed. Deploy the bundle to $APP_DIR, then: sudo systemctl start chota-pos"
fi

echo "Done. Log out/in (or reboot) so group membership applies."
echo "Make sure the Pi boots to CONSOLE (raspi-config > System > Boot > Console), not desktop."
