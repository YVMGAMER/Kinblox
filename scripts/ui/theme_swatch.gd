class_name ThemeSwatch
extends BaseButton
## Preview tile for one theme: its own background, a few piece colors and
## its name. Draws the colors of the theme it represents, not the active one.

var preview: GameTheme
var _box: StyleBoxFlat
var _ring: StyleBoxFlat


func _init(p_theme: GameTheme) -> void:
	preview = p_theme
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(0, 176)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box = StyleBoxFlat.new()
	_box.bg_color = preview.background
	_box.set_corner_radius_all(UiTokens.RADIUS_MD)
	_box.border_color = preview.outline
	_box.set_border_width_all(2)
	_box.anti_aliasing = true
	_ring = StyleBoxFlat.new()
	_ring.draw_center = false
	_ring.set_corner_radius_all(UiTokens.RADIUS_MD + 6)
	_ring.set_border_width_all(4)
	_ring.anti_aliasing = true


func _ready() -> void:
	toggled.connect(func(_on: bool) -> void: queue_redraw())
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())


func _draw() -> void:
	var rect := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	if button_pressed:
		_ring.border_color = ThemeManager.current.accent
		draw_style_box(_ring, Rect2(Vector2.ZERO, size))
	draw_style_box(_box, rect)
	var cell := minf(rect.size.x / 6.0, 34.0)
	var start := rect.position + Vector2(UiTokens.S3, UiTokens.S3)
	for i in 4:
		var r := Rect2(start + Vector2(i * cell * 1.1, 0), Vector2(cell, cell))
		CellPainter.draw_block(self, r, preview.piece_colors[[0, 2, 1, 4][i]], 0, false, preview)
	var font := ThemeManager.font_bold
	var fs := UiTokens.FONT_SMALL
	var baseline := rect.end.y - UiTokens.S3
	draw_string(font, Vector2(rect.position.x + UiTokens.S3, baseline), preview.display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, preview.text_primary)
