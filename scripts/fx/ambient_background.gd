class_name AmbientBackground
extends Control
## Calm drifting color fields behind the board (Zen and menus). Soft edges
## come from stacking a few translucent circles. Static under reduce motion.

const BLOBS := 5
const LAYERS := 6

@export var intensity := 1.0

var _seeds := PackedVector4Array()
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in BLOBS:
		_seeds.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.04, 0.09), rng.randf_range(0.0, TAU)))
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())
	resized.connect(queue_redraw)


func _process(delta: float) -> void:
	if Settings.reduce_motion() or not is_visible_in_tree():
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var gt := ThemeManager.current
	var radius := size.x * 0.5
	for i in BLOBS:
		var s := _seeds[i]
		var t := _time * s.z + s.w
		var c := Vector2(size.x * (0.5 + 0.42 * sin(t + s.x * TAU)), size.y * (0.5 + 0.42 * cos(t * 0.8 + s.y * TAU)))
		var color := gt.piece_color(i * 2 % PieceDefs.COLOR_SLOTS) if i > 0 else gt.accent
		for l in LAYERS:
			var k := 1.0 - float(l) / LAYERS
			draw_circle(c, radius * k, Color(color, 0.018 * intensity), true, -1.0, true)
