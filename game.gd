extends Control

# --- existing vars ---
var down_pressed = false
var left_pressed = false
var up_pressed = false
var right_pressed = false
var maps_location = "res://songs/"

# --- new vars ---
var note_scene = preload("res://Note.tscn")
var chart: Array = []         # list of {time, direction}
var song_position: float = 0.0
var song_started: bool = false
var next_note_index: int = 0

# Hit window in seconds
const HIT_WINDOW = 0.5
# Y position of the receptor (your arrow buttons)
const RECEPTOR_Y = -4
# Notes spawn this many seconds before they need to be hit
const LEAD_TIME = 2.0
const NOTE_SPEED = 300.0

@onready var note_container = $NoteContainer  # Add a plain Control node as child

func _ready() -> void:
	_start("Tutorial")

func _process(delta: float) -> void:
	if song_started:
		song_position += delta
		_spawn_notes()

	# --- your existing input code ---
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

	# --- your existing release code (unchanged) ---
	if Input.is_action_just_released("down"):
		_change_visibility($Down/TextureRect, true)
		_change_visibility($Down/Glow, false)
		down_pressed = false
	if Input.is_action_just_released("left"):
		_change_visibility($Left/TextureRect, true)
		_change_visibility($Left/Glow, false)
		left_pressed = false
	if Input.is_action_just_released("up"):
		_change_visibility($Up/TextureRect, true)
		_change_visibility($Up/Glow, false)
		up_pressed = false
	if Input.is_action_just_released("right"):
		_change_visibility($Right/TextureRect, true)
		_change_visibility($Right/Glow, false)
		right_pressed = false

func _spawn_notes() -> void:
	while next_note_index < chart.size():
		var note_data = chart[next_note_index]
		if note_data["time"] / 1000.0 <= song_position + LEAD_TIME:
			var note = note_scene.instantiate()
			note.direction = _lane_to_direction(note_data["lane"])
			note.position = _get_lane_x(note.direction)
			note_container.add_child(note)
			next_note_index += 1
		else:
			break

func _get_lane_x(direction: String) -> Vector2:
	match direction:
		"left":  return Vector2($Left.position.x,  RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"down":  return Vector2($Down.position.x,  RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"up":    return Vector2($Up.position.x,    RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
		"right": return Vector2($Right.position.x, RECEPTOR_Y + NOTE_SPEED * LEAD_TIME)
	return Vector2.ZERO
	
# At the top, replace the lane mapping helper
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

	# Convert pixel distance to seconds
	var time_diff = closest_dist / NOTE_SPEED if closest else INF

	if time_diff <= HIT_WINDOW:
		closest.queue_free()
		_register_hit(time_diff)
	else:
		_register_miss()

func _register_hit(time_diff: float) -> void:
	if time_diff < 0.05:
		print("PERFECT")
	elif time_diff < 0.10:
		print("GOOD")
	else:
		print("BAD")

func _register_miss() -> void:
	print("MISS")

func _change_visibility(obj, boole) -> void:
	obj.visible = boole

func _start(song: String) -> void:
	var path = maps_location + song + "/song.json"
	print(path)
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		chart = json.get_data()  # expects [{time: 1.2, direction: "left"}, ...]
		chart.sort_custom(func(a, b): return a["time"] < b["time"])
		song_position = 0.0
		next_note_index = 0
		song_started = true
