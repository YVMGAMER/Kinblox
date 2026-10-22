class_name DailyCalendar
extends RefCounted
## UTC date helpers for the Daily challenge. Pure functions of their inputs
## except the *_now() wrappers, which read the system clock.

const SECONDS_PER_DAY := 86400
const SEED_PREFIX := "kinblox:daily:"


static func date_for_unix(unix_time: int) -> String:
	return Time.get_date_string_from_unix_time(unix_time)


static func today() -> String:
	return date_for_unix(int(Time.get_unix_time_from_system()))


static func seed_for_date(date: String) -> int:
	return SeededRng.hash_string(SEED_PREFIX + date)


static func seconds_until_next(unix_time: int) -> int:
	return SECONDS_PER_DAY - posmod(unix_time, SECONDS_PER_DAY)


static func seconds_until_next_now() -> int:
	return seconds_until_next(int(Time.get_unix_time_from_system()))


static func previous_date(date: String) -> String:
	var unix := Time.get_unix_time_from_datetime_string(date + "T00:00:00")
	return date_for_unix(unix - SECONDS_PER_DAY)


static func format_countdown(seconds: int) -> String:
	@warning_ignore("integer_division")
	var h := seconds / 3600
	@warning_ignore("integer_division")
	var m := (seconds % 3600) / 60
	return "%02d:%02d:%02d" % [h, m, seconds % 60]


static func share_text(date: String, score: int, lines: int, best_chain: int) -> String:
	var chain := "x%d" % best_chain if best_chain > 0 else "none"
	return "Kinblox Daily %s: %s pts, %d lines, best chain %s" % [date, format_number(score), lines, chain]


static func format_number(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return ("-" if value < 0 else "") + out
