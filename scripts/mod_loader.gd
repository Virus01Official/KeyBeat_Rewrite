extends Node

var active_skin: Dictionary = {}

var mod_song_paths: Array = []

const MODS_DIR = "user://mods/"

func _ready() -> void:
	_scan_mods()

func _scan_mods() -> void:
	var dir = DirAccess.open(MODS_DIR)
	if not dir:
		DirAccess.make_dir_absolute(MODS_DIR)  
		return

	dir.list_dir_begin()
	var entry = dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			_load_mod(MODS_DIR + entry + "/")
		entry = dir.get_next()
	dir.list_dir_end()

func _load_mod(mod_path: String) -> void:
	var manifest_path = mod_path + "mod.json"
	if not FileAccess.file_exists(manifest_path):
		print("ModLoader: No mod.json in ", mod_path, " — skipping")
		return

	var file = FileAccess.open(manifest_path, FileAccess.READ)
	var json = JSON.new()
	if json.parse(file.get_as_text()) != OK:
		print("ModLoader: Failed to parse mod.json in ", mod_path)
		return
	file.close()

	var manifest: Dictionary = json.get_data()
	var mod_type: String = manifest.get("type", "")
	var mod_name: String = manifest.get("name", mod_path)

	match mod_type:
		"skin":
			_load_skin(mod_path, manifest)
			print("ModLoader: Loaded skin mod '%s'" % mod_name)
		"songs":
			_load_songs(mod_path, manifest)
			print("ModLoader: Loaded songs mod '%s'" % mod_name)
		_:
			print("ModLoader: Unknown mod type '%s' in %s" % [mod_type, mod_path])

const SKIN_KEYS = [
	"note_left", "note_down", "note_up", "note_right",
	"hold_left", "hold_down", "hold_up", "hold_right",
	"tail_left", "tail_down", "tail_up", "tail_right",
]

func _load_skin(mod_path: String, _manifest: Dictionary) -> void:
	for key in SKIN_KEYS:
		for ext in ["png", "jpg", "jpeg", "webp"]:
			var tex_path = mod_path + "textures/" + key + "." + ext
			if FileAccess.file_exists(tex_path):
				var img = Image.load_from_file(tex_path)
				if img:
					active_skin[key] = ImageTexture.create_from_image(img)
				break  # found this key, move on

func get_note_texture(direction: String) -> Texture2D:
	var key = "note_" + direction
	return active_skin.get(key, null)

func get_hold_texture(direction: String) -> Texture2D:
	var key = "hold_" + direction
	return active_skin.get(key, null)

func get_tail_texture(direction: String) -> Texture2D:
	var key = "tail_" + direction
	return active_skin.get(key, null)

func _load_songs(mod_path: String, _manifest: Dictionary) -> void:
	var songs_dir_path = mod_path + "songs/"
	var songs_dir = DirAccess.open(songs_dir_path)
	if not songs_dir:
		print("ModLoader: songs mod has no 'songs/' subfolder in ", mod_path)
		return

	songs_dir.list_dir_begin()
	var folder = songs_dir.get_next()
	while folder != "":
		if songs_dir.current_is_dir() and not folder.begins_with("."):
			mod_song_paths.append(songs_dir_path + folder + "/")
		folder = songs_dir.get_next()
	songs_dir.list_dir_end()
