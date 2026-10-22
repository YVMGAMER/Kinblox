extends Node
## Vibration feedback via Input.vibrate_handheld, scaled by the player's
## intensity setting. A no-op on platforms without a vibration motor.

enum Kind { ROTATE, MOVE, LOCK, HARD_DROP, HOLD, LINE_CLEAR, CHAIN, LEVEL_UP, GAME_OVER, UI }

## Base duration (ms) and amplitude (0..1) per kind.
const PROFILE := {
	Kind.MOVE: Vector2(6, 0.18),
	Kind.ROTATE: Vector2(9, 0.3),
	Kind.LOCK: Vector2(14, 0.45),
	Kind.HARD_DROP: Vector2(24, 0.75),
	Kind.HOLD: Vector2(10, 0.3),
	Kind.LINE_CLEAR: Vector2(22, 0.6),
	Kind.CHAIN: Vector2(30, 0.7),
	Kind.LEVEL_UP: Vector2(45, 0.6),
	Kind.GAME_OVER: Vector2(140, 0.9),
	Kind.UI: Vector2(7, 0.25),
}

var _supported := OS.has_feature("mobile")


func pulse(kind: Kind, scale: float = 1.0) -> void:
	if not _supported or not Settings.haptics_enabled():
		return
	var p: Vector2 = PROFILE[kind]
	var intensity := Settings.haptics_intensity()
	var duration := int(p.x * lerpf(0.7, 1.3, intensity) * scale)
	var amplitude := clampf(p.y * intensity * scale, 0.05, 1.0)
	Input.vibrate_handheld(maxi(duration, 1), amplitude)


## Line clears grow stronger with the number of lines.
func line_clear(lines: int) -> void:
	pulse(Kind.LINE_CLEAR, 1.0 + 0.25 * (lines - 1))
