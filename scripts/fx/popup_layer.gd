class_name PopupLayer
extends Control
## Pooled floating text for score pop-ups ("+800", "Quad", "Chain x3").
## Labels are created once and recycled.

const POOL := 10
const RISE := 96.0
const DURATION := 0.9

var _labels: Array[Label] = []
var _tweens: Array[Tween] = []
var _next := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in POOL:
		var l := Label.new()
		l.theme_type_variation = &"ValueLabel"
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.visible = false
		add_child(l)
		_labels.append(l)
		_tweens.append(null)


## `at` is in this layer's local coordinates.
func pop(text: String, at: Vector2, color: Color, scale_factor: float = 1.0) -> void:
	var i := _next
	_next = (_next + 1) % POOL
	if _tweens[i] != null:
		_tweens[i].kill()
	var l := _labels[i]
	l.text = text
	l.add_theme_color_override(&"font_color", color)
	l.reset_size()
	l.pivot_offset = l.size * 0.5
	l.position = at - l.size * 0.5
	l.modulate.a = 1.0
	l.visible = true
	var still := Settings.reduce_motion()
	l.scale = Vector2.ONE * scale_factor * (1.0 if still else 0.6)
	var tw := create_tween().set_parallel(true)
	if not still:
		tw.tween_property(l, "scale", Vector2.ONE * scale_factor, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(l, "position:y", l.position.y - RISE, DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, DURATION * 0.45).set_delay(DURATION * 0.55)
	tw.chain().tween_callback(func() -> void: l.visible = false)
	_tweens[i] = tw


func clear() -> void:
	for i in POOL:
		if _tweens[i] != null:
			_tweens[i].kill()
		_labels[i].visible = false
