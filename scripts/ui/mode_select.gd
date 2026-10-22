extends MenuScreen
## Mode cards: Classic (or Pure), Zen, and today's Daily with its status,
## streak, countdown and share.

var _countdown: Label
var _share_note: Label
var _last_second := -1


func _title() -> String:
	return "Play"


func _build() -> void:
	var store := SaveData.store
	var chains := Settings.chains_enabled()

	var classic := _card(
		"Classic" if chains else "Pure",
		"Endless. Speed climbs every 10 lines. Place matching colors side by side and a line clear sets off a Color Chain." if chains
			else "Endless and classic: Color Chain is off. Speed climbs every 10 lines.",
		"Best %s" % DailyCalendar.format_number(store.high_score("classic" if chains else "classic_pure")),
		"Play", func() -> void: GameState.start_game(GameState.classic_mode()))
	if not chains:
		(classic[1] as VBoxContainer).add_child(UiFactory.label("Turn Color Chain back on in Settings.", &"MutedLabel"))

	var zen: Dictionary = store.data["zen"]
	var zen_best := "Longest %s · %d lines" % [GameState.format_duration(float(zen["best_seconds"])), int(zen["best_lines"])] if float(zen["best_seconds"]) > 0.0 else "No sessions yet"
	_card("Zen", "No game over and no rush. When the stack reaches the top, it gently clears and you keep going.",
		zen_best, "Start", func() -> void: GameState.start_game(GameState.zen_mode()))

	_daily_card()


func _card(title: String, body: String, meta: String, action: String, on_play: Callable) -> Array:
	var parts := UiFactory.card()
	var panel: PanelContainer = parts[0]
	var box: VBoxContainer = parts[1]
	box.add_child(UiFactory.label(title, &"TitleLabel"))
	box.add_child(UiFactory.label(body, &"BodyLabel", HORIZONTAL_ALIGNMENT_LEFT, true))
	box.add_child(UiFactory.label(meta, &"AccentLabel"))
	box.add_child(UiFactory.spacer(UiTokens.S1))
	box.add_child(UiFactory.button(action, &"PrimaryButton", "", on_play))
	column.add_child(panel)
	return parts


func _daily_card() -> void:
	var store := SaveData.store
	var today := DailyCalendar.today()
	var parts := UiFactory.card()
	var box: VBoxContainer = parts[1]

	var title_row := HBoxContainer.new()
	title_row.add_child(UiFactory.label("Daily", &"TitleLabel"))
	var date := UiFactory.label(today, &"CaptionLabel", HORIZONTAL_ALIGNMENT_RIGHT)
	date.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(date)
	box.add_child(title_row)
	box.add_child(UiFactory.label("The same pieces for everyone today. One scored run per day; practice as much as you like.", &"BodyLabel", HORIZONTAL_ALIGNMENT_LEFT, true))

	var result := store.daily_result(today)
	var attempted := store.daily_attempted(today)
	var status := "Not played yet today"
	if not result.is_empty():
		var chain := int(result["chain"])
		status = "Today: %s pts · %d lines · best chain %s" % [DailyCalendar.format_number(int(result["score"])), int(result["lines"]), "×%d" % chain if chain > 0 else "–"]
	elif attempted:
		status = "Today's scored run was started"
	box.add_child(UiFactory.label(status, &"AccentLabel", HORIZONTAL_ALIGNMENT_LEFT, true))

	var meta := HBoxContainer.new()
	meta.add_theme_constant_override(&"separation", UiTokens.S2)
	meta.add_child(UiFactory.icon_rect("flame", 40))
	var streak := store.daily_streak(today)
	meta.add_child(UiFactory.label("%d-day streak" % streak if streak > 0 else "No streak yet", &"SmallLabel"))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.add_child(gap)
	meta.add_child(UiFactory.icon_rect("clock", 40))
	_countdown = UiFactory.label("", &"SmallLabel")
	meta.add_child(_countdown)
	box.add_child(meta)

	box.add_child(UiFactory.spacer(UiTokens.S1))
	box.add_child(UiFactory.button("Practice" if attempted else "Play today's run", &"PrimaryButton", "",
		func() -> void: GameState.start_game(GameState.daily_mode())))
	if not result.is_empty():
		var text := DailyCalendar.share_text(today, int(result["score"]), int(result["lines"]), int(result["chain"]))
		box.add_child(UiFactory.button("Share result", &"", "share", func() -> void:
			var r := ShareService.share(text)
			_share_note.text = "Shared" if r == ShareService.Result.SHARED else "Copied to clipboard"
			_share_note.visible = true))
		_share_note = UiFactory.label("", &"MutedLabel", HORIZONTAL_ALIGNMENT_CENTER)
		_share_note.visible = false
		box.add_child(_share_note)
	if attempted:
		box.add_child(UiFactory.label("Practice runs are not scored.", &"MutedLabel"))
	column.add_child(parts[0])
	_update_countdown()


func _process(_delta: float) -> void:
	_update_countdown()


func _update_countdown() -> void:
	var left := DailyCalendar.seconds_until_next_now()
	if left == _last_second or _countdown == null:
		return
	_last_second = left
	_countdown.text = "Next in " + DailyCalendar.format_countdown(left)
	# Crossing UTC midnight while this screen is open: rebuild for the new day.
	if left == DailyCalendar.SECONDS_PER_DAY:
		GameState.goto(GameState.MODES)
