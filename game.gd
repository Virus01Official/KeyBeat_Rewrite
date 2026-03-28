extends Control

var down_pressed = false
var left_pressed = false
var up_pressed = false
var right_pressed = false
var maps_location = "res://songs/"

var countdown: float = 0.0

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
const NOTE_SPEED = 500.0

@onready var note_container = $NoteContainer  

func _ready() -> void:
	$Pause.process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if song_started:
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
		
	$Stuff/Perfect.text = "Perfect: " + str(perfect)
	$Stuff/Great.text = "Great: " + str(great)
	$Stuff/Good.text = "Good: " + str(good)
	$Stuff/Okay.text = "Okay: " + str(ok)
	$Stuff/Bad.text = "Bad: " + str(meh)
	$Stuff/Misses.text = "Misses: " + str(misses)
	$Stuff/Score.text = str(score)
	$Stuff/Combo.text = str(combo)
	
	var acc := _accuracy()
	$Stuff/Accurancy.text = "%.2f%%" % acc          # e.g. "97.43%"
	#$Stuff/Grade.text    = _grade(acc)
	
	$Health.value = lerp($Health.value, float(health), delta * 10.0)
	
	for note in note_container.get_children():
		if note.hold_active:
			var shrink = delta * NOTE_SPEED
			note.tail.size.y = max(0.0, note.tail.size.y - shrink)
			note.tail.position.y = 64  
			
	if Input.is_action_just_pressed("ui_cancel"):
		_toggle_pause()
		return

	if paused:
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
			
		if note.position.y < RECEPTOR_Y - (HIT_WINDOW_MISS * NOTE_SPEED) and not note.hold_active:
			_register_miss()
			note.queue_free()
			
func _spawn_notes() -> void:
	var spawn_ahead = song_position + LEAD_TIME if $AudioStreamPlayer.playing else LEAD_TIME
	while next_note_index < chart.size():
		var note_data = chart[next_note_index]
		if note_data["time"] / 1000.0 <= spawn_ahead:
			var note = note_scene.instantiate()
			note.direction = _lane_to_direction(note_data["lane"])
			note.position = _get_lane_x(note.direction)
			note.duration = note_data.get("duration", 0) / 1000.0
			note_container.add_child(note)
			note.init_tail()
			next_note_index += 1
		else:
			break

func _toggle_pause() -> void:
	paused = !paused
	$Pause.visible = paused
	if paused:
		get_tree().paused = true
		$Pause.process_mode = Node.PROCESS_MODE_ALWAYS  # so Pause UI still works while tree is paused
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
	else:
		closest.queue_free()
		_register_hit(time_diff)
			
func _check_hold_release(direction: String) -> void:
	for note in note_container.get_children():
		if note.direction != direction or not note.hold_active:
			continue
			
		if note.tail.size.y > 10.0:   
			_register_miss()
		note.queue_free()

func _register_hit(time_diff: float) -> void:
	if time_diff <= HIT_WINDOW_PERFECT:
		print("MAX (320)")
		perfect += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 320
		health = min(health + 20, max_health)
	elif time_diff <= HIT_WINDOW_GREAT:
		print("GREAT (300)")
		great += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 300
		health = min(health + 16, max_health)
	elif time_diff <= HIT_WINDOW_GOOD:
		print("GOOD (200)")
		good += 1
		score += 200
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		health = min(health + 12, max_health)
	elif time_diff <= HIT_WINDOW_OK:
		print("OK (100)")
		ok += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 100
		health = min(health + 8, max_health)
	else:
		print("MEH (50)")
		meh += 1
		combo += 1
		if combo > highest_combo:
			highest_combo = combo
		score += 50
		health = min(health + 4, max_health)

func _register_miss() -> void:
	print("MISS")
	misses += 1
	combo = 0
	score -= 10
	health -= 10

func _change_visibility(obj, boole) -> void:
	obj.visible = boole
	
func _start(song: String, json_file: String) -> void:
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
		
func _end_song() -> void:
	song_started = false
	$AudioStreamPlayer.stop()
	
	var final_acc := _accuracy()
	print("Song complete! Accuracy: %.2f%% | Grade: %s" % [final_acc, _grade(final_acc)])
	
	$".".visible = false
	$"../play_menu".visible = true
	perfect = 0
	great = 0
	misses = 0
	combo = 0
	highest_combo = 0
	score = 0
	good = 0
	ok = 0
	meh = 0
	health = max_health
	# Add your scene transition or results screen logic here
