extends KinTest


func _draw(seed_value: int, count: int, unlock_level: int) -> Array[int]:
	var bag := Bag.new(SeededRng.new(seed_value), Tuning.new())
	var out: Array[int] = []
	for i in count:
		out.append(bag.next(unlock_level))
	return out


func test_every_bag_is_a_permutation() -> void:
	var seq := _draw(12345, 7 * 200, 0)
	for b in 200:
		var chunk := seq.slice(b * 7, b * 7 + 7)
		chunk.sort()
		check_eq(chunk, PieceDefs.STANDARD, "bag %d" % b)


func test_same_seed_same_sequence() -> void:
	check_eq(_draw(99, 300, 50), _draw(99, 300, 50), "sequence")


func test_different_seed_differs() -> void:
	check(_draw(1, 70, 0) != _draw(2, 70, 0), "seeds differ")


func test_no_custom_pieces_before_unlock() -> void:
	for t in _draw(7, 700, 1):
		check(not PieceDefs.is_custom(t), "custom piece before unlock")


func test_custom_pieces_at_controlled_rate() -> void:
	var tuning := Tuning.new()
	var bags := 2000
	var bag := Bag.new(SeededRng.new(4242), tuning)
	var counts: Dictionary[int, int] = {}
	while bag.bags_generated <= bags:
		var t := bag.next(99)
		counts[t] = counts.get(t, 0) + 1
	# Pieces drawn beyond `bags` complete bags are from the partial last bag.
	for t in PieceDefs.STANDARD:
		check(counts.get(t, 0) >= bags and counts.get(t, 0) <= bags + 1, "standard piece once per bag")
	for t in PieceDefs.CUSTOM:
		var rate := float(counts.get(t, 0)) / bags
		var expected := tuning.custom_chance(t)
		check(absf(rate - expected) < 0.04, "%s rate %.3f vs %.3f" % [PieceDefs.display_name(t), rate, expected])


func test_standard_order_independent_of_unlocks() -> void:
	var locked := _draw(555, 700, 0)
	var unlocked_raw := _draw(555, 900, 99)
	var unlocked: Array[int] = []
	for t in unlocked_raw:
		if not PieceDefs.is_custom(t):
			unlocked.append(t)
	check_eq(unlocked.slice(0, 700), locked, "standard order")


func test_isolated_from_global_rng() -> void:
	seed(1)
	var a := _draw(31337, 50, 99)
	seed(987654)
	randi()
	randf()
	var b := _draw(31337, 50, 99)
	check_eq(a, b, "global rng must not affect bag")


func test_rng_range() -> void:
	var rng := SeededRng.new(0)
	for i in 1000:
		var v := rng.next_int(7)
		check(v >= 0 and v < 7, "next_int range")
		var f := rng.next_float()
		check(f >= 0.0 and f < 1.0, "next_float range")
