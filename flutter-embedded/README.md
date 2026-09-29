# Chota POS – Flutter Embedded Demo

Material 3 sample app. Runs as a Linux desktop app on the dev machine and on a
**Raspberry Pi Zero 2 W (64-bit, aarch64)** through [flutter-pi](https://github.com/ardera/flutter-pi).
flutter-pi draws straight to DRM/KMS, so the Pi needs no X11 or Wayland desktop.

Login: any valid email, password **`admin123`**.

## Features

| Page | What it shows |
|------|---------------|
| Login | Form validation, show/hide password, checkbox, loading state, error text |
| Shell | Left **NavigationDrawer**: modal on narrow screens, permanent sidebar at ≥ 900px. AppBar actions, badge, popup menu, logout confirmation |
| Dashboard | Stat cards, a bar chart built from plain widgets, progress bars, a media card |
| Forms | TextFormField (email, phone, password + confirm, number range), DropdownButtonFormField, DropdownMenu, Autocomplete, date and time pickers, RadioGroup, SegmentedButton, FilterChip, Slider, RangeSlider, Switch, checkbox-as-FormField, submit and reset |
| Dialogs | Alert/confirm, SimpleDialog, form dialog with validation, full-screen dialog, loading dialog, About, date range picker, modal/draggable/persistent bottom sheets, snackbars (plain, undo, floating, error), MaterialBanner, MenuAnchor with a submenu, PopupMenu, Tooltip |
| Data Table | **Editable DataTable**: tap a cell to edit inline with validation, add/delete rows with undo, multi-select bulk delete, column sort, search, per-row Switch, a stock total |
| Components | Every button type, FABs, ToggleButtons, chips, badges, progress indicators, the three card variants, Stepper, NavigationBar, ExpansionTile |
| Lists & Tabs | TabBar, Dismissible (swipe), ReorderableListView, GridView |
| Settings | Light/dark/system theme, seed colour, device info |

The app uses no third-party packages; state is held in a `ChangeNotifier` and `InheritedNotifier`.

```
lib/
  main.dart             app + theme
  state/app_state.dart  auth + theme state
  pages/                one file per drawer page
  widgets/              Section, ResponsiveRow, Validators
scripts/                dev_run, build_pi, deploy_pi, pi_setup
test/app_test.dart      validators, login flow, every page at 800x480
```

## 1. Dev machine (Fedora)

Run once:

```bash
sudo dnf install clang                    # Flutter's Linux build needs clang++
flutter pub global activate -s git https://github.com/ardera/flutterpi_tool
```

> Install `flutterpi_tool` from git. The pub.dev release (0.12.0) fails to
> compile against Flutter 3.47.5.

Run with hot reload in an 800×480 window, the size of a typical Pi display:

```bash
./scripts/dev_run.sh
flutter test          # validators, login flow, every page at 800x480
```

## 2. Pi Zero 2 W setup (run once)

1. Flash **Raspberry Pi OS Lite (64-bit)**.
2. `sudo raspi-config`, then System → Boot → **Console Autologin**. flutter-pi needs exclusive access to the display, so the Pi must not boot into a desktop.
3. Check that `/boot/firmware/config.txt` contains `dtoverlay=vc4-kms-v3d`. It is there by default.
4. Copy `scripts/pi_setup.sh` to the Pi and run it:

   ```bash
   scp scripts/pi_setup.sh pi@raspberrypi.local:
   ssh pi@raspberrypi.local 'bash pi_setup.sh --service'   # --service = start on boot
   ssh pi@raspberrypi.local 'sudo reboot'
   ```

   The script installs the runtime libraries (libdrm, gbm, EGL/GLES, libinput, xkbcommon, gstreamer, fonts), adds your user to the `render`, `video` and `input` groups, and with `--service` sets up a systemd unit on tty1.

The Pi does **not** need Flutter or a compiler. The bundle includes the `flutter-pi` binary and the engine.

## 3. Build and deploy to the Pi

```bash
./scripts/build_pi.sh                             # arm64, Cortex-A53 tuned engine, release
./scripts/deploy_pi.sh pi@raspberrypi.local       # rsync + run in foreground
./scripts/deploy_pi.sh pi@raspberrypi.local --service   # rsync + restart systemd service
```

Build output:

- `build/flutter-pi/pi3-64/` (about 31 MB): `flutter-pi`, `libflutter_engine.so`, `app.so` (AOT), assets
- `dist/chota_pos-pi3-64.tar.gz`: the same bundle as a tarball

`--cpu=pi3` is correct for the Zero 2 W, which uses the same Cortex-A53 cores as the Pi 3.

To start the app on the Pi by hand:

```bash
cd ~/chota_pos && LD_LIBRARY_PATH=$PWD ./flutter-pi --release $PWD
# options: -r 90 (rotate), --dimensions 155,86 (screen size in mm, for correct DPI)
```

### Hot reload on the Pi (optional)

```bash
flutterpi_tool devices add pi@raspberrypi.local
flutterpi_tool run -d raspberrypi       # debug build, hot reload over SSH
```

Debug mode is slow on the Zero 2 W's 512 MB of RAM. Use it for quick checks and use release builds for real testing.

## Notes and limits

- **No on-screen keyboard.** flutter-pi does not provide a soft keyboard. Use a USB or Bluetooth keyboard, or add an in-app keypad widget later for touch-only POS use.
- **Screen size.** Layouts are tested at 800×480. The sidebar becomes permanent at ≥ 900px wide.
- Run `./scripts/build_pi.sh profile` to build a profile-mode bundle for performance tracing.
