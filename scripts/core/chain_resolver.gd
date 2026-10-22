class_name ChainResolver
extends RefCounted
## Color Chain rules, as pure functions of the board.
## A "kin group" is an orthogonally connected set of same-color cells. It
## clears when it has at least min_size cells drawn from at least min_pieces
## different pieces (a lone, intact piece never qualifies).
## Scanning order is fixed (top-left to bottom-right) so results are
## deterministic for a given board.

const _NEIGHBORS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## Returns qualifying groups as sorted lists of cell indices (y * WIDTH + x).
static func find_groups(board: Board, min_size: int, min_pieces: int) -> Array[PackedInt32Array]:
	var groups: Array[PackedInt32Array] = []
	var visited := PackedByteArray()
	visited.resize(Board.WIDTH * Board.HEIGHT)
	var stack := PackedInt32Array()
	for start in Board.WIDTH * Board.HEIGHT:
		var color := board.colors[start]
		if color == Board.EMPTY or visited[start] == 1:
			continue
		var group := PackedInt32Array()
		var owners: Dictionary[int, bool] = {}
		visited[start] = 1
		stack.append(start)
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.remove_at(stack.size() - 1)
			group.append(i)
			owners[board.owners[i]] = true
			var x := i % Board.WIDTH
			@warning_ignore("integer_division")
			var y := i / Board.WIDTH
			for d in _NEIGHBORS:
				var nx := x + d.x
				var ny := y + d.y
				if not Board.in_bounds(nx, ny):
					continue
				var n := Board.index(nx, ny)
				if visited[n] == 0 and board.colors[n] == color:
					visited[n] = 1
					stack.append(n)
		if group.size() >= min_size and owners.size() >= min_pieces:
			group.sort()
			groups.append(group)
	return groups


## Removes every cell in the groups. Within each column, whatever sits above
## a removed cell drops down to fill it (existing holes keep their shape).
## Returns the number of cells removed.
static func remove_groups(board: Board, groups: Array[PackedInt32Array]) -> int:
	var removing := PackedByteArray()
	removing.resize(Board.WIDTH * Board.HEIGHT)
	var removed := 0
	for g in groups:
		for i in g:
			if removing[i] == 0:
				removing[i] = 1
				removed += 1
	for x in Board.WIDTH:
		var write := Board.HEIGHT - 1
		for read in range(Board.HEIGHT - 1, -1, -1):
			var ri := Board.index(x, read)
			if removing[ri] == 1:
				continue
			if write != read:
				var wi := Board.index(x, write)
				board.colors[wi] = board.colors[ri]
				board.owners[wi] = board.owners[ri]
			write -= 1
		while write >= 0:
			board.clear_cell(x, write)
			write -= 1
	return removed


## Runs a full chain to completion on a board (used by tests and previews).
## Returns the number of cells removed at each step.
static func resolve_all(board: Board, tuning: Tuning) -> PackedInt32Array:
	var steps := PackedInt32Array()
	while true:
		var groups := find_groups(board, tuning.chain_min_group, tuning.chain_min_pieces)
		if groups.is_empty():
			break
		steps.append(remove_groups(board, groups))
		board.clear_rows(board.full_rows())
	return steps
