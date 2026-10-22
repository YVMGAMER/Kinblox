extends KinTest
## Gesture recognition, driven with synthetic touch events and a fake clock.

const CELL := 80.0

var _t: TouchInput
var _log: Array[String] = []


func _make() -> TouchInput:
	_log.clear()
	_t = TouchInput.new()
	_t.cell_px = CELL
	_t.fake_time = 10.0
	_t.move_steps.connect(func(dx: int) -> void: _log.append("move %d" % dx))
	_t.soft_drop_rows.connect(func(rows: int) -> void: _log.append("soft %d" % rows))
	_t.hard_drop_requested.connect(func() -> void: _log.append("hard"))
	_t.rotate_requested.connect(func(dir: int) -> void: _log.append("rotate %d" % dir))
	_t.hold_requested.connect(func() -> void: _log.append("hold"))
	return _t


func _down(index: int, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = true
	_t._input(e)


func _up(index: int, pos: Vector2) -> void:
	var e := InputEventScreenTouch.new()
	e.index = index
	e.position = pos
	e.pressed = false
	_t._input(e)


func _drag(index: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = index
	e.position = pos
	_t._input(e)


func _advance(seconds: float) -> void:
	_t.fake_time += seconds


## Moves a finger in small steps over `seconds`.
func _swipe(index: int, from: Vector2, to: Vector2, seconds: float, steps: int = 12) -> void:
	for i in range(1, steps + 1):
		_advance(seconds / steps)
		_drag(index, from.lerp(to, float(i) / steps))


func _moves_total() -> int:
	var total := 0
	for entry in _log:
		if entry.begins_with("move "):
			total += entry.trim_prefix("move ").to_int()
	return total


func test_tap_rotates_clockwise() -> void:
	_make()
	_down(0, Vector2(500, 900))
	_advance(0.08)
	_up(0, Vector2(503, 902))
	check_eq(_log, ["rotate 1"] as Array[String], "tap")
	_t.free()


func test_jittery_tap_does_not_move() -> void:
	_make()
	_down(0, Vector2(500, 900))
	_advance(0.05)
	_drag(0, Vector2(512, 905))
	_advance(0.05)
	_up(0, Vector2(510, 904))
	check_eq(_log, ["rotate 1"] as Array[String], "jitter stays a tap")
	_t.free()


func test_long_press_is_not_a_tap() -> void:
	_make()
	_down(0, Vector2(500, 900))
	_advance(0.6)
	_up(0, Vector2(500, 900))
	check(_log.is_empty(), "no rotate after a long press")
	_t.free()


func test_drag_moves_by_columns() -> void:
	_make()
	_down(0, Vector2(300, 900))
	_swipe(0, Vector2(300, 900), Vector2(300 + CELL * 0.9 * 3 + 5, 910), 0.3)
	_up(0, Vector2(300 + CELL * 0.9 * 3 + 5, 910))
	check_eq(_moves_total(), 3, "three columns right")
	check(not _log.has("rotate 1"), "drag is not a tap")
	_t.free()


func test_drag_back_and_forth() -> void:
	_make()
	_down(0, Vector2(500, 900))
	_swipe(0, Vector2(500, 900), Vector2(500 + CELL * 2, 900), 0.2)
	_swipe(0, Vector2(500 + CELL * 2, 900), Vector2(500 - CELL * 1.0, 900), 0.3)
	_up(0, Vector2(500 - CELL * 1.0, 900))
	check(_moves_total() <= 0 and _moves_total() >= -2, "net move follows finger (%d)" % _moves_total())
	_t.free()


func test_sensitivity_scales_steps() -> void:
	_make()
	_t.sensitivity = 2.0
	_down(0, Vector2(300, 900))
	_swipe(0, Vector2(300, 900), Vector2(300 + CELL * 0.9 * 2 + 5, 900), 0.3)
	_up(0, Vector2(300 + CELL * 0.9 * 2 + 5, 900))
	check_eq(_moves_total(), 4, "double sensitivity, double columns")
	_t.free()


func test_horizontal_drag_never_drops() -> void:
	_make()
	_down(0, Vector2(300, 900))
	_swipe(0, Vector2(300, 900), Vector2(700, 960), 0.12)
	_up(0, Vector2(700, 960))
	for entry in _log:
		check(not entry.begins_with("soft") and entry != "hard", "no drop from a sideways swipe: %s" % entry)
	_t.free()


func test_slow_drag_down_soft_drops() -> void:
	_make()
	_down(0, Vector2(500, 600))
	_swipe(0, Vector2(500, 600), Vector2(505, 600 + CELL * 0.8 * 4 + 4), 0.8, 30)
	_up(0, Vector2(505, 600 + CELL * 0.8 * 4 + 4))
	var rows := 0
	for entry in _log:
		if entry.begins_with("soft "):
			rows += entry.trim_prefix("soft ").to_int()
	check_eq(rows, 4, "four rows of soft drop")
	check(not _log.has("hard"), "slow drag is not a flick")
	check_eq(_moves_total(), 0, "no sideways moves")
	_t.free()


func test_fast_flick_hard_drops() -> void:
	_make()
	_down(0, Vector2(500, 600))
	_swipe(0, Vector2(500, 600), Vector2(510, 900), 0.1, 6)
	_up(0, Vector2(510, 900))
	check(_log.has("hard"), "flick hard drops")
	_t.free()


func test_two_finger_tap_rotates_ccw() -> void:
	_make()
	_down(0, Vector2(400, 900))
	_advance(0.03)
	_down(1, Vector2(650, 920))
	_advance(0.08)
	_up(0, Vector2(401, 900))
	_advance(0.02)
	_up(1, Vector2(650, 921))
	check_eq(_log, ["rotate -1"] as Array[String], "two-finger tap")
	_t.free()


func test_second_finger_ignored_during_drag() -> void:
	_make()
	_down(0, Vector2(300, 900))
	_swipe(0, Vector2(300, 900), Vector2(300 + CELL * 2, 900), 0.2)
	_down(1, Vector2(800, 900))
	_advance(0.05)
	_up(1, Vector2(800, 900))
	_up(0, Vector2(300 + CELL * 2, 900))
	check(not _log.has("rotate -1") and not _log.has("rotate 1"), "no rotation from a stray finger")
	_t.free()


func test_disabled_ignores_everything() -> void:
	_make()
	_t.enabled = false
	_down(0, Vector2(500, 900))
	_advance(0.05)
	_up(0, Vector2(500, 900))
	check(_log.is_empty(), "disabled")
	_t.free()


func test_buttons_scheme_disables_gestures() -> void:
	_make()
	_t.gestures_enabled = false
	_down(0, Vector2(500, 900))
	_advance(0.05)
	_up(0, Vector2(500, 900))
	check(_log.is_empty(), "no gesture in button scheme")
	_t.free()
