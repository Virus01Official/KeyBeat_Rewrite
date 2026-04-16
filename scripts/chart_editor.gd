extends Control

var note_scene = preload("res://Note.tscn")
var chart: Array = []  
var song_position: float = 0.0
var song_started: bool = false
var next_note_index: int = 0

const RECEPTOR_Y = 3

var offset: float = 0.0

const LEAD_TIME = 2.0
var NOTE_SPEED: float:
	get: return GameData.Scroll_Speed

@onready var note_container = $NoteContainer 

func _ready() -> void:
	pass


func _process(delta: float) -> void:
	pass
