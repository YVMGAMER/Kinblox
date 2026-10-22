class_name UiFactory
extends RefCounted
## Small builders for the recurring pieces of the menus, so every screen
## uses the same type styles, spacing and touch-target sizes.


static func label(text: String, variation: StringName = &"BodyLabel", align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


static func button(text: String, variation: StringName = &"", icon_name: String = "", on_pressed: Callable = Callable()) -> Button:
	var b := Button.new()
	b.text = text
	if variation != &"":
		b.theme_type_variation = variation
	b.custom_minimum_size = Vector2(0, UiTokens.TOUCH_TARGET)
	if not icon_name.is_empty():
		b.icon = icon(icon_name)
		b.expand_icon = false
	if on_pressed.is_valid():
		b.pressed.connect(func() -> void:
			AudioManager.play(AudioManager.Sfx.UI_TAP)
			Haptics.pulse(Haptics.Kind.UI)
			on_pressed.call())
	return b


static func icon_button(icon_name: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"IconButton"
	b.icon = icon(icon_name)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = true
	b.custom_minimum_size = Vector2(UiTokens.TOUCH_TARGET, UiTokens.TOUCH_TARGET)
	b.pressed.connect(func() -> void:
		AudioManager.play(AudioManager.Sfx.UI_BACK if icon_name == "back" else AudioManager.Sfx.UI_TAP)
		on_pressed.call())
	return b


static func icon(icon_name: String) -> Texture2D:
	return load("res://assets/icons/%s.svg" % icon_name) as Texture2D


static func icon_rect(icon_name: String, px: int = UiTokens.ICON) -> TextureRect:
	var t := TextureRect.new()
	t.texture = icon(icon_name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Back button + screen title.
static func header(title: String, on_back: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiTokens.S2)
	row.add_child(icon_button("back", on_back))
	var t := label(title, &"TitleLabel")
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(t)
	return row


static func card(variation: StringName = &"CardPanel") -> Array:
	var panel := PanelContainer.new()
	panel.theme_type_variation = variation
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", UiTokens.S3)
	panel.add_child(box)
	return [panel, box]


static func spacer(height: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expander() -> Control:
	var c := Control.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A labelled settings row: text on the left, a control on the right.
static func row(title: String, control: Control, subtitle: String = "") -> HBoxContainer:
	var r := HBoxContainer.new()
	r.custom_minimum_size = Vector2(0, UiTokens.TOUCH_TARGET)
	r.add_theme_constant_override(&"separation", UiTokens.S3)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override(&"separation", 0)
	text_box.add_child(label(title, &"HeadingLabel"))
	if not subtitle.is_empty():
		text_box.add_child(label(subtitle, &"MutedLabel", HORIZONTAL_ALIGNMENT_LEFT, true))
	r.add_child(text_box)
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.add_child(control)
	return r


## Caption + big value, used by stats and results.
static func stat(caption: String, value: String, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", UiTokens.S1)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(label(caption, &"CaptionLabel", align))
	box.add_child(label(value, &"ValueLabel", align))
	return box
