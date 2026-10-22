class_name GameFeedback
extends Node
## Sound and haptics for gameplay events. Pure observer of the session and
## the input router; it never changes game state.

## Chain steps climb the D-major pentatonic scale (in semitones).
const CHAIN_SCALE := [0, 2, 4, 7, 9, 12, 14, 16]
const SOFT_TICK_INTERVAL := 0.05

var _session: GameSession
var _hard_dropped_this_frame := false
var _soft_tick_cooldown := 0.0


func bind(session: GameSession, router: InputRouter) -> void:
	_session = session
	router.player_moved.connect(func(_dx: int) -> void:
		AudioManager.play(AudioManager.Sfx.MOVE)
		Haptics.pulse(Haptics.Kind.MOVE))
	router.player_soft_dropped.connect(_on_soft_dropped)
	session.piece_rotated.connect(func(_p: Piece, kicked: bool) -> void:
		AudioManager.play(AudioManager.Sfx.ROTATE, 0.94 if kicked else 1.0)
		Haptics.pulse(Haptics.Kind.ROTATE))
	session.hard_dropped.connect(func(_p: Piece, rows: int) -> void:
		_hard_dropped_this_frame = true
		AudioManager.play(AudioManager.Sfx.HARD_DROP, 1.0, -3.0 + minf(rows, 12) * 0.25)
		Haptics.pulse(Haptics.Kind.HARD_DROP))
	session.piece_locked.connect(func(_c: Array[Vector2i], _t: int) -> void:
		if not _hard_dropped_this_frame:
			AudioManager.play(AudioManager.Sfx.LOCK)
			Haptics.pulse(Haptics.Kind.LOCK)
		_hard_dropped_this_frame = false)
	session.hold_changed.connect(func(_t: int) -> void:
		AudioManager.play(AudioManager.Sfx.HOLD)
		Haptics.pulse(Haptics.Kind.HOLD))
	session.lines_cleared.connect(func(rows: Array[int], award: Scoring.Award) -> void:
		var big := rows.size() >= 4
		AudioManager.play(AudioManager.Sfx.CLEAR_QUAD if big else AudioManager.Sfx.CLEAR, 1.0 + 0.04 * (rows.size() - 1) + 0.02 * mini(award.combo, 8))
		Haptics.line_clear(rows.size()))
	session.chain_highlight.connect(func(_g: Array[PackedInt32Array], step: int, _m: int) -> void:
		AudioManager.play_semitones(AudioManager.Sfx.CHAIN, CHAIN_SCALE[mini(step - 1, CHAIN_SCALE.size() - 1)])
		Haptics.pulse(Haptics.Kind.CHAIN, 1.0 + 0.15 * (step - 1)))
	if session.mode.fixed_gravity_interval <= 0.0:
		session.level_changed.connect(func(_l: int) -> void:
			AudioManager.play(AudioManager.Sfx.LEVEL_UP)
			Haptics.pulse(Haptics.Kind.LEVEL_UP))
	session.zen_sweep_started.connect(func(_r: int) -> void: AudioManager.play(AudioManager.Sfx.ZEN_SWEEP))
	session.game_over.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.GAME_OVER)
		Haptics.pulse(Haptics.Kind.GAME_OVER))


func _process(delta: float) -> void:
	_soft_tick_cooldown -= delta


func _on_soft_dropped(_rows: int) -> void:
	if _soft_tick_cooldown > 0.0:
		return
	_soft_tick_cooldown = SOFT_TICK_INTERVAL
	AudioManager.play(AudioManager.Sfx.SOFT_DROP)
