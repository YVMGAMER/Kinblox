class_name PieceView
extends Control
## The active piece. Its shape is redrawn only on spawn/rotate; movement is
## a node-position glide toward the logical cell, so falling and sliding
## look smooth without redrawing every frame.

const GLIDE_RATE := 32.0
const SNAP_DISTANCE := 2.5

var board_view: BoardView
var session: GameSession

var _type := -1
var _rot := 0
var _visual := Vector2.ZERO
var _target := Vector2.ZERO
var _gt: GameTheme
var _patterns := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gt = ThemeManager.current
	_patterns = Settings.patterns_enabled()
	ThemeManager.theme_changed.connect(func(gt: GameTheme, _a: bool) -> void:
		_gt = gt
		queue_redraw())
	Settings.changed.connect(func(key: StringName) -> void:
		if key == &"patterns":
			_patterns = Settings.patterns_enabled()
			queue_redraw())


func bind(p_session: GameSession, p_board_view: BoardView) -> void:
	session = p_session
	board_view = p_board_view
	session.piece_spawned.connect(func(p: Piece) -> void: _sync(p, true))
	session.piece_moved.connect(func(p: Piece) -> void: _sync(p, false))
	session.hard_dropped.connect(func(p: Piece, _rows: int) -> void: _sync(p, true))
	session.piece_locked.connect(func(_c: Array[Vector2i], _t: int) -> void: _clear())
	session.state_changed.connect(func(_n: GameSession.State, _o: GameSession.State) -> void:
		if session.active == null:
			_clear())


func _sync(p: Piece, snap: bool) -> void:
	_target = Vector2(p.position)
	if snap or _type < 0 or _visual.distance_to(_target) > SNAP_DISTANCE or Settings.reduce_motion():
		_visual = _target
	if p.type != _type or p.rot != _rot:
		_type = p.type
		_rot = p.rot
		queue_redraw()
	visible = true
	_place()


func _clear() -> void:
	_type = -1
	visible = false


func _process(delta: float) -> void:
	if _type < 0:
		return
	if _visual != _target:
		_visual = _visual.lerp(_target, 1.0 - exp(-GLIDE_RATE * delta))
		if _visual.distance_squared_to(_target) < 0.0004:
			_visual = _target
		_place()


func _place() -> void:
	if board_view != null:
		position = board_view.cell_to_local(_visual)


func _draw() -> void:
	if _type < 0 or board_view == null:
		return
	var cs := board_view.cell_size
	var slot := PieceDefs.color_slot(_type)
	var color := _gt.piece_color(slot)
	for c in PieceDefs.cells(_type, _rot):
		CellPainter.draw_block(self, CellPainter.cell_rect(Vector2.ZERO, c, cs), color, slot, _patterns, _gt)
