# Kinblox — Design

Kinblox is an original falling-block puzzle game for phones, portrait, built in
Godot 4 with typed GDScript. Its twist is **Color Chain**: same-colored blocks
from different pieces that touch are "kin", and a line clear makes kin groups
detonate in cascading chains.

## Pillars

1. **Feels great on a touchscreen.** Gestures that never misfire, plus a full
   on-screen button layout for players who prefer it.
2. **One honest twist.** Color Chain adds a second layer of planning (where to
   put colors) without changing the core loop (clear lines).
3. **Calm, premium presentation.** Minimal UI, one typeface, restrained motion,
   generated audio in one musical key.
4. **Fair and deterministic.** Daily runs are identical for every player.

## Architecture

```
scripts/core/   pure logic, no nodes  ->  testable headlessly
  Board, Piece, PieceDefs, Bag, SeededRng, Scoring, ChainResolver,
  GameRules, GameSession (state machine), Tuning, DailyCalendar, SaveStore
scripts/modes/  ModeConfig: the only thing that differs between modes
scripts/ui/     views and screens (observe the session through signals)
scripts/fx/     particles, pop-ups, shake, banners, audio/haptic feedback, synth
autoload/       GameState, Settings, SaveData, AudioManager, ThemeManager, Haptics
themes/         GameTheme resource + 4 theme .tres files
```

- `GameSession` is a `RefCounted` state machine:
  `READY → PLAYING → LINE_CLEAR → CHAIN → PLAYING … → GAME_OVER`, with `PAUSED`
  storing the state it interrupted. Animation pauses (line flash, chain
  highlight, Zen sweep) are *states with timers inside the session*, so pausing
  or backgrounding mid-animation can never corrupt the board.
- Views (`BoardView`, `PieceView`, `GhostView`, `PiecePreviewView`) only read
  the session and redraw on its signals. `GameFeedback` (audio/haptics) and
  `GameJuice` (particles, pop-ups, shake, banners) are pure observers too.
- Input sources (gestures, button pad, keyboard) all go through `InputRouter`,
  which owns DAS/ARR auto-repeat.
- Every mode is the same `GameSession` configured by a `ModeConfig`
  (`classic()`, `zen()`, `daily()`), never a copy.

## Rules

- 10 × 20 visible field plus 2 hidden spawn rows.
- Pieces: the seven 4-cell shapes (I O T S Z J L) plus three originals that
  unlock with level: **Corner** (3-cell elbow, level 4), **Trio** (3-cell
  straight, level 6), **Cross** (5-cell plus, level 9, rare). All shapes are
  data in `PieceDefs.DEFS`; rotation states are derived by rotating in the
  piece's box.
- Rotation: SRS-style kick tables for the standard pieces (I has its own
  table), simple kicks (stay, ±1 sideways, one up) for the originals. At most
  `floor_kick_limit` upward kicks per piece.
- Randomizer: 7-bag. Unlocked originals are shuffled into a bag at a fixed
  per-bag chance. The bag always draws its RNG values in the same order, so the
  standard sequence does not depend on what is unlocked.
- Lock delay 0.5 s; each move/rotate while the countdown runs resets it, up
  to 15 times; reaching a new lowest row restores the budget (no infinite
  stalling, no punishment for normal play).
- Hold once per piece. Next queue of 3. Ghost piece (toggle).
- Game over when a new piece cannot spawn (Zen sweeps instead).

## Color Chain

After a line clear resolves, the board is scanned for **kin groups**:
orthogonally connected cells of the same color slot, with

- at least **4 cells**, and
- cells from at least **2 different pieces**.

The second condition matters: every 4-cell piece is itself 4 connected
same-colored cells, so without it every intact piece would explode. Each cell
remembers the piece that placed it (`Board.owners`) to make this check
possible.

Resolution, one step at a time:

1. Highlight the groups (0.45 s pulse, chain sound pitched up a pentatonic
   step, counter "CHAIN ×n").
2. Remove them. Within each column, everything above a removed cell drops to
   fill it (existing holes keep their shape — no full "sand" gravity).
3. Rows completed by the fall are cleared as **cascade lines**.
4. Re-scan. Another group means the next step with a higher multiplier.

Design intent: kin groups can sit on the board "charged" for a long time and
only detonate when a line clear triggers the scan. Building kin next to a line
you are about to clear is the skill. Chains also dig out holes, which helps
recovery, so they reward good play twice.

Everything is a pure function of the board (`ChainResolver`), scanned in a
fixed order, so chains are deterministic — required for Daily fairness. Color
matching uses **logical color slots** (`PieceDefs.color`), never theme colors,
so switching themes can never change a result. The three original pieces share
slot 7 so they are kin to each other.

Setting **Color Chain: Off** gives a "Pure" classic variant with its own high
score table (`classic_pure`). Daily always uses chains so all players share
identical rules.

## Scoring

| Event | Points |
|---|---|
| Single / Double / Triple / Quad | 100 / 300 / 500 / 800 × level |
| Back-to-back Quad | × 1.5 |
| Combo (consecutive clearing pieces) | + 50 × combo × level |
| Soft drop / hard drop | 1 / 2 per row |
| Chain step *n* | 10 × cells × multiplier × level, multiplier = min(1 + n, 8) |
| Cascade lines (inside a chain) | line value × level (no multiplier) |

Level = 1 + lines / 10.

## Tuning

All constants live in one resource, `Tuning` (`scripts/core/tuning.gd`,
shipped values in `assets/data/tuning.tres`). Reasoning:

