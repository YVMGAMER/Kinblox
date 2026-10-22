extends SceneTree
## UI smoke test. For every screen it presses every visible button on a fresh
## copy of the screen; any buttons that appear as a result (overlays,
## confirmations, the next screen) are pressed too, one level deeper. The
## game screen is also forced to game over to reach the results sheet.
##   godot --headless --path . -s tests/ui_smoke.gd [-- --only=<screen>]
## Script errors show up in the output; the run ends with a summary.
## Uses a throwaway save file, never the player's.

const SCREENS: Array[StringName] = [&"splash", &"menu", &"modes", &"settings", &"howto", &"stats", &"game"]
const SETTLE_MS := 260
const MAX_DEPTH := 2
const GAME_OVER := -100  # pseudo button: end the current game

var _game_state: Node
## Each job: {"screen": StringName, "path": Array[int]}. Running a job opens
## the screen, presses the path in order, then lists newly shown buttons.
var _jobs: Array[Dictionary] = []
var _ops: Array = []
var _before: Dictionary = {}
var _resume_at := 0
var _pressed := 0
var _jobs_run := 0
var _started := false


func _process(_delta: float) -> bool:
	if not _started:
		_setup()
		_started = true
		return false
	if Time.get_ticks_msec() < _resume_at:
		return false
	if _ops.is_empty():
		if _jobs.is_empty():
			print("UI smoke: %d jobs, %d button presses, done" % [_jobs_run, _pressed])
			return true
		_start_job(_jobs.pop_front())
	var op: Array = _ops.pop_front()
	match op[0]:
		"open":
			_open(op[1])
		"press":
			_before = _ids()
			_press(op[1])
		"list":
			_list(op[1], op[2])
	_resume_at = maxi(_resume_at, Time.get_ticks_msec() + SETTLE_MS)
	return false


func _setup() -> void:
	var store := root.get_node("SaveData").get("store") as SaveStore
	store.path = "user://ui_smoke_save.json"
	store.reset()
	root.get_node("AudioManager").process_mode = Node.PROCESS_MODE_DISABLED
	_game_state = root.get_node("GameState")
	root.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	for s in SCREENS:
		if only.is_empty() or String(s) == only:
			_jobs.append({"screen": s, "path": [] as Array[int]})
			if s == &"game":
				_jobs.append({"screen": s, "path": [GAME_OVER] as Array[int]})


func _start_job(job: Dictionary) -> void:
	_jobs_run += 1
	var path: Array[int] = job["path"]
	_ops.append(["open", job["screen"]])
	_before = {}
	for idx in path:
		_ops.append(["press", idx])
	if path.size() < MAX_DEPTH:
		_ops.append(["list", job["screen"], path])


func _list(screen: StringName, path: Array[int]) -> void:
	var buttons := _buttons()
	var fresh := 0
	for i in buttons.size():
		if _before.has(buttons[i].get_instance_id()):
			continue
		fresh += 1
		var next: Array[int] = path.duplicate()
		next.append(i)
		_jobs.append({"screen": screen, "path": next})
	print("  %-9s path %-12s %d new buttons" % [screen, str(path), fresh])


func _press(index: int) -> void:
	if index == GAME_OVER:
		var screen := _current()
		if screen != null and screen.has_method(&"_on_game_over"):
			(screen.get("session") as GameSession).abandon()
			screen.call(&"_on_game_over")
			_resume_at = Time.get_ticks_msec() + 1200
		return
	var buttons := _buttons()
	if index >= buttons.size():
		return
	var b := buttons[index]
	if b.toggle_mode:
		b.button_pressed = not b.button_pressed
	b.pressed.emit()
	_pressed += 1


func _open(screen: StringName) -> void:
	if screen == &"game":
		_game_state.set("pending_mode", ModeConfig.classic(1, true))
	_game_state.call("goto", screen)


func _current() -> Control:
	var host := root.get_node_or_null("Main/ScreenHost")
	if host == null or host.get_child_count() == 0:
		return null
	return host.get_child(host.get_child_count() - 1) as Control


func _ids() -> Dictionary:
	var out := {}
	for b in _buttons():
		out[b.get_instance_id()] = true
	return out


## Visible, enabled buttons on the current screen, in tree order.
func _buttons() -> Array[BaseButton]:
	var out: Array[BaseButton] = []
	var screen := _current()
	if screen != null:
		_collect(screen, out)
	return out


func _collect(node: Node, out: Array[BaseButton]) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is BaseButton and not (node as BaseButton).disabled:
		out.append(node as BaseButton)
	for c in node.get_children():
		_collect(c, out)
