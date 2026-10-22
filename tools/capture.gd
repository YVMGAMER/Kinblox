extends SceneTree
## Renders screens to PNG at true base resolution for visual review and
## store screenshots. The app runs inside an offscreen SubViewport, so the
## desktop window size does not matter. Needs a renderer (no --headless):
##   godot --path . -s tools/capture.gd -- --screen=game --out=C:/shots/game.png
## Options (after `--`):
##   --screen=<id>      screen to open (see scripts/ui/main.gd)
##   --mode=<id>        classic | zen | daily (game screen)
##   --size=WxH         viewport size (default 1080x1920; try 1080x2400)
##   --theme=<id>       ink | paper | glacier | ember (not saved)
##   --pieces=<n>       let a simple bot place n pieces first (game screen)
##   --frames=<n>       frames to wait before capturing (default 30)
##   --buttons          use the on-screen button scheme (not saved)
##   --patterns         show colorblind patterns (not saved)
##   --pause / --results  open the pause or results overlay
##   --out=<file.png>
## Autoloads are looked up by node path: they are not compile-time globals
## in a -s script, and game scripts are only touched through duck typing.

var _args := {}
var _frame := 0
var _viewport: SubViewport


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		_args[parts[0]] = parts[1] if parts.size() > 1 else "true"
	var settings := root.get_node("Settings")
	var values: Dictionary = settings.get("_values")
	if _args.has("buttons"):
		values[&"control_scheme"] = 1
	if _args.has("patterns"):
		values[&"patterns"] = true
	root.get_node("ThemeManager").call("_apply", _args.get("theme", "ink"), false)
	root.get_node("AudioManager").process_mode = Node.PROCESS_MODE_DISABLED
	var dims: PackedStringArray = String(_args.get("size", "1080x1920")).split("x")
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(dims[0].to_int(), dims[1].to_int())
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_viewport)
	_viewport.add_child((load("res://scenes/main.tscn") as PackedScene).instantiate())


func _process(_delta: float) -> bool:
	_frame += 1
	var wait := int(_args.get("frames", "30"))
	var screen := _screen()
	if _frame == 8 and _args.get("screen", "") == "game" and screen != null:
		_run_bot(screen)
	if _frame == wait - 6 and screen != null and screen.has_method(&"pause_game"):
		if _args.has("pause"):
			screen.call(&"pause_game")
		elif _args.has("results"):
			(screen.get("session") as GameSession).abandon()
			screen.call(&"_on_game_over")
	if _frame >= wait + (60 if _args.has("results") else 0):
		var img := _viewport.get_texture().get_image()
		var out: String = _args.get("out", "user://capture.png")
		img.save_png(out)
		print("saved ", out, " ", img.get_size())
		return true
	return false


func _screen() -> Control:
	var host := _viewport.get_node_or_null("Main/ScreenHost")
	if host == null or host.get_child_count() == 0:
		return null
	return host.get_child(host.get_child_count() - 1) as Control


## Greedy placement: try every rotation and column, keep the lowest, flattest
## result with the fewest holes. Good enough for realistic screenshots.
func _run_bot(screen: Control) -> void:
	var s := screen.get("session") as GameSession
	if s == null:
		return
	var shipped := s.tuning
	s.tuning = shipped.duplicate() as Tuning
	s.tuning.ready_delay = 0.0
	s.tuning.line_clear_delay = 0.0
	s.tuning.chain_highlight_delay = 0.0
	s.update(1.0)
	for i in int(_args.get("pieces", "0")):
		if s.state != GameSession.State.PLAYING:
			s.update(0.0)
		if s.active == null:
			break
		_place_best(s)
	s.tuning = shipped


func _place_best(s: GameSession) -> void:
	var p := s.active
	var best_score := -1e9
	var best_rot := 0
	var best_x := p.position.x
	for rot in 4:
		for x in range(-3, Board.WIDTH):
			var pos := Vector2i(x, p.position.y)
			if not s.board.can_place(p.type, rot, pos):
				continue
			while s.board.can_place(p.type, rot, pos + Vector2i.DOWN):
				pos.y += 1
			var b := s.board.copy()
			b.place(p.type, rot, pos, 1)
			var score := _evaluate(b)
			if score > best_score:
				best_score = score
				best_rot = rot
				best_x = x
	p.rot = best_rot
	p.position.x = best_x
	if not s.board.can_place(p.type, p.rot, p.position):
		p.rot = 0
		p.position.x = PieceDefs.spawn_position(p.type, Board.WIDTH).x
	s.hard_drop()


func _evaluate(b: Board) -> float:
	var lines := b.full_rows().size()
	var holes := 0
	var heights := PackedInt32Array()
	for x in Board.WIDTH:
		var h := 0
		var seen := false
		for y in Board.HEIGHT:
			if not b.is_empty(x, y):
				if not seen:
					h = Board.HEIGHT - y
					seen = true
			elif seen:
				holes += 1
		heights.append(h)
	var aggregate := 0
	var bump := 0
	for x in Board.WIDTH:
		aggregate += heights[x]
		if x > 0:
			bump += absi(heights[x] - heights[x - 1])
	return lines * 0.76 - aggregate * 0.51 - holes * 0.36 - bump * 0.18
