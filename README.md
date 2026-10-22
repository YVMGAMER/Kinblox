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
