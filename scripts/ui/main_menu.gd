extends MenuScreen
## Title screen: logo, Play, today's Daily status, and the secondary screens.

var _ambient: AmbientBackground


func _scrolls() -> bool:
	return false


func _build() -> void:
	_ambient = AmbientBackground.new()
	_ambient.intensity = 0.7
	_ambient.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ambient)
	move_child(_ambient, 0)

	column.add_child(UiFactory.expander())
	var logo := LogoMark.new()
	logo.custom_minimum_size = Vector2(200, 200)
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(logo)
	column.add_child(UiFactory.label("Kinblox", &"DisplayLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiFactory.label("Fit. Clear. Chain.", &"BodyLabel", HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UiFactory.expander())

	var actions := VBoxContainer.new()
	actions.add_theme_constant_override(&"separation", UiTokens.S3)
	var play := UiFactory.button("Play", &"PrimaryButton", "", func() -> void: GameState.goto(GameState.MODES))
	play.custom_minimum_size = Vector2(0, 128)
	actions.add_child(play)
	actions.add_child(UiFactory.label(_daily_status(), &"MutedLabel", HORIZONTAL_ALIGNMENT_CENTER))
	actions.add_child(UiFactory.spacer(UiTokens.S2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.S3)
	for item: Array in [["How to play", "help", GameState.HOW_TO], ["Stats", "stats", GameState.STATS], ["Settings", "settings", GameState.SETTINGS]]:
		var target: StringName = item[2]
		var b := UiFactory.button(item[0], &"", item[1], func() -> void: GameState.goto(target))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_font_size_override(&"font_size", UiTokens.FONT_SMALL)
		b.custom_minimum_size = Vector2(0, 168)
		row.add_child(b)
	actions.add_child(row)
	column.add_child(actions)
	column.add_child(UiFactory.spacer(UiTokens.S4))
	column.add_child(UiFactory.label("Made by Yash", &"MutedLabel", HORIZONTAL_ALIGNMENT_CENTER))
	logo.animate_in(0.5)
	AudioManager.play_music(AudioManager.Music.AMBIENT)


func _daily_status() -> String:
	var store := SaveData.store
	var today := DailyCalendar.today()
	var streak := store.daily_streak(today)
	var streak_text := " · %d-day streak" % streak if streak > 0 else ""
	if store.has_daily_result(today):
		return "Today's Daily is done" + streak_text
	return "Today's Daily is ready" + streak_text


## On the title screen, back leaves the app.
func handle_back() -> bool:
	return false
