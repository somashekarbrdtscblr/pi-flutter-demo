# flutter_app

Chota POS demo. One codebase for Android, web, Linux desktop, Windows desktop
and Raspberry Pi Zero 2 W (via [flutter-pi](https://github.com/ardera/flutter-pi)).

## Develop (hot reload)

```bash
flutter run -d linux     # Linux desktop
flutter run -d chrome    # web
flutter run -d windows   # on a Windows machine
flutter run              # connected Android device / emulator
```

Press `r` for hot reload, `R` for hot restart.

Demo login: `admin@demo.com` / `admin123`.

## Build

```bash
scripts/build.sh pi  [release|profile|debug]   # -> dist/pi/
scripts/build.sh web [release|profile|debug]   # -> dist/web/
```

Mode defaults to `release`.

- **pi** needs `flutterpi_tool`: `flutter pub global activate flutterpi_tool`.
  Targets Pi OS Lite 64-bit (`--arch=arm64 --cpu=pi3`). See
  [Run on the Raspberry Pi](#run-on-the-raspberry-pi) for deploying.
- **web** is built for the site root (`/`) with path URLs (`/products`, not
  `/#/products`). The server must serve `index.html` for unknown paths, e.g.
  nginx: `try_files $uri $uri/ /index.html;`.

Other targets use the standard Flutter commands: `flutter build apk`,
`flutter build linux`, `flutter build windows`.

## Run on the Raspberry Pi

All commands run **on the dev machine** and reach the Pi over SSH. Set these
once per terminal (change them to match your Pi):

```bash
PI=pi@raspberrypi.local   # user@host of the Pi
APP=flutter_app           # install folder, relative to the Pi user's home
```

### One-time Pi setup

The Pi must boot to the **console**, not a desktop, so flutter-pi can take over
the display: `sudo raspi-config` → System Options → Boot / Auto Login →
Console Autologin. Then install the runtime libraries and give your user access
to the GPU and input devices:

```bash
ssh $PI 'sudo apt-get update && sudo apt-get install -y \
  libdrm2 libgbm1 libegl1 libgles2 libinput10 libxkbcommon0 libudev1 \
  libsystemd0 libatomic1 fontconfig fonts-dejavu-core'
ssh $PI 'sudo usermod -aG render,video,input $USER && sudo reboot'
```

### Deploy (scp)

Build, stop the running app, replace the old copy, then start it again:

```bash
scripts/build.sh pi
ssh $PI "pkill -x flutter-pi; rm -rf ~/$APP"
scp -rp dist/pi $PI:~/$APP
```

Delete the old folder first: if `~/$APP` already exists, `scp -r` copies into
it as `~/$APP/pi/` instead of replacing it.

### Start

In the background (keeps running after you close the terminal; output goes to
`~/$APP.log`):

```bash
ssh $PI "cd ~/$APP && LD_LIBRARY_PATH=\$PWD nohup ./flutter-pi --release \$PWD > ~/$APP.log 2>&1 < /dev/null &"
```

Or in the foreground, with logs in your terminal. Ctrl+C stops the app:

```bash
ssh -t $PI "cd ~/$APP && LD_LIBRARY_PATH=\$PWD ./flutter-pi --release \$PWD"
```

The `--release` flag must match the build mode: use `--profile` or `--debug`
for `scripts/build.sh pi profile` or `scripts/build.sh pi debug`.

### Stop

```bash
ssh $PI 'pkill -x flutter-pi'
```

### Restart

Stop, wait for the old process to exit, then start again:

```bash
ssh $PI 'pkill -x flutter-pi; while pgrep -x flutter-pi >/dev/null; do sleep 0.2; done'
ssh $PI "cd ~/$APP && LD_LIBRARY_PATH=\$PWD nohup ./flutter-pi --release \$PWD > ~/$APP.log 2>&1 < /dev/null &"
```

### Check status and logs

```bash
ssh $PI 'pgrep -a flutter-pi'     # prints the process if it is running
ssh $PI "tail -f ~/$APP.log"      # follow the log (background start only)
ssh $PI "ldd ~/$APP/flutter-pi | grep 'not found'"   # missing libs; should print nothing
```

The app does not start by itself after a Pi reboot; run the start command
again.

## Structure

```
lib/
  main.dart        loads saved settings, starts the app
  app.dart         providers + MaterialApp.router
  router.dart      go_router routes, login redirect, navigation destinations
  models/          plain data classes (Product)
  state/           ChangeNotifiers: auth (in-memory), settings (saved), products
  pages/           one file per screen
  widgets/         app shell (drawer/sidebar) and shared widgets
  theme/           ThemeData
  utils/           validators, platform info (web-safe)
test/              unit + widget tests (flutter test)
scripts/build.sh   pi / web release builds
```

- **State:** `provider`. Read with `context.watch<T>()` or
  `context.select<T, R>()` in build, and `context.read<T>()` in callbacks.
- **Navigation:** `go_router`. To add a page, add one `Destination` in
  `router.dart`. Switching pages disposes the old one, which keeps RAM low on
  the Pi. Shared data lives in `state/`, not in pages.
- **Persistence:** only theme mode and seed colour (`shared_preferences`).
  Login and products reset on restart.
- **Plugins:** before adding a package, check that pub.dev lists **Linux**
  support, or it won't work on the Pi.
