class_name Bag
extends RefCounted
## 7-bag randomizer: every bag holds each standard piece exactly once.
## Unlocked original pieces are occasionally shuffled into a bag as extras.
## The RNG is consumed identically whether or not a piece is unlocked, so the
## standard sequence never depends on player progress.

var _rng: SeededRng
var _tuning: Tuning
var _pending: Array[int] = []
var bags_generated := 0


func _init(rng: SeededRng, tuning: Tuning) -> void:
	_rng = rng
	_tuning = tuning


func next(unlock_level: int) -> int:
	if _pending.is_empty():
		_refill(unlock_level)
	return _pending.pop_front()


func _refill(unlock_level: int) -> void:
	var bag: Array[int] = PieceDefs.STANDARD.duplicate()
	for i in range(bag.size() - 1, 0, -1):
		var j := _rng.next_int(i + 1)
		var tmp := bag[i]
		bag[i] = bag[j]
		bag[j] = tmp
	for custom in PieceDefs.CUSTOM:
		var roll := _rng.next_float()
		var slot := _rng.next_int(bag.size() + 1)
		if unlock_level >= _tuning.unlock_level(custom) and roll < _tuning.custom_chance(custom):
			bag.insert(slot, custom)
	_pending.append_array(bag)
	bags_generated += 1
