class_name AmbientBackground
extends Control
## Calm drifting color fields behind the board (Zen) and the main menu.
## Each field is one radial-gradient texture tinted with a theme color, so
## edges are perfectly soft. Static under reduce motion.

const BLOBS := 5

@export var intensity := 1.0

var _seeds := PackedVector4Array()
var _time := 0.0
var _glow: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in BLOBS:
		_seeds.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.04, 0.09), rng.randf_range(0.0, TAU)))
	# Alpha mask only (white fading to transparent); color comes from the theme.
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.5, Color(1, 1, 1, 0.35))
	_glow = GradientTexture2D.new()
	_glow.gradient = g
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	_glow.width = 256
	_glow.height = 256
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if Settings.reduce_motion() or not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var gt := ThemeManager.current
	var radius := size.x * 0.75
	var alpha := (0.16 if gt.is_dark else 0.22) * intensity
	for i in BLOBS:
		var s := _seeds[i]
		var t := _time * s.z + s.w
		var c := Vector2(size.x * (0.5 + 0.45 * sin(t + s.x * TAU)), size.y * (0.5 + 0.42 * cos(t * 0.8 + s.y * TAU)))
		var color := gt.accent if i == 0 else gt.piece_color(i * 2 % PieceDefs.COLOR_SLOTS)
		draw_texture_rect(_glow, Rect2(c - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(color, alpha))
