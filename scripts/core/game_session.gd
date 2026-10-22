class_name GameSession
extends RefCounted
## Mode-agnostic game state machine. Owns the board, bag, active piece, hold
## and scoring. Drive it with update(delta) and the input commands; observe it
## through signals. It never touches nodes, so it runs headlessly in tests.
##
## Animation pauses (line clear flash, chain highlight, Zen sweep) are timed
## here as states, so pausing or backgrounding mid-animation is always safe.

enum State { READY, PLAYING, PAUSED, LINE_CLEAR, CHAIN, GAME_OVER }

signal state_changed(new_state: State, old_state: State)
signal piece_spawned(piece: Piece)
## Any change of the active piece's position or rotation.
signal piece_moved(piece: Piece)
signal piece_rotated(piece: Piece, kicked: bool)
signal soft_dropped(rows: int)
signal hard_dropped(piece: Piece, rows: int)
signal piece_locked(cells: Array[Vector2i], type: int)
signal hold_changed(type: int)
signal queue_changed()
## Rows are detected and scored; they are removed when LINE_CLEAR ends.
signal lines_cleared(rows: Array[int], award: Scoring.Award)
signal chain_highlight(groups: Array[PackedInt32Array], step: int, multiplier: int)
signal chain_step_resolved(step: int, multiplier: int, cells: int, points: int, cascade_rows: Array[int])
signal chain_finished(steps: int)
signal zen_sweep_started(rows: int)
signal board_changed()
signal score_changed(score: int)
signal level_changed(level: int)
signal combo_changed(combo: int)
signal game_over()

var tuning: Tuning
var mode: ModeConfig
var board: Board
var scoring: Scoring
var active: Piece
var hold_type := -1
var queue: Array[int] = []
var state: State = State.READY
## Seconds of play time (excludes READY and PAUSED).
var elapsed := 0.0
var pieces_locked := 0
var chain_step := 0

var _bag: Bag
var _serial := 0
var _bag_draws := 0
var _state_before_pause: State = State.READY
var _timer := 0.0
var _gravity_accum := 0.0
var _lock_timer := 0.0
var _lock_resets := 0
var _lowest_y := 0
var _floor_kicks := 0
var _hold_used := false
var _soft_drop := false
var _pending_rows: Array[int] = []
var _pending_groups: Array[PackedInt32Array] = []
var _sweep_type := -1


func _init(p_mode: ModeConfig, p_tuning: Tuning = null) -> void:
	tuning = p_tuning if p_tuning != null else GameRules.default_tuning()
	mode = p_mode
	board = Board.new()
	scoring = Scoring.new(tuning, mode.start_level)
	_bag = Bag.new(SeededRng.new(mode.rng_seed), tuning)


func start() -> void:
	_fill_queue()
	queue_changed.emit()
	_timer = tuning.ready_delay
	_set_state(State.READY)
	if _timer <= 0.0:
		_spawn_next()


func update(delta: float) -> void:
	match state:
		State.READY:
			_timer -= delta
			if _timer <= 0.0:
				_spawn_next()
		State.PLAYING:
			elapsed += delta
			_step_gravity(delta)
			if state == State.PLAYING:
				_step_lock(delta)
		State.LINE_CLEAR:
			elapsed += delta
			_timer -= delta
			if _timer <= 0.0:
				_finish_line_clear()
		State.CHAIN:
			elapsed += delta
			_timer -= delta
			if _timer <= 0.0:
				_resolve_chain_step()


#region Commands

func is_playing() -> bool:
	return state == State.PLAYING and active != null


func move(dx: int) -> bool:
	if not is_playing() or not _shift(dx, 0):
		return false
	_on_player_adjust()
	piece_moved.emit(active)
	return true


## dir: 1 = clockwise, -1 = counter-clockwise.
func rotate(dir: int) -> bool:
	if not is_playing():
		return false
	var from := active.rot
	var to := posmod(from + dir, 4)
	var allow_up := _floor_kicks < tuning.floor_kick_limit
	var kick_index := GameRules.find_kick(board, active.type, from, to, active.position, allow_up)
	if kick_index < 0:
		return false
	var kick := PieceDefs.kicks(active.type, from, to)[kick_index]
	if kick.y < 0:
		_floor_kicks += 1
	active.rot = to
	active.position += kick
	_track_lowest()
	_on_player_adjust()
	piece_rotated.emit(active, kick_index > 0)
	piece_moved.emit(active)
	return true


