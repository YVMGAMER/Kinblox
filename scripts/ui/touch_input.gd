class_name TouchInput
extends Node
## Gesture controls over the play area.
##   drag sideways      -> move one column per step (sensitivity scales the step)
##   tap                -> rotate clockwise
##   two-finger tap     -> rotate counter-clockwise
##   slow drag down     -> soft drop, row by row
##   fast flick down    -> hard drop
##   tap the hold box   -> hold (works in every control scheme)
## Each touch commits to one axis after a dead zone, so a sloppy tap never
## moves the piece and a sideways drag never drops it.

signal move_steps(dx: int)
signal soft_drop_rows(rows: int)
signal hard_drop_requested
signal rotate_requested(dir: int)
signal hold_requested

enum Axis { NONE, HORIZONTAL, DOWN, UP }

const DEAD_ZONE := 20.0
const TAP_SLOP := 28.0
const TAP_TIME := 0.28
const TWO_FINGER_WINDOW := 0.25
const FLICK_MAX_TIME := 0.32
const FLICK_SPEED := 2200.0
const FLICK_MIN_CELLS := 1.2
const VELOCITY_WINDOW := 0.08
const SAMPLES := 8

## Master switch (off while paused or in overlays).
var enabled := true
## Off in the on-screen-button scheme; the hold box still responds.
var gestures_enabled := true
var cell_px := 80.0
var sensitivity := 1.0
var play_area: Control
var hold_area: Control
## Touches that start on these controls are left to them.
var blockers: Array[Control] = []

var _primary := -1
var _secondary := -1
var _start := Vector2.ZERO
var _last := Vector2.ZERO
var _start_time := 0.0
var _axis: Axis = Axis.NONE
var _accum := 0.0
var _two_finger := false
var _two_finger_ok := false
var _second_start := Vector2.ZERO
var _fingers_down := 0
var _sample_pos := PackedVector2Array()
var _sample_time := PackedFloat64Array()
var _sample_head := 0
## Tests set this to drive time by hand; negative means use the real clock.
var fake_time := -1.0


func _init() -> void:
	_sample_pos.resize(SAMPLES)
	_sample_time.resize(SAMPLES)


func reset() -> void:
	_primary = -1
	_secondary = -1
	_axis = Axis.NONE
	_two_finger = false
	_fingers_down = 0


func _input(event: InputEvent) -> void:
	if not enabled:
		if _primary != -1:
			reset()
		return
	if event is InputEventScreenTouch:
		_on_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_on_drag(event as InputEventScreenDrag)


func _now() -> float:
	if fake_time >= 0.0:
		return fake_time
	return Time.get_ticks_usec() / 1000000.0


func _on_touch(e: InputEventScreenTouch) -> void:
	var now := _now()
	if e.pressed:
		_fingers_down += 1
		if _primary == -1 and not _two_finger:
			if _hit(hold_area, e.position):
				hold_requested.emit()
				return
			var in_play := play_area == null or _hit(play_area, e.position)
			if not gestures_enabled or not in_play or _blocked(e.position):
				return
			_primary = e.index
			_start = e.position
			_last = e.position
			_start_time = now
			_axis = Axis.NONE
			_accum = 0.0
			_sample_head = 0
			_push_sample(e.position, now)
		elif _primary != -1 and _secondary == -1 and e.index != _primary:
			# A second finger only counts if the first has not started a drag.
			if _axis == Axis.NONE and now - _start_time < TWO_FINGER_WINDOW:
				_two_finger = true
				_two_finger_ok = true
				_secondary = e.index
				_second_start = e.position
		elif _two_finger:
			_two_finger_ok = false  # three fingers: ambiguous, do nothing
		return

	_fingers_down = maxi(_fingers_down - 1, 0)
	if _two_finger:
		if e.index == _primary:
			_primary = -2
		elif e.index == _secondary:
			_secondary = -2
		if _primary == -2 and _secondary == -2:
			if _two_finger_ok and now - _start_time < TAP_TIME * 1.6:
				rotate_requested.emit(-1)
			reset()
		return
	if e.index != _primary:
		return
	var elapsed := now - _start_time
	var total := e.position - _start
	match _axis:
		Axis.NONE:
			if total.length() < TAP_SLOP and elapsed < TAP_TIME:
				rotate_requested.emit(1)
		Axis.DOWN:
			_push_sample(e.position, now)
			if elapsed < FLICK_MAX_TIME and total.y > cell_px * FLICK_MIN_CELLS and _velocity_y(now) > FLICK_SPEED:
				hard_drop_requested.emit()
	_primary = -1


func _on_drag(e: InputEventScreenDrag) -> void:
	if _two_finger:
		var origin := _start if e.index == _primary else _second_start
		if (e.position - origin).length() > TAP_SLOP:
			_two_finger_ok = false
		return
	if e.index != _primary:
		return
	var now := _now()
	_push_sample(e.position, now)
	if _axis == Axis.NONE:
		var total := e.position - _start
		if total.length() < DEAD_ZONE:
			return
		if absf(total.x) > absf(total.y):
			_axis = Axis.HORIZONTAL
			_accum = total.x
		elif total.y > 0.0:
			_axis = Axis.DOWN
			_accum = total.y
		else:
			_axis = Axis.UP
		_last = e.position
		_apply()
		return
	match _axis:
		Axis.HORIZONTAL:
			_accum += e.position.x - _last.x
		Axis.DOWN:
			_accum = maxf(_accum + e.position.y - _last.y, 0.0)
	_last = e.position
	_apply()


func _apply() -> void:
	match _axis:
		Axis.HORIZONTAL:
			var step := cell_px * 0.9 / sensitivity
			var n := 0
			while _accum >= step:
				_accum -= step
				n += 1
			while _accum <= -step:
				_accum += step
				n -= 1
			if n != 0:
				move_steps.emit(n)
		Axis.DOWN:
			var step := cell_px * 0.8 / sensitivity
			var rows := 0
			while _accum >= step:
				_accum -= step
				rows += 1
			if rows > 0:
				soft_drop_rows.emit(rows)


func _push_sample(pos: Vector2, t: float) -> void:
	_sample_pos[_sample_head % SAMPLES] = pos
	_sample_time[_sample_head % SAMPLES] = t
	_sample_head += 1


## Downward speed over the last VELOCITY_WINDOW seconds, in px/s.
func _velocity_y(now: float) -> float:
	var count := mini(_sample_head, SAMPLES)
	if count < 2:
		return 0.0
	var newest := (_sample_head - 1) % SAMPLES
	var oldest := newest
	for i in range(1, count):
		var idx := posmod(_sample_head - 1 - i, SAMPLES)
		oldest = idx
		if now - _sample_time[idx] >= VELOCITY_WINDOW:
			break
	var dt := _sample_time[newest] - _sample_time[oldest]
	if dt <= 0.0:
		return 0.0
	return (_sample_pos[newest].y - _sample_pos[oldest].y) / dt


func _hit(c: Control, pos: Vector2) -> bool:
	return c != null and c.is_visible_in_tree() and c.get_global_rect().has_point(pos)


func _blocked(pos: Vector2) -> bool:
	for b in blockers:
		if _hit(b, pos):
			return true
	return false
