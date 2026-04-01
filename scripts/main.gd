extends Node

const MODS_FOLDER = "user://mods/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(MODS_FOLDER)

func _can_drop_data(_pos: Vector2, data) -> bool:
	if data is Dictionary and data.has("files"):
		for file in data["files"]:
			if file.ends_with(".kbmap"):
				return true
	return false

func _drop_data(_pos: Vector2, data) -> void:
	if not (data is Dictionary and data.has("files")):
		return

	for file_path in data["files"]:
		if file_path.ends_with(".kbmap"):
			_install_kbmap(file_path)

func _install_kbmap(file_path: String) -> void:
	var zip = ZIPReader.new()
	var err = zip.open(file_path)
	if err != OK:
		push_error("Failed to open .kbmap file: " + file_path)
		return

	var mod_name = file_path.get_file().get_basename()
	var out_dir = MODS_FOLDER + mod_name + "/"
	DirAccess.make_dir_recursive_absolute(out_dir)

	for entry in zip.get_files():
		var content = zip.read_file(entry)

		if entry.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(out_dir + entry)
			continue

		var entry_dir = (out_dir + entry).get_base_dir()
		DirAccess.make_dir_recursive_absolute(entry_dir)

		# Write the file
		var out = FileAccess.open(out_dir + entry, FileAccess.WRITE)
		if out:
			out.store_buffer(content)
			out.close()
		else:
			push_error("Failed to write: " + out_dir + entry)

	zip.close()
	print("Installed mod: ", mod_name, " → ", out_dir)

	_reload_after_install()

func _reload_after_install() -> void:
	var container = $ScrollContainer/VBoxContainer
	for child in container.get_children():
		child.queue_free()
	$play_menu.load_songs()