## Held soft drop (keys, on-screen button): gravity runs at soft-drop speed.
func set_soft_drop(enabled: bool) -> void:
	_soft_drop = enabled


## One row of soft drop (touch drags move the piece row by row).
func soft_drop_step() -> bool:
	if not is_playing() or not _shift(0, 1):
		return false
	_gravity_accum = 0.0
	scoring.award_soft_drop(1)
	soft_dropped.emit(1)
	score_changed.emit(scoring.score)
	piece_moved.emit(active)
	return true


func hard_drop() -> void:
	if not is_playing():
		return
	var rows := ghost_y() - active.position.y
	active.position.y += rows
	scoring.award_hard_drop(rows)
	hard_dropped.emit(active, rows)
	score_changed.emit(scoring.score)
	_lock_active()


func hold() -> bool:
	if not is_playing() or _hold_used:
		return false
	var current := active.type
	active = null
	if hold_type < 0:
		hold_type = current
		hold_changed.emit(hold_type)
		_spawn(_take_next(), true)
	else:
		var swap := hold_type
		hold_type = current
		hold_changed.emit(hold_type)
		_spawn(swap, true)
	return true


func can_hold() -> bool:
	return is_playing() and not _hold_used


func pause() -> void:
	if state == State.PAUSED or state == State.GAME_OVER:
		return
	_state_before_pause = state
	_soft_drop = false
	_set_state(State.PAUSED)


func resume() -> void:
	if state != State.PAUSED:
		return
	_set_state(_state_before_pause)


## Ends the run early (quit from pause menu). Results stay readable.
func abandon() -> void:
	if state == State.GAME_OVER:
		return
	active = null
	_set_state(State.GAME_OVER)

#endregion

#region Queries

func ghost_y() -> int:
	if active == null:
		return 0
	var y := active.position.y
	while board.can_place(active.type, active.rot, Vector2i(active.position.x, y + 1)):
		y += 1
	return y


func gravity_interval() -> float:
	if mode.fixed_gravity_interval > 0.0:
		return mode.fixed_gravity_interval
	return GameRules.gravity_interval(scoring.level, tuning)


func chain_multiplier() -> int:
	return tuning.chain_multiplier(chain_step)


## Grounded pieces lock after this fraction of lock delay; for views.
func lock_progress() -> float:
	return clampf(_lock_timer / tuning.lock_delay, 0.0, 1.0) if tuning.lock_delay > 0.0 else 0.0


func lock_resets_used() -> int:
	return _lock_resets

#endregion

#region Internals

func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	var old := state
	state = new_state
	state_changed.emit(new_state, old)


func _shift(dx: int, dy: int) -> bool:
	var target := active.position + Vector2i(dx, dy)
	if not board.can_place(active.type, active.rot, target):
		return false
	active.position = target
	_track_lowest()
	return true


func _is_grounded() -> bool:
	return not board.can_place(active.type, active.rot, active.position + Vector2i.DOWN)


## Reaching a new lowest row restores the full lock-reset budget.
func _track_lowest() -> void:
	if active.position.y > _lowest_y:
		_lowest_y = active.position.y
		_lock_resets = 0
		_lock_timer = 0.0


## A successful move or rotate restarts a running lock countdown, up to
## lock_reset_limit times per row. After that the countdown keeps running.
func _on_player_adjust() -> void:
	if _lock_timer > 0.0 and _lock_resets < tuning.lock_reset_limit:
		_lock_timer = 0.0
		_lock_resets += 1


func _step_gravity(delta: float) -> void:
	var interval := gravity_interval()
	if _soft_drop:
		interval = minf(interval, tuning.soft_drop_interval)
	_gravity_accum += delta
	var steps := 0
	var soft_rows := 0
	while _gravity_accum >= interval and steps < Board.HEIGHT:
		_gravity_accum -= interval
		steps += 1
		if not _shift(0, 1):
			_gravity_accum = 0.0
			break
		if _soft_drop:
			soft_rows += 1
	if steps >= Board.HEIGHT:
		_gravity_accum = 0.0
	if steps > 0 and active != null:
		piece_moved.emit(active)
	if soft_rows > 0:
		scoring.award_soft_drop(soft_rows)
		soft_dropped.emit(soft_rows)
		score_changed.emit(scoring.score)


func _step_lock(delta: float) -> void:
	if not _is_grounded():
		return
	_lock_timer += delta
	if _lock_timer >= tuning.lock_delay:
		_lock_active()


