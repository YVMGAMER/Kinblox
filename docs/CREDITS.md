# Credits

**Kinblox** — Made by Yash.

## Font

- **Manrope** (variable, `assets/fonts/Manrope-Variable.ttf`)
  Copyright 2018 The Manrope Project Authors (https://github.com/googlefonts/manrope).
  Licensed under the SIL Open Font License 1.1 — full text in `assets/fonts/OFL.txt`.
  Source: https://github.com/google/fonts/tree/main/ofl/manrope

## Audio

Every sound effect and both music loops in `assets/audio/` are **generated
procedurally by this project** — no samples, recordings or third-party audio.
They are rendered by `tools/generate_audio.gd` using the small synthesizer in
`scripts/fx/synth.gd` (sine/triangle oscillators, filtered noise, pitch sweeps,
exponential envelopes). Regenerate them at any time with:

```
godot --headless --path . -s tools/generate_audio.gd
```

The output is deterministic and is released with the game under the same terms
as the rest of the project.

| File | Description |
|---|---|
| `sfx_move.wav` | short soft tick |
| `sfx_soft_drop.wav` | quiet low tick |
| `sfx_rotate.wav` | glassy D6 "tock" |
| `sfx_lock.wav` | low thump with a soft click |
| `sfx_hard_drop.wav` | falling sine thud plus noise |
| `sfx_hold.wav` | two-note A5 → D6 triangle |
| `sfx_clear.wav` | D–F#–A bell arpeggio |
| `sfx_clear_quad.wav` | five-note bell arpeggio with low D |
| `sfx_chain.wav` | A5 bell plus fifth; pitched up each chain step |
| `sfx_level_up.wav` | rising pentatonic arpeggio |
| `sfx_game_over.wav` | falling arpeggio over a low pad |
| `sfx_zen_sweep.wav` | airy noise swell |
| `sfx_ui_tap.wav`, `sfx_ui_back.wav` | UI clicks |
| `sfx_countdown.wav` | single triangle note |
| `music_ambient.wav` | 32 s seamless loop: Dmaj9 – Bm9 – Gmaj9 – A6sus pads with pentatonic bells |
| `music_zen.wav` | 40 s seamless loop: slower, sparser variation for Zen |

## Icons

All icons in `assets/icons/` and the app icon (`icon.svg`) were drawn for
Kinblox as hand-written SVG and are original to this project.

## Engine

Built with the Godot Engine (MIT license), https://godotengine.org.
