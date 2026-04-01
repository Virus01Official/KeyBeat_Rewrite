extends Button

func _on_pressed() -> void:
	$"../..".visible = true
	$"..".visible = false
	$"../.."._toggle_pause()
	$"../.."._restart()
