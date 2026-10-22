extends Node
## Player preferences. Values are validated against DEFAULTS, persisted via
## SaveData, and announced through `changed`.

signal changed(key: StringName)

enum ControlScheme { GESTURES, BUTTONS }

const DEFAULTS := {
	&"music_volume": 0.55,
	&"sfx_volume": 0.8,
	&"haptics": true,
	&"haptics_intensity": 0.7,
	&"control_scheme": ControlScheme.GESTURES,
	&"sensitivity": 1.0,
	&"ghost": true,
	&"reduce_motion": false,
	&"patterns": false,
	&"theme": "ink",
	&"chains": true,
	&"tutorial_seen": false,
}
const RANGES := {
	&"music_volume": Vector2(0.0, 1.0),
	&"sfx_volume": Vector2(0.0, 1.0),
	&"haptics_intensity": Vector2(0.1, 1.0),
	&"sensitivity": Vector2(0.5, 2.0),
	&"control_scheme": Vector2(0, 1),
}

var _values: Dictionary = {}


func _ready() -> void:
	_load()
	SaveData.data_reset.connect(_on_data_reset)


func get_value(key: StringName) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_error("Unknown setting %s" % key)
		return
	var clean: Variant = _sanitize(key, value)
	if _values.get(key) == clean:
		return
	_values[key] = clean
	SaveData.settings()[String(key)] = clean
	SaveData.request_save()
	changed.emit(key)


func reset_to_defaults() -> void:
	for key: StringName in DEFAULTS:
		set_value(key, DEFAULTS[key])


#region Typed accessors

func music_volume() -> float:
	return get_value(&"music_volume")


func sfx_volume() -> float:
	return get_value(&"sfx_volume")


func haptics_enabled() -> bool:
	return get_value(&"haptics")


func haptics_intensity() -> float:
	return get_value(&"haptics_intensity")


func control_scheme() -> ControlScheme:
	return get_value(&"control_scheme")


func sensitivity() -> float:
	return get_value(&"sensitivity")


func ghost_enabled() -> bool:
	return get_value(&"ghost")


func reduce_motion() -> bool:
	return get_value(&"reduce_motion")


func patterns_enabled() -> bool:
	return get_value(&"patterns")


func theme_id() -> String:
	return get_value(&"theme")


func chains_enabled() -> bool:
	return get_value(&"chains")

#endregion


func _load() -> void:
	var saved := SaveData.settings()
	for key: StringName in DEFAULTS:
		var raw: Variant = saved.get(String(key), DEFAULTS[key])
		_values[key] = _sanitize(key, raw)


func _sanitize(key: StringName, value: Variant) -> Variant:
	var default: Variant = DEFAULTS[key]
	var out: Variant = default
	if default is bool and value is bool:
		out = value
	elif default is int and (value is int or value is float):
		out = int(value)
	elif default is float and (value is int or value is float):
		out = float(value)
	elif default is String and value is String:
		out = value
	if RANGES.has(key) and (out is int or out is float):
		var r: Vector2 = RANGES[key]
		out = clampi(out, int(r.x), int(r.y)) if out is int else clampf(out, r.x, r.y)
	if key == &"theme" and not ThemeManager.has_theme(out):
		out = default
	return out


func _on_data_reset() -> void:
	_values.clear()
	_load()
	for key: StringName in DEFAULTS:
		changed.emit(key)
