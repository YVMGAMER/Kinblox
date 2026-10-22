class_name SafeArea
extends MarginContainer
## Screen-edge padding that also clears notches, punch-holes and gesture
## bars, using DisplayServer.get_display_safe_area().

@export var base_margin := Vector4(UiTokens.S4, UiTokens.S4, UiTokens.S4, UiTokens.S4)  # left, top, right, bottom


func _ready() -> void:
	get_viewport().size_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var insets := SafeArea.insets(get_viewport())
	add_theme_constant_override(&"margin_left", int(base_margin.x + insets.x))
	add_theme_constant_override(&"margin_top", int(base_margin.y + insets.y))
	add_theme_constant_override(&"margin_right", int(base_margin.z + insets.z))
	add_theme_constant_override(&"margin_bottom", int(base_margin.w + insets.w))


## Unsafe insets (left, top, right, bottom) in viewport coordinates.
## Only meaningful on mobile, where the window covers the whole screen.
static func insets(viewport: Viewport) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window := Vector2(DisplayServer.window_get_size())
	if window.x <= 0.0 or window.y <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var visible := viewport.get_visible_rect().size
	var k := visible / window
	return Vector4(
		maxf(safe.position.x, 0.0) * k.x,
		maxf(safe.position.y, 0.0) * k.y,
		maxf(window.x - safe.end.x, 0.0) * k.x,
		maxf(window.y - safe.end.y, 0.0) * k.y)
