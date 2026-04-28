extends Control

var down_pressed = false
var left_pressed = false
var up_pressed = false
var right_pressed = false
var maps_location = "res://songs/"

var stun_timer = 0.0

var STUN_DURATION = 2.0

var _rating_tween: Tween

var final_accuracy: float = 0.0
var final_grade: String = ""
var _touch_direction: Dictionary = {}

@onready var rating = $Rating

var current_song: String = ""
var current_json: String = ""
var current_song_path: String = ""

var sv_points: Array = []

var countdown: float = 0.0

var rating_textures = {
	"max":   preload("res://assets/rating/Perfect.png"),
	"great": preload("res://assets/rating/Great.png"),
	"good":  preload("res://assets/rating/Good.png"),
	"ok":    preload("res://assets/rating/Okay.png"),
	"meh":   preload("res://assets/rating/Bad.png"),
	"miss":  preload("res://assets/rating/Miss.png"),
}

var paused = false

var health = 100
var max_health = 100

var combo = 0
var highest_combo = 0
var score = 0

var note_scene = preload("res://Note.tscn")
var chart: Array = []        
var song_position: float = 0.0
var song_started: bool = false
var next_note_index: int = 0

const HIT_WINDOW_PERFECT = 0.016   # ±16ms  — MAX (320)
const HIT_WINDOW_GREAT   = 0.040   # ±40ms  — 300
const HIT_WINDOW_GOOD    = 0.073   # ±73ms  — 200
const HIT_WINDOW_OK      = 0.103   # ±103ms — 100
const HIT_WINDOW_MEH     = 0.127   # ±127ms — 50
const HIT_WINDOW_MISS    = 0.188

var perfect = 0
var great = 0
var good = 0
var ok = 0
var meh = 0
var misses = 0

var offset: float = 0.0

const RECEPTOR_Y = 3

const LEAD_TIME = 2.0
var NOTE_SPEED: float:
	get: return GameData.Scroll_Speed

@onready var note_container = $NoteContainer  

func _ready() -> void:
	$Pause.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	var current_sv = _get_current_sv_multiplier()
	var effective_speed = NOTE_SPEED * current_sv

	if song_started:
		if $AudioStreamPlayer.playing:
			_spawn_notes()
			_check_missed_notes()
		
		if not $AudioStreamPlayer.playing:
			countdown -= delta
			if countdown <= 0.0:
				$AudioStreamPlayer.play()
		else:
			song_position = $AudioStreamPlayer.get_playback_position()
			
		if next_note_index >= chart.size() and note_container.get_child_count() == 0:
			_end_song()
			return
		
		
	$Hidden.visible = Modifiers.hidden
	
	$Stuff/Perfect.text = "Perfect: " + str(perfect)
	$Stuff/Great.text = "Great: " + str(great)
	$Stuff/Good.text = "Good: " + str(good)
	$Stuff/Okay.text = "Okay: " + str(ok)
	$Stuff/Bad.text = "Bad: " + str(meh)
	$Stuff/Misses.text = "Misses: " + str(misses)
	$Stuff/Score.text = str(score)
	$Stuff/Combo.text = str(combo)
	
	var acc := _accuracy()
	$Stuff/Accurancy.text = "%.2f%%" % acc
	
	$Health.value = lerp($Health.value, float(health), delta * 10.0)
	
	for note in note_container.get_children():
		if note.hold_active:
			var shrink = delta * effective_speed
			note.tail.size.y = max(0.0, note.tail.size.y - shrink)
			note.tail.position.y = 64
		else:
			note.move(delta, effective_speed)
			
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()
		$Pause.visible = paused
		$Pause/Resume.visible = true
		$Pause/Label.text = "PAUSED"
		return

	if paused:
		return
		
	match OS.get_name():
		"Android":
			$Mobile.visible = true
		
	if health <= 0 and not Modifiers.no_fail:
		_toggle_pause()
		$Pause.visible = true
		$Pause/Resume.visible = false
		$Pause/Label.text = "GAME OVER"
	
	if stun_timer > 0.0:
		stun_timer -= delta
		return
	
	if Input.is_action_just_pressed("down"):
		_change_visibility($Down/TextureRect, false)
		_change_visibility($Down/Glow, true)
		down_pressed = true
		_check_hit("down")
	if Input.is_action_just_pressed("left"):
		_change_visibility($Left/TextureRect, false)
		_change_visibility($Left/Glow, true)
		left_pressed = true
		_check_hit("left")
	if Input.is_action_just_pressed("up"):
		_change_visibility($Up/TextureRect, false)
		_change_visibility($Up/Glow, true)
		up_pressed = true
		_check_hit("up")
	if Input.is_action_just_pressed("right"):
		_change_visibility($Right/TextureRect, false)
		_change_visibility($Right/Glow, true)
		right_pressed = true
		_check_hit("right")

	if Input.is_action_just_released("down"):
		_change_visibility($Down/TextureRect, true)
		_change_visibility($Down/Glow, false)
		down_pressed = false
		_check_hold_release("down")
		
	if Input.is_action_just_released("left"):
		_change_visibility($Left/TextureRect, true)
		_change_visibility($Left/Glow, false)
		left_pressed = false
		_check_hold_release("left")
		
	if Input.is_action_just_released("up"):
		_change_visibility($Up/TextureRect, true)
		_change_visibility($Up/Glow, false)
		up_pressed = false
		_check_hold_release("up")
		
	if Input.is_action_just_released("right"):
		_change_visibility($Right/TextureRect, true)
		_change_visibility($Right/Glow, false)
		right_pressed = false
		_check_hold_release("right")

