#!/usr/bin/env bash
# Run ONCE on the Raspberry Pi (Raspberry Pi OS Lite 64-bit, Bookworm/Trixie).
# Installs the runtime libraries the prebuilt flutter-pi + engine link against.
set -euo pipefail

sudo apt-get update
sudo apt-get install -y \
  libatomic1 libdrm2 libgbm1 libegl1 libgles2 libvulkan1 \
  libinput10 libudev1 libsystemd0 libxkbcommon0 \
  libglib2.0-0 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0 \
  fontconfig fonts-dejavu-core rsync

# Access to GPU (DRM/KMS), input devices (touch/keyboard/mouse) and video.
sudo usermod -aG render,input,video "$USER"

echo
echo "Done. Next:"
echo "  1. sudo raspi-config -> System Options -> Boot / Auto Login -> Console Autologin"
echo "     (flutter-pi needs the console, NOT a desktop session, to own the display)"
echo "  2. Optional, 512MB RAM: keep default gpu_mem (KMS driver allocates via CMA)."
echo "  3. Reboot, then from your dev machine: PI_HOST=$USER@$(hostname).local ./scripts/deploy_pi.sh"
echo "  4. Check libs: ldd ~/pi_demo/flutter-pi | grep 'not found'   (should print nothing)"
