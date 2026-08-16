extends Node

var mod_song_paths: Array = []
const MODS_DIR = "user://mods/"

func _ready() -> void:
	_scan_mods()

func _scan_mods() -> void:
	DirAccess.make_dir_absolute(MODS_DIR)
	_load_all_songs()

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

func get_note_texture(direction: String) -> Texture2D:
	return Skins.get_note_texture(direction)

func get_hold_texture(direction: String) -> Texture2D:
	return Skins.get_hold_texture(direction)

func get_tail_texture(direction: String) -> Texture2D:
	return Skins.get_tail_texture(direction)
