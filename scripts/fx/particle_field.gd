class_name ParticleField
extends Control
## Fixed-capacity particle pool drawn in a single _draw pass. All storage is
## preallocated; dead particles are swap-removed, so bursts never allocate.

const CAPACITY := 384
const GRAVITY := 2600.0
const DRAG := 2.2

var _pos := PackedVector2Array()
var _vel := PackedVector2Array()
var _life := PackedFloat32Array()
var _max_life := PackedFloat32Array()
var _size := PackedFloat32Array()
var _color := PackedColorArray()
var _alive := 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pos.resize(CAPACITY)
	_vel.resize(CAPACITY)
	_life.resize(CAPACITY)
	_max_life.resize(CAPACITY)
	_size.resize(CAPACITY)
	_color.resize(CAPACITY)
	set_process(false)


func clear() -> void:
	_alive = 0
	queue_redraw()


## Sprays `count` square particles from a point.
func burst(origin: Vector2, color: Color, count: int, speed: float, particle_size: float) -> void:
	if Settings.reduce_motion():
		count = count / 3
	for i in count:
		if _alive >= CAPACITY:
			break
		var angle := _rng.randf_range(-PI, 0.0) if _rng.randf() < 0.8 else _rng.randf_range(0.0, PI)
		var v := Vector2.from_angle(angle) * speed * _rng.randf_range(0.35, 1.0)
		_spawn(origin + Vector2(_rng.randf_range(-4, 4), _rng.randf_range(-4, 4)), v, color, particle_size * _rng.randf_range(0.5, 1.0), _rng.randf_range(0.35, 0.7))
	set_process(true)


## A row-wide shower used for line clears.
func row_burst(left: Vector2, width: float, colors: PackedColorArray, per_cell: int, speed: float, particle_size: float) -> void:
	var cells := colors.size()
	for c in cells:
		var center := left + Vector2((c + 0.5) * width / cells, 0)
		burst(center, colors[c], per_cell, speed, particle_size)


func _spawn(p: Vector2, v: Vector2, color: Color, s: float, life: float) -> void:
	var i := _alive
	_pos[i] = p
	_vel[i] = v
	_color[i] = color
	_size[i] = s
	_life[i] = life
	_max_life[i] = life
	_alive += 1


func _process(delta: float) -> void:
	var i := 0
	var damp := exp(-DRAG * delta)
	while i < _alive:
		_life[i] -= delta
		if _life[i] <= 0.0:
			var last := _alive - 1
			_pos[i] = _pos[last]
			_vel[i] = _vel[last]
			_color[i] = _color[last]
			_size[i] = _size[last]
			_life[i] = _life[last]
			_max_life[i] = _max_life[last]
			_alive -= 1
			continue
		var v := _vel[i] * damp
		v.y += GRAVITY * delta
		_vel[i] = v
		_pos[i] += v * delta
		i += 1
	queue_redraw()
	if _alive == 0:
		set_process(false)


func _draw() -> void:
	for i in _alive:
		var k := _life[i] / _max_life[i]
		var s := _size[i] * (0.4 + 0.6 * k)
		var c := _color[i]
		c.a *= k
		draw_rect(Rect2(_pos[i] - Vector2(s, s) * 0.5, Vector2(s, s)), c)
