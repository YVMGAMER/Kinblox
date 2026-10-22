class_name ControlPad
extends Control
## On-screen button layout (the alternative to gestures). Handles touches
## itself so several buttons can be held at once (e.g. move + rotate), which
## Godot's Button cannot do with mouse emulation.
##
##   [ HOLD ] [ SOFT ] [ CCW ] [ DROP ]
##   [  <   ] [  >   ] [      CW      ]

signal action_pressed(action: StringName)
signal action_released(action: StringName)

const LAYOUT := [
	{"action": &"hold", "icon": "hold", "cell": Rect2i(0, 0, 1, 1)},
	{"action": &"soft_drop", "icon": "soft_drop", "cell": Rect2i(1, 0, 1, 1)},
	{"action": &"rotate_ccw", "icon": "rotate_ccw", "cell": Rect2i(2, 0, 1, 1)},
	{"action": &"hard_drop", "icon": "hard_drop", "cell": Rect2i(3, 0, 1, 1)},
	{"action": &"move_left", "icon": "left", "cell": Rect2i(0, 1, 1, 1)},
	{"action": &"move_right", "icon": "right", "cell": Rect2i(1, 1, 1, 1)},
	{"action": &"rotate_cw", "icon": "rotate_cw", "cell": Rect2i(2, 1, 2, 1)},
]
const COLUMNS := 4
const ROWS := 2

var enabled := true

var _rects: Array[Rect2] = []
var _icons: Array[Texture2D] = []
var _pressed := PackedInt32Array()  # per button: touch index holding it, or -1
var _gt: GameTheme
var _box: StyleBoxFlat
var _box_down: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pressed.resize(LAYOUT.size())
	_pressed.fill(-1)
	for b: Dictionary in LAYOUT:
		_icons.append(load("res://assets/icons/%s.svg" % b["icon"]) as Texture2D)
	resized.connect(_layout)
	ThemeManager.theme_changed.connect(func(gt: GameTheme, _a: bool) -> void: _set_theme(gt))
	_set_theme(ThemeManager.current)
	_layout()


func release_all() -> void:
	for i in _pressed.size():
		if _pressed[i] != -1:
			_pressed[i] = -1
			action_released.emit(LAYOUT[i]["action"])
	queue_redraw()


func _set_theme(gt: GameTheme) -> void:
	_gt = gt
	_box = StyleBoxFlat.new()
	_box.bg_color = gt.surface_alt
	_box.set_corner_radius_all(UiTokens.RADIUS_MD)
	_box.anti_aliasing = true
	_box_down = _box.duplicate() as StyleBoxFlat
	_box_down.bg_color = gt.accent
	queue_redraw()


func _layout() -> void:
	_rects.clear()
	var gap := float(UiTokens.S3)
	var cw := (size.x - gap * (COLUMNS - 1)) / COLUMNS
	var ch := (size.y - gap * (ROWS - 1)) / ROWS
	for b: Dictionary in LAYOUT:
		var c: Rect2i = b["cell"]
		_rects.append(Rect2(c.position.x * (cw + gap), c.position.y * (ch + gap), c.size.x * cw + (c.size.x - 1) * gap, c.size.y * ch + (c.size.y - 1) * gap))
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not enabled or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if e.pressed:
			var i := _button_at(e.position)
			if i >= 0 and _pressed[i] == -1:
				_press(i, e.index)
		else:
			for i in _pressed.size():
				if _pressed[i] == e.index:
					_release(i)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		var held := _pressed.find(d.index)
		var over := _button_at(d.position)
		# Sliding between the move buttons switches direction without lifting.
		if held >= 0 and over != held and _is_move(held):
			_release(held)
			if over >= 0 and _is_move(over) and _pressed[over] == -1:
				_press(over, d.index)


func _is_move(i: int) -> bool:
	var a: StringName = LAYOUT[i]["action"]
	return a == &"move_left" or a == &"move_right"


func _press(i: int, touch: int) -> void:
	_pressed[i] = touch
	action_pressed.emit(LAYOUT[i]["action"])
	queue_redraw()


func _release(i: int) -> void:
	_pressed[i] = -1
	action_released.emit(LAYOUT[i]["action"])
	queue_redraw()


func _button_at(global_pos: Vector2) -> int:
	var local := get_global_transform().affine_inverse() * global_pos
	for i in _rects.size():
		if _rects[i].has_point(local):
			return i
	return -1


func _draw() -> void:
	if _gt == null:
		return
	var icon_size := float(UiTokens.ICON) * 1.15
	for i in _rects.size():
		var down := _pressed[i] != -1
		draw_style_box(_box_down if down else _box, _rects[i])
		var c := _rects[i].get_center()
		var tint := _gt.accent_text if down else _gt.text_primary
		draw_texture_rect(_icons[i], Rect2(c - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size), false, tint)
