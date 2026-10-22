class_name Hud
extends Node
## Binds the game HUD labels to a session: score (counts up smoothly),
## best, level, lines, combo and the chain counter. Zen swaps the score
## for a session timer.

const SCORE_RATE := 14.0

var score_caption: Label
var score_value: Label
var best_caption: Label
var best_value: Label
var level_value: Label
var lines_value: Label
var combo_label: Label
var chain_label: Label
var mode_label: Label

var _session: GameSession
var _shown_score := 0.0
var _zen := false
var _last_second := -1
var _combo_tween: Tween
var _chain_tween: Tween


func bind(session: GameSession) -> void:
	_session = session
	_zen = not session.mode.shows_score
	mode_label.text = session.mode.display_name().to_upper()
	if session.mode.is_practice:
		mode_label.text += " · NOT SCORED"
	score_caption.text = "TIME" if _zen else "SCORE"
	best_caption.text = "LINES BEST" if _zen else "BEST"
	var store := SaveData.store
	best_value.text = str(int((store.data["zen"] as Dictionary)["best_lines"])) if _zen else DailyCalendar.format_number(store.high_score(session.mode.record_key()))
	_set_labels()
	combo_label.modulate.a = 0.0
	chain_label.modulate.a = 0.0
	session.level_changed.connect(func(_l: int) -> void: _set_labels())
	session.lines_cleared.connect(func(_r: Array[int], _a: Scoring.Award) -> void: _set_labels())
	session.chain_step_resolved.connect(func(_s: int, _m: int, _c: int, _p: int, _cr: Array[int]) -> void: _set_labels())
	session.combo_changed.connect(_on_combo)
	session.chain_highlight.connect(_on_chain)
	session.chain_finished.connect(func(_s: int) -> void: _fade(chain_label, false))


func _process(delta: float) -> void:
	if _session == null:
		return
	if _zen:
		var sec := int(_session.elapsed)
		if sec != _last_second:
			_last_second = sec
			score_value.text = GameState.format_duration(_session.elapsed)
		return
	var target := float(_session.scoring.score)
	if _shown_score != target:
		_shown_score = lerpf(_shown_score, target, 1.0 - exp(-SCORE_RATE * delta))
		if absf(target - _shown_score) < 1.0:
			_shown_score = target
		score_value.text = DailyCalendar.format_number(int(round(_shown_score)))


func _set_labels() -> void:
	level_value.text = str(_session.scoring.level)
	lines_value.text = str(_session.scoring.lines)
	if not _zen and score_value.text.is_empty():
		score_value.text = "0"


func _on_combo(combo: int) -> void:
	if combo >= 1:
		combo_label.text = "COMBO ×%d" % (combo + 1)
		_combo_tween = _pulse(combo_label, _combo_tween)
	else:
		_fade(combo_label, false)


func _on_chain(_groups: Array[PackedInt32Array], _step: int, multiplier: int) -> void:
	chain_label.text = "CHAIN ×%d" % multiplier
	_chain_tween = _pulse(chain_label, _chain_tween)


func _pulse(label: Label, tw: Tween) -> Tween:
	if tw != null:
		tw.kill()
	label.pivot_offset = label.size * 0.5
	label.modulate.a = 1.0
	var t := label.create_tween()
	if not Settings.reduce_motion():
		label.scale = Vector2.ONE * 1.25
		t.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return t


func _fade(label: Label, show: bool) -> void:
	label.create_tween().tween_property(label, "modulate:a", 1.0 if show else 0.0, 0.25)
