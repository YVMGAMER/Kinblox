class_name ShareService
extends RefCounted
## Shares text through a native share-sheet plugin when one is installed,
## otherwise copies it to the clipboard. Godot has no built-in share sheet;
## see README "Native share sheet" for the supported plugin hook.

enum Result { SHARED, COPIED }

## Singleton names and methods used by common Godot share plugins.
const PLUGINS := [
	["GodotShare", "shareText"],
	["Share", "shareText"],
	["NativeShare", "share_text"],
]


static func share(text: String) -> Result:
	for p: Array in PLUGINS:
		var name: String = p[0]
		var method: String = p[1]
		if Engine.has_singleton(name):
			var plugin := Engine.get_singleton(name)
			if plugin.has_method(method):
				if method == "shareText":
					plugin.call(method, "Kinblox", "Kinblox", text)
				else:
					plugin.call(method, text)
				return Result.SHARED
	DisplayServer.clipboard_set(text)
	return Result.COPIED
