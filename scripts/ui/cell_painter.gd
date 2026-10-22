class_name CellPainter
extends RefCounted
## Shared cell drawing so the board, ghost, queues and tutorial all match.
## StyleBoxes are cached per (color, size) so redraws do not allocate.

const GAP_RATIO := 0.06
const RADIUS_RATIO := 0.22
const BEVEL_RATIO := 0.08

static var _boxes: Dictionary = {}  # int key -> StyleBoxFlat


static func clear_cache() -> void:
	_boxes.clear()


static func cell_rect(origin: Vector2, cell: Vector2i, size: float) -> Rect2:
	var gap := size * GAP_RATIO
	return Rect2(origin + Vector2(cell) * size + Vector2(gap, gap) * 0.5, Vector2(size - gap, size - gap))


static func draw_block(ci: CanvasItem, rect: Rect2, color: Color, slot: int, patterns: bool, gt: GameTheme) -> void:
	ci.draw_style_box(_box(color, rect.size.x, false), rect)
	if patterns:
		draw_pattern(ci, rect, slot, gt.pattern_color)


static func draw_ghost(ci: CanvasItem, rect: Rect2, color: Color, gt: GameTheme) -> void:
	ci.draw_style_box(_box(Color(color, gt.ghost_alpha), rect.size.x, true), rect)


static func draw_well(ci: CanvasItem, rect: Rect2, color: Color) -> void:
	ci.draw_style_box(_box(color, rect.size.x, false, false), rect)


## A distinct glyph per color slot for colorblind players.
static func draw_pattern(ci: CanvasItem, rect: Rect2, slot: int, color: Color) -> void:
	var c := rect.get_center()
	var r := rect.size.x * 0.2
	var w := maxf(rect.size.x * 0.08, 2.0)
	match slot:
		0:
			ci.draw_line(c - Vector2(r, 0), c + Vector2(r, 0), color, w, true)
		1:
			ci.draw_circle(c, r * 0.55, color, true, -1.0, true)
		2:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)]), color)
		3:
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), color, w, true)
		4:
			ci.draw_line(c + Vector2(-r, -r), c + Vector2(r, r), color, w, true)
			ci.draw_line(c + Vector2(-r, r), c + Vector2(r, -r), color, w, true)
		5:
			ci.draw_line(c - Vector2(0, r), c + Vector2(0, r), color, w, true)
		6:
			ci.draw_arc(c, r * 0.8, 0.0, TAU, 20, color, w, true)
		7:
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), color)


## Draws a piece type centered in a rect (for hold / next previews).
static func draw_preview(ci: CanvasItem, area: Rect2, type: int, cell: float, alpha: float, patterns: bool, gt: GameTheme) -> void:
	var cells := PieceDefs.cells(type, 0)
	var lo := Vector2i(99, 99)
	var hi := Vector2i(-99, -99)
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var span := Vector2(hi - lo + Vector2i.ONE) * cell
	var origin := area.get_center() - span * 0.5 - Vector2(lo) * cell
	var color := Color(gt.piece_color(PieceDefs.color_slot(type)), alpha)
	for c in cells:
		draw_block(ci, cell_rect(origin, c, cell), color, PieceDefs.color_slot(type), patterns, gt)


static func _box(color: Color, size: float, outline: bool, bevel: bool = true) -> StyleBoxFlat:
	var key := (color.to_rgba32() << 13) ^ (int(size) << 1) ^ (1 if outline else 0) ^ (0 if bevel else 1 << 12)
	var sb: StyleBoxFlat = _boxes.get(key)
	if sb != null:
		return sb
	sb = StyleBoxFlat.new()
	sb.anti_aliasing = true
	sb.corner_detail = 6
	sb.set_corner_radius_all(int(size * RADIUS_RATIO))
	if outline:
		sb.bg_color = Color(color, color.a * 0.25)
		sb.border_color = color
		sb.set_border_width_all(maxi(int(size * 0.06), 2))
	else:
		sb.bg_color = color
		if bevel:
			sb.border_color = color.lightened(0.28)
			sb.border_width_top = maxi(int(size * BEVEL_RATIO), 2)
	if _boxes.size() > 512:
		_boxes.clear()
	_boxes[key] = sb
	return sb
