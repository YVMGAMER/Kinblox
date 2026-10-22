# Kinblox

An original falling-block puzzle game for phones, with **Color Chain**: touching
same-colored blocks from different pieces become "kin" and cascade away after a
line clear. Built with Godot 4.7 (typed GDScript), portrait, 2D.

Made by Yash.

- Design, rules and tuning: [docs/DESIGN.md](docs/DESIGN.md)
- Credits and asset sources: [docs/CREDITS.md](docs/CREDITS.md)
- Ideas not in the MVP: [docs/ROADMAP.md](docs/ROADMAP.md)

## Run

1. Install Godot **4.7** (standard build).
2. Open `project.godot` in the editor and press **Play** (F5), or from a shell:
   ```
   godot --path .
   ```
On desktop the mouse emulates touch, and the keyboard works too: arrows/WASD
move, Up/X rotate, Z rotate back, Space hard drop, C or Shift hold, Esc pause.

## Test

Unit tests use a small built-in runner (no plugins needed):

```
godot --headless --path . --import        # first run / after adding classes
godot --headless --path . -s tests/run_all.gd
```

The runner prints each test and exits with code 0 on success, 1 on failure.

A UI smoke test opens every screen and presses every button (including the
pause, results and confirmation sheets that buttons open), using a throwaway
save file:

```
godot --headless --path . -s tests/ui_smoke.gd
```

It ends with `UI smoke: N jobs, M button presses, done`; any `SCRIPT ERROR`
in its output is a failure.
Suites live in `tests/test_*.gd` and cover collision, rotation and kicks for
every piece, line clears, 7-bag fairness, chain resolution (multi-step),
scoring, lock-delay reset cap, Daily seed determinism, sessions (hold, pause
during line clear, game over, Zen sweep) and save-file corruption fallback.

## Tools

```
godot --headless --path . -s tools/generate_audio.gd   # regenerate all audio
godot --path . -s tools/capture.gd -- --screen=game --pieces=40 --out=shot.png
```

`capture.gd` renders any screen at 1080x1920 (or `--size=WxH`) to PNG, with
options for theme, mode, button layout, and a bot that plays a few pieces.

## Export

`export_presets.cfg` contains an **Android** and an **iOS** preset. Package /
bundle id `com.kincal.kinblox`, version name `1.0.0`, version code `1`.
Signing fields are deliberately blank; Godot stores credentials you enter in
`.godot/export_credentials.cfg`, which is git-ignored. First install the
export templates for your exact Godot version: **Editor → Manage Export
Templates → Download and Install**.

### Android (AAB for Google Play)

1. **JDK 17.** Install a JDK 17 build (Temurin, Zulu or Corretto all work).
2. **Android SDK.** Install Android Studio (or the command-line tools) and,
   through the SDK Manager, install *Platform-Tools*, *Build-Tools*, the
   *Android 16 (API 36)* platform, *CMake* and the *NDK* at the versions that
   Godot's "Exporting for Android" page lists for your Godot release.
   Example with the command-line tools:
   ```
   sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0" "cmake;3.10.2.4988404" "ndk;28.1.13356709"
   ```
3. **Point Godot at them:** *Editor → Editor Settings → Export → Android*:
   set **Java SDK Path** (the JDK 17 folder) and **Android SDK Path**.
4. **Install the build template:** *Project → Install Android Build
   Template…* This creates `android/` (git-ignored; reinstall it on a fresh
   clone). The preset already has **Use Gradle Build** on, which is required
   for AAB output and for setting the target SDK.
5. **Create an upload keystore** (keep it and its passwords safe and out of
   git — `*.keystore` and `*.jks` are ignored):
   ```
   keytool -genkeypair -v -keystore kinblox-upload.keystore -alias kinblox -keyalg RSA -keysize 2048 -validity 10000
   ```
6. **Fill in signing:** *Project → Export → Android → Keystore → Release*:
   path to the keystore, alias (`kinblox`) and password.
7. **Check the preset:** Export Format **Android App Bundle**, **Target SDK
   36** (Google Play requires new apps and updates to target Android 16 /
   API 36 since 31 August 2026; raise it when Google raises the bar),
   Min SDK 24, architectures arm64-v8a (+ armeabi-v7a), permission
   **Vibrate** on (haptics). No Internet permission: the MVP has no network
   access.
8. **Export:** *Export Project…* (uncheck *Export With Debug*) to
   `build/android/kinblox.aab`, or from a shell:
   ```
   godot --headless --path . --export-release "Android" build/android/kinblox.aab
   ```
9. Upload the `.aab` in the Play Console and enroll in Play App Signing.

### iOS

iOS builds need **a Mac with Xcode** (current App Store requirements apply) and
an **Apple Developer Program** membership.

1. On the Mac, install Godot 4.7 and its export templates, and open the
   project.
2. In the Apple Developer portal, register the App ID **com.kincal.kinblox**,
   and create a distribution certificate and an **App Store provisioning
   profile** for it (Xcode can manage these automatically).
3. *Project → Export → iOS*: set **App Store Team ID** (the 10-character Team
   ID from your developer account), and the provisioning profile UUID or
   leave it empty to let Xcode sign automatically. Export method Release is
   *App Store*. Targeted family is iPhone and iPad; minimum iOS 14.
4. Export. Godot produces an Xcode project (and an `.ipa` if signing
   succeeds). Open the `.xcodeproj`, check signing under *Signing &
   Capabilities*, then **Product → Archive** and upload through the
   Organizer to App Store Connect.

### Native share sheet

Godot has no built-in share sheet. Out of the box, "Share result" copies the
text to the clipboard. If you add a share plugin that registers an engine
singleton named `GodotShare` or `Share` (method `shareText(title, subject,
text)`) or `NativeShare` (method `share_text(text)`), Kinblox uses it
automatically — see `scripts/ui/share_service.gd`.

## Project layout

```
autoload/      GameState, Settings, SaveData, AudioManager, ThemeManager, Haptics
scenes/        main.tscn, screens/, game/
scripts/core/  pure game logic (no nodes), unit tested
scripts/modes/ ModeConfig
scripts/ui/    screens and views
scripts/fx/    particles, pop-ups, shake, feedback, synth
themes/        GameTheme + Ink, Paper, Glacier, Ember
assets/        fonts/, audio/, icons/, data/tuning.tres
tests/         headless unit tests
tools/         audio generator, screenshot capture
docs/          design, credits, roadmap
```
