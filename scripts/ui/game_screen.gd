class_name GameScreen
extends Control
## Builds one GameSession from GameState.pending_mode and wires it to the
## views, input, feedback and overlays. Holds no game rules itself.

const RESULTS_DELAY := 0.7

@onready var _board_area: Control = %BoardArea
@onready var _board_view: BoardView = %BoardView
@onready var _field: Control = %Field
@onready var _ghost: GhostView = %Ghost
@onready var _piece: PieceView = %Piece
@onready var _particles: ParticleField = %Particles
@onready var _hold_view: PiecePreviewView = %HoldView
@onready var _next_view: PiecePreviewView = %NextView
@onready var _hold_panel: Control = %HoldPanel
@onready var _pause_button: Button = %PauseButton
@onready var _pad: ControlPad = %ControlPad
@onready var _popups: PopupLayer = %Popups
@onready var _banner: Banner = %Banner
@onready var _touch: TouchInput = %TouchInput
@onready var _router: InputRouter = %InputRouter
@onready var _feedback: GameFeedback = %Feedback
@onready var _juice: GameJuice = %Juice
@onready var _shaker: Shaker = %Shaker
@onready var _hud: Hud = %Hud
@onready var _pause: PauseOverlay = %PauseOverlay
@onready var _results: ResultsOverlay = %ResultsOverlay
@onready var _ambient: AmbientBackground = %Ambient

var session: GameSession
var _chains := 0
var _finished := false


func _ready() -> void:
	var mode := GameState.pending_mode if GameState.pending_mode != null else GameState.classic_mode()
	GameState.pending_mode = null
	session = GameSession.new(mode)
	_bind_hud()
	_board_view.bind(session)
	_piece.bind(session, _board_view)
	_ghost.bind(session, _board_view)
	_hold_view.bind(session)
	_next_view.bind(session)
	_router.bind(session)
	_feedback.bind(session, _router)
	_juice.board_view = _board_view
	_juice.particles = _particles
	_juice.popups = _popups
	_juice.banner = _banner
	_juice.shaker = _shaker
	_juice.bind(session)
	_shaker.target = _board_view

	_touch.play_area = self
	_touch.hold_area = _hold_panel
	_touch.blockers = [_pause_button, _pad] as Array[Control]
	_touch.move_steps.connect(_router.shift_by)
	_touch.soft_drop_rows.connect(_router.soft_drop_rows)
	_touch.hard_drop_requested.connect(func() -> void: session.hard_drop())
	_touch.rotate_requested.connect(func(dir: int) -> void: session.rotate(dir))
	_touch.hold_requested.connect(func() -> void: session.hold())
	_pad.action_pressed.connect(func(a: StringName) -> void: _router.action_down(a, InputRouter.SOURCE_PAD))
	_pad.action_released.connect(func(a: StringName) -> void: _router.action_up(a, InputRouter.SOURCE_PAD))

	_pause_button.pressed.connect(pause_game)
	_pause.configure(mode)
	_pause.resume_requested.connect(resume_game)
	_pause.restart_requested.connect(_restart)
	_pause.quit_requested.connect(_quit_from_pause)
	_results.again_requested.connect(_restart)
	_results.menu_requested.connect(func() -> void: GameState.goto(GameState.MENU))

	session.game_over.connect(_on_game_over)
	session.chain_finished.connect(func(_s: int) -> void: _chains += 1)

	_ambient.visible = mode.id == ModeConfig.Id.ZEN
	_board_area.resized.connect(_layout_board)
	Settings.changed.connect(_on_setting_changed)
	_apply_control_scheme()
	_layout_board.call_deferred()
	AudioManager.play_music(AudioManager.Music.ZEN if mode.id == ModeConfig.Id.ZEN else AudioManager.Music.AMBIENT)
	session.start()
	_banner.show_text("Ready", mode.display_name(), session.tuning.ready_delay * 0.7)


func _bind_hud() -> void:
	_hud.score_caption = %ScoreCaption
	_hud.score_value = %ScoreValue
	_hud.best_caption = %BestCaption
	_hud.best_value = %BestValue
	_hud.level_value = %LevelValue
	_hud.lines_value = %LinesValue
	_hud.combo_label = %ComboLabel
	_hud.chain_label = %ChainLabel
	_hud.mode_label = %ModeLabel
	_hud.bind(session)


func _process(delta: float) -> void:
	session.update(minf(delta, 0.1))


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if is_node_ready() and session != null:
				pause_game()
				SaveData.flush()


## Android back button / Escape.
func handle_back() -> bool:
	if _results.visible:
		GameState.goto(GameState.MENU)
	elif _pause.visible:
		resume_game()
	else:
		pause_game()
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		handle_back()
		get_viewport().set_input_as_handled()


func pause_game() -> void:
	if _finished or session.state == GameSession.State.PAUSED or session.state == GameSession.State.GAME_OVER:
		return
	session.pause()
	_set_input_enabled(false)
	_pause.open()


func resume_game() -> void:
	if _finished:
		return
	_pause.close()
	session.resume()
	_set_input_enabled(true)


func _set_input_enabled(on: bool) -> void:
	_router.reset()
	_router.enabled = on
	_touch.reset()
	_touch.enabled = on
	_pad.release_all()
	_pad.enabled = on


func _restart() -> void:
	if not _finished and session.pieces_locked > 0:
		_record()
	GameState.start_game(GameState.replay_mode(session.mode))


func _quit_from_pause() -> void:
	if session.mode.id == ModeConfig.Id.ZEN:
		session.abandon()
		_on_game_over()
		return
	if session.pieces_locked > 0 or (session.mode.id == ModeConfig.Id.DAILY and not session.mode.is_practice):
		_record()
	GameState.goto(GameState.MENU)


func _record() -> Dictionary:
	_finished = true
	return GameState.record_result(session, _chains)


func _on_game_over() -> void:
	if _finished:
		return
	_set_input_enabled(false)
	var summary := _record()
	_pause.visible = false
	await get_tree().create_timer(RESULTS_DELAY).timeout
	if is_inside_tree():
		_results.show_results(session.mode, summary)


func _on_setting_changed(key: StringName) -> void:
	match key:
		&"control_scheme":
			_apply_control_scheme()
			_layout_board.call_deferred()
		&"sensitivity":
			_touch.sensitivity = Settings.sensitivity()


func _apply_control_scheme() -> void:
	var buttons := Settings.control_scheme() == Settings.ControlScheme.BUTTONS
	_pad.visible = buttons
	_touch.gestures_enabled = not buttons
	_touch.sensitivity = Settings.sensitivity()


func _layout_board() -> void:
	var area := _board_area.size
	var pad := BoardView.FRAME_PAD
	var cell := floorf(minf((area.x - pad * 2.0) / Board.WIDTH, (area.y - pad * 2.0) / Board.VISIBLE_ROWS))
	cell = maxf(cell, 8.0)
	_board_view.set_cell_size(cell)
	var pos := ((area - _board_view.size) * 0.5).floor()
	_board_view.position = pos
	_shaker.rest_position = pos
	_field.size = _board_view.size
	_ghost.size = _board_view.size
	_particles.size = _board_view.size
	_touch.cell_px = cell
	var banner_width := _board_view.size.x
	_banner.size = Vector2(banner_width, 200)
	_banner.position = _board_view.global_position - global_position + Vector2(0, _board_view.size.y * 0.3)
