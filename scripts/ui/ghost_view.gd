class_name GhostView
extends Control
## Outline showing where the active piece would land.

var board_view: BoardView
var session: GameSession

var _gt: GameTheme
var _enabled := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gt = ThemeManager.current
	_enabled = Settings.ghost_enabled()
	ThemeManager.theme_changed.connect(func(gt: GameTheme, _a: bool) -> void:
		_gt = gt
		queue_redraw())
	Settings.changed.connect(func(key: StringName) -> void:
		if key == &"ghost":
			_enabled = Settings.ghost_enabled()
			queue_redraw())


func bind(p_session: GameSession, p_board_view: BoardView) -> void:
	session = p_session
	board_view = p_board_view
	session.piece_spawned.connect(func(_p: Piece) -> void: queue_redraw())
	session.piece_moved.connect(func(_p: Piece) -> void: queue_redraw())
	session.piece_locked.connect(func(_c: Array[Vector2i], _t: int) -> void: queue_redraw())
	session.board_changed.connect(queue_redraw)
	session.state_changed.connect(func(_n: GameSession.State, _o: GameSession.State) -> void: queue_redraw())


func _draw() -> void:
	if not _enabled or session == null or board_view == null or session.active == null:
		return
	if session.state != GameSession.State.PLAYING:
		return
	var p := session.active
	var gy := session.ghost_y()
	if gy == p.position.y:
		return
	var cs := board_view.cell_size
	var origin := board_view.cell_to_local(Vector2(p.position.x, gy))
	var color := _gt.piece_color(PieceDefs.color_slot(p.type))
	for c in PieceDefs.cells(p.type, p.rot):
		if gy + c.y < Board.HIDDEN_ROWS:
			continue
		CellPainter.draw_ghost(self, CellPainter.cell_rect(origin, c, cs), color, _gt)
