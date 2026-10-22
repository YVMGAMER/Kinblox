extends KinTest

const PATH := "user://kinblox_test_save.json"


func _write(text: String) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _cleanup() -> void:
	for p: String in [PATH, PATH + ".corrupt", PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func test_missing_file_gives_defaults() -> void:
	_cleanup()
	var s := SaveStore.new(PATH)
	check(s.load_from_disk(), "clean load")
	check_eq(s.high_score("classic"), 0, "default score")
	check_eq(int(s.data["version"]), SaveStore.VERSION, "version")


func test_corrupt_file_falls_back_to_defaults() -> void:
	_cleanup()
	_write("{ this is not json ]]")
	var s := SaveStore.new(PATH)
	check(not s.load_from_disk(), "reports corruption")
	check(s.recovered_from_corruption, "flag set")
	check_eq(s.high_score("classic"), 0, "defaults used")
	check(FileAccess.file_exists(PATH + ".corrupt"), "bad file kept aside")
	check(s.save_to_disk(), "can save again")
	var again := SaveStore.new(PATH)
	check(again.load_from_disk(), "fresh file loads")
	_cleanup()


func test_truncated_and_empty_files() -> void:
	for text: String in ["", "{\"version\": 1, \"high_scores\": {\"classic\": 12", "[1, 2, 3]", "null", "42"]:
		_cleanup()
		_write(text)
		var s := SaveStore.new(PATH)
		s.load_from_disk()
		check_eq(s.high_score("classic"), 0, "fallback for %s" % text.left(12))
		check(s.data["stats"] is Dictionary, "stats dict for %s" % text.left(12))
	_cleanup()


func test_wrong_types_fall_back_per_field() -> void:
	_cleanup()
	_write(JSON.stringify({
		"version": 1,
		"high_scores": {"classic": "lots", "zen": 77},
		"stats": [1, 2, 3],
		"daily": {"streak": 3.0, "results": {"2026-01-01": "bad", "2026-01-02": {"score": 500}}},
	}))
	var s := SaveStore.new(PATH)
	check(s.load_from_disk(), "parses")
	check_eq(s.high_score("classic"), 0, "bad type replaced")
	check_eq(s.high_score("zen"), 77, "good value kept")
	check_eq(int((s.data["stats"] as Dictionary)["games_played"]), 0, "bad section replaced")
	check_eq(int((s.data["daily"] as Dictionary)["streak"]), 3, "float coerced to int")
	check(not s.has_daily_result("2026-01-01"), "bad daily entry dropped")
	check_eq(int(s.daily_result("2026-01-02")["score"]), 500, "good daily entry kept")
	check_eq(int(s.daily_result("2026-01-02")["lines"]), 0, "missing field defaulted")
	_cleanup()


func test_round_trip() -> void:
	_cleanup()
	var s := SaveStore.new(PATH)
	s.record_game("classic", 12450, 38, 300.0, 120, 4, 6, 3)
	(s.data["settings"] as Dictionary)["theme"] = "ember"
	check(s.save_to_disk(), "saved")
	var t := SaveStore.new(PATH)
	check(t.load_from_disk(), "loaded")
	check_eq(t.high_score("classic"), 12450, "score")
	check_eq(int((t.data["stats"] as Dictionary)["best_chain"]), 4, "best chain")
	check_eq((t.data["settings"] as Dictionary)["theme"], "ember", "settings map kept")
	_cleanup()


func test_high_score_only_rises() -> void:
	var s := SaveStore.new(PATH)
	check(s.record_game("classic", 500, 5, 10.0, 10, 0, 0, 0), "first is a best")
	check(not s.record_game("classic", 300, 5, 10.0, 10, 0, 0, 0), "lower is not")
	check_eq(s.high_score("classic"), 500, "kept best")
	check_eq(int((s.data["stats"] as Dictionary)["games_played"]), 2, "both counted")


func test_daily_attempt_and_streak() -> void:
	var s := SaveStore.new(PATH)
	check(not s.daily_attempted("2026-10-20"), "fresh day")
	s.mark_daily_attempt("2026-10-20")
	check(s.daily_attempted("2026-10-20"), "marked when started")
	s.record_daily("2026-10-20", 1000, 10, 2, 60.0)
	s.record_daily("2026-10-21", 2000, 20, 3, 60.0)
	check_eq(s.daily_streak("2026-10-21"), 2, "two-day streak")
	check_eq(s.daily_streak("2026-10-22"), 2, "still alive the next day")
	check_eq(s.daily_streak("2026-10-23"), 0, "broken after a missed day")
	s.record_daily("2026-10-23", 500, 5, 0, 60.0)
	check_eq(s.daily_streak("2026-10-23"), 1, "restarts at 1")
	check_eq(int((s.data["daily"] as Dictionary)["best_streak"]), 2, "best streak kept")
	s.record_daily("2026-10-23", 99999, 50, 5, 60.0)
	check_eq(int(s.daily_result("2026-10-23")["score"]), 500, "only the first result counts")
	check_eq(s.high_score("daily"), 2000, "daily best")
