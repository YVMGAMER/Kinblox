class_name KinTest
extends RefCounted
## Minimal test base. Methods named test_* are run by tests/run_all.gd.

var _failures := PackedStringArray()


func begin() -> void:
	_failures.clear()


func failures() -> PackedStringArray:
	return _failures


func check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func check_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		_failures.append("%s expected <%s> got <%s>" % [message, str(expected), str(actual)])


## Tuning with every animation delay removed, so sessions resolve instantly.
static func instant_tuning() -> Tuning:
	var t := Tuning.new()
	t.ready_delay = 0.0
	t.line_clear_delay = 0.0
	t.chain_highlight_delay = 0.0
	t.zen_sweep_delay = 0.0
	return t


static func started_session(mode: ModeConfig, tuning: Tuning = null) -> GameSession:
	var s := GameSession.new(mode, tuning if tuning != null else instant_tuning())
	s.start()
	return s


## Replaces the active piece with a chosen one at a chosen spot.
static func set_active(session: GameSession, type: int, rot: int, pos: Vector2i) -> void:
	var p := Piece.new(type, 9000 + session.pieces_locked, pos)
	p.rot = rot
	session.active = p
	session._lowest_y = pos.y
	session._lock_timer = 0.0
	session._lock_resets = 0
