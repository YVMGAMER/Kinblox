extends Node
## Persistent progress (user://kinblox_save.json). Writes are debounced so
## sliders and rapid events do not hammer the disk.

signal data_reset

const SAVE_PATH := "user://kinblox_save.json"
const SAVE_DEBOUNCE := 0.6

var store := SaveStore.new(SAVE_PATH)
var _dirty := false
var _timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not store.load_from_disk():
		push_warning("Save file was corrupt; started from defaults.")


func _process(delta: float) -> void:
	if not _dirty:
		return
	_timer -= delta
	if _timer <= 0.0:
		flush()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush()


func request_save() -> void:
	_dirty = true
	_timer = SAVE_DEBOUNCE


func flush() -> void:
	_dirty = false
	store.save_to_disk()


func settings() -> Dictionary:
	return store.data["settings"]


func reset_all() -> void:
	store.reset()
	flush()
	data_reset.emit()
