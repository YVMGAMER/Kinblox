class_name TutorialIllustration
extends Control
## Small looping demos for the How to play pages, drawn on a 6 x 8 mini
## board with the same CellPainter as the game. Each page is a function of
## time, so there is no state to reset between pages.

enum Page { MOVE, ROTATE, DROP, HOLD, LINES, CHAIN }

const COLS := 6
const ROWS := 8
const T_CELLS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
const CHAIN_FRAMES := [
	["22....", "11....", "11....", "22.6..", "354335"],
	["22....", "11....", "11....", "22.6.."],
	["22....", "22.6.."],
	["...6.."],
]

var page: Page = Page.MOVE
var _t := 0.0
var _cell := 48.0
var _origin := Vector2.ZERO
var _frame: StyleBoxFlat
var _hold_box: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: _frame = null)


func show_page(p: Page) -> void:
	page = p
	_t = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta * (0.5 if Settings.reduce_motion() else 1.0)
	queue_redraw()


func _draw() -> void:
	var gt := ThemeManager.current
	_cell = floorf(minf(size.x / (COLS + 3.5), size.y / (ROWS + 0.6)))
	_origin = ((size - Vector2(COLS, ROWS) * _cell) * 0.5).floor()
	if page == Page.HOLD:
		_origin.x += _cell * 1.2
	if _frame == null:
		_frame = StyleBoxFlat.new()
		_frame.bg_color = gt.board_background
		_frame.border_color = gt.outline
		_frame.set_border_width_all(2)
		_frame.set_corner_radius_all(UiTokens.RADIUS_SM)
		_frame.anti_aliasing = true
	draw_style_box(_frame, Rect2(_origin - Vector2(8, 8), Vector2(COLS, ROWS) * _cell + Vector2(16, 16)))
	for y in ROWS:
		for x in COLS:
			CellPainter.draw_well(self, CellPainter.cell_rect(_origin, Vector2i(x, y), _cell), gt.well)
	match page:
		Page.MOVE:
			_draw_move(gt)
		Page.ROTATE:
			_draw_rotate(gt)
		Page.DROP:
			_draw_drop(gt)
		Page.HOLD:
			_draw_hold(gt)
		Page.LINES:
			_draw_lines(gt)
		Page.CHAIN:
			_draw_chain(gt)


#region Pages

func _draw_move(gt: GameTheme) -> void:
	_rows(gt, ["1.....", "11..53"])
	var xs := [1, 2, 3, 2, 1, 0]
	var x: int = xs[int(_t * 2.2) % xs.size()]
	_piece(gt, T_CELLS, 2, Vector2(x, 1))
	_finger(gt, Vector2(x + 1.5, 4.5), true, Vector2(-1.4, 0))


func _draw_rotate(gt: GameTheme) -> void:
	_rows(gt, ["4....3", "44..33"])
	var step := int(_t * 1.4)
	var cells := T_CELLS
	for i in step % 4:
		var turned: Array[Vector2i] = []
		for c in cells:
			turned.append(Vector2i(2 - c.y, c.x))
		cells = turned
	_piece(gt, cells, 2, Vector2(1.5, 2))
	var phase := fmod(_t * 1.4, 1.0)
	_tap_ring(gt, Vector2(3, ROWS - 1.6), phase)


func _draw_drop(gt: GameTheme) -> void:
	_rows(gt, ["5....1", "55.111"])
	var cycle := fmod(_t, 2.6)
	var landing := 5.0
	var y := 0.0
	var finger_y := 2.0
	if cycle < 1.2:
		y = floorf(cycle * 2.0)
		finger_y = 2.0 + y
	elif cycle < 1.4:
		y = landing
		finger_y = 4.0 + (cycle - 1.2) * 15.0
	else:
		y = landing
		finger_y = -1.0
	if cycle < 1.2:
		_piece(gt, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 1, Vector2(2, landing), true)
	_piece(gt, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], 1, Vector2(2, y))
	if finger_y >= 0.0:
		_finger(gt, Vector2(4.6, finger_y + 0.5), true, Vector2(0, -1.6))
	_caption(gt, "Slow: soft drop" if cycle < 1.2 else "Flick: hard drop")


func _draw_hold(gt: GameTheme) -> void:
	_rows(gt, ["3....2", "33.222"])
	var swapped := int(_t / 1.3) % 2 == 1
	var box := Rect2(_origin + Vector2(-_cell * 3.0, 0), Vector2(_cell * 2.4, _cell * 2.4))
	if _hold_box == null:
		_hold_box = StyleBoxFlat.new()
		_hold_box.set_corner_radius_all(UiTokens.RADIUS_SM)
	_hold_box.bg_color = gt.surface_alt
	draw_style_box(_hold_box, box)
	draw_string(ThemeManager.font_caps, box.position + Vector2(0, -10), "HOLD", HORIZONTAL_ALIGNMENT_CENTER, box.size.x, UiTokens.FONT_CAPTION, gt.text_muted)
	var held := 0 if swapped else 2
	var active := 2 if swapped else 0
	CellPainter.draw_preview(self, box, PieceDefs.Type.I if held == 0 else PieceDefs.Type.T, _cell * 0.5, 1.0, false, gt)
	if active == 0:
		_piece(gt, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], 0, Vector2(1, 1))
	else:
		_piece(gt, T_CELLS, 2, Vector2(1.5, 1))
	_tap_ring(gt, (box.get_center() - _origin) / _cell, fmod(_t / 1.3, 1.0))