func _input(event: InputEvent) -> void:
	if not OS.get_name() == "Android":
		return
	if paused:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			var dir = _get_touch_direction(event.position)
			if dir != "":
				_touch_direction[event.index] = dir
				_change_visibility(get_node(dir.capitalize() + "/TextureRect"), false)
				_change_visibility(get_node(dir.capitalize() + "/Glow"), true)
				_check_hit(dir)
		else:
			var dir = _touch_direction.get(event.index, "")
			if dir != "":
				_change_visibility(get_node(dir.capitalize() + "/TextureRect"), true)
				_change_visibility(get_node(dir.capitalize() + "/Glow"), false)
				_check_hold_release(dir)
				_touch_direction.erase(event.index)

static func calculate_difficulty(charts: Dictionary) -> float:
	var notes: Array = charts.get("notes", [])
	if notes.is_empty():
		return 0.0

	notes.sort_custom(func(a, b): return a["time"] < b["time"])

	var bpm: float = float(charts.get("bpm", 120))
	var beat_ms: float = 60000.0 / bpm

	var duration: float = (notes[-1]["time"] - notes[0]["time"]) / 1000.0
	if duration <= 0.0:
		duration = 1.0
	var nps: float = notes.size() / duration
	var density_score: float = minf(nps / 8.0, 1.0)

	var max_run := 0
	var run := 0
	for i in range(1, notes.size()):
		var gap: float = float(notes[i]["time"] - notes[i - 1]["time"])
		if gap < beat_ms * 0.28:
			run += 1
			max_run = max(max_run, run)
		else:
			run = 0
	var stream_score: float = minf(float(max_run) / 16.0, 1.0)

	var total_lane_dist := 0.0
	var holds := 0
	for i in range(1, notes.size()):
		total_lane_dist += abs(int(notes[i]["lane"]) - int(notes[i - 1]["lane"]))
		if notes[i].has("duration"):
			holds += 1
	var avg_lane_dist: float = total_lane_dist / (notes.size() - 1)
	var hold_ratio: float = float(holds) / notes.size()
	var pattern_score: float = minf(avg_lane_dist / 2.0 * 0.6 + hold_ratio * 0.4, 1.0)

	var bpm_factor: float = minf(bpm / 200.0, 1.0)

	var raw: float = density_score * 3.5 + stream_score * 3.0 \
				   + pattern_score * 2.0 + bpm_factor * 1.5
	return clampf(raw, 0.1, 10.0)

