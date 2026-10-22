class_name SeededRng
extends RefCounted
## Small deterministic PRNG (xorshift32) that never touches Godot's global RNG.
## Its output is identical on every platform and engine version, which the
## Daily mode relies on for fairness.

const MASK_32 := 0xFFFFFFFF

var _state: int


func _init(seed_value: int) -> void:
	_state = seed_value & MASK_32
	if _state == 0:
		_state = 0x9E3779B9
	# Discard a few outputs so similar seeds diverge quickly.
	for i in 8:
		next_u32()


func next_u32() -> int:
	var x := _state
	x ^= (x << 13) & MASK_32
	x ^= x >> 17
	x ^= (x << 5) & MASK_32
	_state = x
	return x


## Uniform integer in [0, n).
func next_int(n: int) -> int:
	assert(n > 0)
	return next_u32() % n


## Uniform float in [0, 1).
func next_float() -> float:
	return float(next_u32()) / 4294967296.0


## 32-bit FNV-1a hash, used to turn strings (e.g. dates) into seeds.
static func hash_string(text: String) -> int:
	var h := 2166136261
	for byte in text.to_utf8_buffer():
		h ^= byte
		h = (h * 16777619) & MASK_32
	return h
