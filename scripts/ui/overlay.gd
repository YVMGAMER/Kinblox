class_name Overlay
extends Control
## Modal sheet over a dimmed scrim. Subclasses fill `%Sheet`.

signal closed

@onready var sheet: Control = %Sheet

var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.current.scrim)


func open() -> void:
	visible = true
	if _tween != null:
		_tween.kill()
	modulate.a = 0.0
	sheet.pivot_offset = sheet.size * 0.5
	sheet.scale = Vector2.ONE if Settings.reduce_motion() else Vector2.ONE * 0.96
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, UiTokens.SCREEN_IN)
	_tween.tween_property(sheet, "scale", Vector2.ONE, UiTokens.SCREEN_IN)


func close() -> void:
	if not visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, UiTokens.SCREEN_OUT)
	_tween.tween_callback(func() -> void:
		visible = false
		closed.emit())
