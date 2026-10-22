class_name ConfirmOverlay
extends Overlay
## Two-button confirmation sheet built in code (used for destructive actions).

signal confirmed

var _title: Label
var _body: Label
var _confirm: Button


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.theme_type_variation = &"SheetPanel"
	panel.custom_minimum_size = Vector2(800, 0)
	center.add_child(panel)
	sheet = panel
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", UiTokens.S3)
	panel.add_child(box)
	_title = UiFactory.label("", &"TitleLabel", HORIZONTAL_ALIGNMENT_CENTER)
	_body = UiFactory.label("", &"BodyLabel", HORIZONTAL_ALIGNMENT_CENTER, true)
	box.add_child(_title)
	box.add_child(_body)
	box.add_child(UiFactory.spacer(UiTokens.S3))
	_confirm = UiFactory.button("", &"DangerButton", "", func() -> void:
		confirmed.emit()
		close())
	box.add_child(_confirm)
	box.add_child(UiFactory.button("Cancel", &"GhostButton", "", close))


func ask(title: String, body: String, confirm_text: String) -> void:
	_title.text = title
	_body.text = body
	_confirm.text = confirm_text
	open()
