class_name ToggleSwitch
extends BaseButton
## Pill-shaped on/off switch drawn from the active GameTheme.

const TRACK := Vector2(108, 60)
const ANIM_RATE := 18.0

var _t := 0.0


func _init() -> void:
	toggle_mode = true
	custom_minimum_size = TRACK
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	_t = 1.0 if button_pressed else 0.0
	toggled.connect(func(_on: bool) -> void:
		AudioManager.play(AudioManager.Sfx.UI_TAP)
		Haptics.pulse(Haptics.Kind.UI)
		set_process(true))
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: queue_redraw())
	set_process(false)


func _process(delta: float) -> void:
	var target := 1.0 if button_pressed else 0.0
	_t = move_toward(_t, target, delta * ANIM_RATE * 0.25) if Settings.reduce_motion() else lerpf(_t, target, 1.0 - exp(-ANIM_RATE * delta))
	if absf(_t - target) < 0.01:
		_t = target
		set_process(false)
	queue_redraw()


func set_on_silently(on: bool) -> void:
	set_pressed_no_signal(on)
	_t = 1.0 if on else 0.0
	queue_redraw()


func _draw() -> void:
	var gt := ThemeManager.current
	var rect := Rect2((size - TRACK) * 0.5, TRACK)
	var r := TRACK.y * 0.5
	var track := gt.surface_alt.lerp(gt.accent, _t)
	if disabled:
		track.a *= 0.4
	_pill(rect, track)
	var knob_r := r - 6.0
	var x := lerpf(rect.position.x + r, rect.end.x - r, _t)
	var knob := gt.text_secondary.lerp(gt.accent_text, _t)
	draw_circle(Vector2(x, rect.get_center().y), knob_r, knob, true, -1.0, true)


func _pill(rect: Rect2, color: Color) -> void:
	var r := rect.size.y * 0.5
	draw_circle(rect.position + Vector2(r, r), r, color, true, -1.0, true)
	draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, color, true, -1.0, true)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - r * 2.0, rect.size.y)), color)
