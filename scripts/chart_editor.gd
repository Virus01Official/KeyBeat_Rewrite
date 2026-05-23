extends Control

var note_scene = preload("res://Note.tscn")
var song_position: float = 0.0
var song_started: bool = false
var next_note_index: int = 0

var current_bpm = 0
var sv_points = []
var chart = []
var current_map_id = 0
var current_difficulty = "None"
var current_title = "None"
var current_credits = "No one"
var current_mapper = "No one"
var current_category = "None"

const RECEPTOR_Y = 3

var offset: float = 0.0

const LEAD_TIME = 2.0
var NOTE_SPEED: float:
	get: return GameData.Scroll_Speed

@onready var note_container = $NoteContainer 

func _build_chart_data() -> Dictionary:
	return {
		"title": current_title,
		"difficulty": current_difficulty,
		"offset": offset * 1000.0,
		"map_id": current_map_id,
		"credits": current_credits,
		"mapper": current_mapper,
		"category": current_category,
		"bpm": current_bpm,
		"sv": sv_points,
		"notes": chart
	}

func _save_chart(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_build_chart_data(), "\t"))
		file.close()
