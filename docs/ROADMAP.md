# Roadmap

Ideas deliberately **not** built for the MVP (out of spec), in rough priority
order. Each would be a clear improvement.

1. **Composed music.** Replace the generated ambient loops with a real score
   (2–3 tracks, intensity layers that follow the stack height). Swap is a file
   change: `AudioManager.MUSIC_FILES`.
2. **Native share-sheet plugin.** Bundle an Android/iOS share plugin so Daily
   results open the OS share sheet instead of copying to the clipboard. The
   hook already exists (`ShareService.PLUGINS`).
3. **Store listing assets.** Screenshots per theme (`tools/capture.gd` already
   renders them at 1080x1920), feature graphic, adaptive Android icon layers.
4. **Online leaderboards for Daily.** Same seed for everyone makes Daily a
   natural fit. Requires a backend and anti-cheat (server-side replay of input
   logs is possible because the game is deterministic).
5. **Replays / ghost runs.** The session is deterministic given seed and input
   timing; recording inputs would allow replays and "race your best".
6. **T-spin-style "twist" bonus** for kicked rotations into tight slots.
7. **Accessibility:** dynamic type scaling setting, screen-reader labels for
   menus, left-handed button layout mirror.
8. **More themes** and an unlockable palette per Daily streak milestone.
9. **Rewarded ads / IAP** (only if monetization is wanted) — e.g. "continue
   once" in Classic. Keep Daily ad-free to stay fair.
10. **Cloud save** (Play Games / Game Center).
11. **Haptic patterns** via a native plugin (Android `VibrationEffect.Composition`,
    iOS Core Haptics) for richer chain feedback than duration/amplitude pulses.
12. **Tablet layout:** side panels for hold/next when the screen is wide.
