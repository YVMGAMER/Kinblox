extends KinTest

const T := PieceDefs.Type


func test_rotation_states_cycle_and_keep_size() -> void:
	for type in PieceDefs.COUNT:
		var n := PieceDefs.cell_count(type)
		for r in 4:
			check_eq(PieceDefs.cells(type, r).size(), n, "%s rot %d size" % [PieceDefs.display_name(type), r])
		var box := PieceDefs.box_size(type)
		for c in PieceDefs.cells(type, 3):
			var back := Vector2i(box - 1 - c.y, c.x)
			check(back in PieceDefs.cells(type, 0), "%s returns to spawn" % PieceDefs.display_name(type))


func test_t_states_match_reference() -> void:
	var right := PieceDefs.cells(T.T, 1).duplicate()
	right.sort()
	check_eq(right, [Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1)] as Array[Vector2i], "T right")
	var rev := PieceDefs.cells(T.T, 2)
	check(Vector2i(1, 2) in rev and Vector2i(1, 0) not in rev, "T reverse points down")


func test_i_states_match_reference() -> void:
	for c in PieceDefs.cells(T.I, 1):
		check_eq(c.x, 2, "I right column")
	for c in PieceDefs.cells(T.I, 2):
		check_eq(c.y, 2, "I reverse row")
	for c in PieceDefs.cells(T.I, 3):
		check_eq(c.x, 1, "I left column")


func test_kick_tables_converted_to_y_down() -> void:
	var expected: Array[Vector2i] = [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)]
	check_eq(PieceDefs.kicks(T.T, 0, 1), expected, "JLSTZ 0->R")
	var expected_i: Array[Vector2i] = [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, 1), Vector2i(1, -2)]
	check_eq(PieceDefs.kicks(T.I, 0, 1), expected_i, "I 0->R")
	check_eq(PieceDefs.kicks(T.O, 0, 1).size(), 1, "O has no kicks")
	check_eq(PieceDefs.kicks(T.V, 0, 1).size(), PieceDefs.SIMPLE_KICKS.size(), "custom simple kicks")


## On an empty board every piece must be able to rotate either way from
## every column it can occupy, including hard against either wall.
func test_every_piece_rotates_at_walls() -> void:
	var b := Board.new()
	for type in PieceDefs.COUNT:
		for rot in 4:
			for x in range(-3, Board.WIDTH):
				var pos := Vector2i(x, 10)
				if not b.can_place(type, rot, pos):
					continue
				for dir: int in [1, -1]:
					var to := posmod(rot + dir, 4)
					var k := GameRules.find_kick(b, type, rot, to, pos, true)
					check(k >= 0, "%s rot %d->%d at x=%d" % [PieceDefs.display_name(type), rot, to, x])


func test_i_wall_kick_moves_off_wall() -> void:
	var b := Board.new()
	# Vertical I in its left state hugging the left wall (column 0 = box x + 1).
	var pos := Vector2i(-1, 10)
	check(b.can_place(T.I, 3, pos), "setup fits")
	var k := GameRules.find_kick(b, T.I, 3, 0, pos, true)
	check(k > 0, "needs a kick")
	var landed := pos + PieceDefs.kicks(T.I, 3, 0)[k]
	check(b.can_place(T.I, 0, landed), "kicked position valid")


func test_t_floor_kick() -> void:
	var b := Board.new()
	# Flat T resting on the floor; rotating right needs an upward kick.
	var pos := Vector2i(4, Board.HEIGHT - 2)
	var k := GameRules.find_kick(b, T.T, 0, 1, pos, true)
	check(k >= 0, "floor kick found")
	check(PieceDefs.kicks(T.T, 0, 1)[k].y < 0, "kick goes up")
	check_eq(GameRules.find_kick(b, T.T, 0, 1, pos, false), -1, "blocked without up kicks")


func test_kick_into_t_slot() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"11...11111",
		"111.111111",
	]))
	# T above the slot, pointing right; rotating CW drops it into the slot
	# via a kick that moves it down.
	var pos := Vector2i(2, Board.HEIGHT - 4)
	check(b.can_place(T.T, 1, pos), "setup fits")
	var k := GameRules.find_kick(b, T.T, 1, 2, pos, true)
	check(k >= 0, "rotation succeeds")


func test_floor_kick_budget_in_session() -> void:
	var tuning := KinTest.instant_tuning()
	var s := KinTest.started_session(ModeConfig.classic(1, false), tuning)
	var successes := 0
	for i in tuning.floor_kick_limit + 3:
		KinTest.set_active(s, T.I, 0, Vector2i(3, Board.HEIGHT - 2))
		if s.rotate(1):
			successes += 1
	check_eq(successes, tuning.floor_kick_limit, "up kicks capped")


func test_custom_pieces_spawn_centered() -> void:
	for type in PieceDefs.CUSTOM:
		var pos := PieceDefs.spawn_position(type, Board.WIDTH)
		var b := Board.new()
		check(b.can_place(type, 0, pos), "%s spawns" % PieceDefs.display_name(type))
	check_eq(PieceDefs.cell_count(T.X), 5, "cross has 5 cells")
	check_eq(PieceDefs.cell_count(T.V), 3, "corner has 3 cells")
	check_eq(PieceDefs.cell_count(T.I3), 3, "trio has 3 cells")
