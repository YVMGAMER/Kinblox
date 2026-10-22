class_name LogoMark
extends Control
## The Kinblox mark: six blocks forming a K, in the active theme's colors.
## Blocks settle in one by one when `animate_in()` is called.

const CELLS: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 0), Vector2i(2, 2)]

var _progress := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())
	resized.connect(queue_redraw)


func animate_in(duration: float = 0.6) -> void:
	if Settings.reduce_motion():
		_progress = 1.0
		queue_redraw()
		return
	_progress = 0.0
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_progress = v
		queue_redraw(), 0.0, 1.0, duration)


func _draw() -> void:
	var gt := ThemeManager.current
	var cell := minf(size.x, size.y) / 3.0
	var origin := (size - Vector2(cell, cell) * 3.0) * 0.5
	var colors := [gt.accent, gt.accent, gt.accent, gt.piece_color(0), gt.piece_color(1), gt.piece_color(4)]
	for i in CELLS.size():
		var k := clampf(_progress * CELLS.size() - i, 0.0, 1.0)
		if k <= 0.0:
			continue
		var ease := 1.0 - pow(1.0 - k, 3.0)
		var offset := Vector2(0, -cell * 0.6 * (1.0 - ease))
		var rect := CellPainter.cell_rect(origin + offset, CELLS[i], cell)
		var c: Color = colors[i]
		c.a *= ease
		CellPainter.draw_block(self, rect, c, 0, false, gt)
