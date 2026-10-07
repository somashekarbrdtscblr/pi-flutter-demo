#!/bin/bash
set -euo pipefail

# Stop and remove the C++ Qt5 billing app display on Pi Zero 2 W - Raspberry
# Pi OS Trixie. Undoes setup-labwc-cpp-qt5-02W.sh so another UI (flutter-pi)
# can take over the display.
#
#   sudo ./remove-labwc-cpp-qt5-02W.sh           stop + disable the labwc service,
#                                                remove its unit file and autostart
#   sudo ./remove-labwc-cpp-qt5-02W.sh --purge   also delete its logs and uninstall
#                                                labwc, squeekboard, wlr-randr, qtwayland5
#
# The app binary (${APP_DIR}/chotapos-billing-cpp-qt) is left in place:
# release.tar.gz still ships it and update.sh runs chmod on it, so deleting it
# would only make the next update fail.

APP_USER="${CHOTAPOS_USER:-chotapos}"
APP_DIR="${CHOTAPOS_APP_DIR:-/home/${APP_USER}/app}"
APP_NAME="${CHOTAPOS_APP_NAME:-chotapos-billing-cpp-qt}"
APP_BIN="${APP_DIR}/${APP_NAME}"
APP_LOG="${APP_DIR}/${APP_NAME}.log"
SQUEEKBOARD_LOG="${APP_DIR}/squeekboard.log"
SERVICE_NAME="${CHOTAPOS_SERVICE_NAME:-chotapos-labwc.service}"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

PURGE=0
case "${1:-}" in
  "") ;;
  --purge) PURGE=1 ;;
  *)
    sed -n '7,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac

if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

echo "=== Stopping ${SERVICE_NAME} ==="
systemctl stop "${SERVICE_NAME}" 2>/dev/null || true
systemctl disable "${SERVICE_NAME}" 2>/dev/null || true

echo "=== Stopping leftover processes ==="
# Match the full path: the process name is cut to 15 characters, so
# `pkill -x chotapos-billing-cpp-qt` would never match.
pkill -f "${APP_BIN}" 2>/dev/null || true
pkill -x squeekboard 2>/dev/null || true
pkill -x labwc 2>/dev/null || true
for _ in $(seq 1 25); do
  pgrep -f "${APP_BIN}" >/dev/null || pgrep -x labwc >/dev/null || break
  sleep 0.2
done
pkill -9 -f "${APP_BIN}" 2>/dev/null || true
pkill -9 -x labwc 2>/dev/null || true

echo "=== Removing systemd service ==="
rm -f "${SERVICE_PATH}"
systemctl daemon-reload
systemctl reset-failed "${SERVICE_NAME}" 2>/dev/null || true

echo "=== Removing labwc autostart ==="
if id "${APP_USER}" >/dev/null 2>&1; then
  APP_HOME="$(getent passwd "${APP_USER}" | cut -d: -f6)"
  AUTOSTART_DIR="${APP_HOME}/.config/labwc"
  AUTOSTART_PATH="${AUTOSTART_DIR}/autostart"
  # Only delete the autostart the setup script wrote; leave a hand-edited one.
  if [[ -f "${AUTOSTART_PATH}" ]] && grep -q "${APP_NAME}" "${AUTOSTART_PATH}"; then
    rm -f "${AUTOSTART_PATH}"
    rmdir "${AUTOSTART_DIR}" 2>/dev/null || true
    echo "Removed ${AUTOSTART_PATH}"
  else
    echo "No ChotaPOS labwc autostart found; skipped."
  fi
else
  echo "User ${APP_USER} does not exist; skipped."
fi

# The labwc setup disabled the tty1 login console. Bring it back so the Pi is
# usable until another UI service takes tty1 (setup-flutter-pi-02W.sh does).
echo "=== Restoring tty1 login console ==="
systemctl enable getty@tty1.service
systemctl start getty@tty1.service || true

if [[ "${PURGE}" -eq 1 ]]; then
  echo "=== Purging logs and labwc packages ==="
  rm -f "${APP_LOG}" "${SQUEEKBOARD_LOG}"
  # Qt5 runtime libraries stay installed so the old binary can still be
  # brought back with setup-labwc-cpp-qt5-02W.sh.
  DEBIAN_FRONTEND=noninteractive apt-get purge -y labwc squeekboard wlr-randr qtwayland5 || true
  DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
fi

echo
echo "C++ Qt app display removed."
echo "Binary kept: ${APP_BIN}"
echo "To undo: sudo ./setup-labwc-cpp-qt5-02W.sh"
