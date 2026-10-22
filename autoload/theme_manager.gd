extends Node
## Owns the active GameTheme and builds the Godot UI Theme from it, so no
## control anywhere needs a hardcoded color. Custom-drawn views read
## `current` and redraw on `theme_changed`.

signal theme_changed(game_theme: GameTheme, animate: bool)

const THEMES := {
	"ink": "res://themes/ink.tres",
	"paper": "res://themes/paper.tres",
	"glacier": "res://themes/glacier.tres",
	"ember": "res://themes/ember.tres",
}
const ORDER: Array[String] = ["ink", "paper", "glacier", "ember"]
const FONT_PATH := "res://assets/fonts/Manrope-Variable.ttf"

var current: GameTheme
var ui_theme: Theme

var font_regular: FontVariation
var font_medium: FontVariation
var font_semibold: FontVariation
var font_bold: FontVariation
var font_heavy: FontVariation
var font_caps: FontVariation


func _ready() -> void:
	_build_fonts()
	_apply(Settings.theme_id(), false)
	Settings.changed.connect(_on_setting_changed)


static func has_theme(id: Variant) -> bool:
	return id is String and THEMES.has(id)


func theme_for(id: String) -> GameTheme:
	return load(THEMES.get(id, THEMES["ink"])) as GameTheme


func _on_setting_changed(key: StringName) -> void:
	if key == &"theme" and Settings.theme_id() != current.id:
		_apply(Settings.theme_id(), true)


func _apply(id: String, animate: bool) -> void:
	current = theme_for(id)
	ui_theme = _build_ui_theme(current)
	RenderingServer.set_default_clear_color(current.background)
	theme_changed.emit(current, animate)


func _build_fonts() -> void:
	var base := load(FONT_PATH) as FontFile
	font_regular = _weight(base, 400)
	font_medium = _weight(base, 500)
	font_semibold = _weight(base, 600)
	font_bold = _weight(base, 700)
	font_heavy = _weight(base, 800)
	font_caps = _weight(base, 700)
	font_caps.spacing_glyph = 3


func _weight(base: FontFile, weight: int) -> FontVariation:
	var f := FontVariation.new()
	f.base_font = base
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return f


#region UI theme

func _build_ui_theme(gt: GameTheme) -> Theme:
	var t := Theme.new()
	t.default_font = font_medium
	t.default_font_size = UiTokens.FONT_BODY

	t.set_color(&"font_color", &"Label", gt.text_primary)
	_label(t, &"DisplayLabel", font_heavy, UiTokens.FONT_DISPLAY, gt.text_primary)
	_label(t, &"TitleLabel", font_bold, UiTokens.FONT_TITLE, gt.text_primary)
	_label(t, &"HeadingLabel", font_semibold, UiTokens.FONT_HEADING, gt.text_primary)
	_label(t, &"BodyLabel", font_medium, UiTokens.FONT_BODY, gt.text_secondary)
	_label(t, &"SmallLabel", font_medium, UiTokens.FONT_SMALL, gt.text_secondary)
	_label(t, &"MutedLabel", font_medium, UiTokens.FONT_SMALL, gt.text_muted)
	_label(t, &"CaptionLabel", font_caps, UiTokens.FONT_CAPTION, gt.text_muted)
	_label(t, &"ValueLabel", font_heavy, UiTokens.FONT_VALUE, gt.text_primary)
	_label(t, &"ScoreLabel", font_heavy, UiTokens.FONT_SCORE, gt.text_primary)
	_label(t, &"AccentLabel", font_bold, UiTokens.FONT_BODY, gt.accent)
	_label(t, &"BannerLabel", font_heavy, UiTokens.FONT_TITLE, gt.text_primary)

	# Buttons: default (secondary), primary, ghost, icon, chip.
	_button(t, &"Button", gt.surface_alt, gt.text_primary, font_semibold, gt)
	_button(t, &"PrimaryButton", gt.accent, gt.accent_text, font_bold, gt)
	_button(t, &"GhostButton", Color(gt.surface_alt, 0.0), gt.text_secondary, font_semibold, gt)
	_button(t, &"IconButton", Color(gt.surface_alt, 0.0), gt.text_primary, font_semibold, gt)
	_button(t, &"ChipButton", gt.surface_alt, gt.text_secondary, font_semibold, gt)
	_button(t, &"DangerButton", gt.danger, gt.accent_text, font_bold, gt)
	for v: StringName in [&"PrimaryButton", &"GhostButton", &"IconButton", &"ChipButton", &"DangerButton"]:
		t.set_type_variation(v, &"Button")
	var chip_on := _box(gt.accent, UiTokens.RADIUS_MD, UiTokens.S4, UiTokens.S3)
	t.set_stylebox(&"pressed", &"ChipButton", chip_on)
	t.set_stylebox(&"hover_pressed", &"ChipButton", chip_on)
	t.set_color(&"font_pressed_color", &"ChipButton", gt.accent_text)
	t.set_color(&"font_hover_pressed_color", &"ChipButton", gt.accent_text)
	t.set_font_size(&"font_size", &"ChipButton", UiTokens.FONT_SMALL)
	var icon_box := _box(Color(gt.surface_alt, 0.0), UiTokens.RADIUS_PILL, UiTokens.S3, UiTokens.S3)
	t.set_stylebox(&"normal", &"IconButton", icon_box)
	t.set_stylebox(&"hover", &"IconButton", icon_box)
	t.set_stylebox(&"pressed", &"IconButton", _box(gt.surface_alt, UiTokens.RADIUS_PILL, UiTokens.S3, UiTokens.S3))
	t.set_stylebox(&"normal", &"GhostButton", _box(Color(gt.surface_alt, 0.0), UiTokens.RADIUS_MD, UiTokens.S4, UiTokens.S3))
	t.set_stylebox(&"hover", &"GhostButton", _box(Color(gt.surface_alt, 0.0), UiTokens.RADIUS_MD, UiTokens.S4, UiTokens.S3))

	# Panels.
	t.set_stylebox(&"panel", &"PanelContainer", _box(gt.surface, UiTokens.RADIUS_LG, UiTokens.S5, UiTokens.S5))
	t.set_type_variation(&"CardPanel", &"PanelContainer")
	t.set_stylebox(&"panel", &"CardPanel", _box(gt.surface, UiTokens.RADIUS_LG, UiTokens.S5, UiTokens.S5))
	t.set_type_variation(&"InsetPanel", &"PanelContainer")
	t.set_stylebox(&"panel", &"InsetPanel", _box(gt.surface_alt, UiTokens.RADIUS_MD, UiTokens.S4, UiTokens.S3))
	t.set_type_variation(&"SheetPanel", &"PanelContainer")
	var sheet := _box(gt.surface, UiTokens.RADIUS_XL, UiTokens.S5, UiTokens.S5)
	sheet.shadow_color = Color(0, 0, 0, 0.25 if gt.is_dark else 0.12)
	sheet.shadow_size = UiTokens.S4
	sheet.shadow_offset = Vector2(0, UiTokens.S2)
	t.set_stylebox(&"panel", &"SheetPanel", sheet)
	t.set_type_variation(&"ClearPanel", &"PanelContainer")
	t.set_stylebox(&"panel", &"ClearPanel", StyleBoxEmpty.new())

	# Slider.
	var track := _box(gt.surface_alt, UiTokens.RADIUS_PILL, 0, 0)
	track.content_margin_top = UiTokens.S2 * 1.5
	track.content_margin_bottom = UiTokens.S2 * 1.5
	t.set_stylebox(&"slider", &"HSlider", track)
	var fill := _box(gt.accent, UiTokens.RADIUS_PILL, 0, 0)
	t.set_stylebox(&"grabber_area", &"HSlider", fill)
	t.set_stylebox(&"grabber_area_highlight", &"HSlider", fill)
	var knob := _circle_texture(22, gt.text_primary)
	t.set_icon(&"grabber", &"HSlider", knob)
	t.set_icon(&"grabber_highlight", &"HSlider", knob)
	t.set_icon(&"grabber_disabled", &"HSlider", knob)

	# Scrolling.
	t.set_stylebox(&"panel", &"ScrollContainer", StyleBoxEmpty.new())
	var bar := StyleBoxEmpty.new()
	bar.content_margin_left = 6
	bar.content_margin_right = 6
	t.set_stylebox(&"scroll", &"VScrollBar", bar)
	var grab := _box(gt.outline, UiTokens.RADIUS_PILL, 0, 0)
	t.set_stylebox(&"grabber", &"VScrollBar", grab)
	t.set_stylebox(&"grabber_highlight", &"VScrollBar", grab)
	t.set_stylebox(&"grabber_pressed", &"VScrollBar", grab)

	# Containers use the spacing scale.
	t.set_constant(&"separation", &"VBoxContainer", UiTokens.S3)
	t.set_constant(&"separation", &"HBoxContainer", UiTokens.S3)
	return t


