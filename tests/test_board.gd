extends KinTest


func test_new_board_is_empty() -> void:
	var b := Board.new()
	check_eq(b.cell_count(), 0, "cells")
	check_eq(b.stack_height(), 0, "height")


func test_walls_and_floor_block_placement() -> void:
	var b := Board.new()
	var t := PieceDefs.Type.T
	check(b.can_place(t, 0, Vector2i(0, 10)), "fits at left edge")
	check(not b.can_place(t, 0, Vector2i(-1, 10)), "left wall")
	check(not b.can_place(t, 0, Vector2i(8, 10)), "right wall")
	check(b.can_place(t, 0, Vector2i(7, 10)), "fits at right edge")
	check(b.can_place(t, 0, Vector2i(3, Board.HEIGHT - 2)), "rests on floor")
	check(not b.can_place(t, 0, Vector2i(3, Board.HEIGHT - 1)), "floor")
	check(not b.can_place(t, 0, Vector2i(3, -1)), "above top")


func test_collision_with_filled_cells() -> void:
	var b := Board.new()
	b.set_cell(4, 15, 0, 1)
	var o := PieceDefs.Type.O
	check(not b.can_place(o, 0, Vector2i(3, 14)), "overlaps filled cell")
	check(b.can_place(o, 0, Vector2i(5, 14)), "beside filled cell")
	check(b.can_place(o, 0, Vector2i(3, 13)), "on top of filled cell")


func test_place_writes_color_and_owner() -> void:
	var b := Board.new()
	var cells := b.place(PieceDefs.Type.O, 0, Vector2i(0, 20), 77)
	check_eq(cells.size(), 4, "cells")
	check_eq(b.color_at(1, 21), PieceDefs.color_slot(PieceDefs.Type.O), "color")
	check_eq(b.owner_at(1, 21), 77, "owner")


func test_full_rows_detected() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"0000000000",
		"000000000.",
		"1111111111",
	]))
	check_eq(b.full_rows(), [Board.HEIGHT - 3, Board.HEIGHT - 1] as Array[int], "rows")


func test_clear_rows_shifts_content_down() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"2.........",
		"0000000000",
		"3........3",
		"1111111111",
	]))
	b.clear_rows(b.full_rows())
	check_eq(b.to_pattern(2), PackedStringArray(["2.........", "3........3"]), "after clear")
	check_eq(b.cell_count(), 3, "remaining cells")


func test_clear_four_rows() -> void:
	var b := Board.new()
	b.load_pattern(PackedStringArray([
		"5.........",
		"0000000000",
		"0000000000",
		"0000000000",
		"0000000000",
	]))
	b.clear_rows(b.full_rows())
	check_eq(b.to_pattern(1), PackedStringArray(["5........."]), "quad clear")


func test_empty_top_rows() -> void:
	var b := Board.new()
	for y in Board.HEIGHT:
		b.set_cell(0, y, 1, y)
	b.empty_top_rows(5)
	check(b.is_empty(0, 4), "row 4 cleared")
	check(not b.is_empty(0, 5), "row 5 kept")
