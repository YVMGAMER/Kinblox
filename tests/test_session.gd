extends KinTest


func test_spawns_into_visible_field() -> void:
	var s := KinTest.started_session(ModeConfig.classic(1, true))
	check_eq(s.state, GameSession.State.PLAYING, "playing")
	check(s.active != null, "has piece")
	var lowest := 0
	for c in s.active.board_cells():
		lowest = maxi(lowest, c.y)
	check(lowest >= Board.HIDDEN_ROWS, "piece reaches visible rows")
	check_eq(s.queue.size(), 3, "next queue of 3")


func test_ready_state_waits() -> void:
	var s := GameSession.new(ModeConfig.classic(1, true), Tuning.new())
	s.start()
	check_eq(s.state, GameSession.State.READY, "starts ready")
	s.update(s.tuning.ready_delay + 0.01)
	check_eq(s.state, GameSession.State.PLAYING, "then plays")


func test_hold_once_per_piece() -> void:
	var s := KinTest.started_session(ModeConfig.classic(2, true))
	var first := s.active.type
	var next := s.queue[0]
	check(s.hold(), "first hold")
	check_eq(s.hold_type, first, "held type")
	check_eq(s.active.type, next, "took next")
	check(not s.hold(), "second hold blocked")
	s.hard_drop()
	check(s.hold(), "hold allowed again after lock")
	check_eq(s.active.type, first, "swapped back")


func test_gravity_moves_piece() -> void:
	var s := KinTest.started_session(ModeConfig.classic(2, true))
	var y := s.active.position.y
	s.update(s.gravity_interval() + 0.001)
	check_eq(s.active.position.y, y + 1, "fell one row")


func test_gravity_speeds_up_with_level() -> void:
	var t := Tuning.new()
	var prev := 999.0
	for level in range(1, 21):
		var interval := GameRules.gravity_interval(level, t)
		check(interval <= prev, "monotonic at %d" % level)
		check(interval >= t.gravity_min_interval, "floor at %d" % level)
		prev = interval
	check(absf(GameRules.gravity_interval(1, t) - 1.0) < 0.001, "level 1 is 1 s/row")


func test_line_clear_counts_lines() -> void:
	var s := KinTest.started_session(ModeConfig.classic(3, false))
	s.board.load_pattern(PackedStringArray(["012345012."]))
	KinTest.set_active(s, PieceDefs.Type.I, 1, Vector2i(7, Board.HEIGHT - 4))
	s.hard_drop()
	check_eq(s.scoring.lines, 1, "one line")
	check(s.board.is_empty(0, Board.HEIGHT - 1), "row cleared")
	check_eq(s.state, GameSession.State.PLAYING, "next piece")


func test_game_over_when_spawn_blocked() -> void:
	var s := KinTest.started_session(ModeConfig.classic(4, true))
	var over := [false]
	s.game_over.connect(func() -> void: over[0] = true)
	for y in range(0, 4):
		for x in range(2, 8):
			s.board.set_cell(x, y, 1, 500 + x + y * 10)
	s.hard_drop()
	check(over[0], "game over")
	check_eq(s.state, GameSession.State.GAME_OVER, "state")
	check(not s.move(1), "no input after game over")


func test_zen_sweeps_instead_of_game_over() -> void:
	var tuning := KinTest.instant_tuning()
	var s := KinTest.started_session(ModeConfig.zen(4, true, tuning), tuning)
	var over := [false]
	var swept := [0]
	s.game_over.connect(func() -> void: over[0] = true)
	s.zen_sweep_started.connect(func(rows: int) -> void: swept[0] = rows)
	for y in range(0, Board.HEIGHT):
		for x in range(0, Board.WIDTH):
			if x != y % Board.WIDTH:
				s.board.set_cell(x, y, 1, 500 + x + y * 10)
	s.active = null
	s.hold_type = -1
	s._spawn_next()
	check(not over[0], "no game over in zen")
	check(swept[0] > 0, "sweep happened")
	check(s.active != null, "play continues")
	check(s.board.is_row_empty(Board.HIDDEN_ROWS), "top rows cleared")
	check(not s.board.is_row_empty(Board.HEIGHT - 1), "bottom rows kept")


func test_pause_during_line_clear_is_safe() -> void:
	var s := KinTest.started_session(ModeConfig.classic(3, true), Tuning.new())
	s.update(s.tuning.ready_delay + 0.01)
	s.board.load_pattern(PackedStringArray(["012345012."]))
	KinTest.set_active(s, PieceDefs.Type.I, 1, Vector2i(7, Board.HEIGHT - 4))
	s.hard_drop()
	check_eq(s.state, GameSession.State.LINE_CLEAR, "clearing")
	s.pause()
	s.update(10.0)
	check_eq(s.state, GameSession.State.PAUSED, "stays paused")
	check(not s.board.is_empty(0, Board.HEIGHT - 1), "row not yet removed while paused")
	s.resume()
	check_eq(s.state, GameSession.State.LINE_CLEAR, "resumes clearing")
	s.update(1.0)
	check(s.board.is_empty(0, Board.HEIGHT - 1), "row removed after resume")
	check_eq(s.state, GameSession.State.PLAYING, "back to play")


func test_inputs_ignored_when_not_playing() -> void:
	var s := GameSession.new(ModeConfig.classic(1, true), Tuning.new())
	s.start()
	check(not s.move(1), "move in READY")
	check(not s.rotate(1), "rotate in READY")
	check(not s.hold(), "hold in READY")
	s.hard_drop()
	check_eq(s.pieces_locked, 0, "hard drop in READY")


func test_rapid_hard_drops() -> void:
	var s := KinTest.started_session(ModeConfig.classic(8, true))
	for i in 200:
		if s.state == GameSession.State.GAME_OVER:
			break
		s.hard_drop()
		s.update(0.0)
	check(s.pieces_locked > 10, "many pieces locked")
	check_eq(s.state, GameSession.State.GAME_OVER, "stack tops out")
