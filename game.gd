extends Control

var down_pressed = false
var left_pressed = false
var up_pressed = false
var right_pressed = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("down"):
		_change_visibility($Down/TextureRect, false)
		_change_visibility($Down/Glow, true)
		down_pressed = true
	if Input.is_action_just_pressed("left"):
		_change_visibility($Left/TextureRect, false)
		_change_visibility($Left/Glow, true)
		left_pressed = true
	if Input.is_action_just_pressed("up"):
		_change_visibility($Up/TextureRect, false)
		_change_visibility($Up/Glow, true)
		up_pressed = true
	if Input.is_action_just_pressed("right"):
		_change_visibility($Right/TextureRect, false)
		_change_visibility($Right/Glow, true)
		right_pressed = true

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
		
func _change_visibility(obj, boole) -> void:
	obj.visible = boole
