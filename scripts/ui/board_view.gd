class_name BoardView
extends Control
## Draws the well, locked cells and board-level animations (line flash,
## lock squash, chain highlight, Zen sweep). Redraws only when the board
## changes or while an animation is running.

const LOCK_ANIM := 0.16
const FRAME_PAD := 12.0

var session: GameSession
var cell_size := 64.0
var patterns := false

var _gt: GameTheme
var _frame_box: StyleBoxFlat
var _ring_box: StyleBoxFlat
var _flash_rows: Array[int] = []
var _flash_t := 0.0
var _flash_len := 0.3
var _lock_cells: Array[Vector2i] = []
var _lock_t := 1.0
var _highlight := PackedByteArray()
var _highlight_t := 0.0
var _highlight_on := false
var _sweep_rows := 0
var _sweep_t := 0.0
var _sweep_len := 0.8


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.resize(Board.WIDTH * Board.HEIGHT)
	_set_theme(ThemeManager.current)
	patterns = Settings.patterns_enabled()
	ThemeManager.theme_changed.connect(func(gt: GameTheme, _a: bool) -> void: _set_theme(gt))
	Settings.changed.connect(func(key: StringName) -> void:
		if key == &"patterns":
			patterns = Settings.patterns_enabled()
			queue_redraw())
	set_process(false)


func bind(p_session: GameSession) -> void:
	session = p_session
	session.board_changed.connect(_on_board_changed)
	session.piece_locked.connect(_on_piece_locked)
	session.lines_cleared.connect(_on_lines_cleared)
	session.chain_highlight.connect(_on_chain_highlight)
	session.chain_step_resolved.connect(_on_chain_resolved)
	session.zen_sweep_started.connect(_on_zen_sweep)
	_flash_len = session.tuning.line_clear_delay
	_sweep_len = session.tuning.zen_sweep_delay
	queue_redraw()


func set_cell_size(size_px: float) -> void:
	cell_size = size_px
	size = Vector2(Board.WIDTH, Board.VISIBLE_ROWS) * cell_size
	_set_theme(_gt)


## Top-left of a board cell in local coordinates.
func cell_to_local(cell: Vector2) -> Vector2:
	return Vector2(cell.x, cell.y - Board.HIDDEN_ROWS) * cell_size


func cell_center(cell: Vector2i) -> Vector2:
	return cell_to_local(Vector2(cell)) + Vector2.ONE * cell_size * 0.5


func _process(delta: float) -> void:
	var busy := false
	if _lock_t < 1.0:
		_lock_t = minf(_lock_t + delta / LOCK_ANIM, 1.0)
		busy = true
	if not _flash_rows.is_empty():
		_flash_t += delta
		busy = true
	if _highlight_on:
		_highlight_t += delta
		busy = true
	if _sweep_rows > 0:
		_sweep_t += delta
		busy = true
	queue_redraw()
	if not busy:
		set_process(false)


