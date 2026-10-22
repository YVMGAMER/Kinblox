extends KinTest


## The first `count` piece types a Daily session deals.
func _sequence(date: String, count: int) -> Array[int]:
	var s := KinTest.started_session(ModeConfig.daily(date, false))
	var seen: Array[int] = [s.active.type]
	while seen.size() < count:
		seen.append(s._take_next())
	return seen


func test_same_date_same_seed() -> void:
	check_eq(DailyCalendar.seed_for_date("2026-10-22"), DailyCalendar.seed_for_date("2026-10-22"), "seed")
	check(DailyCalendar.seed_for_date("2026-10-22") != DailyCalendar.seed_for_date("2026-10-23"), "dates differ")


func test_same_date_identical_sequence() -> void:
	var a := _sequence("2026-10-22", 60)
	var b := _sequence("2026-10-22", 60)
	check_eq(a, b, "sequence")
	check(a != _sequence("2026-10-23", 60), "different day differs")


func test_sequence_ignores_global_rng() -> void:
	seed(42)
	var a := _sequence("2026-01-01", 40)
	randomize()
	var b := _sequence("2026-01-01", 40)
	check_eq(a, b, "isolated from global rng")


## Daily unlocks by pieces dealt, so the sequence is identical for players
## at different levels.
func test_sequence_independent_of_progress() -> void:
	var t := KinTest.instant_tuning()
	var slow := KinTest.started_session(ModeConfig.daily("2026-05-05", false), t)
	var fast := KinTest.started_session(ModeConfig.daily("2026-05-05", false), t)
	fast.scoring.level = 15
	var a: Array[int] = []
	var b: Array[int] = []
	for i in 300:
		a.append(slow._take_next())
		b.append(fast._take_next())
	check_eq(a, b, "same pieces regardless of level")


func test_previous_date() -> void:
	check_eq(DailyCalendar.previous_date("2026-03-01"), "2026-02-28", "month boundary")
	check_eq(DailyCalendar.previous_date("2026-01-01"), "2025-12-31", "year boundary")


func test_countdown() -> void:
	check_eq(DailyCalendar.seconds_until_next(86400 * 100), 86400, "at midnight")
	check_eq(DailyCalendar.seconds_until_next(86400 * 100 + 86399), 1, "one second left")
	check_eq(DailyCalendar.format_countdown(3723), "01:02:03", "format")


func test_share_text() -> void:
	check_eq(DailyCalendar.share_text("2026-10-22", 12450, 38, 4),
		"Kinblox Daily 2026-10-22: 12,450 pts, 38 lines, best chain x4", "share text")
	check_eq(DailyCalendar.format_number(1234567), "1,234,567", "thousands")
	check_eq(DailyCalendar.format_number(0), "0", "zero")
