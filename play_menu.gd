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
	
	$Select.pressed.connect(select_song)
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var song_path = maps_location + folder_name + "/song.json"
			var song_data = load_song_json(song_path)
			var newCategory = categoryScene.instantiate()
			category_container.add_child(newCategory)
			if song_data:
				newCategory.get_node('Category').get_node('CategoryName').text = song_data.get("title", "Unknown")
				var button = newCategory.get_node('Category/ScrollContainer/VBoxContainer/SongDifficulty/Button')
				button.text = song_data.get("difficulty", "Unknown")
				button.pressed.connect(choose.bind(
					song_data.get("title", "Unknown"),
					button.text,
					song_data.get("credits", "No one"),
					song_data.get("mapper", "No one")
				))
				# image loading here too
			
			for ext in ["jpg", "png", "jpeg"]:
				var image_path = maps_location + folder_name + "/background." + ext
				var texture_rect = newCategory.get_node("Category/ScrollContainer/VBoxContainer/SongDifficulty/TextureRect")
				if FileAccess.file_exists(image_path):
					var tex = load(image_path)
					texture_rect.texture = tex
					break  
			
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
	
func choose(song, Difficulty, credits, mapper):
	$Selected.text = song
	$Difficulty.text = Difficulty
	$Credits.text = credits
	$Mapper.text = mapper
	
func select_song():
	var song = $Selected.text
	$"..".get_node("game").visible = true
	$"..".get_node("game")._start(song)
