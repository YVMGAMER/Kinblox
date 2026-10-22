class_name MenuScreen
extends Control
## Base for menu screens: safe-area padding, an optional header, and a
## scrollable or fixed column. Subclasses implement _build().

var column: VBoxContainer
var layout: SafeArea


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout = SafeArea.new()
	layout.base_margin = Vector4(UiTokens.S4, UiTokens.S4, UiTokens.S4, UiTokens.S5)
	layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layout)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override(&"separation", UiTokens.S4)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(outer)
	var title := _title()
	if not title.is_empty():
		outer.add_child(UiFactory.header(title, go_back))
	column = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", UiTokens.S4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if _scrolls():
		var scroll := ScrollContainer.new()
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		# Touch scrolling still works; a visible bar only crowds the cards on phones.
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		outer.add_child(scroll)
		scroll.add_child(column)
	else:
		outer.add_child(column)
	_build()


## Header title; empty for screens without a header.
func _title() -> String:
	return ""


func _scrolls() -> bool:
	return true


func _build() -> void:
	pass


func go_back() -> void:
	GameState.goto(GameState.MENU)


## Back button / Escape: handled by going back; return true to consume.
func handle_back() -> bool:
	go_back()
	return true
