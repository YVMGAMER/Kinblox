class_name Piece
extends RefCounted
## The active, falling piece: a type, a rotation state and a board position
## (the top-left of its rotation box).

var type: int
var rot: int = 0
var position: Vector2i
## Unique per spawned piece; written into the board as each cell's owner.
var serial: int


func _init(p_type: int, p_serial: int, p_position: Vector2i = Vector2i.ZERO) -> void:
	type = p_type
	serial = p_serial
	position = p_position


func local_cells() -> Array[Vector2i]:
	return PieceDefs.cells(type, rot)


## Absolute board cells. Allocates; meant for views and tests, not hot loops.
func board_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c in PieceDefs.cells(type, rot):
		out.append(c + position)
	return out