func _draw_lines(gt: GameTheme) -> void:
	var cycle := fmod(_t, 2.4)
	if cycle < 1.0:
		_rows(gt, ["4.....", "44.33.", "135562"])
		_piece(gt, [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], 0, Vector2(5, floorf(cycle * 4.0) - 1.0))
	elif cycle < 1.5:
		var k := (cycle - 1.0) / 0.5
		_rows(gt, ["4.....", "44.330", "135560"], ROWS - 1, k)
		_piece(gt, [Vector2i(0, 0), Vector2i(0, 1)], 0, Vector2(5, ROWS - 4))
	else:
		_rows(gt, ["4....0", "44.330"])
		_piece(gt, [Vector2i(0, 0)], 0, Vector2(5, ROWS - 3))
		_caption(gt, "Line clear")


func _draw_chain(gt: GameTheme) -> void:
	var f := int(_t / 0.9) % (CHAIN_FRAMES.size() + 1)
	if f >= CHAIN_FRAMES.size():
		f = CHAIN_FRAMES.size() - 1
	var rows: Array = CHAIN_FRAMES[f]
	match f:
		0:
			_rows(gt, rows, ROWS - 1, fmod(_t / 0.9, 1.0))
			_caption(gt, "Clear a line…")
		1:
			_rows(gt, rows, -1, 0.0, [Vector2i(0, 5), Vector2i(1, 5), Vector2i(0, 6), Vector2i(1, 6)])
			_caption(gt, "Kin burst: Chain ×2")
		2:
			_rows(gt, rows, -1, 0.0, [Vector2i(0, 6), Vector2i(1, 6), Vector2i(0, 7), Vector2i(1, 7)])
			_caption(gt, "They fall and link: ×3")
		3:
			_rows(gt, rows)
			_caption(gt, "")

#endregion

#region Drawing helpers

## Draws bottom-aligned rows of color digits. A flashing row shrinks and
## whitens with progress k; `ring` cells get a highlight outline.
func _rows(gt: GameTheme, rows: Array, flash_row: int = -1, k: float = 0.0, ring: Array[Vector2i] = []) -> void:
	var top := ROWS - rows.size()
	for r in rows.size():
		var line: String = rows[r]
		for x in mini(line.length(), COLS):
			if line[x] == ".":
				continue
			var cell := Vector2i(x, top + r)
			var rect := CellPainter.cell_rect(_origin, cell, _cell)
			var color := gt.piece_color(line[x].to_int())
			if cell.y == flash_row:
				var s := 1.0 - 0.7 * k
				rect = Rect2(rect.get_center() - rect.size * s * 0.5, rect.size * s)
				color = color.lerp(gt.flash, 0.6)
			elif not ring.is_empty() and not ring.has(cell):
				color.a *= 0.4
			CellPainter.draw_block(self, rect, color, line[x].to_int(), false, gt)
			if ring.has(cell):
				draw_rect(rect.grow(3), gt.flash, false, 3.0)


func _piece(gt: GameTheme, cells: Array[Vector2i], slot: int, at: Vector2, ghost: bool = false) -> void:
	var color := gt.piece_color(slot)
	for c in cells:
		var rect := CellPainter.cell_rect(_origin + at * _cell, c, _cell)
		if ghost:
			CellPainter.draw_ghost(self, rect, color, gt)
		else:
			CellPainter.draw_block(self, rect, color, slot, false, gt)


func _finger(gt: GameTheme, at_cells: Vector2, pressed: bool, trail: Vector2) -> void:
	var p := _origin + at_cells * _cell
	if trail != Vector2.ZERO:
		draw_line(p, p + trail * _cell, Color(gt.text_primary, 0.18), _cell * 0.5, true)
	draw_circle(p, _cell * 0.38, Color(gt.text_primary, 0.35 if pressed else 0.2), true, -1.0, true)
	draw_circle(p, _cell * 0.38, Color(gt.text_primary, 0.8), false, 3.0, true)


func _tap_ring(gt: GameTheme, at_cells: Vector2, phase: float) -> void:
	var p := _origin + at_cells * _cell
	draw_circle(p, _cell * (0.3 + 0.6 * phase), Color(gt.text_primary, 0.7 * (1.0 - phase)), false, 3.0, true)
	draw_circle(p, _cell * 0.3, Color(gt.text_primary, 0.35), true, -1.0, true)


func _caption(gt: GameTheme, text: String) -> void:
	if text.is_empty():
		return
	draw_string(ThemeManager.font_bold, Vector2(0, _origin.y - _cell * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, size.x, UiTokens.FONT_SMALL, gt.accent)

#endregion
