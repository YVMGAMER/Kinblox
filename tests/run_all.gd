extends SceneTree
## Headless test runner:
##   godot --headless --path . -s tests/run_all.gd
## Exits with code 0 when every test passes, 1 otherwise.

const SUITES: Array[String] = [
	"res://tests/test_board.gd",
	"res://tests/test_pieces.gd",
	"res://tests/test_bag.gd",
	"res://tests/test_scoring.gd",
	"res://tests/test_lock_delay.gd",
	"res://tests/test_chain.gd",
	"res://tests/test_session.gd",
	"res://tests/test_daily.gd",
	"res://tests/test_save.gd",
]


func _initialize() -> void:
	var total := 0
	var failed := 0
	for path in SUITES:
		if not ResourceLoader.exists(path):
			continue
		var script := load(path) as GDScript
		var suite := script.new() as KinTest
		print("\n[%s]" % path.get_file().get_basename())
		for method in suite.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			total += 1
			suite.begin()
			suite.call(name)
			var errors := suite.failures()
			if errors.is_empty():
				print("  ok    ", name)
			else:
				failed += 1
				print("  FAIL  ", name)
				for e in errors:
					print("        - ", e)
	print("\n%d tests, %d passed, %d failed" % [total, total - failed, failed])
	quit(1 if failed > 0 else 0)
