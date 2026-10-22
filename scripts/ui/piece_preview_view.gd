class_name PiecePreviewView
extends Control
## Shows either the hold slot or the next queue, centered in its rect.
## In queue mode the first piece is larger and the rest step down in size.

enum Source { HOLD, NEXT }

@export var source: Source = Source.NEXT

var session: GameSession
var _gt: GameTheme
var _patterns := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gt = ThemeManager.current
	_patterns = Settings.patterns_enabled()
	resized.connect(queue_redraw)
	ThemeManager.theme_changed.connect(func(gt: GameTheme, _a: bool) -> void:
		_gt = gt
		queue_redraw())
	Settings.changed.connect(func(key: StringName) -> void:
		if key == &"patterns":
			_patterns = Settings.patterns_enabled()
			queue_redraw())


func bind(p_session: GameSession) -> void:
	session = p_session
	session.queue_changed.connect(queue_redraw)
	session.hold_changed.connect(func(_t: int) -> void: queue_redraw())
	session.piece_spawned.connect(func(_p: Piece) -> void: queue_redraw())
	queue_redraw()


func _draw() -> void:
	if session == null or _gt == null:
		return
	var area := Rect2(Vector2.ZERO, size)
	if source == Source.HOLD:
		if session.hold_type >= 0:
			var alpha := 1.0 if session.can_hold() or session.active == null else 0.35
			var cell := minf(area.size.x / 4.6, area.size.y / 3.0)
			CellPainter.draw_preview(self, area, session.hold_type, cell, alpha, _patterns, _gt)
		return
	var count := session.queue.size()
	if count == 0:
		return
	# Weighted slots: first piece gets 1.4x the width of the others.
	var weights := PackedFloat32Array()
	var total := 0.0
	for i in count:
		var w := 1.4 if i == 0 else 1.0
		weights.append(w)
		total += w
	var x := 0.0
	for i in count:
		var w := area.size.x * weights[i] / total
		var slot := Rect2(Vector2(x, 0), Vector2(w, area.size.y))
		var cell := minf(w / 4.6, area.size.y / 3.0) * (1.0 if i == 0 else 0.82)
		CellPainter.draw_preview(self, slot, session.queue[i], cell, 1.0 if i == 0 else 0.75, _patterns, _gt)
		x += w
