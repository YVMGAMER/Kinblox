class_name InputRouter
extends Node
## Single entry point for player commands from keyboard, gestures and the
## on-screen pad. Held directions get DAS/ARR auto-repeat here.

signal player_moved(dx: int)
signal player_soft_dropped(rows: int)

const DAS := 0.16
const ARR := 0.045

var session: GameSession
var enabled := true

var _held_left := 0  # bitmask of sources holding the direction
var _held_right := 0
var _dir := 0
var _das := 0.0
var _arr := 0.0
var _soft_sources := 0

const SOURCE_KEYS := 1
const SOURCE_PAD := 2


func bind(p_session: GameSession) -> void:
	session = p_session


func reset() -> void:
	_held_left = 0
	_held_right = 0
	_dir = 0
	_soft_sources = 0
	if session != null:
		session.set_soft_drop(false)


func _process(delta: float) -> void:
	if session == null or _dir == 0 or not enabled:
		return
	_das += delta
	if _das < DAS:
		return
	_arr += delta
	var steps := 0
	while _arr >= ARR and steps < Board.WIDTH:
		_arr -= ARR
		steps += 1
		if not shift(_dir):
			_arr = 0.0
			break


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or event.is_echo():
		return
	for action: StringName in [&"move_left", &"move_right", &"soft_drop", &"hard_drop", &"rotate_cw", &"rotate_ccw", &"hold"]:
		if event.is_action_pressed(action):
			action_down(action, SOURCE_KEYS)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_released(action):
			action_up(action, SOURCE_KEYS)
			get_viewport().set_input_as_handled()
			return


func action_down(action: StringName, source: int) -> void:
	match action:
		&"move_left":
			_held_left |= source
			_start_repeat(-1)
		&"move_right":
			_held_right |= source
			_start_repeat(1)
		&"soft_drop":
			_soft_sources |= source
			session.set_soft_drop(true)
		&"hard_drop":
			session.hard_drop()
		&"rotate_cw":
			session.rotate(1)
		&"rotate_ccw":
			session.rotate(-1)
		&"hold":
			session.hold()


func action_up(action: StringName, source: int) -> void:
	match action:
		&"move_left":
			_held_left &= ~source
			_dir = 1 if _held_right != 0 else 0
			_restart_timers()
		&"move_right":
			_held_right &= ~source
			_dir = -1 if _held_left != 0 else 0
			_restart_timers()
		&"soft_drop":
			_soft_sources &= ~source
			if _soft_sources == 0:
				session.set_soft_drop(false)


## One column step.
func shift(dx: int) -> bool:
	if not enabled or session == null:
		return false
	var ok := session.move(dx)
	if ok:
		player_moved.emit(dx)
	return ok


func shift_by(steps: int) -> void:
	var dir := signi(steps)
	for i in absi(steps):
		if not shift(dir):
			break


func soft_drop_rows(rows: int) -> void:
	var moved := 0
	for i in rows:
		if not session.soft_drop_step():
			break
		moved += 1
	if moved > 0:
		player_soft_dropped.emit(moved)


func _start_repeat(dir: int) -> void:
	_dir = dir
	_restart_timers()
	shift(dir)


func _restart_timers() -> void:
	_das = 0.0
	_arr = 0.0
