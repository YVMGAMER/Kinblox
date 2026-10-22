class_name Banner
extends VBoxContainer
## Centered announcement ("Level 5", "Ready") with a quick rise-and-fade.

const HOLD_TIME := 0.9

var _title: Label
var _subtitle: Label
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override(&"separation", UiTokens.S1)
	_title = Label.new()
	_title.theme_type_variation = &"BannerLabel"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle = Label.new()
	_subtitle.theme_type_variation = &"CaptionLabel"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	add_child(_subtitle)
	modulate.a = 0.0


func show_text(title: String, subtitle: String = "", hold: float = HOLD_TIME) -> void:
	_title.text = title
	_subtitle.text = subtitle.to_upper()
	_subtitle.visible = not subtitle.is_empty()
	if _tween != null:
		_tween.kill()
	pivot_offset = size * 0.5
	var still := Settings.reduce_motion()
	scale = Vector2.ONE if still else Vector2.ONE * 0.92
	modulate.a = 0.0
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, 0.14)
	if not still:
		_tween.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(self, "modulate:a", 0.0, 0.25).set_delay(hold)


func hide_now() -> void:
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
