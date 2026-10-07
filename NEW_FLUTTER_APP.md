# Creating a new Flutter app (Raspberry Pi ready)

This guide sets up a new Flutter app the same way as [`flutter-app/`](flutter-app/):
one codebase for Android, web, Linux, Windows and the Raspberry Pi Zero 2 W
(through [flutter-pi](https://github.com/ardera/flutter-pi)).

- **Part 1** creates the app and works on its own, in any repository.
- **Part 2** adds the extra steps for putting it inside the `chota-pos` npm
  workspace monorepo.

`flutter-app/` is the reference implementation. Most steps copy files from it,
so keep this repository checked out next to the place where you create the
new app.

## What you get on top of `flutter create`

`flutter create` gives you an empty app. These steps add:

| Added | Why |
|---|---|
| Pi build with `flutterpi_tool` | The Pi runs the app with flutter-pi, not `flutter build linux` |
| On-screen keyboard (Pi build only) | flutter-pi has no desktop, so the system keyboard cannot appear |
| Bundled fonts: Roboto + Noto Sans for 9 Indic scripts | Pi OS Lite has neither, so text would fall back or show as boxes |
| No page transitions, old pages disposed on navigation | Less GPU and RAM use on the Pi |
| `go_router` + `provider` app structure, login redirect, saved settings | Same layout in every app, so adding a page is one line |
| Path URLs on web (`/home`, not `/#/home`) | Clean web URLs |
| `scripts/build.sh pi\|web` | One command per target, output in `dist/<target>/` |
| GitHub Actions workflow | Format check, analyze and test on every push, plus web and Pi builds |

The `android/`, `linux/`, `web/` and `windows/` folders stay exactly as
`flutter create` makes them.

## Prerequisites

- **Flutter 3.47.5** (includes Dart 3.13.4). Check with `flutter --version`.
- **flutterpi_tool**, pinned to the commit that supports Flutter 3.47:

  ```bash
  flutter pub global activate --source git https://github.com/ardera/flutterpi_tool \
    --git-ref 248d79914b84ce89b44435ad8f104e81a37e1ffc
  ```

  The pub.dev release (0.12.0) does not compile against Flutter 3.47. When a
  newer release supports your Flutter version, switch to
  `flutter pub global activate flutterpi_tool <version>`.
  flutterpi_tool must always match the Flutter version: upgrade both together.
- A Linux machine for the Pi build. Windows builds need a Windows machine.

---

# Part 1: Create the app

The examples use these names. Replace them with your own:

| Name | Example | Rule |
|---|---|---|
| Folder | `chotapos-flutter` | Anything |
| Dart package name | `chotapos_flutter` | Lowercase letters, digits and `_` only |
| Org (reverse domain) | `com.chotapos` | Becomes the Android app id: `com.chotapos.chotapos_flutter`. Do not use `com.example`; Google Play rejects it |

Set two shell variables first; later steps use them:

```bash
SRC=/path/to/pi-flutter-demo/flutter-app   # the reference app
APP=chotapos-flutter                       # the new app's folder
```

## Step 1: Generate the project

```bash
flutter create \
  --org com.chotapos \
  --project-name chotapos_flutter \
  --platforms android,linux,web,windows \
  --description "Chota POS Flutter app: Android, web, Linux, Windows and Raspberry Pi (flutter-pi)." \
  "$APP"
cd "$APP"
rm lib/main.dart test/widget_test.dart   # replaced in later steps
```

There is no "pi" platform. On the Pi the app runs on flutter-pi, which uses
Flutter's Linux engine, so no extra platform folder is needed.

## Step 2: Set the web title

In `web/index.html`, set `<title>` and `apple-mobile-web-app-title` to the
app's display name (for example `Chota POS`). In `web/manifest.json`, set
`name`, `short_name` and `description`.

## Step 3: Dependencies and fonts

Edit `pubspec.yaml`:

1. Set `version: 0.1.0+1`.
2. Replace the `dependencies:` block:

   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     flutter_web_plugins:
       sdk: flutter
     go_router: ^18.0.2
     provider: ^6.1.5+1
     shared_preferences: ^2.5.5
   ```

3. Replace the `flutter:` section with the one from `$SRC/pubspec.yaml`. It
   keeps `uses-material-design: true` and adds the `fonts:` list (Roboto and
   the nine `NotoSans*` families).

Copy the font files and fetch packages:

```bash
cp -r "$SRC/assets" .
flutter pub get
```

**Plugin rule:** before adding any package, check that pub.dev lists
**Linux** support. flutter-pi uses the Linux embedding, so a plugin that only
supports Android, iOS or web will fail on the Pi.

## Step 4: Analyzer and git ignore

```bash
cp "$SRC/analysis_options.yaml" .
printf '\n# Build script output\n/dist/\n' >> .gitignore
```

`analysis_options.yaml` stops `flutter analyze` from scanning the generated
platform folders and `build/`.

## Step 5: App code

Copy the app skeleton from the reference app:

```bash
mkdir -p lib/pages lib/state lib/theme lib/utils lib/widgets
cp "$SRC"/lib/{main,app,router}.dart lib/
cp "$SRC"/lib/pages/{login,settings}_page.dart lib/pages/
cp "$SRC"/lib/state/{auth_state,settings_state,on_screen_keyboard}.dart lib/state/
cp "$SRC"/lib/theme/app_theme.dart lib/theme/
cp "$SRC"/lib/utils/{validators,platform_info,platform_info_io,platform_info_web,keyboard_layouts}.dart lib/utils/
cp "$SRC"/lib/widgets/{home_shell,section,on_screen_keyboard}.dart lib/widgets/
```

The demo pages (dashboard, components, forms, dialogs, lists, products) and
`ProductStore` are left out on purpose. Then make three edits:

**`lib/app.dart`:** remove the `ProductStore` import, the `_products` field,
`_products.dispose()`, and its `ChangeNotifierProvider`. Change `title:` to
your app's name.

**`lib/pages/home_page.dart`:** create a starting page:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../widgets/section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthState, String>((a) => a.user ?? '');

    return PageBody(
      children: [
        Text(
          'Hello, ${user.split('@').first}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        const Section(title: 'Getting started', child: Text('Build here.')),
      ],
    );
  }
}
```

**`lib/router.dart`:** replace the demo page imports with
`import 'pages/home_page.dart';`, keep `login_page.dart` and
`settings_page.dart`, and cut the list down to two entries:

```dart
const destinations = <Destination>[
  Destination('/home', 'Home', Icons.home_outlined, Icons.home, HomePage()),
  Destination(
    '/settings',
    'Settings',
    Icons.settings_outlined,
    Icons.settings,
    SettingsPage(),
  ),
];

const loginPath = '/login';
const homePath = '/home';
```

Leave the rest of `router.dart` as it is. The `NoTransitionPage` and plain
`ShellRoute` are deliberate: no animations saves the Pi's GPU, and switching
pages disposes the old one to keep RAM low.

### How the code is organised

```
lib/
  main.dart        loads saved settings, turns on path URLs for web, starts the app
  app.dart         providers + MaterialApp.router (+ on-screen keyboard on Pi)
  router.dart      routes, login redirect, the side-navigation list
  state/           ChangeNotifiers: auth, settings (saved), on-screen keyboard
  pages/           one file per screen
  widgets/         app shell (drawer/sidebar), Section/PageBody, on-screen keyboard
  theme/           ThemeData
  utils/           validators, web-safe platform info, keyboard layouts
```

- **Add a page:** create it in `pages/`, then add one `Destination` in
  `router.dart`. The sidebar and the route both come from that list.
- **Shared data** lives in `state/` as a `ChangeNotifier` provided in
  `app.dart`, never in a page (pages are disposed when you navigate away).
- **Login** (`AuthState`) checks fixed demo credentials
  (`admin@demo.com` / `admin123`). Replace `AuthState.login` with a real API
  call.
- **On-screen keyboard** is compiled in only when the build passes
  `--dart-define=ON_SCREEN_KEYBOARD=true`, which `scripts/build.sh pi` does.
  Other builds use the system keyboard.

## Step 6: Tests

```bash
cp "$SRC"/test/{keyboard_test,validators_test,state_test,app_test}.dart test/
```

Then:

1. Change the package name in the test imports:

   ```bash
   sed -i 's#package:flutter_app/#package:chotapos_flutter/#g' test/*.dart
   ```

   (Files in `lib/` use relative imports, so they need no change.)
2. In `test/state_test.dart`, delete the `ProductStore` import and the
   `group('ProductStore', ...)` block.
3. In `test/app_test.dart`, keep the login part and change the rest: after
   login expect `Hello, admin`, then open the drawer and tap **Settings**
   instead of **Products**, and check for a widget on the settings page in
   place of `SKU-0001`.

## Step 7: Build script

```bash
mkdir -p scripts
cp "$SRC/scripts/build.sh" scripts/
chmod +x scripts/build.sh
```

The script needs no edits. It works from any directory:

```bash
scripts/build.sh pi  [release|profile|debug]   # -> dist/pi/
scripts/build.sh web [release|profile|debug]   # -> dist/web/
```

- **pi:** `flutterpi_tool build --arch=arm64 --cpu=pi3` (Pi Zero 2 W has
  the same Cortex-A53 as the Pi 3), with the on-screen keyboard turned on.
  The result in `dist/pi/` includes the `flutter-pi` binary, so the Pi needs
  no Flutter install.
- **web:** `flutter build web --base-href /` for hosting at the site root.
  The web server must serve `index.html` for unknown paths (nginx:
  `try_files $uri $uri/ /index.html;`).

Android, Linux and Windows use the normal Flutter commands
(`flutter build apk`, `flutter build linux`, `flutter build windows`).

## Step 8: Check it works

```bash
dart format lib test
flutter analyze            # expect: No issues found!
flutter test               # expect: All tests passed!
flutter run -d linux       # log in, open Settings, change the theme, restart: theme is kept
scripts/build.sh web
scripts/build.sh pi
```

## Step 9: CI (standalone repository)

Copy [`.github/workflows/flutter-app.yml`](.github/workflows/flutter-app.yml)
to the new repository's `.github/workflows/` and change:

- the `paths:` filters and `defaults.run.working-directory` to the app folder,
- the `flutter_app-` prefix in the `Package` and `upload-artifact` steps to
  your package name.

Keep `FLUTTER_VERSION` and `FLUTTERPI_TOOL_REF` matched with what you use
locally. (In the monorepo, use Part 2, step 5 instead.)

## Step 10: README

Copy `$SRC/README.md` and update it: names, the `APP=` folder variable, and
the "Structure" section. Drop the parts about the demo pages. Keep the
Raspberry Pi sections; they apply unchanged:

- **One-time Pi setup:** boot to console (not desktop), install `libdrm2
  libgbm1 libegl1 libgles2 libinput10 libxkbcommon0 libudev1 libsystemd0
  libatomic1 libvulkan1 libgstreamer1.0-0 libgstreamer-plugins-base1.0-0
  fontconfig fonts-dejavu-core`, and add the user to the `render,video,input`
  groups. flutter-pi links GStreamer and Vulkan even if the app uses neither,
  so it won't start without them.
- **Deploy:** `ssh $PI "pkill -x flutter-pi; rm -rf ~/$APP"` then
  `scp -rp dist/pi $PI:~/$APP`. Remove the old folder first, or `scp` nests
  the new copy inside it.
- **Start:** `cd ~/$APP && LD_LIBRARY_PATH=$PWD ./flutter-pi --release $PWD`.
  The flag (`--release`, `--profile`, `--debug`) must match the build mode.

---

# Part 2: Add it to the chota-pos monorepo

`chota-pos` is an npm workspace monorepo (`apps/*`, `bandi/*`, `packages/*`,
`documentation`). A Flutter app is not an npm package, so it joins the
monorepo the same way as `apps/chotapos-billing-cpp-qt`: it sits in `apps/`,
has **no `package.json`**, and root npm scripts drive it.

Run every command below from the `chota-pos` root.

## Step 1: Create a branch

```bash
git switch test && git pull
git switch -c feat/chotapos-flutter
```

## Step 2: Create the app under `apps/`

Follow Part 1, steps 1 to 8, with the app folder at `apps/chotapos-flutter`:

```bash
APP=apps/chotapos-flutter
```

**Do not add a `package.json` to the app.** npm only treats a folder matched
by `apps/*` as a workspace if it contains a `package.json`. Without one,
`npm install` and `npm run <x> --workspaces` skip it.

## Step 3: Add root npm scripts

In the root `package.json` `scripts`, next to the
`*:chotapos-billing-cpp-*` entries:

```json
"dev:chotapos-flutter": "cd apps/chotapos-flutter && flutter run -d linux",
"test:chotapos-flutter": "cd apps/chotapos-flutter && flutter analyze && flutter test",
"build:chotapos-flutter-pi": "bash apps/chotapos-flutter/scripts/build.sh pi",
"build:chotapos-flutter-web": "bash apps/chotapos-flutter/scripts/build.sh web",
```

Pass a mode after `--`, for example `npm run build:chotapos-flutter-pi -- profile`.

## Step 4: Keep root tooling away from Flutter files

| File | Change | Why |
|---|---|---|
| `.prettierignore` | Add a line `.dart_tool` | The root `format` script passes `--ignore-path .prettierignore`, which turns off `.gitignore`. Without this line, Prettier rewrites the JSON files in `.dart_tool/` |
| `.gitattributes` | None | `*.sh text eol=lf` already covers `scripts/build.sh` (CRLF line endings would break it on Linux) |
| `.gitignore` | None | Root already ignores `dist`. The app's own `.gitignore` covers `build/`, `.dart_tool/` and the rest |
| `.husky/pre-commit`, ESLint | None | They only run inside the JS workspaces |

Optional: to check Dart formatting before each commit, add this line to
`.husky/pre-commit`:

```bash
dart format --output=none --set-exit-if-changed apps/chotapos-flutter/lib apps/chotapos-flutter/test
```

## Step 5: CI workflow

Copy the workflow from this repository to
`.github/workflows/chotapos-flutter.yml` in `chota-pos` and change:

```yaml
name: chotapos-flutter

on:
  push:
    branches: [main, test]
    paths:
      - 'apps/chotapos-flutter/**'
      - '.github/workflows/chotapos-flutter.yml'
  pull_request:
    paths:
      - 'apps/chotapos-flutter/**'
      - '.github/workflows/chotapos-flutter.yml'
  workflow_dispatch: # keep the mode input as it is

defaults:
  run:
    working-directory: apps/chotapos-flutter
```

In the `build` job, change the `flutter_app-` prefix to `chotapos_flutter-`
in the `Package` step, the artifact `name`, and the artifact `path` (which
becomes `apps/chotapos-flutter/chotapos_flutter-...tar.gz`).

The `paths:` filter keeps this workflow from running on backend or frontend
changes, and keeps the existing workflows from running on Flutter changes.
This workflow only builds and uploads artifacts. Wiring it into the S3
release workflows (`s3-release-*.yml`) is a separate step.

## Step 6: Check the integration

```bash
npm run test:chotapos-flutter
npm run build:chotapos-flutter-web
npm run build:chotapos-flutter-pi
npm query .workspace | grep chotapos-flutter       # prints nothing: not an npm workspace
npm run format:check                               # no .dart_tool files listed
git status                                         # no build/, dist/ or .dart_tool/ files
```

Then commit, push the branch and open a pull request into `test`. Check that
the `chotapos-flutter` workflow runs and goes green.

---

## Troubleshooting

| Symptom | Cause and fix |
|---|---|
| `Failed to build flutterpi_tool` with `Error when reading .../flutter_tools/lib/src/...` | flutterpi_tool does not match the Flutter version. Install the matching version or git ref (see Prerequisites), locally and in the workflow |
| `pub get` fails with "The current Dart SDK version is X" | Flutter is older than the `sdk:` constraint in `pubspec.yaml` (`^3.13.4` = Flutter 3.47.x). Upgrade Flutter |
| A plugin works on Android or web but crashes on the Pi | The plugin has no Linux support. Pick one that lists Linux on pub.dev |
| Text on the Pi shows boxes or the wrong font | A font is missing from `assets/fonts/` or the `fonts:` list in `pubspec.yaml` |
| No keyboard appears on the Pi | The build did not pass `--dart-define=ON_SCREEN_KEYBOARD=true`. Build with `scripts/build.sh pi`. The keyboard opens only when a field is focused by touch |
| Web page 404s after a refresh | The web server does not fall back to `index.html` for unknown paths |
| After `scp`, the app is in `~/$APP/pi/` | The old folder still existed. Delete it before copying |
