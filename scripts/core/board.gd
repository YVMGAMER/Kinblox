class_name Board
extends RefCounted
## Grid storage. Row 0 is the top; the first HIDDEN_ROWS rows are the spawn
## buffer above the visible field. Each cell stores a color slot and the
## serial of the piece that placed it (used by the Color Chain rule).

const WIDTH := 10
const VISIBLE_ROWS := 20
const HIDDEN_ROWS := 2
const HEIGHT := VISIBLE_ROWS + HIDDEN_ROWS
const EMPTY := -1

var colors := PackedInt32Array()
var owners := PackedInt32Array()


func _init() -> void:
	colors.resize(WIDTH * HEIGHT)
	owners.resize(WIDTH * HEIGHT)
	clear()


func clear() -> void:
	colors.fill(EMPTY)
	owners.fill(EMPTY)


static func index(x: int, y: int) -> int:
	return y * WIDTH + x


static func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT


func is_empty(x: int, y: int) -> bool:
	return colors[y * WIDTH + x] == EMPTY


func color_at(x: int, y: int) -> int:
	return colors[y * WIDTH + x]


func owner_at(x: int, y: int) -> int:
	return owners[y * WIDTH + x]


func set_cell(x: int, y: int, color: int, owner: int) -> void:
	var i := y * WIDTH + x
	colors[i] = color
	owners[i] = owner


func clear_cell(x: int, y: int) -> void:
	set_cell(x, y, EMPTY, EMPTY)


func can_place(type: int, rot: int, pos: Vector2i) -> bool:
	for c in PieceDefs.cells(type, rot):
		var x := pos.x + c.x
		var y := pos.y + c.y
		if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT:
			return false
		if colors[y * WIDTH + x] != EMPTY:
			return false
	return true


## Writes a piece into the grid and returns the absolute cells it filled.
func place(type: int, rot: int, pos: Vector2i, owner: int) -> Array[Vector2i]:
	var slot := PieceDefs.color_slot(type)
	var out: Array[Vector2i] = []
	for c in PieceDefs.cells(type, rot):
		var p := pos + c
		set_cell(p.x, p.y, slot, owner)
		out.append(p)
	return out


func is_row_full(y: int) -> bool:
	var base := y * WIDTH
	for x in WIDTH:
		if colors[base + x] == EMPTY:
			return false
	return true


func is_row_empty(y: int) -> bool:
	var base := y * WIDTH
	for x in WIDTH:
		if colors[base + x] != EMPTY:
			return false
	return true


func full_rows() -> Array[int]:
	var rows: Array[int] = []
	for y in HEIGHT:
		if is_row_full(y):
			rows.append(y)
	return rows


## Removes the given rows; everything above shifts down to fill the gap.
func clear_rows(rows: Array[int]) -> void:
	if rows.is_empty():
		return
	var removing := PackedByteArray()
	removing.resize(HEIGHT)
	for r in rows:
		removing[r] = 1
	var write := HEIGHT - 1
	for read in range(HEIGHT - 1, -1, -1):
		if removing[read] == 1:
			continue
		if write != read:
			_copy_row(read, write)
		write -= 1
	while write >= 0:
		_empty_row(write)
		write -= 1


## Empties rows [0, row_count) in place without shifting (Zen top sweep).
func empty_top_rows(row_count: int) -> void:
	for y in mini(row_count, HEIGHT):
		_empty_row(y)


## Number of rows from the bottom up to the highest occupied cell.
func stack_height() -> int:
	for y in HEIGHT:
		if not is_row_empty(y):
			return HEIGHT - y
	return 0


func cell_count() -> int:
	var n := 0
	for c in colors:
		if c != EMPTY:
			n += 1
	return n


func copy() -> Board:
	var b := Board.new()
	b.colors = colors.duplicate()
	b.owners = owners.duplicate()
	return b


## Test helper. Rows are bottom-aligned; '.' is empty, '0'-'7' a color slot.
## Each filled cell gets its own owner unless an owner map of the same shape
## is given, where any character groups cells into the same piece.
func load_pattern(rows: PackedStringArray, owner_rows: PackedStringArray = PackedStringArray()) -> void:
	clear()
	var top := HEIGHT - rows.size()
	for r in rows.size():
		var line := rows[r]
		for x in mini(line.length(), WIDTH):
			var ch := line[x]
			if ch == ".":
				continue
			var y := top + r
			var owner := 1000 + index(x, y)
			if owner_rows.size() == rows.size():
				owner = owner_rows[r].unicode_at(x)
			set_cell(x, y, ch.to_int(), owner)


## Debug/test helper: the bottom `count` rows as pattern strings.
func to_pattern(count: int = HEIGHT) -> PackedStringArray:
	var out := PackedStringArray()
	for y in range(HEIGHT - count, HEIGHT):
		var line := ""
		for x in WIDTH:
			var c := color_at(x, y)
			line += "." if c == EMPTY else str(c)
		out.append(line)
	return out


func _copy_row(from_y: int, to_y: int) -> void:
	var src := from_y * WIDTH
	var dst := to_y * WIDTH
	for x in WIDTH:
		colors[dst + x] = colors[src + x]
		owners[dst + x] = owners[src + x]


func _empty_row(y: int) -> void:
	var base := y * WIDTH
	for x in WIDTH:
		colors[base + x] = EMPTY
		owners[base + x] = EMPTY
