extends Control

var maps_location = "res://songs/"
var selected_folder: String = ""
var selected_json: String = ""

func _ready() -> void:
	pick_random_song()

func pick_random_song() -> void:
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

	if all_song_folders.is_empty():
		return

	all_song_folders.shuffle()
	for song_folder_path in all_song_folders:
		var json_files = get_json_files_in_folder(song_folder_path)
		if json_files.is_empty():
			continue

		var song_data = load_song_json(song_folder_path + json_files[0])
		if song_data.is_empty():
			continue

		selected_folder = song_folder_path
		selected_json = json_files[0]

		for ext in ["jpg", "png", "jpeg"]:
			var image_path = song_folder_path + "background." + ext
			if FileAccess.file_exists(image_path):
				$background.texture = load_texture(image_path)
				break

		for ext in ["ogg", "mp3"]:
			var audio_path = song_folder_path + "audio." + ext
			if not FileAccess.file_exists(audio_path):
				continue
			var file = FileAccess.open(audio_path, FileAccess.READ)
			if not file:
				continue
			var buffer = file.get_buffer(file.get_length())
			file.close()

			var audio_stream: AudioStream = null
			if ext == "ogg":
				audio_stream = AudioStreamOggVorbis.load_from_buffer(buffer)
			elif ext == "mp3":
				var stream = AudioStreamMP3.new()
				stream.data = buffer
				audio_stream = stream

			if audio_stream:
				$AudioStreamPlayer.stream = audio_stream
				$AudioStreamPlayer.play()
				break

		break  

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
	if path.begins_with("res://"):
		return load(path) if ResourceLoader.exists(path) else null
	else:
		if FileAccess.file_exists(path):
			var img = Image.load_from_file(path)
			if img and not img.is_empty():
				return ImageTexture.create_from_image(img)
	return null

func _on_play_pressed() -> void:
	$AudioStreamPlayer.stop()
	var play_menu = $"../play_menu"
	play_menu.visible = true
	play_menu.selected_folder = selected_folder
	play_menu.selected_json = selected_json
	# Update the UI labels in play_menu to reflect the pre-selected song
	if play_menu.has_method("apply_preselected_song"):
		play_menu.apply_preselected_song()
	$".".visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	var settings = $"../Settings"
	var screen_width = get_viewport().get_visible_rect().size.x
	var target_x = 0.0
	settings.position.x = -screen_width
	settings.visible = true
	var tween = create_tween()
	tween.tween_property(settings, "position:x", target_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)

func _on_credits_pressed() -> void:
	$credits.visible = true


func _on_chart_editor_pressed() -> void:
	$".".visible = false
	$"../Chart Editor".visible = true
	$AudioStreamPlayer.stop()
