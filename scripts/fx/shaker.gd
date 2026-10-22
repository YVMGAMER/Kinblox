class_name Shaker
extends Node
## Trauma-based screen shake applied to one Control as an offset from its
## laid-out position. Disabled entirely by the "reduce motion" setting.

const MAX_OFFSET := 18.0
const DECAY := 2.6
const FREQUENCY := 38.0

var target: Control
## Where layout put the target; shake is applied on top of this.
var rest_position := Vector2.ZERO

var _trauma := 0.0
var _time := 0.0


func _ready() -> void:
	set_process(false)


func add_trauma(amount: float) -> void:
	if Settings.reduce_motion() or target == null:
		return
	_trauma = minf(_trauma + amount, 1.0)
	set_process(true)


func stop() -> void:
	_trauma = 0.0
	if target != null:
		target.position = rest_position
	set_process(false)


func _process(delta: float) -> void:
	_time += delta
	_trauma = maxf(_trauma - DECAY * delta, 0.0)
	var power := _trauma * _trauma * MAX_OFFSET
	var offset := Vector2(sin(_time * FREQUENCY * 1.13), cos(_time * FREQUENCY * 0.87)) * power
	target.position = rest_position + offset
	if _trauma <= 0.0:
		stop()
