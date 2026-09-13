extends Node

const MODS_FOLDER = "user://mods/songs/"

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(MODS_FOLDER)
	get_viewport().files_dropped.connect(_on_files_dropped)

func _on_files_dropped(files: PackedStringArray) -> void:
	for file_path in files:
		if file_path.ends_with(".kbmap"):
			_install_kbmap(file_path)
			return
		elif file_path.ends_with(".osz"):
			_install_osz(file_path)
			return
		elif file_path.ends_with(".qp"):
			_install_qp(file_path)
			return

func _install_kbmap(file_path: String) -> void:
	var zip = ZIPReader.new()
	var err = zip.open(file_path)
	if err != OK:
		push_error("Failed to open .kbmap file: " + file_path)
		return

	var mod_name = file_path.get_file().get_basename()
	var out_dir  = MODS_FOLDER + mod_name + "/"
	DirAccess.make_dir_recursive_absolute(out_dir)

	for entry in zip.get_files():
		var content = zip.read_file(entry)
		if entry.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(out_dir + entry)
			continue
		DirAccess.make_dir_recursive_absolute((out_dir + entry).get_base_dir())
		var out = FileAccess.open(out_dir + entry, FileAccess.WRITE)
		if out:
			out.store_buffer(content)
			out.close()
		else:
			push_error("Failed to write: " + out_dir + entry)
			zip.close()
			return

	zip.close()
	print("Installed .kbmap: ", mod_name, " → ", out_dir)
	_reload_after_install()

func _install_osz(file_path: String) -> void:
	var zip = ZIPReader.new()
	if zip.open(file_path) != OK:
		push_error("Failed to open .osz file: " + file_path)
		return

	var all_entries: PackedStringArray = zip.get_files()

	var osu_files:   Array[String] = []
	var audio_entry: String        = ""
	var bg_entry:    String        = ""

	$Importing.visible = true

	for entry in all_entries:
		var low = entry.to_lower()
		if low.ends_with(".osu"):
			osu_files.append(entry)
		elif audio_entry == "" and (low.ends_with(".mp3") or low.ends_with(".ogg")):
			audio_entry = entry
		elif bg_entry == "" and (low.ends_with(".jpg") or low.ends_with(".jpeg") or low.ends_with(".png")):
			bg_entry = entry

	if osu_files.is_empty():
		push_error("No .osu files found inside: " + file_path)
		zip.close()
		return

	var song_folder_name: String = _sanitise_filename(file_path.get_file().get_basename())
	var out_dir: String          = MODS_FOLDER + song_folder_name + "/"
	DirAccess.make_dir_recursive_absolute(out_dir)

	if audio_entry != "":
		var audio_ext  = audio_entry.get_extension().to_lower()
		var audio_data = zip.read_file(audio_entry)
		var audio_out  = FileAccess.open(out_dir + "audio." + audio_ext, FileAccess.WRITE)
		if audio_out:
			audio_out.store_buffer(audio_data)
			audio_out.close()

	if bg_entry != "":
		var bg_ext  = bg_entry.get_extension().to_lower()
		var bg_data = zip.read_file(bg_entry)
		var bg_out  = FileAccess.open(out_dir + "background." + bg_ext, FileAccess.WRITE)
		if bg_out:
			bg_out.store_buffer(bg_data)
			bg_out.close()

	var converted_count := 0
	for osu_entry in osu_files:
		var raw_bytes = zip.read_file(osu_entry)
		var source    = raw_bytes.get_string_from_utf8()

		var chart = _parse_osu_chart(source)
		if chart.is_empty():
			push_error("Failed to parse: " + osu_entry)
			continue

		var diff_name: String = chart.get("difficulty", osu_entry.get_basename())
		diff_name = _sanitise_filename(diff_name)
		if diff_name == "":
			diff_name = "difficulty_%d" % converted_count

		var json_str  = JSON.stringify(chart, "\t")
		var json_path = out_dir + diff_name + ".json"
		var json_out  = FileAccess.open(json_path, FileAccess.WRITE)
		if json_out:
			json_out.store_string(json_str)
			json_out.close()
			converted_count += 1
		else:
			push_error("Could not write: " + json_path)

	zip.close()

	if converted_count == 0:
		push_error("No difficulties were converted from: " + file_path)
		return

	print("Installed .osz '%s' (%d difficulties) → %s" % [song_folder_name, converted_count, out_dir])
	$Importing.visible = false
	$AudioStreamPlayer.play()
	DirAccess.remove_absolute(file_path)

	_reload_after_install()

