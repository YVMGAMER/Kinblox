class_name Scoring
extends RefCounted
## Score, lines, level, combo and back-to-back bookkeeping.

## Result of one line clear, for pop-ups and haptics.
class Award:
	extends RefCounted
	var lines := 0
	var points := 0
	var combo := 0
	var back_to_back := false

	func label() -> String:
		match lines:
			1:
				return "Single"
			2:
				return "Double"
			3:
				return "Triple"
			4:
				return "Quad"
		return ""


var tuning: Tuning
var score := 0
var lines := 0
var level := 1
var start_level := 1
## -1 means no active combo; 0 is the first clear of a streak.
var combo := -1
var best_combo := 0
var best_chain := 0
var _b2b_ready := false


func _init(p_tuning: Tuning, p_start_level: int = 1) -> void:
	tuning = p_tuning
	start_level = p_start_level
	level = p_start_level


func award_lines(count: int) -> Award:
	var a := Award.new()
	a.lines = count
	var points := tuning.line_points[mini(count, tuning.line_points.size() - 1)] * level
	if count >= 4:
		if _b2b_ready:
			points = int(points * tuning.back_to_back_multiplier)
			a.back_to_back = true
		_b2b_ready = true
	else:
		_b2b_ready = false
	combo += 1
	best_combo = maxi(best_combo, combo)
	a.combo = combo
	if combo > 0:
		points += tuning.combo_points * combo * level
	a.points = points
	score += points
	_add_lines(count)
	return a


func break_combo() -> void:
	combo = -1


func award_soft_drop(rows: int) -> void:
	score += rows * tuning.soft_drop_points


func award_hard_drop(rows: int) -> void:
	score += rows * tuning.hard_drop_points


func award_chain_step(cells: int, multiplier: int) -> int:
	var points := tuning.chain_cell_points * cells * multiplier * level
	score += points
	best_chain = maxi(best_chain, multiplier)
	return points


## Lines completed by cells falling during a chain. Scored at the plain line
## rate: no multiplier, no back-to-back, no combo.
func award_cascade_lines(count: int) -> int:
	var points := tuning.line_points[mini(count, tuning.line_points.size() - 1)] * level
	score += points
	_add_lines(count)
	return points


func _add_lines(count: int) -> void:
	lines += count
	@warning_ignore("integer_division")
	level = start_level + lines / tuning.lines_per_level
