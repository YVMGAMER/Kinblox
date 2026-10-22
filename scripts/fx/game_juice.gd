class_name GameJuice
extends Node
## Visual feedback for gameplay events: particle bursts, score pop-ups,
## banners and screen shake. Observes the session; never changes it.

var board_view: BoardView
var particles: ParticleField
var popups: PopupLayer
var banner: Banner
var shaker: Shaker

var _session: GameSession
var _chain_cells: Array[Vector2i] = []
var _chain_slots := PackedInt32Array()


func bind(session: GameSession) -> void:
	_session = session
	session.lines_cleared.connect(_on_lines_cleared)
	session.chain_highlight.connect(_on_chain_highlight)
	session.chain_step_resolved.connect(_on_chain_resolved)
	session.hard_dropped.connect(_on_hard_dropped)
	# Zen has one constant speed, so levels are not announced there.
	if session.mode.fixed_gravity_interval <= 0.0:
		session.level_changed.connect(func(level: int) -> void: banner.show_text("Level %d" % level, "Speed up"))
	session.zen_sweep_started.connect(func(_r: int) -> void: banner.show_text("Fresh start", "The top is clear"))


func _gt() -> GameTheme:
	return ThemeManager.current


func _to_popup_space(board_local: Vector2) -> Vector2:
	var global := board_view.get_global_transform() * board_local
	return popups.get_global_transform().affine_inverse() * global


func _on_lines_cleared(rows: Array[int], award: Scoring.Award) -> void:
	var cs := board_view.cell_size
	var center_y := 0.0
	for r in rows:
		var colors := PackedColorArray()
		for x in Board.WIDTH:
			colors.append(_gt().piece_color(_session.board.color_at(x, r)))
		var left := board_view.cell_to_local(Vector2(0, r)) + Vector2(0, cs * 0.5)
		particles.row_burst(left, Board.WIDTH * cs, colors, 3, cs * 9.0, cs * 0.22)
		center_y += left.y
	center_y /= rows.size()
	var at := _to_popup_space(Vector2(board_view.size.x * 0.5, center_y))
	popups.pop("+%s" % DailyCalendar.format_number(award.points), at, _gt().text_primary, 1.0)
	if rows.size() >= 2:
		var label := award.label()
		if award.back_to_back:
			label = "Back-to-back " + label
		popups.pop(label, at - Vector2(0, cs * 1.1), _gt().accent, 0.8)
	if rows.size() >= 3:
		shaker.add_trauma(0.45 if rows.size() == 3 else 0.65)


func _on_chain_highlight(groups: Array[PackedInt32Array], _step: int, multiplier: int) -> void:
	_chain_cells.clear()
	_chain_slots.clear()
	var sum := Vector2.ZERO
	for g in groups:
		for i in g:
			@warning_ignore("integer_division")
			var cell := Vector2i(i % Board.WIDTH, i / Board.WIDTH)
			_chain_cells.append(cell)
			_chain_slots.append(_session.board.color_at(cell.x, cell.y))
			sum += board_view.cell_center(cell)
	if _chain_cells.is_empty():
		return
	var center := sum / _chain_cells.size()
	popups.pop("Chain ×%d" % multiplier, _to_popup_space(center), _gt().accent, 0.9)


func _on_chain_resolved(step: int, _multiplier: int, _cells: int, points: int, cascade: Array[int]) -> void:
	var cs := board_view.cell_size
	var sum := Vector2.ZERO
	for i in _chain_cells.size():
		var p := board_view.cell_center(_chain_cells[i])
		sum += p
		particles.burst(p, _gt().piece_color(_chain_slots[i]), 4, cs * 7.0, cs * 0.24)
	if not _chain_cells.is_empty():
		var center := sum / _chain_cells.size()
		popups.pop("+%s" % DailyCalendar.format_number(points), _to_popup_space(center + Vector2(0, cs)), _gt().text_primary, 0.85)
	if step >= 3 or not cascade.is_empty():
		shaker.add_trauma(0.3 + 0.08 * mini(step, 5))
	_chain_cells.clear()
	_chain_slots.clear()


func _on_hard_dropped(piece: Piece, rows: int) -> void:
	if rows < 2:
		return
	var cs := board_view.cell_size
	var color := _gt().piece_color(PieceDefs.color_slot(piece.type))
	var cells := piece.board_cells()
	for c in cells:
		if (c + Vector2i.DOWN) in cells:
			continue
		var bottom := board_view.cell_center(c) + Vector2(0, cs * 0.5)
		particles.burst(bottom, Color(color, 0.7), 2, cs * 3.0, cs * 0.14)
