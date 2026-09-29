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

## CI (GitHub Actions)

[`.github/workflows/flutter-app.yml`](../.github/workflows/flutter-app.yml)
runs on every push to `main` and every pull request that touches
`flutter-app/`:

1. **Analyze & test:** format check, `flutter analyze`, `flutter test`.
2. **Build web** and **Build pi** (in parallel, only if step 1 passes): runs
   `scripts/build.sh`, uploads `flutter_app-web-release.tar.gz` and
   `flutter_app-pi-release.tar.gz` as artifacts (kept 14 days).

To build a `profile` or `debug` bundle: Actions tab → flutter-app →
**Run workflow** → pick the mode.

To deploy a CI build instead of a local one, download the artifact from the
run page (or `gh run download -n flutter_app-pi-release`), then:

```bash
unzip flutter_app-pi-release.zip            # GitHub wraps artifacts in a zip
tar -xzf flutter_app-pi-release.tar.gz      # -> pi/
ssh $PI "pkill -x flutter-pi; rm -rf ~/$APP"
scp -rp pi $PI:~/$APP
```

(`gh run download` unzips for you; skip the `unzip` step.)

Flutter (`3.47.5`) and flutterpi_tool (`0.12.0`) versions are pinned at the
top of the workflow. Bump them there when you upgrade locally.

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

## On-screen keyboard (Pi)

flutter-pi draws straight to the display with no desktop, so the OS on-screen
keyboard (squeekboard/wvkbd) cannot appear. The Pi build draws its own keyboard
inside the app instead.

- **When it opens:** when a text field is focused **by touch**. Focusing with a
  mouse click or Tab does not open it; using the mouse or a physical key while
  it is open hides it. A physical keyboard keeps working either way.
- **Layouts:** QWERTY with shift (double tap = caps lock), two symbol pages,
  and a number pad for number/phone fields (`ABC` switches to letters).
  Follows each field's capitalization, enter action (done / next / search),
  and input formatters.
- **Languages** (🌐 key; last choice is remembered): English and 9 Indic
  scripts: Devanagari (Hindi, Marathi, Nepali, Sanskrit…), Bengali (Bengali,
  Assamese, Manipuri), Gurmukhi (Punjabi), Gujarati, Odia, Tamil, Telugu,
  Kannada, Malayalam. The first page has vowel signs and consonants; the
  vowel key (e.g. `अ`) opens independent vowels, native digits and
  script-specific letters. Backspace removes one character at a time
  (e.g. the vowel sign, not the whole syllable).
- **Only in the Pi build:** `scripts/build.sh pi` passes
  `--dart-define=ON_SCREEN_KEYBOARD=true`. Android, web and desktop use their
  system keyboards; the keyboard code is not compiled into those builds.
- **Fonts:** the Pi has neither Roboto nor Indic fonts, so both are bundled:
  Roboto (~0.5 MB, the app font on every platform) and Noto Sans for each
  script (~1.4 MB, font fallback). This applies to all builds, so web also
  downloads them on first load.

## Structure

```
lib/
  main.dart        loads saved settings, starts the app
  app.dart         providers + MaterialApp.router
  router.dart      go_router routes, login redirect, navigation destinations
  models/          plain data classes (Product)
  state/           ChangeNotifiers: auth (in-memory), settings (saved), products,
                   on-screen keyboard (TextInputControl)
  pages/           one file per screen
  widgets/         app shell (drawer/sidebar), on-screen keyboard, shared widgets
  theme/           ThemeData
  utils/           validators, platform info (web-safe), keyboard layouts
assets/fonts/      Roboto (Apache 2.0) + Noto Sans for 9 Indic scripts (SIL OFL)
test/              unit + widget tests (flutter test)
scripts/build.sh   pi / web release builds
```

- **State:** `provider`. Read with `context.watch<T>()` or
  `context.select<T, R>()` in build, and `context.read<T>()` in callbacks.
- **Navigation:** `go_router`. To add a page, add one `Destination` in
  `router.dart`. Switching pages disposes the old one, which keeps RAM low on
  the Pi. Shared data lives in `state/`, not in pages.
- **Persistence:** only theme mode, seed colour and the on-screen keyboard
  language (`shared_preferences`).
  Login and products reset on restart.
- **Plugins:** before adding a package, check that pub.dev lists **Linux**
  support, or it won't work on the Pi.
