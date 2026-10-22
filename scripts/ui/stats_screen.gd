extends MenuScreen
## Lifetime numbers from SaveData.


func _title() -> String:
	return "Stats"


func _build() -> void:
	var data := SaveData.store.data
	var stats: Dictionary = data["stats"]
	var zen: Dictionary = data["zen"]
	var daily: Dictionary = data["daily"]
	var store := SaveData.store
	var chain := int(stats["best_chain"])

	_card("Overview", [
		["GAMES PLAYED", _n(stats["games_played"])],
		["LINES CLEARED", _n(stats["total_lines"])],
		["TIME PLAYED", GameState.format_duration(float(stats["total_seconds"]))],
		["PIECES PLACED", _n(stats["pieces_placed"])],
	])
	_card("Best scores", [
		["CLASSIC", _n(store.high_score("classic"))],
		["PURE", _n(store.high_score("classic_pure"))],
		["DAILY", _n(store.high_score("daily"))],
		["ZEN LONGEST", GameState.format_duration(float(zen["best_seconds"]))],
	])
	_card("Color Chain", [
		["BEST CHAIN", "×%d" % chain if chain > 0 else "–"],
		["CHAINS SET OFF", _n(stats["chains_triggered"])],
		["BEST COMBO", "×%d" % (int(stats["best_combo"]) + 1) if int(stats["best_combo"]) > 0 else "–"],
		["ZEN MOST LINES", _n(zen["best_lines"])],
	])
	_card("Daily", [
		["CURRENT STREAK", _n(store.daily_streak(DailyCalendar.today()))],
		["BEST STREAK", _n(daily["best_streak"])],
		["DAILIES PLAYED", _n((daily["results"] as Dictionary).size())],
		["TODAY", _n(int(store.daily_result(DailyCalendar.today()).get("score", 0))) if store.has_daily_result(DailyCalendar.today()) else "–"],
	])
	column.add_child(UiFactory.spacer(UiTokens.S5))


func _n(v: Variant) -> String:
	return DailyCalendar.format_number(int(v))


func _card(title: String, items: Array) -> void:
	var parts := UiFactory.card()
	var box: VBoxContainer = parts[1]
	box.add_child(UiFactory.label(title, &"HeadingLabel"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override(&"h_separation", UiTokens.S4)
	grid.add_theme_constant_override(&"v_separation", UiTokens.S4)
	for item: Array in items:
		grid.add_child(UiFactory.stat(item[0], item[1]))
	box.add_child(grid)
	column.add_child(parts[0])
