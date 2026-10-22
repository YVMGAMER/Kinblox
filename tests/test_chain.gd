extends KinTest


func _groups(b: Board) -> Array[PackedInt32Array]:
	var t := Tuning.new()
	return ChainResolver.find_groups(b, t.chain_min_group, t.chain_min_pieces)


func test_single_intact_piece_never_chains() -> void:
	var b := Board.new()
	b.place(PieceDefs.Type.O, 0, Vector2i(0, 20), 1)
	check(_groups(b).is_empty(), "one piece alone")


func test_two_pieces_same_color_form_group() -> void:
	var b := Board.new()
	b.place(PieceDefs.Type.O, 0, Vector2i(0, 20), 1)
	b.place(PieceDefs.Type.O, 0, Vector2i(2, 20), 2)
	var g := _groups(b)
	check_eq(g.size(), 1, "one group")
	check_eq(g[0].size(), 8, "8 cells")


func test_below_min_size() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray(["333......."]))
	check(_groups(b).is_empty(), "3 cells is not enough")


func test_diagonals_do_not_connect() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"22........",
		"..22......",
	]))
	check(_groups(b).is_empty(), "diagonal only")


func test_different_colors_do_not_connect() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray(["2233......"]))
	check(_groups(b).is_empty(), "mixed colors")


func test_column_gravity_keeps_holes() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"5.........",
		"..........",
		"4.........",
		"1111......",
	]))
	var removed := ChainResolver.remove_groups(b, _groups(b))
	check_eq(removed, 4, "removed")
	check_eq(b.to_pattern(4), PackedStringArray([
		"..........",
		"5.........",
		"..........",
		"4.........",
	]), "column fell by one, hole kept")


func test_multi_step_chain() -> void:
	var b := Board.new()
	# Step 1 clears the four 1s; the 2s above them fall onto the 2s at the
	# bottom and form a new group for step 2.
	b.load_pattern(PackedStringArray([
		"22........",
		"11........",
		"11........",
		"22........",
	]))
	check_eq(_groups(b).size(), 1, "only the 1s qualify at first")
	var t := Tuning.new()
	var steps := ChainResolver.resolve_all(b, t)
	check_eq(steps.size(), 2, "two steps")
	check_eq(steps[0], 4, "first step cells")
	check_eq(steps[1], 4, "second step cells")
	check_eq(b.cell_count(), 0, "everything cleared")


func test_chain_is_deterministic() -> void:
	var b := Board.new()
	var rng := SeededRng.new(77)
	for y in range(8, Board.HEIGHT):
		for x in Board.WIDTH:
			if rng.next_float() < 0.7:
				b.set_cell(x, y, rng.next_int(4), rng.next_int(30))
	var a := b.copy()
	var c := b.copy()
	var t := Tuning.new()
	check_eq(ChainResolver.resolve_all(a, t), ChainResolver.resolve_all(c, t), "same steps")
	check_eq(a.colors, c.colors, "same board")
	check_eq(a.owners, c.owners, "same owners")


func test_session_chain_after_line_clear() -> void:
	var s := KinTest.started_session(ModeConfig.classic(5, true))
	# Bottom row is full except column 9. Above it, a 2x2 block of color 6
	# made of two different pieces: a kin group that detonates once a line
	# clear triggers the scan.
	s.board.load_pattern(PackedStringArray([
		"66........",
		"66........",
		"012345012.",
	]), PackedStringArray([
		"aa........",
		"bb........",
		"cdefghijk.",
	]))
	var highlights: Array[int] = []
	var finished := [0]
	s.chain_highlight.connect(func(_g: Array[PackedInt32Array], _step: int, mult: int) -> void: highlights.append(mult))
	s.chain_finished.connect(func(steps: int) -> void: finished[0] = steps)
	# Vertical I into column 9 completes the bottom row.
	KinTest.set_active(s, PieceDefs.Type.I, 1, Vector2i(7, Board.HEIGHT - 4))
	s.hard_drop()
	check_eq(highlights, [2] as Array[int], "one chain step at x2")
	check_eq(finished[0], 1, "chain finished")
	check_eq(s.scoring.best_chain, 2, "best chain recorded")
	check(s.board.is_empty(0, Board.HEIGHT - 1), "group removed")


func test_pure_mode_has_no_chains() -> void:
	var s := KinTest.started_session(ModeConfig.classic(5, false))
	s.board.load_pattern(PackedStringArray([
		"66........",
		"66........",
		"012345012.",
	]), PackedStringArray([
		"aa........",
		"bb........",
		"cdefghijk.",
	]))
	var chained := [false]
	s.chain_highlight.connect(func(_g: Array[PackedInt32Array], _s: int, _m: int) -> void: chained[0] = true)
	KinTest.set_active(s, PieceDefs.Type.I, 1, Vector2i(7, Board.HEIGHT - 4))
	s.hard_drop()
	check(not chained[0], "no chain in Pure")
	check(not s.board.is_empty(0, Board.HEIGHT - 1), "group stays")
