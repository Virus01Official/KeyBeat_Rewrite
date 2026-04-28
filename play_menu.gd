extends Control
var maps_location = "res://songs/"
var categoryScene = preload("res://category.tscn")

var selected_folder: String = ""
var selected_json: String = ""  # ADD THIS

@onready var search_bar = $Panel/SearchBar

func _ready() -> void:
	load_songs()
	await get_tree().process_frame
	$ScrollContainer.queue_redraw()
	$ScrollContainer/VBoxContainer.reset_size()

func load_songs() -> void:
	var category_container = $ScrollContainer/VBoxContainer
	$Select.pressed.connect(select_song)

	var all_song_folders: Array = []

	var builtin_dir = DirAccess.open(maps_location)
	if builtin_dir:
		builtin_dir.list_dir_begin()
		var folder_name = builtin_dir.get_next()
		while folder_name != "":
			if builtin_dir.current_is_dir() and not folder_name.begins_with("."):
				all_song_folders.append(maps_location + folder_name + "/")
			folder_name = builtin_dir.get_next()
		builtin_dir.list_dir_end()

	for mod_path in ModLoader.mod_song_paths:
		all_song_folders.append(mod_path)

	for song_folder_path in all_song_folders:
		var json_files = get_json_files_in_folder(song_folder_path)
		if json_files.size() == 0:
			continue

		var newCategory = categoryScene.instantiate()
		category_container.add_child(newCategory)

		var first_song_data = load_song_json(song_folder_path + json_files[0])
		if first_song_data:
			newCategory.get_node('Category').get_node('CategoryName').text = first_song_data.get("title", "Unknown")

		for ext in ["jpg", "png", "jpeg"]:
			var image_path = song_folder_path + "background." + ext
			var texture_rect = newCategory.get_node("Category/ScrollContainer/VBoxContainer/SongDifficulty/TextureRect")
			if FileAccess.file_exists(image_path):
				texture_rect.texture = load_texture(image_path)
				break

		var difficulty_container = newCategory.get_node("Category/ScrollContainer/VBoxContainer")

		for i in range(json_files.size()):
			var json_file = json_files[i]
			var song_data = load_song_json(song_folder_path + json_file)
			if not song_data:
				continue

			var star_rating = $"../game".calculate_difficulty(song_data)
			var difficulty_label := "★ %.1f  %s" % [star_rating, song_data.get("difficulty", json_file.get_basename())]

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
					json_file
				))

	await get_tree().process_frame
	for category in category_container.get_children():
		var inner_vbox = category.get_node("Category/ScrollContainer/VBoxContainer")
		var item_count = inner_vbox.get_child_count()
		category.custom_minimum_size.y = item_count * 100

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
	
func load_texture(path: String) -> Texture2D:
	var img: Image
	if path.begins_with("res://"):
		if ResourceLoader.exists(path):
			return load(path)
		var file = FileAccess.open(path, FileAccess.READ)
		if not file:
			return null
		var buffer = file.get_buffer(file.get_length())
		file.close()
		img = Image.new()
		var ext = path.get_extension().to_lower()
		var err = ERR_UNAVAILABLE
		if ext == "png":
			err = img.load_png_from_buffer(buffer)
		elif ext in ["jpg", "jpeg"]:
			err = img.load_jpg_from_buffer(buffer)
		if err != OK or img.is_empty():
			return null
	else:
		if not FileAccess.file_exists(path):
			return null
		img = Image.load_from_file(path)
		if not img or img.is_empty():
			return null
	return ImageTexture.create_from_image(img)

func choose(song, difficulty, credits, mapper, song_folder_path, json_file):
	$Selected.text = song
	$Difficulty.text = "Difficulty: " + difficulty
	$Credits.text = "Credits: " + credits
	$Mapper.text = "Mapped by: " + mapper
	selected_json = json_file
	selected_folder = song_folder_path

	for ext in ["jpg", "png", "jpeg"]:
		var image_path = song_folder_path + "background." + ext
		if FileAccess.file_exists(image_path):
			$Thumbnail.texture = load_texture(image_path)
			break

	var audio_stream: AudioStream = null
	for ext in ["ogg", "mp3"]:
		var audio_path = song_folder_path + "audio." + ext
		if not FileAccess.file_exists(audio_path):
			continue

		var file = FileAccess.open(audio_path, FileAccess.READ)
		if not file:
			continue
		var buffer = file.get_buffer(file.get_length())
		file.close()

		if ext == "ogg":
			audio_stream = AudioStreamOggVorbis.load_from_buffer(buffer)
		elif ext == "mp3":
			var stream = AudioStreamMP3.new()
			stream.data = buffer
			audio_stream = stream

		if audio_stream:
			break

	if audio_stream:
		$AudioStreamPlayer.stream = audio_stream
		$AudioStreamPlayer.stop()
		$AudioStreamPlayer.play()

func select_song():
	$AudioStreamPlayer.stop()
	$".".visible = false
	$"..".get_node("game").visible = true
	$"..".get_node("game")._start_from_path(selected_folder, selected_json) 

func apply_preselected_song() -> void:
	if selected_folder == "" or selected_json == "":
		return
	var song_data = load_song_json(selected_folder + selected_json)
	if song_data.is_empty():
		return
	var star_rating = $"../game".calculate_difficulty(song_data)
	var difficulty_label := "★ %.1f  %s" % [star_rating, song_data.get("difficulty", selected_json.get_basename())]
	choose(
		song_data.get("title", "Unknown"),
		difficulty_label,
		song_data.get("credits", "No one"),
		song_data.get("mapper", "No one"),
		selected_folder,
		selected_json
	)

func _on_search_bar_text_changed() -> void:
	var query = search_bar.text.strip_edges().to_lower()
	var category_container = $ScrollContainer/VBoxContainer
	
	for category in category_container.get_children():
		var title_node = category.get_node("Category/CategoryName")
		var title = title_node.text.to_lower()
		
		if query == "" or title.contains(query):
			category.visible = true
		else:
			category.visible = false
			
	category_container.recalculate() 
	$ScrollContainer.scroll_to_top()

func _on_button_pressed() -> void:
	var settings = $"../Settings"
	var screen_width = get_viewport().get_visible_rect().size.x
	var target_x = 0.0 

	settings.position.x = -screen_width
	settings.visible = true

	var tween = create_tween()
	tween.tween_property(settings, "position:x", target_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func _on_back_pressed() -> void:
	$".".visible = false
	$"../main_menu".visible = true

func _on_modifiers_button_pressed() -> void:
	$modifiersPanel.visible = not $modifiersPanel.visible
