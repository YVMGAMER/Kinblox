class_name PieceDefs
extends RefCounted
## Data for every piece: spawn shape, rotation box, kick set and color slot.
## Coordinates are (x, y) with y pointing down, matching the board.
## Rotation states are 0 = spawn, 1 = right (CW), 2 = reverse, 3 = left.

enum Type { I, O, T, S, Z, J, L, V, X, I3 }
enum KickSet { NONE, SRS_JLSTZ, SRS_I, SIMPLE }

const COUNT := 10
## Logical color slots. Themes map each slot to an actual color, so chain
## matching never depends on the active theme.
const COLOR_SLOTS := 8

const STANDARD: Array[int] = [Type.I, Type.O, Type.T, Type.S, Type.Z, Type.J, Type.L]
## Original Kinblox pieces, in the fixed order the bag rolls for them.
const CUSTOM: Array[int] = [Type.V, Type.I3, Type.X]

## Indexed by Type. "cells" is the spawn state inside a box x box square;
## other states are derived by rotating inside that box.
const DEFS: Array[Dictionary] = [
	{"name": "I", "box": 4, "kicks": KickSet.SRS_I, "color": 0,
		"cells": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]},
	{"name": "O", "box": 2, "kicks": KickSet.NONE, "color": 1,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "T", "box": 3, "kicks": KickSet.SRS_JLSTZ, "color": 2,
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]},
	{"name": "S", "box": 3, "kicks": KickSet.SRS_JLSTZ, "color": 3,
		"cells": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	{"name": "Z", "box": 3, "kicks": KickSet.SRS_JLSTZ, "color": 4,
		"cells": [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)]},
	{"name": "J", "box": 3, "kicks": KickSet.SRS_JLSTZ, "color": 5,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]},
	{"name": "L", "box": 3, "kicks": KickSet.SRS_JLSTZ, "color": 6,
		"cells": [Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]},
	# Corner: 3-cell elbow.
	{"name": "Corner", "box": 2, "kicks": KickSet.SIMPLE, "color": 7,
		"cells": [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]},
	# Cross: 5-cell plus, rare.
	{"name": "Cross", "box": 3, "kicks": KickSet.SIMPLE, "color": 7,
		"cells": [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)]},
	# Trio: 3-cell straight.
	{"name": "Trio", "box": 3, "kicks": KickSet.SIMPLE, "color": 7,
		"cells": [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]},
]

# Kick tables as published for SRS, written with y pointing UP. Keys are
# from * 4 + to. They are converted to y-down when the cache is built.
const SRS_JLSTZ_Y_UP := {
	1: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	4: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	6: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, 2), Vector2i(1, 2)],
	9: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, -2), Vector2i(-1, -2)],
	11: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
	14: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	12: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, 2), Vector2i(-1, 2)],
	3: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, -2), Vector2i(1, -2)],
}
const SRS_I_Y_UP := {
	1: [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	4: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	6: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
	9: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	11: [Vector2i(0, 0), Vector2i(2, 0), Vector2i(-1, 0), Vector2i(2, 1), Vector2i(-1, -2)],
	14: [Vector2i(0, 0), Vector2i(-2, 0), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(1, 2)],
	12: [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(1, -2), Vector2i(-2, 1)],
	3: [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(-1, 2), Vector2i(2, -1)],
}
## Simple tests for the original pieces, already y-down: stay, sideways, then one floor kick.
const SIMPLE_KICKS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, -1),
]

static var _states: Array = []  # [type][rot] -> Array[Vector2i]
static var _kicks: Array = []  # [type][from * 4 + to] -> Array[Vector2i]


static func _static_init() -> void:
	for type in COUNT:
		var def: Dictionary = DEFS[type]
		var box: int = def["box"]
		var rots: Array = []
		var current: Array[Vector2i] = []
		for c: Vector2i in def["cells"]:
			current.append(c)
		for r in 4:
			rots.append(current)
			var next_state: Array[Vector2i] = []
			for c in current:
				next_state.append(Vector2i(box - 1 - c.y, c.x))
			current = next_state
		_states.append(rots)

		var table: Array = []
		table.resize(16)
		for from in 4:
			for dir: int in [1, 3]:
				var to := (from + dir) % 4
				table[from * 4 + to] = _build_kicks(def["kicks"], from * 4 + to)
		_kicks.append(table)


static func _build_kicks(kick_set: int, key: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	match kick_set:
		KickSet.SRS_JLSTZ, KickSet.SRS_I:
			var source: Dictionary = SRS_JLSTZ_Y_UP if kick_set == KickSet.SRS_JLSTZ else SRS_I_Y_UP
			for k: Vector2i in source[key]:
				out.append(Vector2i(k.x, -k.y))
		KickSet.SIMPLE:
			out.assign(SIMPLE_KICKS)
		_:
			out.append(Vector2i.ZERO)
	return out


## Cells of a piece in a rotation state, relative to its box origin.
## The returned array is shared; callers must not modify it.
static func cells(type: int, rot: int) -> Array[Vector2i]:
	return _states[type][rot]


## Kick offsets to try, in order, for rotating from one state to another.
static func kicks(type: int, from: int, to: int) -> Array[Vector2i]:
	return _kicks[type][from * 4 + to]


static func box_size(type: int) -> int:
	return DEFS[type]["box"]


static func color_slot(type: int) -> int:
	return DEFS[type]["color"]


static func display_name(type: int) -> String:
	return DEFS[type]["name"]


static func cell_count(type: int) -> int:
	return (DEFS[type]["cells"] as Array).size()


static func is_custom(type: int) -> bool:
	return type in CUSTOM


## Box origin for a freshly spawned piece: horizontally centered, top row 0.
static func spawn_position(type: int, board_width: int) -> Vector2i:
	return Vector2i((board_width - box_size(type)) >> 1, 0)
