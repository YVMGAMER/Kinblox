extends KinTest

const STEP := 1.0 / 60.0


func _grounded_session() -> GameSession:
	var s := KinTest.started_session(ModeConfig.classic(11, false))
	KinTest.set_active(s, PieceDefs.Type.T, 0, Vector2i(3, Board.HEIGHT - 2))
	return s


func test_locks_after_delay() -> void:
	var s := _grounded_session()
	var locked := [false]
	s.piece_locked.connect(func(_c: Array[Vector2i], _t: int) -> void: locked[0] = true)
	var t := 0.0
	while not locked[0] and t < 2.0:
		s.update(STEP)
		t += STEP
	check(locked[0], "piece locked")
	check(absf(t - s.tuning.lock_delay) < 0.05, "locked after lock_delay (%.3f)" % t)


func test_moves_reset_timer_until_cap() -> void:
	var s := _grounded_session()
	var locked := [false]
	s.piece_locked.connect(func(_c: Array[Vector2i], _t: int) -> void: locked[0] = true)
	var frame := 0
	var dir := 1
	var moves := 0
	# Wiggle every 0.3 s: each move would postpone locking forever without a cap.
	while not locked[0] and frame < 1800:
		s.update(STEP)
		frame += 1
		if not locked[0] and frame % 18 == 0:
			if s.move(dir):
				moves += 1
			dir = -dir
	var t := frame * STEP
	check(locked[0], "piece eventually locks")
	var limit := s.tuning.lock_reset_limit
	var max_time := (limit + 1) * 0.3 + s.tuning.lock_delay + 0.1
	check(t <= max_time, "lock reset capped (t=%.2f, max %.2f)" % [t, max_time])
	check(t > limit * 0.3, "resets postponed locking (t=%.2f)" % t)
	check(moves >= limit, "resets were actually used (%d)" % moves)


func test_resets_counted_only_while_grounded() -> void:
	var s := KinTest.started_session(ModeConfig.classic(11, false))
	KinTest.set_active(s, PieceDefs.Type.T, 0, Vector2i(3, 5))
	for i in 10:
		s.move(1 if i % 2 == 0 else -1)
	check_eq(s.lock_resets_used(), 0, "airborne moves cost nothing")


func test_new_lowest_row_restores_resets() -> void:
	var s := KinTest.started_session(ModeConfig.classic(11, false))
	s.board.load_pattern(PackedStringArray([".........1"]))
	# Flat T resting on the single block at the bottom right. Sliding off the
	# ledge and dropping to a new lowest row restores the reset budget.
	KinTest.set_active(s, PieceDefs.Type.T, 0, Vector2i(7, Board.HEIGHT - 3))
	s.update(0.1)
	check(s.move(-1), "move while grounded")
	check_eq(s.lock_resets_used(), 1, "one reset used")
	check(s.soft_drop_step(), "falls to a new lowest row")
	check_eq(s.lock_resets_used(), 0, "budget restored at new low")
