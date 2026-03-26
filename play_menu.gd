extends Control

var maps_location = "res://songs/"
var categoryScene = preload("res://category.tscn")

func _ready() -> void:
	load_songs()

func load_songs() -> void:
	# Get the VBoxContainer inside the ScrollContainer (for categories)
	var category_container = $ScrollContainer/VBoxContainer
	
	# Scan the songs directory for song folders
	var dir = DirAccess.open(maps_location)
	if not dir:
		print("Could not open maps directory: ", maps_location)
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var song_path = maps_location + folder_name + "/song.json"
			var song_data = load_song_json(song_path)
		folder_name = dir.get_next()
	
	dir.list_dir_end()

func load_song_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Could not open file: ", path)
		return {}
	
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	
	if err != OK:
		print("JSON parse error in: ", path)
		return {}
	
	return json.get_data()
