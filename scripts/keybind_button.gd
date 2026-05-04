extends Button

var action_name: String = "left"
var is_listening := false

func _ready():
	pressed.connect(_on_pressed)
	update_label()

func update_label():
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		text = events[0].as_text()
	else:
		text = "Unbound"

func _on_pressed():
	is_listening = true
	text = "Press a key..."

func _input(event):
	if not is_listening:
		return
	if event is InputEventKey and event.pressed:
		InputMap.action_erase_events(action_name)
		InputMap.action_add_event(action_name, event)
		is_listening = false
		update_label()
		get_viewport().set_input_as_handled()
