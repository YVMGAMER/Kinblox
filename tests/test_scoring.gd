extends KinTest


func test_line_points_scale_with_level() -> void:
	var s := Scoring.new(Tuning.new())
	check_eq(s.award_lines(1).points, 100, "single L1")
	s.break_combo()
	check_eq(s.award_lines(2).points, 300, "double L1")
	s.break_combo()
	check_eq(s.award_lines(3).points, 500, "triple L1")
	s.break_combo()
	var s3 := Scoring.new(Tuning.new(), 3)
	check_eq(s3.award_lines(4).points, 2400, "quad L3")


func test_back_to_back_quads() -> void:
	var s := Scoring.new(Tuning.new())
	var first := s.award_lines(4)
	s.break_combo()
	var second := s.award_lines(4)
	check(not first.back_to_back, "first quad not b2b")
	check(second.back_to_back, "second quad b2b")
	check_eq(second.points, 1200, "b2b points")
	s.break_combo()
	s.award_lines(1)
	s.break_combo()
	check(not s.award_lines(4).back_to_back, "single breaks b2b")


func test_combo_bonus() -> void:
	var s := Scoring.new(Tuning.new())
	check_eq(s.award_lines(1).points, 100, "combo 0")
	var second := s.award_lines(1)
	check_eq(second.combo, 1, "combo count")
	check_eq(second.points, 150, "combo 1 bonus")
	s.break_combo()
	check_eq(s.award_lines(1).combo, 0, "combo reset")


func test_level_every_ten_lines() -> void:
	var s := Scoring.new(Tuning.new())
	for i in 9:
		s.award_lines(1)
	check_eq(s.level, 1, "level after 9")
	s.award_lines(1)
	check_eq(s.level, 2, "level after 10")
	s.award_lines(4)
	s.award_lines(4)
	s.award_lines(4)
	check_eq(s.level, 3, "level after 22")


func test_drop_points() -> void:
	var s := Scoring.new(Tuning.new())
	s.award_soft_drop(5)
	s.award_hard_drop(10)
	check_eq(s.score, 25, "soft 1/row, hard 2/row")


func test_chain_points_and_cap() -> void:
	var t := Tuning.new()
	var s := Scoring.new(t, 2)
	check_eq(s.award_chain_step(6, t.chain_multiplier(1)), 6 * 10 * 2 * 2, "chain step 1")
	check_eq(t.chain_multiplier(1), 2, "first chain is x2")
	check_eq(t.chain_multiplier(3), 4, "third chain is x4")
	check_eq(t.chain_multiplier(50), t.chain_multiplier_cap, "capped")
	check_eq(s.best_chain, 2, "best chain")


func test_session_drop_scoring() -> void:
	var s := KinTest.started_session(ModeConfig.classic(3, true))
	var start_score := s.scoring.score
	var rows := s.ghost_y() - s.active.position.y
	s.hard_drop()
	check_eq(s.scoring.score - start_score, rows * 2, "hard drop points")
	var before := s.scoring.score
	check(s.soft_drop_step(), "soft drop step")
	check_eq(s.scoring.score - before, 1, "soft drop point")
