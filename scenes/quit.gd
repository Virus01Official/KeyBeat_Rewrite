extends Button

func _on_pressed() -> void:
	get_tree().paused = false
	$"..".visible = false
	$"../.."._end_song()
	$"../..".visible = false
	$"../.."._reset_all_stats()
