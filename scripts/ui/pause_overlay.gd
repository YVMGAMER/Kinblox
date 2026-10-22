class_name PauseOverlay
extends Overlay

signal resume_requested
signal restart_requested
signal quit_requested

@onready var _subtitle: Label = %Subtitle
@onready var _resume: Button = %Resume
@onready var _restart: Button = %Restart
@onready var _quit: Button = %Quit
@onready var _note: Label = %Note


func _ready() -> void:
	super._ready()
	_resume.pressed.connect(func() -> void: resume_requested.emit())
	_restart.pressed.connect(func() -> void: restart_requested.emit())
	_quit.pressed.connect(func() -> void: quit_requested.emit())


func configure(mode: ModeConfig) -> void:
	_subtitle.text = mode.display_name().to_upper()
	var scored_daily := mode.id == ModeConfig.Id.DAILY and not mode.is_practice
	_restart.visible = not scored_daily
	_quit.text = "End session" if mode.id == ModeConfig.Id.ZEN else "Quit to menu"
	_note.visible = scored_daily
	_note.text = "Leaving now ends today's scored Daily run."
