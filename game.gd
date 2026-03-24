extends Control

var down_pressed = false
var left_pressed = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("down"):
		_change_visibility($Down/TextureRect, false)
		_change_visibility($Down/Glow, true)
		down_pressed = true
	if Input.is_action_just_pressed("left"):
		_change_visibility($Left/TextureRect, false)
		_change_visibility($Left/Glow, true)
		left_pressed = true

	if Input.is_action_just_released("down"):
		_change_visibility($Down/TextureRect, true)
		_change_visibility($Down/Glow, false)
		down_pressed = false
	if Input.is_action_just_released("left"):
		_change_visibility($Left/TextureRect, true)
		_change_visibility($Left/Glow, false)
		left_pressed = false
		
func _change_visibility(obj, boole) -> void:
	obj.visible = boole
