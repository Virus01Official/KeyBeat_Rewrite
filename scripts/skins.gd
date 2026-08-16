extends Node

var current_skin: String = "default"
var fallback_skin: String = "default"

var builtin_skins_root: String = "res://skins/"
var external_skins_root: String = "user://mods/skins/"

var skin_roots: Array = [external_skins_root, builtin_skins_root]

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(external_skins_root)

var rating_filenames := {
	"max": "Perfect",
	"great": "Great",
	"good": "Good",
	"ok": "Okay",
	"meh": "Bad",
	"miss": "Miss"
}

func get_available_skins() -> Array:
	var skins: Array = []
	for root in skin_roots:
		var dir = DirAccess.open(root)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir() and not file_name.begins_with("."):
					if not skins.has(file_name):
						skins.append(file_name)
				file_name = dir.get_next()
			dir.list_dir_end()
	return skins

func set_skin(skin_name: String) -> void:
	if skin_name in get_available_skins():
		current_skin = skin_name
	else:
		current_skin = fallback_skin

func _file_exists(path: String) -> bool:
	if path.begins_with("res://"):
		return ResourceLoader.exists(path)
	return FileAccess.file_exists(path)

func _load_texture_from_path(path: String) -> Texture2D:
	if path.begins_with("res://"):
		return load(path)
	var img = Image.load_from_file(path)
	if img != null and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null

func _load_audio_from_path(path: String) -> AudioStream:
	if path.begins_with("res://"):
		return load(path)
	var ext = path.get_extension().to_lower()
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var buffer = file.get_buffer(file.get_length())
	if ext == "ogg":
		return AudioStreamOggVorbis.load_from_buffer(buffer)
	elif ext == "mp3":
		var stream = AudioStreamMP3.new()
		stream.data = buffer
		return stream
	return null

func _candidate_paths(relative_path: String) -> Array:
	var paths: Array = []
	for skin_name in [current_skin, fallback_skin]:
		for root in skin_roots:
			paths.append(root + skin_name + "/" + relative_path)
	return paths

func get_texture(relative_path: String) -> Texture2D:
	for path in _candidate_paths(relative_path):
		if _file_exists(path):
			return _load_texture_from_path(path)
	return null

func get_sound(relative_path: String) -> AudioStream:
	for path in _candidate_paths(relative_path):
		if _file_exists(path):
			return _load_audio_from_path(path)
	return null

func get_note_texture(direction: String = "") -> Texture2D:
	if direction != "":
		var tex = get_texture("note_" + direction + ".png")
		if tex:
			return tex
	return get_texture("note.png")

func get_hold_texture(direction: String = "") -> Texture2D:
	if direction != "":
		var tex = get_texture("hold_" + direction + ".png")
		if tex:
			return tex
	return get_texture("hold.png")

func get_tail_texture(direction: String = "") -> Texture2D:
	if direction != "":
		var tex = get_texture("tail_" + direction + ".png")
		if tex:
			return tex
	return get_texture("tail.png")

func get_empty_texture() -> Texture2D:
	return get_texture("empty.png")

func get_glow_texture() -> Texture2D:
	return get_texture("glow.png")

func get_splash_texture() -> Texture2D:
	return get_texture("Splash.png")

func get_hitsound() -> AudioStream:
	return get_sound("hitsound.ogg")

func get_miss_sound() -> AudioStream:
	return get_sound("miss.ogg")

func get_rating_texture(key: String) -> Texture2D:
	var filename = rating_filenames.get(key, "")
	if filename == "":
		return null
	return get_texture("rating/" + filename + ".png")

func get_grade_texture(grade: String) -> Texture2D:
	return get_texture("grades/" + grade + ".png")