func _label(t: Theme, variation: StringName, font: Font, size: int, color: Color) -> void:
	t.set_type_variation(variation, &"Label")
	t.set_font(&"font", variation, font)
	t.set_font_size(&"font_size", variation, size)
	t.set_color(&"font_color", variation, color)


func _button(t: Theme, type: StringName, bg: Color, fg: Color, font: Font, gt: GameTheme) -> void:
	var normal := _box(bg, UiTokens.RADIUS_MD, UiTokens.S5, UiTokens.S4)
	var hover := _box(bg.lightened(0.04) if gt.is_dark else bg.darkened(0.03), UiTokens.RADIUS_MD, UiTokens.S5, UiTokens.S4)
	var pressed_bg := bg.darkened(0.12) if bg.a > 0.0 else Color(gt.surface_alt, 1.0)
	var pressed := _box(pressed_bg, UiTokens.RADIUS_MD, UiTokens.S5, UiTokens.S4)
	var disabled := _box(Color(bg, bg.a * 0.45), UiTokens.RADIUS_MD, UiTokens.S5, UiTokens.S4)
	t.set_stylebox(&"normal", type, normal)
	t.set_stylebox(&"hover", type, hover)
	t.set_stylebox(&"pressed", type, pressed)
	t.set_stylebox(&"hover_pressed", type, pressed)
	t.set_stylebox(&"disabled", type, disabled)
	t.set_stylebox(&"focus", type, StyleBoxEmpty.new())
	t.set_font(&"font", type, font)
	t.set_font_size(&"font_size", type, UiTokens.FONT_BUTTON)
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		t.set_color(state, type, fg)
	t.set_color(&"font_disabled_color", type, Color(fg, 0.4))
	for state: StringName in [&"icon_normal_color", &"icon_hover_color", &"icon_pressed_color", &"icon_hover_pressed_color", &"icon_focus_color"]:
		t.set_color(state, type, fg)
	t.set_color(&"icon_disabled_color", type, Color(fg, 0.4))
	t.set_constant(&"h_separation", type, UiTokens.S3)
	t.set_constant(&"icon_max_width", type, UiTokens.ICON)


func _box(color: Color, radius: int, pad_x: float, pad_y: float) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 10
	sb.anti_aliasing = true
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb


func _circle_texture(radius: int, color: Color) -> ImageTexture:
	var d := radius * 2
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var c := Vector2(radius, radius)
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5, y + 0.5).distance_to(c)
			img.set_pixel(x, y, Color(color, clampf(radius - dist, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)

#endregion