- **Gravity curve.** The familiar `(0.8 − (L−1)·0.007)^(L−1)` seconds-per-row
  curve is tuned for keyboards; on touch it becomes unplayable around level
  12. Kinblox compresses the level (`gravity_level_scale = 0.7`) and floors at
  `0.033 s/row` (30 rows/s). Level 1 is 1.0 s/row, level 10 ≈ 0.17 s, level 15
  ≈ 0.047 s, level 20+ hits the floor. That keeps the late game intense but
  reachable with thumbs.
- **Lock delay 0.5 s, 15 resets, 4 floor kicks.** Generous enough for touch
  latency (a tap is only recognized on release), strict enough that stalling
  is impossible.
- **Chain multiplier starts at ×2.** The line clear that triggers a chain is
  the "×1" link, so the first chain step reads as ×2 — matching the on-screen
  counter and share text.
- **Chain points 10 × cells × multiplier × level.** A typical step removes 5–8
  cells. Step 1 (≈ 6 cells × 2 = 120 × level) sits between a Single and a
  Double; a 3-step chain (≈ 120 + 180 + 240 = 540 × level) is worth about a
  Triple; reaching ×4 or more beats a Quad. Chains matter, but cannot replace
  line clearing because they only fire after one.
- **Multiplier cap ×8.** Long cascades are rare; the cap stops a lucky board
  from producing absurd scores while still rewarding deep setups.
- **Cascade lines** score the plain line rate without the chain multiplier,
  so a chain cannot farm big line bonuses.
- **Min group 4, min 2 pieces.** 4 matches the falling-block vocabulary and
  makes the rule easy to read. The 2-piece rule is what makes it a puzzle.
- **Original pieces.** Corner and Trio (3 cells) are mild relief pieces that
  fill awkward gaps; the Cross (5 cells) is a hard piece, so it is rare
  (7 % per bag) and late (level 9). Chances: Corner 25 %, Trio 20 % per bag.
- **Daily unlocks by pieces dealt** (`sequence_pieces_per_level = 25`, about
  one level of play) rather than by level, so the piece sequence is identical
  for every player no matter how they play.
- **Timings.** Line flash 0.28 s, chain highlight 0.45 s (long enough to read
  which cells are kin), Zen sweep 0.8 s, ready 0.9 s.
- **Zen:** constant 1.1 s/row, sweeps the top 12 visible rows (plus the spawn
  rows) when the stack reaches the top.

## Modes

- **Classic:** endless, speed ramps with level. Chains on or off (Pure).
- **Zen:** no game over (top rows sweep away with a gentle fade), slow
  constant speed, ambient drifting background, calmer music, timer instead of
  score. Ends from the pause menu with a session summary.
- **Daily:** seed = FNV-1a hash of `kinblox:daily:<UTC date>` into Kinblox's
  own xorshift32 RNG (never Godot's global RNG, and identical on every
  platform). One scored attempt per UTC day — the attempt is marked as used
  when it starts, so quitting cannot buy a retry. Unlimited practice runs
  afterwards, never recorded. Results, streak and best streak persist.
  Countdown to the next UTC midnight. Share text, e.g.
  `Kinblox Daily 2026-10-22: 12,450 pts, 38 lines, best chain x4`.

## Controls

Gestures (default):

| Gesture | Action |
|---|---|
| Drag sideways | move one column per ~0.9 cell of finger travel ÷ sensitivity |
| Tap | rotate clockwise |
| Two-finger tap | rotate counter-clockwise |
| Slow drag down | soft drop, row by row |
| Fast flick down (< 0.32 s, > 2200 px/s, > 1.2 cells) | hard drop |
| Tap the HOLD box | hold |

Disambiguation: a touch is a tap until it moves 20 px; then it locks to one
axis for its whole life (sideways moves never drop; downward drags never
move). Taps must be short (< 0.28 s) and still (< 28 px). A second finger only
counts as a two-finger tap if the first has not started dragging; any third
finger cancels. Touches that start on the pause button or button pad are
ignored by the gesture layer.

Buttons (alternative, Settings → Controls): a two-row pad with Hold, Soft,
Rotate ↺, Drop, ◀, ▶ and a wide Rotate ↻. It handles multi-touch itself so
moving and rotating at the same time works. ◀/▶ auto-repeat (DAS 0.16 s,
ARR 0.045 s) and you can slide between them.

Keyboard (desktop testing): arrows/WASD, Up/X/W rotate CW, Z/Q rotate CCW,
Space hard drop, C/Shift hold, Esc/P pause.

## Visual design

- One typeface: **Manrope** (variable), weights 400–800. Hierarchy: display
  128 / score 80 / title 64 / value 48 / heading 44 / button 38 / body 34 /
  small 30 / caption 24 (bold, tracked caps).
- Spacing scale 4 / 8 / 16 / 24 / 32 only. Radii 12 / 24 / 32 / 40.
- Cells: rounded squares (22 % radius) with a lighter top bevel, drawn by one
  shared `CellPainter`. Empty cells show as subtle "wells".
- Elevation: only modal sheets cast a shadow.
- Motion: screens 200 ms in / 150 ms out, overlays 200 ms, theme switch is a
  350 ms crossfade of a snapshot. "Reduce motion" removes shake, slides,
  squash, scale pops and the drifting background, and thins particles.
- Themes: Ink (dark, default), Paper (light), Glacier (blue), Ember (amber).
  One `GameTheme` resource each; nothing outside `themes/` defines a color.
  Each theme has 8 piece colors chosen to differ in hue *and* lightness, plus
  an optional pattern glyph per color slot for colorblind players.

## Audio

Everything is generated by `tools/generate_audio.gd` in the D-major
pentatonic palette, so effects and music never clash. Chain steps climb the
scale. `AudioManager` maps an enum to files, so any sound can be replaced
without code changes. Buses: Master → SFX, Music.
