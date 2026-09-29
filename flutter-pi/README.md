# pi_demo

Material 3 sample app for [flutter-pi](https://github.com/ardera/flutter-pi).
Develop on a Linux desktop; deploy to a **Raspberry Pi Zero 2 W** (Cortex-A53,
64-bit / aarch64, 512 MB RAM).

No third-party packages, so the release bundle stays around 32 MB and memory use stays low.

## What's inside

| Drawer page | Shows |
|---|---|
| Login | Form validation, password show/hide, remember me, forgot-password dialog, async sign-in with a loading state, error box. Demo login: `admin@demo.com` / `admin123` |
| Dashboard | Stat cards, a bar chart built from widgets only, progress bar, recent activity list |
| Components | All button kinds, icon buttons, FABs, segmented and toggle buttons, chips, checkbox (tristate), switch, radio, sliders, progress indicators, badges, MenuAnchor, PopupMenu, DropdownMenu, tooltip, SearchAnchor |
| Forms | Text, email, phone, number range, password with confirm (checks both match), multiline text with counter, dropdown, autocomplete, date and time pickers, radio group, segmented button, FilterChip `FormField`, slider, switch, terms `FormField`, reset, submit summary dialog |
| Dialogs | Alert/confirm, simple, input (validated), loading, full-screen, about, modal/draggable/persistent bottom sheets, snackbars (plain, with action, error), MaterialBanner, date/range/time pickers |
| Editable Table | Sortable `DataTable` with **inline cell editing** (tap ✎: Enter saves, Esc cancels, validates as you type), category dropdown and active switch in cells, multi-select and bulk delete with undo, add/edit dialog form, search, **card view** toggle |
| Lists & Layout | Tabs: swipe-to-dismiss list with undo, ListTile variants, ExpansionTile, card variants, Stepper with a validated step, grid |
| Settings | Light/dark/system theme, seed colour, device info (screen size and DPR, which help when checking the Pi display) |

Layout: screens narrower than 1000 px (for example the 800×480 Pi touch display) get a **modal left drawer**. Wider screens get a **fixed sidebar**.

## Dev machine

```bash
# one-time: Linux desktop toolchain (Fedora). flutter doctor currently reports clang++ missing.
sudo dnf install clang gtk3-devel

cd pi_demo
flutter run -d linux          # hot reload
flutter run -d chrome         # works without clang too
flutter test                  # login + renders every page at 800x480
```

In VS Code, use the launch configs **pi_demo (Linux desktop)** and **pi_demo (Chrome)** in the root `.vscode/`.

Tip: to preview the Pi screen size, resize the window to 800×480. **Settings → Device info** shows the current logical size.

## Raspberry Pi Zero 2 W

### 1. Prepare the Pi (once)

1. Flash **Raspberry Pi OS Lite (64-bit)**. Use Lite with no desktop, because flutter-pi draws straight to the display through KMS.
2. Copy and run the setup script:
   ```bash
   scp scripts/pi_setup.sh pi@raspberrypi.local:
   ssh pi@raspberrypi.local ./pi_setup.sh
   ```
3. Run `sudo raspi-config`, then **System Options → Boot / Auto Login → Console Autologin**. Reboot.

### 2. Build (on the dev machine)

```bash
cd pi_demo
./scripts/build_pi.sh          # = flutterpi_tool build --arch=arm64 --cpu=pi3 --release
```

The output is `build/flutter-pi/pi3-64/`. It contains `app.so` (AOT), `flutter-pi`, `libflutter_engine.so`, and the assets.
`--cpu=pi3` gives a Cortex-A53-tuned engine, which is the right choice for the Zero 2 W. Use `--cpu=generic` if you're unsure.

### 3. Deploy and run

```bash
PI_HOST=pi@raspberrypi.local ./scripts/deploy_pi.sh             # build + rsync + run
PI_HOST=pi@raspberrypi.local ./scripts/deploy_pi.sh --no-build  # rsync + run only
```

To run it by hand on the Pi:

```bash
cd ~/pi_demo && LD_LIBRARY_PATH=$PWD ./flutter-pi --release $PWD
# useful flags: -r 90 (rotate), -d "155,86" (display size in mm, fixes DPI/scale)
```

### 4. Autostart on boot (optional)

```bash
scp scripts/pi-demo.service pi@raspberrypi.local:
ssh pi@raspberrypi.local
sudo cp pi-demo.service /etc/systemd/system/
sudo sed -i "s/__USER__/$USER/g" /etc/systemd/system/pi-demo.service
sudo systemctl daemon-reload && sudo systemctl enable --now pi-demo.service
```

Once the service is enabled, `deploy_pi.sh` restarts the service instead of starting a foreground process.

### Hot reload on the Pi (optional)

```bash
flutterpi_tool devices add pi@raspberrypi.local
flutterpi_tool run -d raspberrypi   # debug mode (JIT). Heavy for 512 MB; use for UI checks only
```

## Notes for 512 MB RAM

- Always test performance in `--release` builds. Debug mode uses JIT and much more memory.
- Keep the package list small. Every plugin adds RAM use and startup time.
- Don't run a desktop environment. flutter-pi needs the console to own the display.
- The tooling has no on-screen keyboard. Use a USB/BT keyboard, or add your own keypad widget, which is common for POS screens.
- If the app fails to start, run `ldd ~/pi_demo/flutter-pi | grep "not found"` to find missing libraries.