func _install_qp(file_path: String) -> void:
	var zip = ZIPReader.new()
	if zip.open(file_path) != OK:
		push_error("Failed to open .qp file: " + file_path)
		return

	var all_entries: PackedStringArray = zip.get_files()

	var qua_files: Array[String] = []
	for entry in all_entries:
		if entry.to_lower().ends_with(".qua"):
			qua_files.append(entry)

	if qua_files.is_empty():
		push_error("No .qua files found inside: " + file_path)
		zip.close()
		return

	$Importing.visible = true

	var groups: Dictionary = {}
	for qua_entry in qua_files:
		var dir = qua_entry.get_base_dir()
		if not groups.has(dir):
			groups[dir] = []
		groups[dir].append(qua_entry)

	var total_converted := 0
	var group_index := 0

	for dir in groups.keys():
		var entries_in_group: Array = groups[dir]
		var raw_source = zip.read_file(entries_in_group[0]).get_string_from_utf8()
		var raw_data   = _parse_qua_data(raw_source)

		var song_folder_name: String
		if dir != "":
			song_folder_name = _sanitise_filename(dir.get_file())
		else:
			song_folder_name = _sanitise_filename(file_path.get_file().get_basename())
		if groups.size() > 1:
			song_folder_name += "_%d" % group_index
		var out_dir: String = MODS_FOLDER + song_folder_name + "/"
		DirAccess.make_dir_recursive_absolute(out_dir)

		var audio_name: String = raw_data.get("AudioFile", "")
		var bg_name:    String = raw_data.get("BackgroundFile", "")

		var audio_entry = _find_entry_in_dir(all_entries, dir, audio_name)
		if audio_entry != "":
			var audio_ext  = audio_entry.get_extension().to_lower()
			var audio_data = zip.read_file(audio_entry)
			var audio_out  = FileAccess.open(out_dir + "audio." + audio_ext, FileAccess.WRITE)
			if audio_out:
				audio_out.store_buffer(audio_data)
				audio_out.close()

		var bg_entry = _find_entry_in_dir(all_entries, dir, bg_name)
		if bg_entry != "":
			var bg_ext  = bg_entry.get_extension().to_lower()
			var bg_data = zip.read_file(bg_entry)
			var bg_out  = FileAccess.open(out_dir + "background." + bg_ext, FileAccess.WRITE)
			if bg_out:
				bg_out.store_buffer(bg_data)
				bg_out.close()

		var converted_count := 0
		for qua_entry in entries_in_group:
			var qsource = zip.read_file(qua_entry).get_string_from_utf8()
			var chart   = _parse_qua_chart(qsource)
			if chart.is_empty():
				push_error("Failed to parse: " + qua_entry)
				continue

			var diff_name: String = chart.get("difficulty", qua_entry.get_file().get_basename())
			diff_name = _sanitise_filename(diff_name)
			if diff_name == "":
				diff_name = "difficulty_%d" % converted_count

			var json_str  = JSON.stringify(chart, "\t")
			var json_path = out_dir + diff_name + ".json"
			var json_out  = FileAccess.open(json_path, FileAccess.WRITE)
			if json_out:
				json_out.store_string(json_str)
				json_out.close()
				converted_count += 1
			else:
				push_error("Could not write: " + json_path)

		total_converted += converted_count
		group_index += 1

	zip.close()

	if total_converted == 0:
		push_error("No difficulties were converted from: " + file_path)
		return

	print("Installed .qp '%s' (%d difficulties)" % [file_path.get_file(), total_converted])
	$Importing.visible = false
	$AudioStreamPlayer.play()
	DirAccess.remove_absolute(file_path)

	_reload_after_install()

func _osu_x_to_lane(x: int, key_count: int) -> int:
	var lane = int(x * key_count / 512) + 1
	return clampi(lane, 1, key_count)

func _parse_osu_kv_section(source: String, section: String) -> Dictionary:
	var result: Dictionary = {}
	var pattern = "\\[" + section + "\\]"
	var in_section := false
	for line in source.split("\n"):
		line = line.strip_edges()
		if line == "[" + section + "]":
			in_section = true
			continue
		if in_section:
			if line.begins_with("["):
				break
			if ":" in line:
				var idx = line.find(":")
				var k   = line.left(idx).strip_edges()
				var v   = line.substr(idx + 1).strip_edges()
				result[k] = v
	return result

