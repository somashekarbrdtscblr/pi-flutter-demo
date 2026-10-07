#!/bin/bash
set -euo pipefail

# Setup the Flutter billing app on Pi Zero 2 W for Production - Raspberry Pi
# OS Trixie. Runs the flutter-pi bundle straight on the display (DRM/KMS) from
# a systemd service, so it starts on boot. No labwc, Wayland or squeekboard:
# flutter-pi draws without a desktop and the app has its own keyboard.
#
# Before running:
#   1. Run remove-labwc-cpp-qt5-02W.sh (only one UI can own the display).
#   2. Copy the bundle from `scripts/build.sh pi` to ${FLUTTER_DIR}, e.g.
#        ssh $PI "rm -rf /home/chotapos/app/flutter"
#        scp -rp dist/pi $PI:/home/chotapos/app/flutter
#
# Redeploying a new bundle later does not need this script again:
#   ssh $PI "sudo systemctl stop chotapos-flutter && rm -rf /home/chotapos/app/flutter"
#   scp -rp dist/pi $PI:/home/chotapos/app/flutter
#   ssh $PI "sudo systemctl start chotapos-flutter"
#
# Per-device settings go in ${ENV_FILE} (created once, never overwritten).

APP_USER="${CHOTAPOS_USER:-chotapos}"
APP_DIR="${CHOTAPOS_APP_DIR:-/home/${APP_USER}/app}"
FLUTTER_DIR="${CHOTAPOS_FLUTTER_DIR:-${APP_DIR}/flutter}"
FLUTTER_BIN="${FLUTTER_DIR}/flutter-pi"
# Must match the build: scripts/build.sh pi [release|profile|debug].
FLUTTER_MODE="${CHOTAPOS_FLUTTER_MODE:-release}"
# Extra flutter-pi flags, e.g. "-r 90" to rotate the display.
FLUTTER_PI_ARGS="${CHOTAPOS_FLUTTER_PI_ARGS:-}"
APP_LOG="${APP_DIR}/chotapos-flutter.log"
ENV_FILE="${CHOTAPOS_FLUTTER_ENV_FILE:-${APP_DIR}/flutter.env}"
BASE_API="${CHOTAPOS_BASE_API:-http://localhost:3000/api}"
SERVICE_NAME="${CHOTAPOS_FLUTTER_SERVICE_NAME:-chotapos-flutter.service}"
OLD_SERVICE_NAME="chotapos-labwc.service"

case "${FLUTTER_MODE}" in
  release | profile | debug) ;;
  *)
    echo "ERROR: CHOTAPOS_FLUTTER_MODE must be release, profile or debug." >&2
    exit 1
    ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

if ! id "${APP_USER}" >/dev/null 2>&1; then
  echo "ERROR: user does not exist: ${APP_USER}" >&2
  echo "Create it first, or run with CHOTAPOS_USER=<user>." >&2
  exit 1
fi

APP_GROUP="$(id -gn "${APP_USER}")"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

# Both services want tty1 and the display. If the old one stays enabled,
# whichever starts last at boot wins.
if systemctl is-enabled --quiet "${OLD_SERVICE_NAME}" 2>/dev/null; then
  echo "=== Disabling ${OLD_SERVICE_NAME} ==="
  echo "Run remove-labwc-cpp-qt5-02W.sh to clean it up fully."
  systemctl disable --now "${OLD_SERVICE_NAME}"
fi

echo "=== Installing flutter-pi runtime dependencies ==="
apt-get update
# flutter-pi links GStreamer (video/audio player plugins) and Vulkan even when
# the app uses neither, so they must be installed for it to start.
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates \
  fontconfig \
  fonts-dejavu-core \
  libatomic1 \
  libdrm2 \
  libegl1 \
  libgbm1 \
  libgles2 \
  libgstreamer1.0-0 \
  libgstreamer-plugins-base1.0-0 \
  libinput10 \
  libsystemd0 \
  libudev1 \
  libvulkan1 \
  libxkbcommon0 \
  procps

if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -f
fi

echo "=== Configuring user groups ==="
usermod -a -G video,input,render "${APP_USER}"

echo "=== Preparing app directory ==="
mkdir -p "${APP_DIR}" "${FLUTTER_DIR}"
chown -R "${APP_USER}:${APP_GROUP}" "${APP_DIR}"

# Without the bundle the service would restart every few seconds forever and
# fill the log, so stop here instead of enabling it.
if [[ ! -f "${FLUTTER_BIN}" ]]; then
  echo "ERROR: flutter-pi bundle not found: ${FLUTTER_BIN}" >&2
  echo "Copy dist/pi from 'scripts/build.sh pi' to ${FLUTTER_DIR}, then run this again." >&2
  exit 1
fi

chmod 0755 "${FLUTTER_BIN}"
if command -v ldd >/dev/null 2>&1; then
  echo "Shared-library check for ${FLUTTER_BIN}:"
  # libflutter_engine.so ships inside the bundle, next to flutter-pi.
  LDD_OUTPUT="$(LD_LIBRARY_PATH="${FLUTTER_DIR}" ldd "${FLUTTER_BIN}")"
  echo "${LDD_OUTPUT}"
  if grep -q "not found" <<<"${LDD_OUTPUT}"; then
    echo "ERROR: one or more runtime libraries are missing." >&2
    exit 1
  fi
fi

echo "=== Writing runtime config ==="
if [[ -f "${ENV_FILE}" ]]; then
  echo "Keeping existing ${ENV_FILE}"
else
  cat >"${ENV_FILE}" <<EOF
# Runtime settings for ${SERVICE_NAME}, one KEY=value per line.
# Read by the app with Platform.environment. Restart the service after editing:
#   sudo systemctl restart ${SERVICE_NAME}
# Not secret-safe: anything here is readable on the device.
CHOTAPOS_BASE_API=${BASE_API}
EOF
  chown "${APP_USER}:${APP_GROUP}" "${ENV_FILE}"
  chmod 0644 "${ENV_FILE}"
  echo "Wrote ${ENV_FILE}"
fi

echo "=== Writing systemd service ==="
cat >"${SERVICE_PATH}" <<EOF
[Unit]
Description=ChotaPOS Billing Display (flutter-pi)
After=systemd-user-sessions.service
Conflicts=getty@tty1.service ${OLD_SERVICE_NAME}

[Service]
Type=simple
User=${APP_USER}
Group=${APP_GROUP}
SupplementaryGroups=video input render
PAMName=login
TTYPath=/dev/tty1
StandardInput=tty
StandardOutput=append:${APP_LOG}
StandardError=append:${APP_LOG}

WorkingDirectory=${FLUTTER_DIR}
EnvironmentFile=-${ENV_FILE}
Environment=LD_LIBRARY_PATH=${FLUTTER_DIR}

ExecStart=${FLUTTER_BIN} --${FLUTTER_MODE} ${FLUTTER_PI_ARGS} ${FLUTTER_DIR}
KillMode=control-group
TimeoutStopSec=5
SendSIGKILL=yes
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "${SERVICE_NAME}"

echo
echo "Setup complete. Pi will reboot in 10 seconds..."
echo "Bundle:  ${FLUTTER_DIR}"
echo "Config:  ${ENV_FILE}"
echo "Log:     ${APP_LOG}"
echo "Service: ${SERVICE_PATH}"
echo "Status after boot: systemctl status ${SERVICE_NAME}"
systemd-run --on-active=10 /usr/sbin/reboot
systemd-run --on-active=5 /usr/bin/systemctl disable getty@tty1.service

# This will kill the current TTY1 session.
systemctl start "${SERVICE_NAME}" || true
