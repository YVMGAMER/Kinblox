extends MenuScreen
## Illustrated steps. On first launch it leads straight into the menu.

const PAGES := [
	["Move", "Drag left or right anywhere on the board. The piece moves one column at a time and only sideways, so it never drops by accident."],
	["Rotate", "Tap anywhere to rotate clockwise. Tap with two fingers to rotate the other way. Pieces nudge off walls and floors when they can."],
	["Drop", "Drag down slowly to soft drop. Flick down quickly to drop the piece straight to its ghost outline."],
	["Hold and next", "Tap the HOLD box to save the current piece for later (once per piece). The next three pieces wait at the top right."],
	["Clear lines", "Fill a row to clear it. Clear several at once for more points, and four at once twice in a row for a back-to-back bonus."],
	["Color Chain", "Same-colored blocks from different pieces are kin. After a line clear, kin groups of 4 or more burst, everything above falls, and new groups chain for ×2, ×3 and up."],
]

var _first_run := false
var _index := 0
var _art: TutorialIllustration
var _heading: Label
var _body: Label
var _dots: Control
var _back: Button
var _next: Button


func setup(payload: Dictionary) -> void:
	_first_run = bool(payload.get("first_run", false))


func _title() -> String:
	return "How to play"


func _scrolls() -> bool:
	return false


func _build() -> void:
	_art = TutorialIllustration.new()
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_art.custom_minimum_size = Vector2(0, 560)
	column.add_child(_art)
	_heading = UiFactory.label("", &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(_heading)
	_body = UiFactory.label("", &"BodyLabel", HORIZONTAL_ALIGNMENT_CENTER, true)
	_body.custom_minimum_size = Vector2(0, 200)
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	column.add_child(_body)
	_dots = Control.new()
	_dots.custom_minimum_size = Vector2(0, UiTokens.S3)
	_dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dots.draw.connect(_draw_dots)
	column.add_child(_dots)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.S3)
	_back = UiFactory.button("Back", &"GhostButton", "", func() -> void: _show(_index - 1))
	_next = UiFactory.button("Next", &"PrimaryButton", "", _advance)
	_back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_back)
	row.add_child(_next)
	column.add_child(row)
	ThemeManager.theme_changed.connect(func(_gt: GameTheme, _a: bool) -> void: _paint_dots())
	_show(0)


func _advance() -> void:
	if _index >= PAGES.size() - 1:
		_finish()
	else:
		_show(_index + 1)


func _show(i: int) -> void:
	_index = clampi(i, 0, PAGES.size() - 1)
	_art.show_page(_index as TutorialIllustration.Page)
	_heading.text = PAGES[_index][0]
	_body.text = PAGES[_index][1]
	if _index == 0 and Settings.control_scheme() == Settings.ControlScheme.BUTTONS:
		_body.text += " With the button layout, use the on-screen pad instead."
	_back.disabled = _index == 0
	_next.text = ("Let's play" if _first_run else "Done") if _index == PAGES.size() - 1 else "Next"
	_paint_dots()


func _paint_dots() -> void:
	_dots.queue_redraw()


## Page indicator: the current page is a wider pill, the rest small dots.
func _draw_dots() -> void:
	var gt := ThemeManager.current
	var r := UiTokens.S2 * 0.5 + 2.0
	var gap := float(UiTokens.S3)
	var current_w := r * 6.0
	var total := (PAGES.size() - 1) * (r * 2.0 + gap) + current_w
	var x := (_dots.size.x - total) * 0.5
	var y := _dots.size.y * 0.5
	for i in PAGES.size():
		if i == _index:
			_dots.draw_circle(Vector2(x + r, y), r, gt.accent, true, -1.0, true)
			_dots.draw_circle(Vector2(x + current_w - r, y), r, gt.accent, true, -1.0, true)
			_dots.draw_rect(Rect2(x + r, y - r, current_w - r * 2.0, r * 2.0), gt.accent)
			x += current_w + gap
		else:
			_dots.draw_circle(Vector2(x + r, y), r, gt.outline, true, -1.0, true)
			x += r * 2.0 + gap


func _finish() -> void:
	Settings.set_value(&"tutorial_seen", true)
	GameState.goto(GameState.MODES if _first_run else GameState.MENU)


func go_back() -> void:
	if _first_run:
		Settings.set_value(&"tutorial_seen", true)
	GameState.goto(GameState.MENU)
