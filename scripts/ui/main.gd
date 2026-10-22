extends Control
## App root. Hosts one screen at a time with quick fade/slide transitions,
## owns the UI theme, crossfades theme switches and routes the back button.

const SCREENS := {
	GameState.SPLASH: "res://scenes/screens/splash.tscn",
	GameState.MENU: "res://scenes/screens/main_menu.tscn",
	GameState.MODES: "res://scenes/screens/mode_select.tscn",
	GameState.GAME: "res://scenes/game/game_screen.tscn",
	GameState.SETTINGS: "res://scenes/screens/settings.tscn",
	GameState.HOW_TO: "res://scenes/screens/how_to_play.tscn",
	GameState.STATS: "res://scenes/screens/stats.tscn",
}

@onready var _host: Control = %ScreenHost
@onready var _fade: TextureRect = %ThemeFade

var _current: Control
var _fade_tween: Tween


func _ready() -> void:
	theme = ThemeManager.ui_theme
	ThemeManager.theme_changed.connect(_on_theme_changed)
	GameState.screen_requested.connect(_show)
	_show(_start_screen(), {})


## Optional user args (after `--`) for testing and screenshots:
##   --screen=game|menu|modes|settings|howto|stats   --mode=classic|zen|daily
func _start_screen() -> StringName:
	var screen := GameState.SPLASH
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screen="):
			screen = StringName(arg.trim_prefix("--screen="))
		elif arg.begins_with("--mode="):
			match arg.trim_prefix("--mode="):
				"zen":
					GameState.pending_mode = GameState.zen_mode()
				"daily":
					GameState.pending_mode = ModeConfig.daily(DailyCalendar.today(), true)
				_:
					GameState.pending_mode = GameState.classic_mode()
	return screen if SCREENS.has(screen) else GameState.SPLASH


func _show(id: StringName, payload: Dictionary) -> void:
	var path: String = SCREENS.get(id, SCREENS[GameState.MENU])
	var next := (load(path) as PackedScene).instantiate() as Control
	if next.has_method(&"setup"):
		next.call(&"setup", payload)
	var previous := _current
	_current = next
	GameState.current_screen = id
	_host.add_child(next)
	var still := Settings.reduce_motion()
	next.modulate.a = 0.0
	if not still:
		next.position.y = UiTokens.SLIDE
	var tw := next.create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(next, "modulate:a", 1.0, UiTokens.SCREEN_IN)
	tw.tween_property(next, "position:y", 0.0, UiTokens.SCREEN_IN)
	if previous != null:
		previous.process_mode = Node.PROCESS_MODE_DISABLED
		previous.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var out := previous.create_tween()
		out.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		out.bind_node(self)
		out.tween_property(previous, "modulate:a", 0.0, UiTokens.SCREEN_OUT)
		out.tween_callback(previous.queue_free)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_back()
		get_viewport().set_input_as_handled()


func _back() -> void:
	if _current != null and _current.has_method(&"handle_back") and bool(_current.call(&"handle_back")):
		return
	if GameState.current_screen == GameState.MENU or GameState.current_screen == GameState.SPLASH:
		get_tree().quit()
	else:
		AudioManager.play(AudioManager.Sfx.UI_BACK)
		GameState.goto(GameState.MENU)


func _on_theme_changed(_gt: GameTheme, animate: bool) -> void:
	var img: Image = null
	# The headless dummy renderer has no frame to snapshot.
	if animate and not Settings.reduce_motion() and DisplayServer.get_name() != "headless":
		img = get_viewport().get_texture().get_image()
	if img != null and not img.is_empty():
		_fade.texture = ImageTexture.create_from_image(img)
		_fade.modulate.a = 1.0
		_fade.visible = true
		if _fade_tween != null:
			_fade_tween.kill()
		_fade_tween = create_tween()
		_fade_tween.tween_property(_fade, "modulate:a", 0.0, UiTokens.THEME_FADE).set_trans(Tween.TRANS_SINE)
		_fade_tween.tween_callback(func() -> void:
			_fade.visible = false
			_fade.texture = null)
	theme = ThemeManager.ui_theme
