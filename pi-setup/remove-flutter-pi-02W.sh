#!/bin/bash
set -euo pipefail

# Stop and remove the Flutter billing app display on Pi Zero 2 W - Raspberry
# Pi OS Trixie. Undoes setup-flutter-pi-02W.sh so another UI (e.g.
# setup-labwc-cpp-qt5-02W.sh) can take over the display.
#
#   sudo ./remove-flutter-pi-02W.sh           stop + disable the flutter-pi service
#                                             and remove its unit file
#   sudo ./remove-flutter-pi-02W.sh --purge   also delete the app bundle, its log
#                                             and its runtime config (flutter.env)
#
# Runtime libraries (libdrm, libegl, libinput...) and the video/input/render
# groups are left in place: the system and the labwc setup use them too.

APP_USER="${CHOTAPOS_USER:-chotapos}"
APP_DIR="${CHOTAPOS_APP_DIR:-/home/${APP_USER}/app}"
FLUTTER_DIR="${CHOTAPOS_FLUTTER_DIR:-${APP_DIR}/flutter}"
FLUTTER_BIN="${FLUTTER_DIR}/flutter-pi"
APP_LOG="${APP_DIR}/chotapos-flutter.log"
ENV_FILE="${CHOTAPOS_FLUTTER_ENV_FILE:-${APP_DIR}/flutter.env}"
SERVICE_NAME="${CHOTAPOS_FLUTTER_SERVICE_NAME:-chotapos-flutter.service}"
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

PURGE=0
case "${1:-}" in
  "") ;;
  --purge) PURGE=1 ;;
  *)
    sed -n '8,11p' "$0" | sed 's/^# \{0,1\}//'
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
pkill -f "${FLUTTER_BIN}" 2>/dev/null || true
for _ in $(seq 1 25); do
  pgrep -f "${FLUTTER_BIN}" >/dev/null || break
  sleep 0.2
done
pkill -9 -f "${FLUTTER_BIN}" 2>/dev/null || true

echo "=== Removing systemd service ==="
rm -f "${SERVICE_PATH}"
systemctl daemon-reload
systemctl reset-failed "${SERVICE_NAME}" 2>/dev/null || true

# The flutter-pi setup disabled the tty1 login console. Bring it back so the
# Pi is usable until another UI service takes tty1.
echo "=== Restoring tty1 login console ==="
systemctl enable getty@tty1.service
systemctl start getty@tty1.service || true

if [[ "${PURGE}" -eq 1 ]]; then
  echo "=== Deleting app bundle, log and config ==="
  if [[ -d "${FLUTTER_DIR}" ]]; then
    # Guard against a wrong CHOTAPOS_FLUTTER_DIR: only delete a folder that
    # really holds a flutter-pi bundle.
    if [[ -f "${FLUTTER_BIN}" || -d "${FLUTTER_DIR}/flutter_assets" ]]; then
      rm -rf "${FLUTTER_DIR}"
      echo "Removed ${FLUTTER_DIR}"
    else
      echo "WARNING: ${FLUTTER_DIR} has no flutter-pi bundle; not deleting it." >&2
    fi
  fi
  rm -f "${APP_LOG}" "${ENV_FILE}"
fi

echo
echo "Flutter app display removed."
if [[ "${PURGE}" -eq 0 ]]; then
  echo "Kept: ${FLUTTER_DIR}, ${ENV_FILE}, ${APP_LOG} (use --purge to delete)"
fi
echo "To undo: sudo ./setup-flutter-pi-02W.sh"
echo "To bring back the C++ Qt app: sudo ./setup-labwc-cpp-qt5-02W.sh"