func _draw() -> void:
	if _gt == null:
		return
	var frame := Rect2(Vector2(-FRAME_PAD, -FRAME_PAD), size + Vector2(FRAME_PAD, FRAME_PAD) * 2.0)
	draw_style_box(_frame_box, frame)
	var origin := Vector2(0, -Board.HIDDEN_ROWS * cell_size)
	for y in range(Board.HIDDEN_ROWS, Board.HEIGHT):
		for x in Board.WIDTH:
			CellPainter.draw_well(self, CellPainter.cell_rect(origin, Vector2i(x, y), cell_size), _gt.well)
	if session == null:
		return
	var board := session.board
	for y in range(Board.HIDDEN_ROWS, Board.HEIGHT):
		var flashing := y in _flash_rows
		var sweeping := y < _sweep_rows
		for x in Board.WIDTH:
			var slot := board.color_at(x, y)
			if slot == Board.EMPTY:
				continue
			var rect := CellPainter.cell_rect(origin, Vector2i(x, y), cell_size)
			var color := _gt.piece_color(slot)
			if flashing:
				var k := clampf(_flash_t / maxf(_flash_len, 0.01), 0.0, 1.0)
				rect = _scale_rect(rect, Vector2.ONE * (1.0 - 0.6 * k * k))
				color = color.lerp(_gt.flash, 0.7 * (1.0 - k) + 0.3)
			elif sweeping:
				color.a *= 1.0 - clampf(_sweep_t / maxf(_sweep_len, 0.01), 0.0, 1.0)
			elif _highlight_on:
				if _highlight[Board.index(x, y)] == 1:
					var pulse := 0.5 + 0.5 * sin(_highlight_t * 22.0)
					color = color.lerp(_gt.flash, 0.15 + 0.3 * pulse)
					rect = _scale_rect(rect, Vector2.ONE * (1.0 + 0.06 * pulse))
					CellPainter.draw_block(self, rect, color, slot, patterns, _gt)
					draw_style_box(_ring_box, rect.grow(cell_size * 0.06))
					continue
				# Everything that is not kin steps back so the groups read clearly.
				color.a *= 0.4
			CellPainter.draw_block(self, rect, color, slot, patterns, _gt)
	if _lock_t < 1.0:
		var k := _lock_t
		var squash := Vector2(1.0 + 0.1 * (1.0 - k), 1.0 - 0.14 * (1.0 - k))
		for c in _lock_cells:
			if c.y < Board.HIDDEN_ROWS or board.is_empty(c.x, c.y):
				continue
			var rect := _scale_rect(CellPainter.cell_rect(origin, c, cell_size), squash)
			rect.position.y += cell_size * 0.07 * (1.0 - k)
			var color := _gt.piece_color(board.color_at(c.x, c.y)).lerp(_gt.flash, 0.35 * (1.0 - k))
			CellPainter.draw_block(self, rect, color, board.color_at(c.x, c.y), patterns, _gt)
	for r in _flash_rows:
		if r < Board.HIDDEN_ROWS:
			continue
		var k := clampf(_flash_t / maxf(_flash_len, 0.01), 0.0, 1.0)
		var row_rect := Rect2(Vector2(0, (r - Board.HIDDEN_ROWS) * cell_size), Vector2(size.x, cell_size))
		draw_rect(row_rect, Color(_gt.flash, 0.55 * (1.0 - k)))


func _set_theme(gt: GameTheme) -> void:
	_gt = gt
	_frame_box = StyleBoxFlat.new()
	_frame_box.bg_color = gt.board_background
	_frame_box.set_corner_radius_all(UiTokens.RADIUS_MD)
	_frame_box.anti_aliasing = true
	_frame_box.border_color = gt.outline
	_frame_box.set_border_width_all(2)
	_ring_box = StyleBoxFlat.new()
	_ring_box.draw_center = false
	_ring_box.border_color = gt.flash
	_ring_box.set_border_width_all(3)
	_ring_box.set_corner_radius_all(int(cell_size * CellPainter.RADIUS_RATIO) + 2)
	_ring_box.anti_aliasing = true
	queue_redraw()


static func _scale_rect(rect: Rect2, s: Vector2) -> Rect2:
	var c := rect.get_center()
	var half := rect.size * s * 0.5
	return Rect2(c - half, half * 2.0)


func _animate() -> void:
	set_process(true)
	queue_redraw()


## The session announces rows (lines_cleared / zen_sweep_started) after the
## lock's board change and before the board changes again, so any board
## change here means those rows are gone.
func _on_board_changed() -> void:
	_flash_rows.clear()
	_sweep_rows = 0
	queue_redraw()


func _on_piece_locked(cells: Array[Vector2i], _type: int) -> void:
	_lock_cells = cells
	_lock_t = 0.0 if not Settings.reduce_motion() else 1.0
	_animate()


func _on_lines_cleared(rows: Array[int], _award: Scoring.Award) -> void:
	_flash_rows = rows.duplicate()
	_flash_t = 0.0
	_animate()


func _on_chain_highlight(groups: Array[PackedInt32Array], _step: int, _mult: int) -> void:
	_highlight.fill(0)
	for g in groups:
		for i in g:
			_highlight[i] = 1
	_highlight_on = true
	_highlight_t = 0.0
	_animate()


func _on_chain_resolved(_step: int, _mult: int, _cells: int, _points: int, _cascade: Array[int]) -> void:
	_highlight_on = false
	queue_redraw()


func _on_zen_sweep(rows: int) -> void:
	_sweep_rows = rows
	_sweep_t = 0.0
	_animate()


## Cells currently highlighted for a chain (board coordinates).
func highlighted_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for i in _highlight.size():
		if _highlight[i] == 1:
			@warning_ignore("integer_division")
			out.append(Vector2i(i % Board.WIDTH, i / Board.WIDTH))
	return out
