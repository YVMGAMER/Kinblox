class_name GameTheme
extends Resource
## Every color the game draws comes from one of these. The UI theme, the
## board and the effects all read the active GameTheme from ThemeManager.

@export var id := "ink"
@export var display_name := "Ink"
@export var is_dark := true

@export_group("Surfaces")
@export var background := Color("0e0f13")
@export var surface := Color("171920")
@export var surface_alt := Color("1f222b")
@export var board_background := Color("121319")
@export var well := Color("191b22")
@export var outline := Color("2a2d37")
@export var scrim := Color(0.03, 0.03, 0.05, 0.72)

@export_group("Text")
@export var text_primary := Color("f2f3f5")
@export var text_secondary := Color("a2a7b4")
@export var text_muted := Color("646a78")

@export_group("Accents")
@export var accent := Color("9d8cff")
@export var accent_text := Color("0e0f13")
@export var positive := Color("5bd68a")
@export var danger := Color("ff5c7a")
## Line-clear flash and chain highlight glow.
@export var flash := Color("ffffff")

@export_group("Pieces")
## One color per logical color slot (see PieceDefs.COLOR_SLOTS).
@export var piece_colors := PackedColorArray([
	Color("4cc9f0"), Color("ffd166"), Color("b388ff"), Color("5bd68a"),
	Color("ff5c7a"), Color("4d7cfe"), Color("ff9f45"), Color("ede6da"),
])
## Glyphs drawn on cells when colorblind patterns are enabled.
@export var pattern_color := Color(0.0, 0.0, 0.0, 0.42)
@export var ghost_alpha := 0.32


func piece_color(slot: int) -> Color:
	if slot < 0 or slot >= piece_colors.size():
		return text_muted
	return piece_colors[slot]