func _parse_osu_raw_section(source: String, section: String) -> Array:
	var lines: Array = []
	var in_section := false
	for line in source.split("\n"):
		line = line.strip_edges()
		if line == "[" + section + "]":
			in_section = true
			continue
		if in_section:
			if line.begins_with("["):
				break
			if line != "" and not line.begins_with("//"):
				lines.append(line)
	return lines

func _parse_osu_chart(source: String) -> Dictionary:
	if source.begins_with("\ufeff"):
		source = source.substr(1)

	var general  = _parse_osu_kv_section(source, "General")
	var metadata = _parse_osu_kv_section(source, "Metadata")
	var diff     = _parse_osu_kv_section(source, "Difficulty")

	var key_count: int  = int(diff.get("CircleSize", "4"))
	var offset:    int  = int(general.get("AudioLeadIn", "0"))
	var title:     String = metadata.get("Title", "")
	var creator:   String = metadata.get("Creator", "")
	var artist:   String = metadata.get("Artist", "")
	var version:   String = metadata.get("Version", "")
	var map_id:    int   = int(metadata.get("BeatmapID", "0"))

	var bpm: float             = -1.0
	var sv_points: Array       = []

	for line in _parse_osu_raw_section(source, "TimingPoints"):
		var parts = line.split(",")
		if parts.size() < 7:
			continue

		var tp_time:     int   = int(parts[0])
		var beat_length: float = float(parts[1])
		var uninherited: bool  = parts[6].strip_edges() == "1"

		if uninherited:
			if beat_length > 0.0:
				if bpm < 0.0:
					bpm = snappedf(60000.0 / beat_length, 0.001)
				sv_points.append({"time": tp_time, "multiplier": 1.0})
		else:
			if beat_length < 0.0:
				var mult = snappedf(-100.0 / beat_length, 0.000001)
				sv_points.append({"time": tp_time, "multiplier": mult})

	if sv_points.is_empty() or sv_points[0]["time"] != 0:
		sv_points.insert(0, {"time": 0, "multiplier": 1.0})
	sv_points.sort_custom(func(a, b): return a["time"] < b["time"])

	var notes: Array = []

	for line in _parse_osu_raw_section(source, "HitObjects"):
		var parts = line.split(",")
		if parts.size() < 5:
			continue

		var x:        int = int(parts[0])
		var time:     int = int(parts[2])
		var obj_type: int = int(parts[3])
		var lane:     int = _osu_x_to_lane(x, key_count)

		var note: Dictionary = {"time": time, "lane": lane}

		if obj_type == 128 and parts.size() >= 6:
			var end_time = int(parts[5].split(":")[0])
			note["duration"] = end_time - time

		notes.append(note)

	notes.sort_custom(func(a, b):
		return a["time"] < b["time"] if a["time"] != b["time"] else a["lane"] < b["lane"]
	)

	var chart: Dictionary = {
		"title":      title,
		"difficulty": version,
		"offset":     offset,
		"map_id":     map_id,
		"credits":    artist,
		"mapper":     creator,
		"key_count":  key_count,
		"sv":         sv_points,
		"notes":      notes,
	}
	if bpm >= 0.0:
		chart["bpm"] = bpm

	return chart

func _parse_qua_data(source: String) -> Dictionary:
	if source.begins_with("\ufeff"):
		source = source.substr(1)

	var lines: Array = source.split("\n")
	var data: Dictionary = {}
	var i := 0
	while i < lines.size():
		var line: String = lines[i]
		var trimmed: String = line.strip_edges()
		if trimmed == "" or trimmed.begins_with("#"):
			i += 1
			continue
		var indent: int = line.length() - line.lstrip(" ").length()
		if indent != 0:
			i += 1
			continue
		var colon_idx: int = trimmed.find(":")
		if colon_idx == -1:
			i += 1
			continue
		var key: String   = trimmed.left(colon_idx).strip_edges()
		var value: String = trimmed.substr(colon_idx + 1).strip_edges()
		if value == "":
			var parsed = _parse_qua_list_items(lines, i + 1, 0)
			data[key] = parsed["items"]
			i = parsed["next_index"]
		elif value == "[]":
			data[key] = []
			i += 1
		else:
			data[key] = _strip_quotes(value)
			i += 1
	return data

