extends Button

func _on_pressed() -> void:
	$"..".visible = false
	$"../.."._end_song()
	$"../..".visible = false
