class_name ModeConfig
extends RefCounted
## Describes how a GameSession behaves. Every mode is one GameSession plus
## one of these; nothing else about the rules is mode-specific.

enum Id { CLASSIC, ZEN, DAILY }
enum UnlockBasis { LEVEL, SEQUENCE }

var id: Id = Id.CLASSIC
var rng_seed := 1
var chains_enabled := true
## When false, a blocked spawn sweeps the top rows instead of ending the game.
var has_game_over := true
## Seconds per row; 0 means use the level speed curve.
var fixed_gravity_interval := 0.0
var shows_score := true
var unlock_basis: UnlockBasis = UnlockBasis.LEVEL
var start_level := 1
## UTC date (YYYY-MM-DD) for Daily runs.
var daily_date := ""
## Daily retries after the scored attempt; never recorded.
var is_practice := false


static func classic(seed_value: int, chains: bool) -> ModeConfig:
	var m := ModeConfig.new()
	m.id = Id.CLASSIC
	m.rng_seed = seed_value
	m.chains_enabled = chains
	return m


static func zen(seed_value: int, chains: bool, tuning: Tuning) -> ModeConfig:
	var m := ModeConfig.new()
	m.id = Id.ZEN
	m.rng_seed = seed_value
	m.chains_enabled = chains
	m.has_game_over = false
	m.fixed_gravity_interval = tuning.zen_gravity_interval
	m.shows_score = false
	return m


## Daily always uses chains so every player plays identical rules.
static func daily(date: String, practice: bool) -> ModeConfig:
	var m := ModeConfig.new()
	m.id = Id.DAILY
	m.rng_seed = DailyCalendar.seed_for_date(date)
	m.chains_enabled = true
	m.unlock_basis = UnlockBasis.SEQUENCE
	m.daily_date = date
	m.is_practice = practice
	return m


## Key used for high scores and stats.
func record_key() -> String:
	match id:
		Id.ZEN:
			return "zen"
		Id.DAILY:
			return "daily"
	return "classic" if chains_enabled else "classic_pure"


func display_name() -> String:
	match id:
		Id.ZEN:
			return "Zen"
		Id.DAILY:
			return "Daily Practice" if is_practice else "Daily"
	return "Classic" if chains_enabled else "Pure"