func _parse_qua_list_items(lines: Array, start_index: int, base_indent: int) -> Dictionary:
	var items: Array = []
	var i: int = start_index
	while i < lines.size():
		var line: String = lines[i]
		if line.strip_edges() == "":
			i += 1
			continue
		var indent: int = line.length() - line.lstrip(" ").length()
		if indent < base_indent:
			break
		if indent == base_indent and line.strip_edges().begins_with("- "):
			var item: Dictionary = {}
			var rest: String = line.strip_edges().substr(2)
			var c: int = rest.find(":")
			if c != -1:
				item[rest.left(c).strip_edges()] = _strip_quotes(rest.substr(c + 1).strip_edges())
			i += 1
			while i < lines.size():
				var line2: String = lines[i]
				if line2.strip_edges() == "":
					i += 1
					continue
				var indent2: int = line2.length() - line2.lstrip(" ").length()
				if indent2 <= base_indent:
					break
				var s2: String = line2.strip_edges()
				var c2: int = s2.find(":")
				if c2 != -1:
					item[s2.left(c2).strip_edges()] = _strip_quotes(s2.substr(c2 + 1).strip_edges())
				i += 1
			items.append(item)
		else:
			break
	return {"items": items, "next_index": i}

func _parse_qua_chart(source: String) -> Dictionary:
	var data = _parse_qua_data(source)
	if data.is_empty():
		return {}

	var mode: String   = data.get("Mode", "Keys4")
	var key_count: int = mode.replace("Keys", "").to_int()
	if key_count <= 0:
		key_count = 4

	var title:   String = data.get("Title", "")
	var artist:  String = data.get("Artist", "")
	var creator: String = data.get("Creator", "")
	var diff:    String = data.get("DifficultyName", "")
	var map_id:  int    = int(data.get("MapId", "0"))

	var sv_points: Array = []
	var bpm: float = -1.0

	for tp in data.get("TimingPoints", []):
		var t: int = int(float(tp.get("StartTime", "0")))
		sv_points.append({"time": t, "multiplier": 1.0})
		if bpm < 0.0:
			bpm = float(tp.get("Bpm", "0"))

	for sv in data.get("SliderVelocities", []):
		var t2: int     = int(float(sv.get("StartTime", "0")))
		var mult: float = float(sv.get("Multiplier", "1.0"))
		sv_points.append({"time": t2, "multiplier": mult})

	if sv_points.is_empty() or sv_points[0]["time"] != 0:
		sv_points.insert(0, {"time": 0, "multiplier": 1.0})
	sv_points.sort_custom(func(a, b): return a["time"] < b["time"])

	var notes: Array = []
	for ho in data.get("HitObjects", []):
		var lane: int = int(ho.get("Lane", "1"))
		var time: int = int(float(ho.get("StartTime", "0")))
		var note: Dictionary = {"time": time, "lane": lane}
		if ho.has("EndTime"):
			var end_time: int = int(float(ho["EndTime"]))
			note["duration"] = end_time - time
		notes.append(note)

	notes.sort_custom(func(a, b):
		return a["time"] < b["time"] if a["time"] != b["time"] else a["lane"] < b["lane"]
	)

	var chart: Dictionary = {
		"title":      title,
		"difficulty": diff,
		"offset":     0,
		"map_id":     map_id,
		"credits":    artist,
		"mapper":     creator,
		"key_count":  key_count,
		"sv":         sv_points,
		"notes":      notes,
	}
	if bpm >= 0.0:
		chart["bpm"] = bpm

	return chart

func _find_entry_in_dir(all_entries: PackedStringArray, dir: String, filename: String) -> String:
	if filename == "":
		return ""
	var target: String = (dir + "/" + filename) if dir != "" else filename
	target = target.to_lower()
	for entry in all_entries:
		if entry.to_lower() == target:
			return entry
	return ""

func _strip_quotes(s: String) -> String:
	if s.length() >= 2 and ((s.begins_with("\"") and s.ends_with("\"")) or (s.begins_with("'") and s.ends_with("'"))):
		return s.substr(1, s.length() - 2)
	return s

func _sanitise_filename(s: String) -> String:
	for ch in ["\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		s = s.replace(ch, "-")
	while s.contains("--"):
		s = s.replace("--", "-")
	s = s.strip_edges().trim_suffix("-").trim_prefix("-")
	if s == "":
		s = "unknown"
	return s

func _reload_after_install() -> void:
	var container = $play_menu/Categories/VBoxContainer

	for child in container.get_children():
		child.queue_free()

	await get_tree().process_frame
	await get_tree().process_frame

	ModLoader._scan_mods()
	$play_menu.load_categories()