func _total_notes() -> int:
	return perfect + great + good + ok + meh + misses

func _weighted_score() -> float:
	return (320.0 * perfect + 300.0 * great + 200.0 * good
		  + 100.0 * ok      +  50.0 * meh)

func _accuracy() -> float:
	var total := _total_notes()
	if total == 0:
		return 100.0
	return (_weighted_score() / (320.0 * total)) * 100.0

func _grade(acc: float) -> String:
	if acc >= 100.0: return "SS"
	elif acc >= 95.0: return "S"
	elif acc >= 90.0: return "A"
	elif acc >= 80.0: return "B"
	elif acc >= 70.0: return "C"
	else: return "D"

func _check_missed_notes() -> void:
	for note in note_container.get_children():
		if note.is_hold and note.hold_active and note.tail.size.y <= 0.0:
			_register_hit(0.0)
			note.queue_free()
			continue

		if not note.hold_active and note.position.y < RECEPTOR_Y - 64:
			if note.is_stun:
				note.queue_free()
				continue
			_register_miss()
			note.queue_free()
			
func _spawn_notes() -> void:
	var spawn_ahead = song_position + LEAD_TIME if $AudioStreamPlayer.playing else LEAD_TIME
	
	while next_note_index < chart.size():
		var note_data = chart[next_note_index]
		if note_data["time"] / 1000.0 <= spawn_ahead:
			var note = note_scene.instantiate()
			note.direction = _lane_to_direction(note_data["lane"])
			
			var note_tex = ModLoader.get_note_texture(note.direction)
			if note_tex:
				note.get_node("Note").texture = note_tex

			var note_time = note_data["time"] / 1000.0
			var current_scroll = _get_scroll_position(song_position)
			var note_scroll   = _get_scroll_position(note_time)
			var visual_offset = (note_scroll - current_scroll) * NOTE_SPEED

			note.position = _get_lane_x(note.direction)
			note.position.y = RECEPTOR_Y + visual_offset
			
			note.is_stun = note_data.get("type", "") == "stun"

			note.duration = note_data.get("duration", 0) / 1000.0
			note_container.add_child(note)
			note.init_tail(NOTE_SPEED)
			next_note_index += 1
		else:
			break

func _get_scroll_position(time_sec: float) -> float:
	var pos: float = 0.0
	for i in range(sv_points.size()):
		var sv = sv_points[i]
		var sv_time = sv["time"] / 1000.0
		var next_time = sv_points[i + 1]["time"] / 1000.0 if i + 1 < sv_points.size() else time_sec
		if time_sec <= sv_time:
			break
		var segment_end = min(time_sec, next_time)
		pos += (segment_end - sv_time) * sv["multiplier"]
	return pos

func _toggle_pause() -> void:
	paused = !paused
	if paused:
		get_tree().paused = true
		$Pause.process_mode = Node.PROCESS_MODE_ALWAYS  
	else:
		get_tree().paused = false