func _lock_active() -> void:
	var cells := board.place(active.type, active.rot, active.position, active.serial)
	var type := active.type
	active = null
	pieces_locked += 1
	piece_locked.emit(cells, type)
	board_changed.emit()
	var rows := board.full_rows()
	if rows.is_empty():
		if scoring.combo >= 0:
			scoring.break_combo()
			combo_changed.emit(scoring.combo)
		_spawn_next()
		return
	var old_level := scoring.level
	var award := scoring.award_lines(rows.size())
	_pending_rows = rows
	_timer = tuning.line_clear_delay
	_set_state(State.LINE_CLEAR)
	lines_cleared.emit(rows, award)
	score_changed.emit(scoring.score)
	combo_changed.emit(scoring.combo)
	if scoring.level != old_level:
		level_changed.emit(scoring.level)
	if _timer <= 0.0:
		_finish_line_clear()


func _finish_line_clear() -> void:
	if _sweep_type >= 0:
		board.empty_top_rows(Board.HIDDEN_ROWS + tuning.zen_sweep_rows)
		board_changed.emit()
		var type := _sweep_type
		_sweep_type = -1
		_spawn(type, false)
		return
	board.clear_rows(_pending_rows)
	_pending_rows.clear()
	board_changed.emit()
	if not _begin_chain_step():
		_spawn_next()


## Looks for kin groups; if any, enters CHAIN and highlights them.
func _begin_chain_step() -> bool:
	if not mode.chains_enabled:
		return false
	_pending_groups = ChainResolver.find_groups(board, tuning.chain_min_group, tuning.chain_min_pieces)
	if _pending_groups.is_empty():
		return false
	chain_step += 1
	_timer = tuning.chain_highlight_delay
	_set_state(State.CHAIN)
	chain_highlight.emit(_pending_groups, chain_step, chain_multiplier())
	if _timer <= 0.0:
		_resolve_chain_step()
	return true


func _resolve_chain_step() -> void:
	var multiplier := chain_multiplier()
	var old_level := scoring.level
	var removed := ChainResolver.remove_groups(board, _pending_groups)
	_pending_groups.clear()
	var points := scoring.award_chain_step(removed, multiplier)
	var cascade := board.full_rows()
	if not cascade.is_empty():
		board.clear_rows(cascade)
		points += scoring.award_cascade_lines(cascade.size())
	chain_step_resolved.emit(chain_step, multiplier, removed, points, cascade)
	board_changed.emit()
	score_changed.emit(scoring.score)
	if scoring.level != old_level:
		level_changed.emit(scoring.level)
	if not _begin_chain_step():
		chain_finished.emit(chain_step)
		chain_step = 0
		_spawn_next()


func _unlock_level() -> int:
	if mode.unlock_basis == ModeConfig.UnlockBasis.SEQUENCE:
		@warning_ignore("integer_division")
		return 1 + _bag_draws / tuning.sequence_pieces_per_level
	return scoring.level


func _fill_queue() -> void:
	while queue.size() < tuning.next_count:
		queue.append(_bag.next(_unlock_level()))
		_bag_draws += 1


func _take_next() -> int:
	var type: int = queue.pop_front()
	_fill_queue()
	queue_changed.emit()
	return type


func _spawn_next() -> void:
	_spawn(_take_next(), false)


func _spawn(type: int, from_hold: bool) -> void:
	_serial += 1
	var piece := Piece.new(type, _serial, PieceDefs.spawn_position(type, Board.WIDTH))
	if not board.can_place(type, 0, piece.position):
		active = null
		if mode.has_game_over:
			_set_state(State.GAME_OVER)
			game_over.emit()
		else:
			_begin_zen_sweep(type)
		return
	# Drop one row straight away so the piece enters the visible field.
	if board.can_place(type, 0, piece.position + Vector2i.DOWN):
		piece.position.y += 1
	active = piece
	_lock_timer = 0.0
	_lock_resets = 0
	_floor_kicks = 0
	_lowest_y = piece.position.y
	_gravity_accum = 0.0
	if not from_hold:
		_hold_used = false
	else:
		_hold_used = true
	_set_state(State.PLAYING)
	piece_spawned.emit(piece)


func _begin_zen_sweep(pending_type: int) -> void:
	_sweep_type = pending_type
	_timer = tuning.zen_sweep_delay
	_set_state(State.LINE_CLEAR)
	zen_sweep_started.emit(Board.HIDDEN_ROWS + tuning.zen_sweep_rows)
	if _timer <= 0.0:
		_finish_line_clear()

#endregion
