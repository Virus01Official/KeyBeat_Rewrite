extends Control
var maps_location = "res://songs/"
var categoryScene = preload("res://category.tscn")

var selected_json: String = ""  # ADD THIS

func _ready() -> void:
	load_songs()
	await get_tree().process_frame
	$ScrollContainer.queue_redraw()
	$ScrollContainer/VBoxContainer.reset_size()

func load_songs() -> void:
	var category_container = $ScrollContainer/VBoxContainer
	var dir = DirAccess.open(maps_location)
	if not dir:
		print("Could not open maps directory: ", maps_location)
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	$Select.pressed.connect(select_song)
	
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var song_folder_path = maps_location + folder_name + "/"
			var json_files = get_json_files_in_folder(song_folder_path)
			
			if json_files.size() > 0:
				var newCategory = categoryScene.instantiate()
				category_container.add_child(newCategory)
				
				var first_song_data = load_song_json(song_folder_path + json_files[0])
				if first_song_data:
					newCategory.get_node('Category').get_node('CategoryName').text = first_song_data.get("title", "Unknown")
				
				for ext in ["jpg", "png", "jpeg"]:
					var image_path = song_folder_path + "background." + ext
					var texture_rect = newCategory.get_node("Category/ScrollContainer/VBoxContainer/SongDifficulty/TextureRect")
					if FileAccess.file_exists(image_path):
						texture_rect.texture = load(image_path)
						break
				
				var difficulty_container = newCategory.get_node("Category/ScrollContainer/VBoxContainer")
				
				for i in range(json_files.size()):
					var json_file = json_files[i]
					var song_data = load_song_json(song_folder_path + json_file)
					if not song_data:
						continue
					
					var difficulty_label = song_data.get("difficulty", json_file.get_basename())
					
					if i == 0:
						var button = newCategory.get_node('Category/ScrollContainer/VBoxContainer/SongDifficulty/Button')
						button.text = difficulty_label
						button.pressed.connect(choose.bind(
							song_data.get("title", "Unknown"),
							difficulty_label,
							song_data.get("credits", "No one"),
							song_data.get("mapper", "No one"),
							song_folder_path,
							json_file 
						))
					else:
						var original_diff_node = newCategory.get_node("Category/ScrollContainer/VBoxContainer/SongDifficulty")
						var new_diff_node = original_diff_node.duplicate()
						difficulty_container.add_child(new_diff_node)
						
						var button = new_diff_node.get_node("Button")
						button.text = difficulty_label
						for connection in button.pressed.get_connections():
							button.pressed.disconnect(connection["callable"])
						button.pressed.connect(choose.bind(
							song_data.get("title", "Unknown"),
							difficulty_label,
							song_data.get("credits", "No one"),
							song_data.get("mapper", "No one"),
							song_folder_path,
							json_file  # PASS THE FILENAME
						))
		
		folder_name = dir.get_next()
	dir.list_dir_end()

func get_json_files_in_folder(folder_path: String) -> Array:
	var json_files = []
	var dir = DirAccess.open(folder_path)
	if not dir:
		return json_files
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			json_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	json_files.sort()
	return json_files

func load_song_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return {}
	return json.get_data()

func choose(song, difficulty, credits, mapper, song_folder_path, json_file):
	$Selected.text = song
	$Difficulty.text = "Difficulty: " + difficulty
	$Credits.text = "Credits: " + credits
	$Mapper.text = "Mapped by: " + mapper
	selected_json = json_file 
	
	for ext in ["jpg", "png", "jpeg"]:
		var image_path = song_folder_path + "background." + ext
		if FileAccess.file_exists(image_path):
			$Thumbnail.texture = load(image_path)
			break

func select_song():
	var song = $Selected.text
	$".".visible = false
	$"..".get_node("game").visible = true
	$"..".get_node("game")._start(song, selected_json)  