func _get_lane_x(direction: String) -> Vector2:
	match direction:
		"left":  return Vector2($Left/TextureRect.global_position.x,  RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"down":  return Vector2($Down/TextureRect.global_position.x,  RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"up":    return Vector2($Up/TextureRect.global_position.x,    RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"right": return Vector2($Right/TextureRect.global_position.x, RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
	return Vector2.ZERO
			
func _lane_to_direction(lane: int) -> String:
	match lane:
		1: return "left"
		2: return "down"
		3: return "up"
		4: return "right"
	return ""

func _check_hit(direction: String) -> void:
	var closest: Node = null
	var closest_dist = INF

	for note in note_container.get_children():
		if note.direction != direction:
			continue
		var dist = abs(note.position.y - RECEPTOR_Y)
		if dist < closest_dist:
			closest_dist = dist
			closest = note

	if closest == null:
		return

	var time_diff = closest_dist / NOTE_SPEED

	if time_diff > HIT_WINDOW_MISS:
		return

	if closest.is_hold:
		closest.hold_active = true
		_register_hit(time_diff)
		if closest.is_stun:
			_apply_stun()
		$Hitsound.play()
	else:
		closest.queue_free()
		if closest.is_stun:
			_apply_stun()
		_register_hit(time_diff)
		$Hitsound.play()
			
func _check_hold_release(direction: String) -> void:
	for note in note_container.get_children():
		if note.direction != direction or not note.hold_active:
			continue
			
		if note.tail.size.y > 10.0:   
			_register_miss()
		note.queue_free()

func _apply_stun() -> void:
	stun_timer = STUN_DURATION

func _register_hit(time_diff: float) -> void:
	if time_diff <= HIT_WINDOW_PERFECT:
		_show_rating("max")
		perfect += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 320
		health = min(health + 20, max_health)
	elif time_diff <= HIT_WINDOW_GREAT:
		_show_rating("great")
		great += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 300
		health = min(health + 16, max_health)
	elif time_diff <= HIT_WINDOW_GOOD:
		_show_rating("good")
		good += 1
		score += 200
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		health = min(health + 12, max_health)
	elif time_diff <= HIT_WINDOW_OK:
		_show_rating("ok")
		ok += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 100
		health = min(health + 8, max_health)
	else:
		_show_rating("meh")
		meh += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 50
		health = min(health + 4, max_health)

func _register_miss() -> void:
	misses += 1
	combo = 0
	score -= 10
	health -= 10
	$Miss.play()
	_show_rating("miss")

func _change_visibility(obj, boole) -> void:
	obj.visible = boole
	
func _start(song: String, json_file: String) -> void:
	current_song = song
	current_json = json_file
	paused = false
	$Pause.visible = false
	var path = maps_location + song + "/" + json_file
	print(path)
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		var data = json.get_data()
		chart = data.get("notes", []) 
		chart.sort_custom(func(a, b): return a["time"] < b["time"])
		offset = data.get("offset", 0) / 1000.0
		countdown = offset
		song_position = 0.0
		next_note_index = 0
		
		sv_points = data.get("sv", [{"time": 0, "multiplier": 1.0}])
		sv_points.sort_custom(func(a, b): return a["time"] < b["time"])
		
		var audio_stream: AudioStream = null
		for ext in ["mp3", "ogg"]:
			var audio_path = maps_location + song + "/audio." + ext
			if ResourceLoader.exists(audio_path):
				audio_stream = load(audio_path)
				break
				
		for exte in ["png", "jpg", "jpeg"]:
			var image_path = maps_location + song + "/background." + exte
			if ResourceLoader.exists(image_path):
				$background.texture = load(image_path)
				break

		if audio_stream:
			$AudioStreamPlayer.stream = audio_stream

		song_started = true
		
func _start_from_path(song_folder_path: String, json_file: String) -> void:
	current_song_path = song_folder_path  
	current_json = json_file
	paused = false
	$Pause.visible = false

	var path = song_folder_path + json_file
	print("Loading chart: ", path)

	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Could not open chart: ", path)
		return

	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.get_data()

	chart = data.get("notes", [])
	chart.sort_custom(func(a, b): return a["time"] < b["time"])
	offset = data.get("offset", 0) / 1000.0
	countdown = offset
	song_position = 0.0
	next_note_index = 0

	sv_points = data.get("sv", [{"time": 0, "multiplier": 1.0}])
	sv_points.sort_custom(func(a, b): return a["time"] < b["time"])

	var audio_stream: AudioStream = null
	for ext in ["mp3", "ogg"]:
		var audio_path = song_folder_path + "audio." + ext
		
		if audio_path.begins_with("res://"):
			if ResourceLoader.exists(audio_path):
				audio_stream = load(audio_path)
				break
		else:
			if FileAccess.file_exists(audio_path):
				var files = FileAccess.open(audio_path, FileAccess.READ)
				var buffer = files.get_buffer(files.get_length())
				
				if ext == "ogg":
					var stream = AudioStreamOggVorbis.new()
					stream.data = buffer
					audio_stream = stream
					break
				elif ext == "mp3":
					var stream = AudioStreamMP3.new()
					stream.data = buffer
					audio_stream = stream
					break

	for exte in ["png", "jpg", "jpeg"]:
		var image_path = song_folder_path + "background." + exte
		var texture: Texture2D = null

		if image_path.begins_with("res://"):
			if ResourceLoader.exists(image_path):
				texture = load(image_path)
		else:
			if FileAccess.file_exists(image_path):
				var img = Image.load_from_file(image_path)
				if img != null and not img.is_empty():
					texture = ImageTexture.create_from_image(img)

		if texture:
			$background.texture = texture

	if audio_stream:
		$AudioStreamPlayer.stream = audio_stream

	song_started = true

func _get_current_sv_multiplier() -> float:
	var multiplier := 1.0
	for sv in sv_points:
		if sv["time"] / 1000.0 <= song_position:
			multiplier = sv["multiplier"]
		else:
			break
	return multiplier

func _restart() -> void:
	for note in note_container.get_children():
		note.queue_free()

	_reset_all_stats()
	song_started = false

	$AudioStreamPlayer.stop()

	if current_song_path != "":
		_start_from_path(current_song_path, current_json)
	else:
		_start(current_song, current_json)

func _reset_all_stats() -> void:
	perfect = 0
	chart = []
	great   = 0
	good    = 0
	ok      = 0
	meh     = 0
	misses  = 0
	score   = 0
	combo   = 0
	highest_combo = 0
	health  = max_health

func _end_song() -> void:
	song_started = false
	$AudioStreamPlayer.stop()
	chart = []
	
	final_accuracy = _accuracy()
	final_grade = _grade(final_accuracy)
	
	_save_score()
	
	$".".visible = false
	$"../Results".visible = true
	
	combo = 0
	health = max_health
	
func _save_score() -> void:
	var save_path := "user://scores.json"
	
	var map_key: String = current_song_path if current_song_path != "" else current_song
	if map_key == "":
		map_key = "unknown"
	
	var existing: Dictionary = {}
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f:
			var json := JSON.new()
			json.parse(f.get_as_text())
			f.close()
			var parsed = json.get_data()
			if parsed is Dictionary:
				existing = parsed
	
	var new_entry := {
		"score":         score,
		"accuracy":      snappedf(final_accuracy, 0.01),
		"grade":         final_grade,
		"perfect":       perfect,
		"great":         great,
		"good":          good,
		"ok":            ok,
		"meh":           meh,
		"misses":        misses,
		"highest_combo": highest_combo,
		"timestamp":     Time.get_datetime_string_from_system()
	}
	
	var prev = existing.get(map_key, null)
	if prev == null \
	or new_entry["score"] > int(prev.get("score", 0)) \
	or (new_entry["score"] == int(prev.get("score", 0)) and new_entry["accuracy"] > float(prev.get("accuracy", 0.0))):
		existing[map_key] = new_entry
		print("New best score saved for: ", map_key)
	else:
		print("Score not a new best — not saved.")
	
	var out := FileAccess.open(save_path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(existing, "\t"))
		out.close()
		print("Scores saved to: ", save_path)
	else:
		print("Failed to write scores file!")

func _show_rating(key: String) -> void:
	if _rating_tween:
		_rating_tween.kill()
	rating.texture = rating_textures.get(key)
	rating.modulate.a = 1.0
	_rating_tween = create_tween()
	_rating_tween.tween_interval(0.5)
	_rating_tween.tween_property(rating, "modulate:a", 0.0, 0.3)

func _get_touch_direction(pos: Vector2) -> String:
	if $Mobile/Left.get_global_rect().has_point(pos):
		return "left"
	if $Mobile/Down.get_global_rect().has_point(pos):
		return "down"
	if $Mobile/Up.get_global_rect().has_point(pos):
		return "up"
	if $Mobile/Right.get_global_rect().has_point(pos):
		return "right"
	return ""
