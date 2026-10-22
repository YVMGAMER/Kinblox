class_name GameRules
extends RefCounted
## Stateless rules shared by every mode: speed curve and rotation with kicks.

const TUNING_PATH := "res://assets/data/tuning.tres"

static var _default_tuning: Tuning


static func default_tuning() -> Tuning:
	if _default_tuning == null:
		if ResourceLoader.exists(TUNING_PATH):
			_default_tuning = load(TUNING_PATH) as Tuning
		if _default_tuning == null:
			_default_tuning = Tuning.new()
	return _default_tuning


## Seconds per row at a level. A softened version of the familiar
## (0.8 - (L - 1) * 0.007) ^ (L - 1) curve; see docs/DESIGN.md.
static func gravity_interval(level: int, tuning: Tuning) -> float:
	var eff := 1.0 + float(maxi(level, 1) - 1) * tuning.gravity_level_scale
	var base := maxf(0.8 - (eff - 1.0) * 0.007, 0.05)
	return maxf(pow(base, eff - 1.0), tuning.gravity_min_interval)


## Finds the first kick that lets a piece rotate. Returns the kick index, or
## -1 if no kick fits. Upward kicks are skipped when allow_up_kicks is false.
static func find_kick(board: Board, type: int, from_rot: int, to_rot: int, pos: Vector2i, allow_up_kicks: bool) -> int:
	var kicks := PieceDefs.kicks(type, from_rot, to_rot)
	for i in kicks.size():
		var k := kicks[i]
		if k.y < 0 and not allow_up_kicks:
			continue
		if board.can_place(type, to_rot, pos + k):
			return i
	return -1
