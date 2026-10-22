class_name ResultsOverlay
extends Overlay
## End-of-run summary with high score, share and replay.

signal again_requested
signal menu_requested

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _score: Label = %ScoreValue
@onready var _best: Label = %BestLabel
@onready var _stats: HBoxContainer = %Stats
@onready var _again: Button = %Again
@onready var _share: Button = %Share
@onready var _menu: Button = %Menu
@onready var _note: Label = %ShareNote

var _share_text := ""


func _ready() -> void:
	super._ready()
	_again.pressed.connect(func() -> void: again_requested.emit())
	_menu.pressed.connect(func() -> void: menu_requested.emit())
	_share.pressed.connect(_on_share)


func show_results(mode: ModeConfig, summary: Dictionary) -> void:
	var zen := mode.id == ModeConfig.Id.ZEN
	var daily := mode.id == ModeConfig.Id.DAILY
	_title.text = "Session complete" if zen else ("Daily complete" if daily and not mode.is_practice else "Game over")
	_subtitle.text = (mode.display_name() + ("  ·  " + mode.daily_date if daily else "")).to_upper()
	if zen:
		_score.text = "%d lines" % int(summary["lines"])
	else:
		_score.text = DailyCalendar.format_number(summary["score"])
	if not bool(summary["recorded"]):
		_best.text = "Practice run, not scored"
		_best.theme_type_variation = &"MutedLabel"
	elif bool(summary["new_best"]) and not zen:
		_best.text = "New best!"
		_best.theme_type_variation = &"AccentLabel"
	else:
		var best := maxi(int(summary["previous_best"]), int(summary["score"]))
		_best.text = "Best %s" % DailyCalendar.format_number(best) if not zen else "Time %s" % GameState.format_duration(summary["seconds"])
		_best.theme_type_variation = &"MutedLabel"
	_fill_stats(zen, summary)
	_again.text = "Practice again" if daily else "Play again"
	_share_text = GameState.share_text(mode, summary)
	_note.text = ""
	open()


func _fill_stats(zen: bool, summary: Dictionary) -> void:
	for c in _stats.get_children():
		c.queue_free()
	var items := [
		["LINES", str(summary["lines"])],
		["LEVEL", str(summary["level"])] if not zen else ["TIME", GameState.format_duration(summary["seconds"])],
		["BEST CHAIN", "×%d" % int(summary["best_chain"]) if int(summary["best_chain"]) > 0 else "–"],
	]
	for item: Array in items:
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		box.add_theme_constant_override(&"separation", UiTokens.S1)
		var cap := Label.new()
		cap.theme_type_variation = &"CaptionLabel"
		cap.text = item[0]
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var val := Label.new()
		val.theme_type_variation = &"HeadingLabel"
		val.text = item[1]
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(cap)
		box.add_child(val)
		_stats.add_child(box)


func _on_share() -> void:
	var result := ShareService.share(_share_text)
	_note.text = "Shared" if result == ShareService.Result.SHARED else "Copied to clipboard"
