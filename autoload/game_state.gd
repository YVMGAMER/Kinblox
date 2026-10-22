extends Node
## App-level flow: which screen is showing, which mode is about to start,
## and recording finished runs into SaveData.

signal screen_requested(screen: StringName, payload: Dictionary)

const SPLASH := &"splash"
const MENU := &"menu"
const MODES := &"modes"
const GAME := &"game"
const SETTINGS := &"settings"
const HOW_TO := &"howto"
const STATS := &"stats"

var current_screen: StringName = &""
var pending_mode: ModeConfig


func goto(screen: StringName, payload: Dictionary = {}) -> void:
	screen_requested.emit(screen, payload)


func start_game(mode: ModeConfig) -> void:
	pending_mode = mode
	if mode.id == ModeConfig.Id.DAILY and not mode.is_practice:
		SaveData.store.mark_daily_attempt(mode.daily_date)
		SaveData.flush()
	goto(GAME)


func new_seed() -> int:
	return randi()


func classic_mode() -> ModeConfig:
	return ModeConfig.classic(new_seed(), Settings.chains_enabled())


func zen_mode() -> ModeConfig:
	return ModeConfig.zen(new_seed(), Settings.chains_enabled(), GameRules.default_tuning())


## Today's Daily: scored if not yet attempted, otherwise practice.
func daily_mode() -> ModeConfig:
	var today := DailyCalendar.today()
	return ModeConfig.daily(today, SaveData.store.daily_attempted(today))


## Same rules and a fresh seed (Daily keeps its date seed, as practice).
func replay_mode(previous: ModeConfig) -> ModeConfig:
	match previous.id:
		ModeConfig.Id.ZEN:
			return ModeConfig.zen(new_seed(), previous.chains_enabled, GameRules.default_tuning())
		ModeConfig.Id.DAILY:
			return ModeConfig.daily(previous.daily_date, true)
	return ModeConfig.classic(new_seed(), previous.chains_enabled)


## Records a finished run. Returns a summary for the results panel.
func record_result(session: GameSession, chains_triggered: int) -> Dictionary:
	var mode := session.mode
	var store := SaveData.store
	var key := mode.record_key()
	var score := session.scoring.score
	var previous_best := store.high_score(key)
	var summary := {
		"score": score,
		"lines": session.scoring.lines,
		"level": session.scoring.level,
		"seconds": session.elapsed,
		"best_chain": session.scoring.best_chain,
		"previous_best": previous_best,
		"new_best": false,
		"recorded": true,
	}
	if mode.id == ModeConfig.Id.DAILY and mode.is_practice:
		summary["recorded"] = false
		return summary
	summary["new_best"] = store.record_game(key, score, session.scoring.lines, session.elapsed,
		session.pieces_locked, session.scoring.best_chain, chains_triggered, session.scoring.best_combo)
	if mode.id == ModeConfig.Id.DAILY:
		store.record_daily(mode.daily_date, score, session.scoring.lines, session.scoring.best_chain, session.elapsed)
	SaveData.flush()
	return summary


func share_text(mode: ModeConfig, summary: Dictionary) -> String:
	var score: int = summary["score"]
	var lines: int = summary["lines"]
	var chain: int = summary["best_chain"]
	if mode.id == ModeConfig.Id.DAILY:
		return DailyCalendar.share_text(mode.daily_date, score, lines, chain)
	if mode.id == ModeConfig.Id.ZEN:
		return "Kinblox Zen: %d lines in %s" % [lines, format_duration(summary["seconds"])]
	var chain_text := "x%d" % chain if chain > 0 else "none"
	return "Kinblox %s: %s pts, %d lines, best chain %s" % [mode.display_name(), DailyCalendar.format_number(score), lines, chain_text]


static func format_duration(seconds: float) -> String:
	var s := int(seconds)
	@warning_ignore("integer_division")
	var h := s / 3600
	@warning_ignore("integer_division")
	var m := (s % 3600) / 60
	if h > 0:
		return "%d:%02d:%02d" % [h, m, s % 60]
	return "%d:%02d" % [m, s % 60]
