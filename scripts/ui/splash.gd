extends MenuScreen
## Brief brand moment, then the menu (or the tutorial on first launch).
## Tap anywhere to skip.

const HOLD_TIME := 1.5

var _done := false


func _scrolls() -> bool:
	return false


func _build() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(UiFactory.expander())
	var logo := LogoMark.new()
	logo.custom_minimum_size = Vector2(240, 240)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(logo)
	column.add_child(UiFactory.label("Kinblox", &"DisplayLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiFactory.expander())
	column.add_child(UiFactory.label("Made by Yash", &"MutedLabel", HORIZONTAL_ALIGNMENT_CENTER))
	logo.animate_in(0.7)
	get_tree().create_timer(HOLD_TIME).timeout.connect(_continue)


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_pressed():
		_continue()


func _continue() -> void:
	if _done or not is_inside_tree():
		return
	_done = true
	if bool(Settings.get_value(&"tutorial_seen")):
		GameState.goto(GameState.MENU)
	else:
		GameState.goto(GameState.HOW_TO, {"first_run": true})


func handle_back() -> bool:
	return false
