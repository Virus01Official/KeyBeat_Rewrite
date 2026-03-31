extends Control

func _on_play_pressed() -> void:
	$"../play_menu".visible = true
	$".".visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
