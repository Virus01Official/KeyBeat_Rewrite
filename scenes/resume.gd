extends Button

func _on_pressed() -> void:
	$"..".visible = false
	$"../.."._toggle_pause()
