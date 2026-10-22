class_name SaveStore
extends RefCounted
## Versioned JSON save file. Loading never fails: a missing, unreadable or
## corrupt file yields defaults (a corrupt file is kept aside as *.corrupt),
## and every field is type-checked against the defaults on the way in.

const VERSION := 1
const DAILY_HISTORY_DAYS := 120

var path: String
var data: Dictionary = {}
## Set when the last load had to fall back to defaults.
var recovered_from_corruption := false


func _init(p_path: String) -> void:
	path = p_path
	data = defaults()


static func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"settings": {},
		"high_scores": {"classic": 0, "classic_pure": 0, "zen": 0, "daily": 0},
		"zen": {"best_seconds": 0.0, "best_lines": 0},
		"stats": {
			"games_played": 0,
			"total_lines": 0,
			"total_seconds": 0.0,
			"pieces_placed": 0,
			"chains_triggered": 0,
			"best_chain": 0,
			"best_combo": 0,
		},
		"daily": {
			"results": {},
			"attempted": "",
			"streak": 0,
			"best_streak": 0,
			"last_completed": "",
		},
	}


## Returns true if the file was read cleanly (or did not exist yet).
func load_from_disk() -> bool:
	recovered_from_corruption = false
	data = defaults()
	if not FileAccess.file_exists(path):
		return true
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	var parsed: Variant = json.data if not text.is_empty() and json.parse(text) == OK else null
	if not parsed is Dictionary:
		_quarantine()
		return false
	data = merge(defaults(), parsed as Dictionary)
	data["version"] = VERSION
	_validate_daily_results()
	return true


func save_to_disk() -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	return DirAccess.rename_absolute(tmp, path) == OK


func reset() -> void:
	data = defaults()


## Takes values from `loaded` wherever they match the type in `base`.
## Dictionaries in `base` that are empty accept any keys (open maps).
static func merge(base: Dictionary, loaded: Dictionary) -> Dictionary:
	var out := base.duplicate(true)
	for key: Variant in base:
		if not loaded.has(key):
			continue
		var want: Variant = base[key]
		var got: Variant = loaded[key]
		if want is Dictionary and got is Dictionary:
			if (want as Dictionary).is_empty():
				out[key] = (got as Dictionary).duplicate(true)
			else:
				out[key] = merge(want, got)
		elif want is int and (got is int or got is float):
			out[key] = int(got)
		elif want is float and (got is int or got is float):
			out[key] = float(got)
		elif typeof(want) == typeof(got):
			out[key] = got
	return out


#region Records

## Records a finished run. Returns true if it set a new high score.
func record_game(mode_key: String, score: int, lines: int, seconds: float, pieces: int, best_chain: int, chains: int, best_combo: int) -> bool:
	var stats: Dictionary = data["stats"]
	stats["games_played"] = int(stats["games_played"]) + 1
	stats["total_lines"] = int(stats["total_lines"]) + lines
	stats["total_seconds"] = float(stats["total_seconds"]) + seconds
	stats["pieces_placed"] = int(stats["pieces_placed"]) + pieces
	stats["chains_triggered"] = int(stats["chains_triggered"]) + chains
	stats["best_chain"] = maxi(int(stats["best_chain"]), best_chain)
	stats["best_combo"] = maxi(int(stats["best_combo"]), best_combo)
	if mode_key == "zen":
		var zen: Dictionary = data["zen"]
		zen["best_seconds"] = maxf(float(zen["best_seconds"]), seconds)
		zen["best_lines"] = maxi(int(zen["best_lines"]), lines)
	var scores: Dictionary = data["high_scores"]
	var previous := int(scores.get(mode_key, 0))
	if score > previous:
		scores[mode_key] = score
		return true
	return false


func high_score(mode_key: String) -> int:
	return int((data["high_scores"] as Dictionary).get(mode_key, 0))


func daily_attempted(date: String) -> bool:
	return (data["daily"] as Dictionary)["attempted"] == date or has_daily_result(date)


## Called when the scored Daily run starts, so quitting cannot buy a retry.
func mark_daily_attempt(date: String) -> void:
	(data["daily"] as Dictionary)["attempted"] = date


func has_daily_result(date: String) -> bool:
	return ((data["daily"] as Dictionary)["results"] as Dictionary).has(date)


func daily_result(date: String) -> Dictionary:
	return ((data["daily"] as Dictionary)["results"] as Dictionary).get(date, {})


func record_daily(date: String, score: int, lines: int, best_chain: int, seconds: float) -> void:
	var daily: Dictionary = data["daily"]
	var results: Dictionary = daily["results"]
	if results.has(date):
		return
	results[date] = {"score": score, "lines": lines, "chain": best_chain, "seconds": seconds}
	if daily["last_completed"] == DailyCalendar.previous_date(date):
		daily["streak"] = int(daily["streak"]) + 1
	else:
		daily["streak"] = 1
	daily["last_completed"] = date
	daily["best_streak"] = maxi(int(daily["best_streak"]), int(daily["streak"]))
	var scores: Dictionary = data["high_scores"]
	scores["daily"] = maxi(int(scores["daily"]), score)
	_trim_daily_history()


## Current streak, or 0 if the chain of days is already broken.
func daily_streak(today: String) -> int:
	var daily: Dictionary = data["daily"]
	var last: String = daily["last_completed"]
	if last == today or last == DailyCalendar.previous_date(today):
		return int(daily["streak"])
	return 0

#endregion


func _quarantine() -> void:
	recovered_from_corruption = true
	var bad := path + ".corrupt"
	if FileAccess.file_exists(bad):
		DirAccess.remove_absolute(bad)
	DirAccess.rename_absolute(path, bad)


func _validate_daily_results() -> void:
	var results: Dictionary = (data["daily"] as Dictionary)["results"]
	var template := {"score": 0, "lines": 0, "chain": 0, "seconds": 0.0}
	for date: Variant in results.keys():
		if not date is String or not results[date] is Dictionary:
			results.erase(date)
			continue
		results[date] = merge(template, results[date])


func _trim_daily_history() -> void:
	var results: Dictionary = (data["daily"] as Dictionary)["results"]
	if results.size() <= DAILY_HISTORY_DAYS:
		return
	var dates := results.keys()
	dates.sort()
	for i in dates.size() - DAILY_HISTORY_DAYS:
		results.erase(dates[i])
