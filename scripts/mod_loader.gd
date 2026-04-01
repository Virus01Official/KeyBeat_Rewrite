extends Node

var active_skin: Dictionary = {}

var mod_song_paths: Array = []

const MODS_DIR = "user://mods/"

func _ready() -> void:
	_scan_mods()

func _scan_mods() -> void:
	DirAccess.make_dir_absolute(MODS_DIR)

	_load_all_songs()
	_load_all_skins()

func _load_all_songs() -> void:
	var songs_dir_path = MODS_DIR + "songs/"
	var dir = DirAccess.open(songs_dir_path)

	if not dir:
		print("ModLoader: No songs folder found")
		return

	dir.list_dir_begin()
	var folder = dir.get_next()

	while folder != "":
		if dir.current_is_dir() and not folder.begins_with("."):
			mod_song_paths.append(songs_dir_path + folder + "/")
		folder = dir.get_next()

	dir.list_dir_end()

	print("ModLoader: Loaded ", mod_song_paths.size(), " songs")
	
func _load_all_skins() -> void:
	var skins_path = MODS_DIR + "skins/"

	for key in SKIN_KEYS:
		for ext in ["png", "jpg", "jpeg", "webp"]:
			var tex_path = skins_path + key + "." + ext

			if FileAccess.file_exists(tex_path):
				var img = Image.load_from_file(tex_path)
				if img:
					active_skin[key] = ImageTexture.create_from_image(img)
				break

	print("ModLoader: Loaded skin textures: ", active_skin.size())

const SKIN_KEYS = [
	"note_left", "note_down", "note_up", "note_right",
	"hold_left", "hold_down", "hold_up", "hold_right",
	"tail_left", "tail_down", "tail_up", "tail_right",
]

func get_note_texture(direction: String) -> Texture2D:
	var key = "note_" + direction
	return active_skin.get(key, null)

func get_hold_texture(direction: String) -> Texture2D:
	var key = "hold_" + direction
	return active_skin.get(key, null)

func get_tail_texture(direction: String) -> Texture2D:
	var key = "tail_" + direction
	return active_skin.get(key, null)
